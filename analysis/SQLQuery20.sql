--ADVANCE ANALYSIS

-- CHANGE OVER TIME ANALYSIS
--analyze sales performance over  time
-- by year function
select 
year(order_date) as order_year,
month(order_date) as order_month,
sum(price) as total_sales,
count(distinct customer_key) as total_customer,
sum(quantity) as total_quantity
from gold.fact_sales
where order_date is not null
group by year(order_date), month(order_date)
--having year(order_date) = 2013     for specific year
order by year(order_date), month(order_date)

-- datetrunc function
select 
--datetrunc(year,order_date) as order_year,
datetrunc(month,order_date) as order_month,
sum(price) as total_sales,
count(distinct customer_key) as total_customer,
sum(quantity) as total_quantity
from gold.fact_sales
where order_date is not null
group by datetrunc(month,order_date)
--having year(order_date) = 2013     for specific year
order by datetrunc(month,order_date)


-- by format function (it return int or output is int not date)
select 
--datetrunc(year,order_date) as order_year,
format(order_date , 'yyyy-MMM') as order_date,
sum(price) as total_sales,
count(distinct customer_key) as total_customer,
sum(quantity) as total_quantity
from gold.fact_sales
where order_date is not null
group by format(order_date , 'yyyy-MMM')
--having year(order_date) = 2013     for specific year
order by order_date


--CUMULATIVE ANALYSIS

-- calculate the totall sales per month
-- and the running total of sales over time

select
order_date,
total_sales,
sum(total_sales) over (partition by order_date order by order_date) as running_total_sales,
avg(avg_sales) over (partition by order_date order by order_date) as running_avg_sales
from(
	select 
	datetrunc(month, order_date) as order_date,
	sum(price) as total_sales,
	avg(price) as avg_sales
	from gold.fact_sales
	where order_date is not null
	group by datetrunc(month, order_date)
) t

--PERFORMANCE ANALYSIS
/* analyze the yearly performance of prodects by comparinf their sales to both
the avg sales performance of the product and the previous year's sales*/
--cte
with yearly_product_sales as (
	select 
	year(f.order_date) as order_year,
	d.product_name,
	sum(f.price) as current_sales
	from gold.fact_sales as f
	left join gold.dim_product as d
	on  f.product_key = d.product_key
	where f.order_date is not null
	group by year(f.order_date) ,d.product_name
)

select
order_year,
product_name,
current_sales,
avg(current_sales) over (partition by product_name) as avg_sales,
current_sales - avg(current_sales) over (partition by product_name) as diff_avg,
case when current_sales - avg(current_sales) over (partition by product_name) < 0 then 'below avg'
     when current_sales - avg(current_sales) over (partition by product_name) > 0 then 'above avg'
	 else 'avg'
end avg_change,
-- year by year analysis
lag(current_sales) over(partition by product_name order by order_year) as py_sales,
current_sales - lag(current_sales) over(partition by product_name order by order_year) as diff_py,
case when current_sales - lag(current_sales) over(partition by product_name order by order_year) <0 then 'decrease'
     when current_sales - lag(current_sales) over(partition by product_name order by order_year) < 0 then 'increase'
	 else 'constant'
end as py_change
from yearly_product_sales
order by product_name,order_year

-- PART TO WHOLE ANALYSIS

-- which category contribute rhe most to overall sales?
with category_sales as(
select
category,
sum(price) as total_sales
from gold.fact_sales as f
left join gold.dim_product as p
on f.product_key = p.product_key
group by category
)
select
category,
total_sales,
sum(total_sales) over() as overall_sales,
concat(round((cast(total_sales as float)/sum(total_sales) over())*100 , 2), '%') as percentag_of_total
from category_sales
order by total_sales desc

--DATA SEGMENT ANALYSIS
/* segment products into cost range and count hoe many products fall into
each segment*/

with product_segments as(
select
product_key,
product_name,
cost,
case when cost<100 then 'below 100'
     when cost between 100 and 500 then '100-500'
	 when cost between 500 and 1000 then '500-1000'
	 else 'above 1000'
end as cost_range
from gold.dim_product
)

select 
cost_range,
count(product_key) as total_products
from product_segments
group by cost_range
order by total_products desc

/* group customers into three segments based on their spending behaviour:
 vip:spending>5000 and history>= 12 months
 regular: spending<5000 and history>=12 months
 new : lifespan <12 months
 and find the total number of customer by each group*/

 with customer_spendings as (
 select
 c.customer_key,
 sum(f.price) as total_spending,
 min(order_date) as first_order,
 max(order_date) as last_order,
 datediff(month,min(order_date), max(order_date)) as lifespan
 from gold.fact_sales as f
 left join gold.dim_customer as c
 on f.customer_key = c.customer_key
 group by c.customer_key
 )

 select
 customer_segment,
 count(customer_key) as total_customer
 from(
	 select
	 customer_key,
	 total_spending,
	 lifespan,
	 case when lifespan >= 12 and total_spending > 5000 then 'VIP'
		  when lifespan >= 12 and total_spending <= 5000 then 'Regular'
		  else 'New'
	 end as customer_segment
	 from customer_spendings
) t 
group by customer_segment
order by total_customer desc