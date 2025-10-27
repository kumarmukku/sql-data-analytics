-- BASIC ANALLYSIS
--DATABASE EXPLORATION

select *
from INFORMATION_SCHEMA.TABLES

--explore all column in database
select *
from INFORMATION_SCHEMA.COLUMNS

-- DIMENSION EXPLORATION
--explore all countries our customer come from
select distinct country
from gold.dim_customer

-- explore all categories the major divison
select distinct category , subcategory, product_name
from gold.dim_product
order by 1,2,3
--checking
select *
from gold.dim_product

----- DATE EXPLORATION

-- find the date of first and last order
-- how many years of sales are available
select min(order_date) as first_order_date,
       max(order_date) as last_order_date,
       datediff(year, min(order_date),max(order_date)) as order_range_years
from gold.fact_sales

-- find the youngest and oldest customer
select 
    min(Dob) as oldest_birthdate,
    datediff(year, min(Dob), getdate()) as oldest_age,
    max(Dob) as newest_birthdate,
    datediff(year, max(Dob), getdate()) as youngest_age
from gold.dim_customer

-- MEASURE EXPLORATION

-- find total sales
select 
sum(sales) as total_sales
from gold.fact_sales

-- find how many item are sold
select sum(quantity) as total_item
from gold.fact_sales

-- find the avg selling price
select 
avg(price) as selling_price
from gold.fact_sales

-- find the total number of order
select
count(order_number) as total_order
from gold.fact_sales

select
count(distinct order_number) as total_order
from gold.fact_sales

-- find the total number of product
select
count(product_key) as total_product
from gold.dim_product


--find total number of customer
select 
count(customer_key) as total_customer
from gold.dim_customer

-- find the total number of customer that has placed an order
select
count( distinct customer_key) as total_customer
from gold.fact_sales

-- generate a report that shows all key metrics of the business

select 
'Total sales' as measure_name,
sum(sales) as measure_value
from gold.fact_sales
union all
select 
'Total quantiry' as measure_name,
sum(quantity) as measure_value
from gold.fact_sales
union all
select
'Avg price' as measure_name,
avg(price) as measure_value
from gold.fact_sales
union all
select
'Total order' as measure_name,
count(distinct order_number) as measure_value
from gold.fact_sales
union all
select
'Total product' as measure_name,
count(product_key) as measure_value
from gold.dim_product
union all
select
'Total customer' as measure_name,
count(customer_key) as measure_value
from gold.dim_customer
union all
select
'order customer' as measure_value,
count( distinct customer_key) as measure_value
from gold.fact_sales

-- MAGNITUDE MEASURE

-- find total customer by countries
select
country,
count(customer_key) as total_customer
from gold.dim_customer
group by country
order by total_customer desc

-- find total customer by gender
select
gender,
count(customer_key) as total_customer
from gold.dim_customer
group by gender
order by total_customer desc

-- find total product by category
select
category,
count(product_key) as total_product
from gold.dim_product
group by category
order by total_product desc

-- what is the avg cost in each category
select
category,
avg(cost) as avg_cost
from gold.dim_product
group by category
order by avg_cost desc

-- find the total revenue generated for each category
select
g.category,
sum(f.price) as total_revenue
from gold.fact_sales as f
left join gold.dim_product as g
on  f.product_key = g.product_key
group by category
order by total_revenue desc

--find the total revenue genreted by each customer
select
c.customer_key,
c.first_name,
c.last_name,
sum(d.price) as total_revenue
from gold.fact_sales as d
left join gold.dim_customer as c
on  c.customer_key = d.customer_key
group by
c.customer_key,
c.first_name,
c.last_name
order by total_revenue desc

-- what is the distribution of sold items across countries
select
c.country,
sum(d.quantity) as total_sold_items
from gold.fact_sales as d
left join gold.dim_customer as c
on  c.customer_key = d.customer_key
group by
c.country
order by total_sold_items desc

--RANKING ANALYSIS

-- which 5 products generate the highest revenue?
select top 5
p.product_name,
sum(d.price) as total_revenue
from gold.fact_sales as d
left join gold.dim_product as p
on  d.product_key = p.product_key
group by p.product_name
order by total_revenue desc

--by window  function
select *
from(
    select 
    p.product_name,
    sum(d.price) as total_revenue,
    row_number() over(order by sum(d.price) desc) as rank_products
    from gold.fact_sales as d
    left join gold.dim_product as p
    on  d.product_key = p.product_key
    group by p.product_name) t 
where rank_products <= 5

-- ehat are the 5 worst performing products in terms of sales

select top 5
p.product_name,
sum(d.price) as total_revenue
from gold.fact_sales as d
left join gold.dim_product as p
on  d.product_key = p.product_key
group by
p.product_name
order by total_revenue 

-- find the top 10 customer who have generated the highest revenue
select top 10
c.customer_key,
c.first_name,
c.last_name,
sum(d.price) as total_revenue
from gold.fact_sales as d
left join gold.dim_customer as c
on  c.customer_key = d.customer_key
group by
c.customer_key,
c.first_name,
c.last_name
order by total_revenue desc

-- top 5 customer with fewest order place
select top 5
c.customer_key,
c.first_name,
c.last_name,
count(distinct d.order_number) as total_order
from gold.fact_sales as d
left join gold.dim_customer as c
on  c.customer_key = d.customer_key
group by
c.customer_key,
c.first_name,
c.last_name
order by total_order