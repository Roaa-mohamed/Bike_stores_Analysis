USE BIKESTORE;
-- Total Revenue per each store
select sales.stores.store_name , count(sales.orders.order_id) as N_orders,
('$  ' +cast((sum(sales.order_items.quantity*sales.order_items.list_price)) as varchar(200))) as total_revenue ,
round(( sum(sales.order_items.quantity*sales.order_items.list_price)/
(select sum(sales.order_items.quantity*sales.order_items.list_price)from sales.order_items )) ,2 ,0)  as percentage_of_each_store
from sales.stores join sales.orders on sales.orders.store_id=sales.stores.store_id
join sales.order_items on sales.order_items.order_id = sales.orders.order_id
group by sales.stores.store_name
order by round(( sum(sales.order_items.quantity*sales.order_items.list_price)/(select sum(sales.order_items.quantity*sales.order_items.list_price))) ,2) desc; 
---------------------------------------------------------------------------------------------------------
/* the lowest brand in each country for each year */
select  production.brands.brand_name,sales.customers.city ,
sum(sales.order_items.quantity* sales.order_items.list_price) as Revenue , 
count (sales.orders.order_id) as N_orders
from production.brands join production.products on production.products.brand_id=production.brands.brand_id 
join sales.order_items on production.products.product_id = sales.order_items.product_id 
join sales.orders on sales.orders.order_id = sales.order_items.order_id 
join sales.customers on  sales.customers.customer_id = sales.orders.Customer_id 
group by production.products.model_year,production.brands.brand_name,sales.customers.city,sales.customers.state
order by sales.customers.city , max(sales.orders.order_id) ;
------------------------------------------------------------------------------------------------------------------
--loyalty of customer by total orders 
select (sales.customers.first_name+' ' +sales.customers.last_name) as customername , max(sales.orders.order_date)as last_order ,
count (sales.orders.order_id) as N_orders ,sum (sales.order_items.quantity )as total_units ,  sum(sales.order_items.list_price) as total_spending
from  production.products join sales.order_items  on production.products.product_id = sales.order_items.product_id 
join sales.orders on sales.orders.order_id = sales.order_items.order_id 
join sales.customers on  sales.customers.customer_id = sales.orders.Customer_id 
 group by sales.customers.customer_id,sales.customers.first_name , sales.customers.last_name ,production.products.model_year
 order by count (sales.orders.order_id)  desc  ;
 -------------------------------------------------------------------------------------------------------------------------
 -- revenue growth per month for each brand  
select  datepart (year , sales.orders.order_date) as year , production.brands.brand_name ,
sales.order_items.product_id ,production.products.product_name ,sum(sales.order_items.quantity* sales.order_items.list_price) as Revenue,
(sum(sales.order_items.quantity* sales.order_items.list_price) -lag(sum(sales.order_items.quantity* sales.order_items.list_price))
 over(order by datepart (year, sales.orders.order_date) asc)) as Revenue_Growth,
  sum(sales.order_items.quantity* sales.order_items.list_price) -lag(sum(sales.order_items.quantity* sales.order_items.list_price))
 over(order by datepart (year , sales.orders.order_date) asc)/lag(sum(sales.order_items.quantity* sales.order_items.list_price))over
 (order by datepart (year , sales.orders.order_date)asc) *100 as Revenue_percentage_Growth ,
 lead(sum(sales.order_items.quantity* sales.order_items.list_price))over(order by datepart (year, sales.orders.order_date) asc) as next_year_growth   
