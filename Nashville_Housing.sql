use NashvilleHousing;

-- Now we have imported the required data , lets look after the table where data is stored

select * 
from 
NashvilleHousing.information_schema.tables;

-- finding out the data type of the table we have

select column_name, data_type
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME='NashvilleData'

-- lets see the data more

select * from NashvilleData;


---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------



-- lets change the Sale date data type in date format

select SaleDate, cast(SaleDate as date) SaleDate_date
from NashvilleData;


-- updating to the table

Alter table NashvilleData
add Converted_Sales_date date;

update NashvilleData
set Converted_Sales_date = convert(date,SaleDate)

select Converted_sales_date from NashvilleData;



---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------



-- There are some nulls in property address of our data
-- Also propert address is detremined by the parcel id
-- We must be filling out the data in property address according to the value of parcel id

select * from NashvilleData
--where PropertyAddress is null
order by ParcelID;


-- lets check the null Property address with different unique id but same Parcel_Id

select a.ParcelID, a.PropertyAddress,b.ParcelID, b.PropertyAddress from 
NashvilleData a
join NashvilleData b
on 
a.ParcelID = b.ParcelID
and
a.[UniqueID ]<>b.[UniqueID ]
where a.PropertyAddress is null;

-- 35 rows were found on total, lets fill them up with absolute property address

select a.ParcelID, a.PropertyAddress,b.ParcelID, b.PropertyAddress, isnull(a.PropertyAddress,b.PropertyAddress) 
from 
NashvilleData a
join NashvilleData b
on 
a.ParcelID = b.ParcelID
and
a.[UniqueID ]<>b.[UniqueID ]
where a.PropertyAddress is null;

-- Now updating the data according to the Parcel id

update a
set
a. PropertyAddress = isnull(a.PropertyAddress, b.PropertyAddress)
from NashvilleData a
join NashvilleData b on 
a.ParcelID = b.ParcelID
and a.[UniqueID ]<>b.[UniqueID ];

select * from NashvilleData;

---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------


-- We have transformed the NAshvilleData table by replacing nulls of propert address.
-- Lets split the propert address in two part as address and city.

select PropertyAddress
from NashvilleData;

select 
PARSENAME(replace(PropertyAddress,',','.'),2) as PropertAddress_Split,
PARSENAME(replace(PropertyAddress,',','.'),1) as PropertCity
from NashvilleData;

-- Lets update our table with splitting the property address

-- adding the required columns

alter table NashvilleData
add PropertyAddress_Split nvarchar(100),
PropertyCity nvarchar(100);

update NashvilleData
set
PropertyAddress_Split = PARSENAME(replace(PropertyAddress,',','.'),2) ,
PropertyCity = PARSENAME(replace(PropertyAddress,',','.'),1);

select * from NashvilleData;


---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------


-- Similarly lets split the Owner Address

select 
PARSENAME(replace(OwnerAddress,',','.'),3) as OwnerAddress_Split,
PARSENAME(replace(OwnerAddress,',','.'),2) as OwnerCity,
PARSENAME(replace(OwnerAddress,',','.'),1) as OwnerState
from NashvilleData;

alter table NashvilleData
add OwnerAddress_Split nvarchar(100), OwnerCity varchar(50),OwnerState nvarchar(10);

update NashvilleData
set
OwnerAddress_Split = PARSENAME(replace(OwnerAddress,',','.'),3),
OwnerCity = PARSENAME(replace(OwnerAddress,',','.'),2),
OwnerState = PARSENAME(replace(OwnerAddress,',','.'),1)

select * from NashvilleData;

-- Lets add the proper value in SoldAsVAcant column
-- Y for yes and N for no

select SoldAsVacant,
case when SoldAsVacant = 'Y' then 'Yes'
when SoldAsVacant = 'N' then 'No'
else SoldAsVacant
End
from NashvilleData

-- lets update the value

update NashvilleData
set SoldAsVacant = case when SoldAsVacant = 'Y' then 'Yes'
when SoldAsVacant = 'N' then 'No'
else SoldAsVacant
End;

---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------

-- Now lets see for  duplicates 

select * , ROW_NUMBER() over (partition by ParcelID, PropertyAddress , 
SalePrice, SaleDate,  
LegalReference order by [UniqueID] 
) row_count
from 
NashvilleData order by row_count desc;

