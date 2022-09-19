create database retail_new
use retail_new
select * from [dbo].[Customer]
select * from [dbo].[prod_cat_info]
select * from [dbo].[Transactions]

---Q1.	What is the total number of rows in each of the 3 tables in the database?
select count(*) from Transactions
select count(*) from Customer
select count(*) from prod_cat_info

---Q2.	What is the total number of transactions that have a return?
select count(distinct transaction_id)[no of transaction] from transactions
where qty <0

---Q3.	As you would have noticed, the dates provided across the datasets are not in a correct format. 
---     As first steps, pls convert the date variables into valid date formats before proceeding ahead.
Alter table Transactions alter column tran_date date

---Q4.	What is the time range of the transaction data available for analysis? 
---     Show the output in number of days, months and years simultaneously in different columns.
select datediff(day,min(tran_date),max(tran_date)) from Transactions
select datediff(month,min(tran_date),max(tran_date)) from Transactions
select datediff(year,min(tran_date),max(tran_date)) from Transactions

--   5.	Which product category does the sub-category “DIY” belong to?
SELECT prod_cat from prod_cat_info
where prod_subcat='DIY'

--data analysis

--1	Which channel is most frequently used for transactions?
select top 1 store_type from transactions
group by store_type
order by count(store_type) desc

---Q2.What is the count of Male and Female customers in the database?

 Select count(distinct customer_Id)[Males] from Customer
 where Gender='M'
 Select count(distinct customer_Id)[Females] from Customer
 where Gender='F'

 --3	From which city do we have the maximum number of customers and how many?

select top 1 city_code from Customer
group by city_code
order by count(customer_id) desc

---Q4.How many sub-categories are there under the Books category?

  Select count(Prod_subcat)[Subcategories] from prod_cat_info
  group by prod_cat
  having prod_cat='Books'

--5.What is the maximum quantity of products ever ordered?
select max(qty) from transactions

--6.	What is the net total revenue generated in categories Electronics and Books?

select sum(total_amt)[net revenue] from transactions t 
inner join prod_cat_info p on t.prod_cat_code=p.prod_cat_code and t.prod_subcat_code=p.prod_sub_cat_code
where prod_cat in('electronics','books')

--7.	How many customers have >10 transactions with us, excluding returns?

 Select count(cust_id)[no.of cust] from(
 Select cust_id from Transactions
 group by cust_id
 having count(transaction_id)>10)t1

---Q8.What is the combined revenue earned from the “Electronics” & “Clothing” categories, from “Flagship stores”?

 Select sum(total_amt)[Revenue] from Transactions t inner join prod_cat_info p on t.prod_cat_code=p.prod_cat_code
          and t.prod_subcat_code=p.prod_sub_cat_code
 where Store_type ='Flagship store' and 
 prod_cat in ('Electronics','Clothing')

---Q9.	What is the total revenue generated from “Male” customers in “Electronics” category? 
 ---    Output should display total revenue by prod sub-cat.

 Select distinct prod_subcat,sum(total_amt)[Total Revenue] from Transactions t 
 inner join prod_cat_info p on t.prod_subcat_code=p.prod_sub_cat_code
 inner join Customer c on t.cust_id=c.customer_Id
 where prod_cat='Electronics' and gender='M'
 group by p.prod_subcat

---Q10.What is percentage of sales and returns by product sub category; display only top 5 sub categories in terms of sales?
  
  Select t1.prod_subcat,[Percent sales],[Percent returns] from
 (Select top 5 prod_subcat,sum(total_amt) /(select sum(total_amt) from Transactions)*100[Percent sales] 
 from Transactions t 
 inner join prod_cat_info p on t.prod_cat_code = p.prod_cat_code
 group by prod_sub_cat_code, prod_subcat
 order by sum(total_amt) desc)t1
 left join
 (Select top 5 p.prod_subcat,sum(qty)/(Select sum(qty)*0.01 from Transactions where qty<0)[Percent returns]
 from Transactions t2 inner join  prod_cat_info p on t2.prod_cat_code = p.prod_cat_code
 where Qty<0
 group by prod_sub_cat_code, prod_subcat
 order by [Percent returns] desc)t2 on t1.prod_subcat=t2.prod_subcat

---Q11.For all customers aged between 25 to 35 years find what is the net total revenue generated
 ---   by these consumers in last 30 days of transactions from max transaction date available in the data?
 
  Select sum(total_amt)[Net Revenue] from Customer c inner join Transactions t on c.customer_Id=t.cust_id
  where DATEDIFF (year,DOB,getdate()) between 25 and 35
  and tran_date=(dateadd(day,-30,(Select max(tran_date)[Max_date] from transactions)))

---Q12.Which product category has seen the max value of returns in the last 3 months of transaction?
 
select top 1 prod_cat from Transactions t inner join prod_cat_info p on p.prod_cat_code=t.prod_cat_code
where tran_date between dateadd(month,-3,(select max(tran_date) from transactions)) and (select max(tran_date) from transactions)
and qty<0
group by prod_cat
order by sum(qty) desc

---Q13.Which store-type sells the maximum products; by value of sales amount and by quantity sold?
 
 Select top 1 Store_type,sum(total_amt)[Amount], sum(qty)[Quant] from Transactions 
 group by Store_type
 order by [Amount]desc,[Quant] desc

---Q14.What are the categories for which average revenue is above the overall average.

 Select prod_cat from Transactions t inner join prod_cat_info pc
 on t.prod_cat_code=pc.prod_cat_code
 group by t.prod_cat_code,prod_cat
 having AVG(total_amt) > (Select AVG(total_amt) from Transactions)

  ---Q15.Find the average and total revenue by each subcategory for the categories which are among 
 --- top 5 categories in terms of quantity sold.

with cte5 as (
select top 5 prod_cat from transactions t inner join prod_cat_info p on t.prod_cat_code=p.prod_cat_code
group by prod_cat
order by sum(qty) desc)

select prod_subcat, avg(total_amt)[average revenue],sum(total_amt)[total revenue] from Transactions t inner join prod_cat_info p on t.prod_subcat_code=p.prod_sub_cat_code
where prod_cat in (select * from cte5)
group by prod_subcat

---END