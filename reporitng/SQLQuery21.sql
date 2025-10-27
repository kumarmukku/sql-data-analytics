--BUILDING REPORTS

create view gold.report_customer as 
with base_query as (
-- base query : retrieve core column from tabele--
select 
f.order_number,
f.product_key,
f.order_date,
f.price,
f.quantity,
c.customer_key,
c.customer_number,
concat(c.first_name , c.last_name) as customer_name,
datediff(year,Dob ,getdate()) as age
from gold.fact_sales as f
left join gold.dim_customer as c
on f.customer_key = c.customer_key
where order_date is not null
)

-- customer aggregation : summarize key metrices
, customer_aggregation as (
	select
	customer_key,
	customer_number,
	customer_name,
	age,
	count(distinct order_number) as total_order,
	sum(price) as total_sales,
	sum(quantity) as total_quantity,
	count(distinct product_key) as total_products,
	min(order_date) as first_order_date,
	max(order_date) as last_order_date,
	datediff(month, min(order_date), max(order_date)) as lifespan
	from base_query
	group by 
	   customer_key,
	   customer_number,
	   customer_name,
	   age
)

 -- final result (segment or kpi for this report)

 select
 customer_key,
 customer_number,
 customer_name,
 age,
 case when age <20 then 'under 20'
      when age between 20 and 30 then '20-30'
	  when age between 30 and 40 then '30-40'
	  when age between 40 and 50 then '40-50'
	  else 'above 50'
 end as age_segment,
 case when lifespan >= 12 and total_sales > 5000  then 'VIP'
	  when lifespan >= 12 and total_sales <= 5000  then 'Regular'
	  else 'New'
 end as customer_segment,
 last_order_date, 
 datediff(month,last_order_date , getdate()) as recency,      --- calculate how recent customer order from last time in months
 total_order,
 total_sales,
 total_quantity,
 total_products,
 first_order_date,
 lifespan,
 -- computing avg order value
 case when total_order = 0 then 0
      else total_sales/total_order 
 end as avg_order_value,
 --compute avg monthly spend of customer    == avg_monthly_spending =total sales/no.pf months
 case when lifespan = 0 then total_sales
      else total_sales/lifespan
 end as avg_monthly_spend
 from customer_aggregation

 -- ececute view
 select * from gold.report_customer