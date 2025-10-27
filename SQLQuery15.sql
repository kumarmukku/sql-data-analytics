use DataWarehouse
go
-- we are using star schema
-- dimendion table
create view gold.dim_customer as 
select 
    row_number() over (order by cst_id) as customer_key, -- surrogated key
	ci.cst_id as customer_id,
	ci.cst_key as customer_number,
	ci.cst_firstname as first_name,
	ci.cst_lastname as last_name,
	la.cntry as country,
	ci.cst_material_status as marital_status,
	case when ci.cst_gndr != 'n/a' then ci.cst_gndr  --crm is the master for the gender info
	     else coalesce(cd.gen , 'n/a')
    end as gender,
	cd.bdate as Dob,
	ci.cst_create_date as create_date
from silver.crm_cust_info as ci
left join silver.erp_cust_az12 as cd
on     ci.cst_key = cd.cid
left join silver.erp_loc_a101 as la
on   ci.cst_key = la.cid

-- after joining table check for duplicates by count() and group by
--select * from gold.dim_customer

-- product details

-- this too is dimension table
--exec sp_rename 'gold.dim_product.prodect_name', 'product_name', 'COLUMN'; -- for renaming the column name
create view gold.dim_product as 
select
    row_number() over (order by pn.prd_id ,pn.prd_start_dt) as product_key, -- surrogated key
	pn.prd_id as product_id,
	pn.prd_key as product_number,
	pn.prd_nm as prodect_name,
	pn.cat_id as category_id,
	pc.cat as category,
	pc.subcat as subcategory,
	pc.maintenance as maintenance,
	pn.prd_cost as cost,
	pn.prd_line as product_line,
	pn.prd_start_dt as start_date
from silver.crm_prd_info as pn
left join silver.erp_px_cat_g1v2 as pc
on   pn.cat_id = pc.id
where prd_end_dt is null  --filter out all historical data
