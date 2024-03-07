drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
VALUES (1,'2017-09-22'),
(3,'2017-04-21');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
VALUES (1,'2014-09-02'),
(2,'2015-01-15'),
(3,'2014-04-11');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
VALUES (1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


-- Select statements to check data
select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

-- Query 1: Total amount spent by each user
select a.userid, sum(b.price) as total_amt_spent 
from sales a 
inner join product b on a.product_id = b.product_id
group by a.userid;

-- Query 2: Number of distinct days each user made a purchase
select userid, count(distinct created_date) as distinct_days
from sales 
group by userid;

-- Query 3: First purchase made by each user
select * 
from (select *, rank() over (partition by userid order by created_date) as rnk 
      from sales) a 
where rnk = 1;

-- Query 4: Number of purchases of the most purchased product by each user
select userid, count(product_id) as cnt 
from sales 
where product_id = (select product_id 
                    from sales 
                    group by product_id 
                    order by count(product_id) desc 
                    limit 1)
group by userid;

-- Query 5: Most frequently purchased product by each user
select * 
from (select *, rank() over (partition by userid order by cnt desc) as rnk 
      from (select userid, product_id, count(product_id) as cnt 
            from sales 
            group by userid, product_id) a) b 
where rnk = 1;

-- Query 6: First purchase after gold signup date for each user
select * 
from (select c.*, rank() over (partition by userid order by created_date) as rnk 
      from (select a.userid, a.created_date, a.product_id, b.gold_signup_date 
            from sales a 
            inner join goldusers_signup b 
            on a.userid = b.userid and a.created_date >= b.gold_signup_date) c) d 
where rnk = 1;

-- Query 7: Last purchase before gold signup date for each user
select * 
from (select c.*, rank() over (partition by userid order by created_date desc) as rnk 
      from (select a.userid, a.created_date, a.product_id, b.gold_signup_date 
            from sales a 
            inner join goldusers_signup b 
            on a.userid = b.userid and a.created_date <= b.gold_signup_date) c) d 
where rnk = 1;

-- Query 8: User-wise statistics after gold signup date
select userid, 
       count(created_date) as order_purchased, 
       sum(price) as total_amt_spent 
from (select c.*, d.price 
      from (select a.userid, a.created_date, a.product_id, b.gold_signup_date 
            from sales a 
            inner join goldusers_signup b 
            on a.userid = b.userid and a.created_date <= b.gold_signup_date) c 
      inner join product d 
      on c.product_id = d.product_id) e 
group by userid;

-- Query 9: Total points earned by each user
select userid, sum(total_points) * 2.5 as total_point_earned 
from (select e.*, amt / points as total_points 
      from (select d.*, 
                   case 
                     when product_id = 1 then 5 
                     when product_id = 2 then 2 
                     when product_id = 3 then 5 
                     else 0 
                   end as points 
            from (select c.userid, c.product_id, sum(price) as amt 
                  from (select a.*, b.price 
                        from sales a 
                        inner join product b 
                        on a.product_id = b.product_id) c 
                  group by userid, product_id) d) e) f 
group by userid;

-- Query 10: Most earned points product-wise
select * 
from (select * , rank() over (order by total_point_earned desc) as rnk 
      from (select product_id, sum(total_points) as total_point_earned 
            from (select e.*, amt / points as total_points 
                  from (select d.*, 
                               case 
                                 when product_id = 1 then 5 
                                 when product_id = 2 then 2 
                                 when product_id = 3 then 5 
                                 else 0 
                               end as points 
                        from (select c.userid, c.product_id, sum(price) as amt 
                              from (select a.*, b.price 
                                    from sales a 
                                    inner join product b 
                                    on a.product_id = b.product_id) c 
                              group by userid, product_id) d) e) f 
            group by product_id) g) h 
where rnk = 1;

-- Query 11: Total points earned for each user and product combination
select c.*, d.price * 0.5 as total_points_earned 
from (select a.userid, a.created_date, a.product_id, b.gold_signup_date 
      from sales a 
      inner join goldusers_signup b 
      on a.userid = b.userid and a.created_date >= b.gold_signup_date 
      and a.created_date <= date(b.gold_signup_date, '+1 year')) c 
inner join product d 
on c.product_id = d.product_id;

-- Query 12: Add a rank column and handle null values
select e.*, 
       case 
           when rnk = 1 then '1' 
           else 'na' 
       end as rnkk 
from (
    select c.*, 
           cast((case 
                     when gold_signup_date is null then 0  
                     else rank() over (partition by userid order by created_date desc) 
                end) as varchar) as rnk 
    from (
        select a.userid, 
               a.created_date, 
               a.product_id, 
               b.gold_signup_date 
        from sales a 
        left join goldusers_signup b 
        on a.userid = b.userid 
        and created_date >= gold_signup_date
    ) c
) e;