-- there are duplicates so lets clear the duplicates 

with duplicatecte as
(
select * , ROW_NUMBER() over (partition by ParcelID, PropertyAddress , 
SalePrice, SaleDate,  
LegalReference order by [UniqueID] 
) row_count
from 
NashvilleData )

--select * from duplicatecte
--where row_count > 1;

-- 104 rows were duplicate so deleting it.

delete from duplicatecte where row_count>1;

	select * from NashvilleData;

-- Let us Now remove the unwanted columns 

alter table NashvilleData
drop column PropertyAddress, SaleDate, OwnerAddress, TaxDistrict;

select * from NashvilleData
order by PropertyCity desc

---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------

-- Now our data is more on the clean side. 
-- Now calculating the profit will also be very helpful in our data analysis process
-- lets add column that represent the column

alter table NashvilleData
add Profit_amount as (SalePrice - TotalValue);

---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------
-- Now we will be doing some exploratory data analysis here

select * from NashvilleData;

-- Average Total valur according to the different city

select round(avg(TotalValue),2) as Average_Total , PropertyCity
from 
NashvilleData
group by PropertyCity
order by Average_Total desc;

---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------

-- Total Profit generated on housing according to cities

select sum(Profit_amount) as Profit_Revenue, PropertyCity
from 
NashvilleData
group by PropertyCity
order by Profit_Revenue desc;

---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------

-- how many single family  land use property were sold

select count(*) count_of_sales, LandUse
from NashvilleData
--where
--LandUse = 'SINGLE FAMILY'
group by LandUse
order by count_of_sales;

---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------

-- Top 5 highest Property along with Sale Value

select top(5) * from
NashvilleData
order by TotalValue desc;

---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------
-- Top 5 bad profitable property details 

select top(5) * from
NashvilleData
where Profit_amount is not null
order by Profit_amount ;

---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------

--Provide the list of property  that had a profit amount more than 200000 using the subqueries method.

select ParcelID, LandUse , SalePrice , Profit_amount, PropertyAddress_Split, PropertyCity
from 
NashvilleData
where
Profit_amount in 
(select Profit_amount from NashvilleData 
where 
Profit_amount>200000)
order by Profit_amount desc;

---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------

-- List the property cities with the average Sale Price using select cte

select PropertyCity , (select round(avg(SalePrice),2)) as AverageSellingPrice
from NashvilleData
group by PropertyCity
order by AverageSellingPrice desc;

---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------

-- How many properties were and were not sold as vacant. Count in numbers

select SoldAsVacant, count(*) total_counts from
NashvilleData
group by SoldAsVacant;

---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------

-- SHow the state of owners and count the number of property sold

select count(*), OwnerState
from NashvilleData
group by OwnerState

-- Average Land value and total sale value for the different property according to the city

select avg(LandValue) as Average_land_value , avg(TotalValue) as Average_Total , PropertyCity
from
NashvilleData
group by PropertyCity;

---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------


-- Display the value of the total sale of the NAshville as Property city where the year built is later than 1999

select PropertyCity , YearBuilt, sum (TotalValue) as Total_Value_generated
from NashvilleData
where PropertyCity = ' NASHVILLE'
and YearBuilt in (select YearBuilt from 
NashvilleData where
YearBuilt > 1999)
group by PropertyCity, YearBuilt;

---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------

-- Sales details with the date as 2015-07-27

select * from 
NashvilleData
where Converted_Sales_date = ' 2015-07-27';

---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------

-- What were the average bedroomn , fullBAth room and halfbathrrom with the year built over 2000

select avg(Bedrooms) as Average_bedrooms , avg(FullBath) as Avg_bathroom,
avg(HalfBath) as Avg_halfbathroom , YearBuilt
from NashvilleData
where YearBuilt in (select YearBuilt from NashvilleData where YearBuilt > 2000)
group by YearBuilt;

---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------

-- Sale total value according to the bedrooms and bathrroms

select Bedrooms, FullBath, HalfBath,sum(TotalVAlue) as TOtal_value from NashvilleData
group by Bedrooms, FullBath, HalfBath
order by TOtal_value desc;

---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------

-- LAnd use and Profit generation according to the city 

select PropertyCity ,LandUSe, sum(Profit_amount) as Profit_generated from NashvilleData
group by  PropertyCity , LandUse
order by Profit_generated desc;

