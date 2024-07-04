/*
  Name: MySQL classicmodels Database
  Link to database: http://www.mysqltutorial.org/mysql-sample-database.aspx 
  The code below is applicable if the classicmodels database has been created and in use with all its necessary tables and values.
*/

-- Address trailing whitespaces in country record Norway
UPDATE customers
SET country = "Norway"
WHERE city IN ("Oslo", "Bergen");

-- Overview of information embedded in each table
SELECT * FROM  productlines;
SELECT * FROM  products;
SELECT * FROM  offices;
SELECT * FROM  employees;
SELECT * FROM  customers;
SELECT * FROM  payments;
SELECT * FROM  orders;
SELECT * FROM  orderdetails LIMIT 3000;

-- Number of Sub-Products for Each Parent Product 
SELECT productLine, 
COUNT(DISTINCT productCode) AS Number_of_Sub_Products
FROM products 
GROUP BY productLine;

-- Category of Sub-Products for Each Parent Product
SELECT 
DISTINCT (productLine),
productCode
FROM products;

-- Number and List of Vendors who supply business with products
SELECT COUNT(DISTINCT productVendor) AS Total_Number_of_Vendors
FROM products;
SELECT DISTINCT productVendor AS Vendors
FROM products;

-- Created a new table by adding the costs and quantities ordered
-- CREATE VIEW orderdetails_info AS 
WITH orderdetails_Sales_details  AS (
SELECT
	products.productLine,
	products.productCode,
    IFNULL(orderdetails.quantityOrdered,0) AS quantityOrdered,
    IFNULL(orderdetails.priceEach,0) AS priceEach,
    IFNULL(orderdetails.quantityOrdered * orderdetails.priceEach,0) AS Cost,
    IFNULL(SUM(orderdetails.quantityOrdered) OVER (
    PARTITION BY orderdetails.productCode),0) AS Quantities_Ordered_Across_productLine,
    IFNULL(SUM(orderdetails.quantityOrdered * orderdetails.priceEach) OVER (
    PARTITION BY orderdetails.productCode),0) AS Revenue
FROM products
LEFT JOIN orderdetails
ON orderdetails.productCode = products.productCode
ORDER BY products.productCode
LIMIT 3000
)
SELECT * FROM orderdetails_Sales_details;

-- SELECT * FROM orderdetails_info;


/* The queries below make a distinction of customers in the customers' table. In the customer table, the data on the customers will be referred to as Registered_Customers. From this same table, a filter is applied to the creditLimit column, which will return data on customers who are referred to as Transacting_Customers. These criteria are further applied to customer distribution across countries.
In the customer list, some customers have not yet transacted business with classicmodels. This could be because these customers have a creditLimit of 0. Hence no records of orders placed for products in the orders table. This bit of information makes for a new query that returns a list of transacting customers and their distribution across countries.

The following queries differentiate between customers in the customer table. Data on customers in the customers' table will be referred to as Registered_Customers. A filter is applied to the creditLimit column in the same table, which returns data on customers referred to as Transacting_Customers. These criteria are then applied to the distribution of customers across different countries.
In the customer list, some customers have not yet transacted with classicmodels (Non_Transacting_Customers), likely because they have a creditLimit of 0. As a result, there are no records of orders placed for products in the orders table.
*/

-- Number of Registered_Customers and their Distribution across Countries
SELECT 
COUNT(customerNumber) AS Total_Registered_Customers
FROM customers;

SELECT 
DISTINCT country,
COUNT(customerNumber) AS Registered_Customers
FROM customers 
GROUP BY country
ORDER BY Registered_Customers DESC;

-- Number of Transacting_Customers and their Distribution across Countries. i.e. WHERE creditLimit != 0
SELECT 
COUNT(customerNumber) AS Transacting_Customers
FROM customers
WHERE creditLimit != 0;

SELECT 
DISTINCT country,
COUNT(customerNumber) AS Transacting_Customers
FROM customers
WHERE creditLimit != 0 
GROUP BY country
ORDER BY Transacting_Customers DESC;

-- Number of Non_Transacting_Customers and their Distribution across Countries. i.e. WHERE creditLimit = 0
SELECT 
COUNT(customerNumber) AS Non_Transacting_Customers
FROM customers
WHERE creditLimit = 0;

