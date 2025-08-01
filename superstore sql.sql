create database superstore;
use superstore;
select * from superstore;

-- Total sales amount
create view total_sales as
select concat(round(sum(Sales),2), "$") total_sales from superstore;

-- Top 5 Best-Selling Products

CREATE VIEW Top5_Products AS
SELECT Product_rank,
    Product_Name,
    Total_Sales
FROM (SELECT Product_Name,
        SUM(Sales) AS Total_Sales,
        RANK() OVER (ORDER BY SUM(Sales) DESC) AS Product_rank
    FROM superstore
    GROUP BY Product_Name
) AS r
WHERE Product_rank <= 5;


-- Top 5 Customers Who Spent the Most
CREATE VIEW Top5_Customers AS
SELECT customer_rank,
    customer_Name,
    Total_Sales
FROM (SELECT customer_Name,
        concat(round(sum(Sales),2), " $") AS Total_Sales,
        RANK() OVER (ORDER BY SUM(Sales) DESC) AS customer_rank
    FROM superstore
    GROUP BY customer_Name
) AS r
WHERE customer_rank <= 5;

-- Analyze sales by month
create view Monthly_Sales as
 SELECT 
    DATE_FORMAT(STR_TO_DATE(Order_Date, '%d-%m-%Y'), '%Y-%m') AS Month, 
    concat(round(sum(Sales),2),"$") AS Monthly_Sales
FROM superstore
WHERE Order_Date IS NOT NULL
GROUP BY Month
ORDER BY Month;

-- Find the Most Sold Product Category
create view Most_Sold_Product_Category as
select category,concat(round(sum(Sales),2), "$") total_sales from superstore
group by category
order by sum(sales) desc limit 1;

-- Find the city with the highest sales
create view highest_sales_city as
select city,concat(round(sum(Sales),2), "$") total_sales from superstore
group by city
order by sum(sales) desc limit 1;

-- Find the most frequently used shipping mode
create view most_used_shipping_mode as
select ship_mode,concat(round(sum(Sales),2), "$") total_sales from superstore
group by ship_mode
order by sum(sales) desc limit 1;