use db_SQLCaseStudies
SElect * from dbo.DIM_CUSTOMER
Select * from dbo.DIM_DATE
Select * from dbo.DIM_LOCATION 
Select * from dbo.DIM_MODEL
Select * from DIM_MANUFACTURER
Select * from FACT_TRANSACTIONS
--Q1- List all the states in which we have customers who have bought cellphones from 2005 till today

Select distinct l.[State] from  DIM_DATE d 
inner join FACT_TRANSACTIONS f on d.Date=f.Date 
inner join DIM_LOCATION l on f.IDLocation=l.IDLocation
Where d.YEAR >'2005'
--Q1--END

--Q2--BEGIN
	
 Select top 1 [state] from DIM_LOCATION l inner join FACT_TRANSACTIONS f on l.IDLocation=f.IDLocation
 inner join DIM_MODEL mo on f.IDModel=mo.IDModel inner join DIM_MANUFACTURER m on mo.IDManufacturer=m.IDManufacturer
 where Country='US' and Manufacturer_Name='Samsung'
 Group by [State] 
 order by sum(Quantity)desc
--Q2--END

--Q3-- Show the number of transactions for each model per zip code per state.   
	
Select model_name, zipcode, state, 
count(idcustomer) as no_of_transactions from dim_location
inner join fact_transactions on dim_location.idlocation=fact_transactions.idlocation
inner join dim_model on fact_transactions.idmodel = dim_model.idmodel
group by model_name, zipcode, state

--Q3--END

--Q4- Show the cheapest cellphone (Output should contain the price also)

 Select top 1
 Model_name,Unit_price from DIM_MODEL
 order by Unit_price 

--Q4--END

--Q5--Find out the average price for each model in the top5 manufacturers in terms of sales quantity
 --     and order by average price.

select model_name, avg(totalprice) from dim_model
inner join dim_manufacturer on dim_manufacturer.idmanufacturer = dim_model.idmanufacturer
inner join fact_transactions ft on ft.idmodel = dim_model.idmodel
where manufacturer_name in 
(
select top 5 manufacturer_name from fact_transactions 
inner join dim_model on fact_transactions.idmodel = dim_model.idmodel
inner join dim_manufacturer on dim_manufacturer.idmanufacturer = dim_model.idmanufacturer
group by manufacturer_name
order by sum(quantity) desc
)
group by model_name,manufacturer_name
order by avg(totalprice) desc

--Q5--END

--Q6--List the names of the customers and the average amount spent in 2009, where the average is higher than 500

select customer_name, avg(totalprice) avg_spent
from dim_customer
inner join fact_transactions on dim_customer.idcustomer = fact_transactions.idcustomer
where year(date) ='2009' 
group by customer_name
having avg(totalprice)>500

--Q6--END
	
--Q7--List if there is any model that was in the top 5 in terms of quantity, simultaneously in 2008, 2009 and 2010

select * from [dbo].[DIM_MODEL] d right join 
(select idmodel from (SELECT TOP 5 SUM(QUANTITY)[qty],idmodel FROM FACT_TRANSACTIONS WHERE YEAR(DATE)=2008
GROUP BY IDMODEL ORDER BY SUM(QUANTITY)DESC)t3
intersect
select idmodel from (SELECT TOP 5 SUM(QUANTITY)[qty],idmodel FROM FACT_TRANSACTIONS WHERE YEAR(DATE)=2009
GROUP BY IDMODEL ORDER BY SUM(QUANTITY)DESC)t3
intersect
select idmodel from (SELECT TOP 5 SUM(QUANTITY)[qty],idmodel FROM FACT_TRANSACTIONS WHERE YEAR(DATE)=2010
GROUP BY IDMODEL ORDER BY SUM(QUANTITY)DESC)t3) t4 on d.idmodel=t4.IDModel

--Q7--END	
--Q8--Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer 
 -- with the 2nd top sales in the year of 2010.

  with rnk as
 (Select year(date)[Year],m.IDManufacturer,Manufacturer_Name ,rank() over( order by sum(TotalPrice) desc) as [Rank]
 from FACT_TRANSACTIONS f inner join DIM_MODEL m on f.IDModel=m.IDModel 
 inner join DIM_MANUFACTURER ma on m.IDManufacturer=ma.IDManufacturer
 where year(date) ='2009' 
 group by year(date),m.IDManufacturer,Manufacturer_Name
 union all
 Select year(date)[Year], m.IDManufacturer,Manufacturer_Name ,rank() over( order by sum(TotalPrice) desc) as [Rank]
 from FACT_TRANSACTIONS f inner join DIM_MODEL m on f.IDModel=m.IDModel 
 inner join DIM_MANUFACTURER ma on m.IDManufacturer=ma.IDManufacturer
 where year(date) ='2010' 
 group by year(date), m.IDManufacturer,Manufacturer_Name)
 Select year[Year],Manufacturer_Name from rnk
 where [Rank]=2


--Q8--END
--Q9--Show the manufacturers that sold cellphones in 2010 but did not in 2009.
	
select manufacturer_name from dim_manufacturer d1
inner join dim_model d2 on d1.idmanufacturer= d2.idmanufacturer
inner join fact_transactions d3 on d2.idmodel= d3.idmodel
where year(date) = 2010 
except 
select manufacturer_name from dim_manufacturer d1
inner join dim_model d2 on d1.idmanufacturer= d2.idmanufacturer
inner join fact_transactions d3 on d2.idmodel= d3.idmodel
where year(date) = 2009

--Q9--END

--Q10--Find top 100 customers and their average spend, average quantity by each year. 
 ---Also find the percentage of change in their spend.

 create view a as
 (Select top 100 f.IDCustomer, Customer_Name from DIM_CUSTOMER c inner join FACT_TRANSACTIONS f on c.IDCustomer=f.IDCustomer
 group by f.IDCustomer,Customer_Name
 order by sum(TotalPrice) desc)

 create view a1 as
 (Select Customer_Name,avg(TotalPrice)[Average spend],avg(Quantity)[Average quantity], sum(TotalPrice)[Total Spend],
 lag(sum (TotalPrice)) over(Partition by a.Customer_Name order by year(date))[lag]from FACT_TRANSACTIONS f inner join a
 on f.IDCustomer=a.IDCustomer
 Group by a.Customer_Name,year([date]))

 Select a.Customer_Name, [Average spend],[Average quantity],([Total Spend] - [lag])*100/[lag]
 [Percent change of spend] from a inner join a1 on   a.Customer_Name=a1.Customer_Name  
--Q10--END