SELECT 
country,
COUNT(customerNumber) AS Non_Transacting_Customers
FROM customers
WHERE creditLimit = 0 
GROUP BY country
ORDER BY Non_Transacting_Customers DESC;

-- Comparison: Transacting and Non_Transacting Customers across Countries
-- CREATE VIEW Customers_Breakdown_across_Countries AS 
WITH Registered_Customers AS (
SELECT 
country,
COUNT(customerNumber) AS Registered_Customers
FROM customers 
GROUP BY country
ORDER BY country ASC
),
Transacting_Customers AS (
SELECT 
country,
COUNT(customerNumber) AS Transacting_Customers
FROM customers
WHERE creditLimit != 0 
GROUP BY country
ORDER BY country ASC
),
Non_Transacting_Customers AS (
SELECT 
country,
COUNT(customerNumber) AS Non_Transacting_Customers
FROM customers
WHERE creditLimit = 0 
GROUP BY country
ORDER BY country ASC
)
SELECT
Registered_Customers.country,
IFNULL(Transacting_Customers.Transacting_Customers,0) AS Transacting_Customers,
IFNULL(Non_Transacting_Customers.Non_Transacting_Customers,0) AS Non_Transacting_Customers,
Registered_Customers.Registered_Customers
FROM Registered_Customers
LEFT JOIN Transacting_Customers
ON Registered_Customers.country = Transacting_Customers.country
LEFT JOIN Non_Transacting_Customers
ON Registered_Customers.country = Non_Transacting_Customers.country;
-- SELECT * FROM Customers_Breakdown_across_Countries;

-- Table for quantities of products ordered across countries
-- CREATE VIEW Products_Transactions_Across_Countries AS
WITH Product_Transactions AS (
SELECT 
	orderdetails.orderNumber,
    orderdetails.productCode,
    orderdetails.quantityOrdered,
    orderdetails.priceEach,
    orderdetails.orderLineNumber,
    orders.customerNumber,
    customers.country
FROM orderdetails
LEFT JOIN orders
ON orders.orderNumber = orderdetails.orderNumber
LEFT JOIN customers
ON customers.customerNumber = orders.customerNumber
LIMIT 3000
)
-- SELECT * FROM Product_Transactions;
SELECT 
	DISTINCT country,
    -- COUNT(DISTINCT customerNumber),
    COUNT(DISTINCT productCode) AS Transacted_Products,
    SUM(quantityOrdered) AS Quantities_of_Products_Ordered
FROM Product_Transactions
GROUP BY country;

-- Table of Transacting customers and the total quantities of Products Ordered
-- CREATE VIEW   
WITH orderdetails_Product_Quantities AS (
SELECT 
    DISTINCT orderdetails.orderNumber AS orderNumber,
    orders.orderDate,
    orders.customerNumber AS customerNumber,
    COUNT(DISTINCT orderdetails.productCode) AS Products_Purchased,
    SUM(orderdetails.quantityOrdered) AS Quantities_Purchased
FROM orderdetails
LEFT JOIN orders
ON orders.orderNumber = orderdetails.orderNumber
GROUP BY orderNumber, customerNumber
)
-- SELECT * FROM orderdetails_Product_Quantities;
SELECT
	DISTINCT customerNumber,
	SUM(Quantities_Purchased) OVER (
    PARTITION BY customerNumber) AS Total_Quantities
FROM orderdetails_Product_Quantities;

-- Table of Transacting customers with their Sales Revenue
-- CREATE VIEW 
WITH Costs_of_Products_Purchased AS ( 
SELECT 
    DISTINCT orderdetails.orderNumber AS orderNumber,
	orders.orderDate,
	orders.customerNumber AS customerNumber,
    orderdetails.quantityOrdered,
    orderdetails.priceEach,
    (orderdetails.quantityOrdered * orderdetails.priceEach) AS Cost
FROM orderdetails
LEFT JOIN orders
ON orders.orderNumber = orderdetails.orderNumber
LIMIT 3000
)
-- SELECT * FROM Costs_of_Products_Purchased;
SELECT 
	DISTINCT customerNumber,    
    SUM(Cost) OVER (
    PARTITION BY customerNumber) AS Total_Cost
FROM Costs_of_Products_Purchased;

 