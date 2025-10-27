use DataWarehouse
go

select distinct 
	ci.cst_gndr,
    cd.gen,
	case when ci.cst_gndr != 'n/a' then ci.cst_gndr  --crm is the master for the gender info
	     else coalesce(cd.gen , 'n/a')
    end as new_gen
from silver.crm_cust_info as ci
left join silver.erp_cust_az12 as cd
on     ci.cst_key = cd.cid
left join silver.erp_loc_a101 as la
on   ci.cst_key = la.cid
order by 1,2