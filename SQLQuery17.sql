use DataWarehouse
go

-- fact tabel of gold layer
create view gold.fact_sales as
select 
	sd.sls_ord_num as order_number, -- top 3 are dimension keys pk and fk
	pr.product_key as product_key,
	cu.customer_key as customer_key,
	sd.sls_order_dt as order_date,
	sd.sls_ship_dt as ship_date,
	sd.sls_due_dt as due_date,
	sd.sls_sales as sales,
	sd.sls_quantity as quantity,
	sd.sls_price as price
from silver.crm_sales_details as sd
left join gold.dim_product as pr
on  sd.sls_prd_key = pr.product_number
left join gold.dim_customer as cu
on   sd.sls_cust_id = cu.customer_id

--select  * from gold.fact_sales