from production.brands join production.products on production.brands.brand_id=production.products.brand_id 
join sales.order_items on production.products.product_id = sales.order_items.product_id 
join sales.orders on sales.orders.order_id = sales.order_items.order_id
group by datepart (year, sales.orders.order_date),
production.products.product_name,sales.order_items.product_id , production.brands.brand_name ;
----------------------------------------------------------------------------------------------------------------------------------------
--Top 10 staff measured by total_orders , Total sold amount 
select datepart (year , sales.orders.order_date) as year , datename (MONTH,sales.orders.order_date )as name_of_months, 
(sales.staffs.first_name +' ' +sales.staffs.last_name) as staff_name,sales.stores.store_name, count(sales.orders.order_id)as Total_orders ,
sum(sales.order_items.quantity) as total_amount ,
('$  '+cast (sum(sales.order_items.list_price*sales.order_items.quantity) as varchar(300)))as total_revenue
from  sales.staffs join sales.orders on sales.staffs.staff_id = sales.orders.staff_id 
join sales.order_items on sales.order_items.order_id = sales.orders.order_id 
join sales.stores on sales.stores.store_id = sales.orders.store_id 
group by sales.staffs.first_name , sales.staffs.last_name,sales.stores.store_name , 
datename (MONTH,sales.orders.order_date ) , datepart (year , sales.orders.order_date)
order by count(sales.orders.order_id) desc
offset 0 rows fetch first 10 rows only ;
------------------------------------------------------------------------------------------------------------------------------------
--bottom 5 sellers by total_orders , total sold amount  
select datepart (year , sales.orders.order_date) as year , datename (MONTH,sales.orders.order_date )as name_of_months, 
(sales.staffs.first_name +' ' +sales.staffs.last_name) as staff_name,sales.stores.store_name, count(sales.orders.order_id)as Total_orders ,
sum(sales.order_items.quantity) as total_amount ,
('$  '+cast (sum(sales.order_items.list_price*sales.order_items.quantity) as varchar(300)))as total_revenue
from  sales.staffs join sales.orders on sales.staffs.staff_id = sales.orders.staff_id 
join sales.order_items on sales.order_items.order_id = sales.orders.order_id 
join sales.stores on sales.stores.store_id = sales.orders.store_id 
group by sales.staffs.first_name , sales.staffs.last_name,sales.stores.store_name , 
datename (MONTH,sales.orders.order_date ) , datepart (year , sales.orders.order_date)
order by count(sales.orders.order_id)  asc 
offset 0 rows fetch first 10 rows only ;
--------------------------------------------------------------------------------------------------------------------------------------
--Which Products Should We produce More of or Less of?
select p.product_id, p.product_name ,(p.total_purchase - s.total_sold) as  cur_on_hand
from (select production.stocks.product_id,production.products.product_name as product_name , sum(production.stocks.quantity) as total_purchase
  from production.stocks join production.products on production.products.product_id =production.stocks.product_id
  group by production.stocks.product_id , production.products.product_name )
  as p join (select sales.order_items.product_id, sum(sales.order_items.quantity) as total_sold 
  from sales.order_items
  group by sales.order_items.product_id
) as s on p.product_id = s.product_id
order by (p.total_purchase - s.total_sold) asc ;
---------------------------------------------------------------------------------------------------------------------------------------------
--percentage of sales per category 
select datepart (year, sales.orders.order_date ) as years , production.products.category_id  ,production.categories.category_name,
round ((sum(sales.order_items.list_price* sales.order_items.quantity)*100 / 
(select sum(sales.order_items.list_price* sales.order_items.quantity) from sales.order_items)),0) as percentageofrevenue , 
('$  '+cast (sum(sales.order_items.list_price* sales.order_items.quantity) as varchar(300)))as total_revenue
from production.categories join production.products on production.categories.category_id = production.products.category_id
join sales.order_items on production.products.product_id = sales.order_items.product_id
join sales.orders  on  sales.order_items.order_id = sales.orders.order_id 
group by production.products.category_id , datepart (year,sales.orders.order_date), production.categories.category_name 
order by round ((sum(sales.order_items.list_price* sales.order_items.quantity)*100 / 
(select sum(sales.order_items.list_price* sales.order_items.quantity) from sales.order_items)),2) desc;
----------------------------------------------------------------------------------------------------------------------------------------------