-- Your NUID: 001091651
-- Your Name: Apeksha Khandelwal

-- Question 1 (3 points)

/* Rewrite the following query to present the same data in a horizontal format,
   as listed below, using the SQL PIVOT command. 

FullName					1st Quarter		2nd Quarter		3rd Quarter		4th Quarter
Abbas, Syed					3					4				6				3
Alberts, Amy				11					5				12				11
Ansman-Wolfe, Pamela		20					19				34				22
Blythe, Michael				110					109				112				119
Campbell, David				48					46				45				50
Carson, Jillian				119					121				115				118
Ito, Shu					61					58				63				60
Jiang, Stephen				9					13				15				11
Mensa-Annan, Tete			40					41				23				36
Mitchell, Linda				107					104				101				106
Pak, Jae					85					87				86				90
Reiter, Tsvi				104					109				108				108
Saraiva, José				64					69				71				67
Tsoflias, Lynn				28					28				27				26
Valdez, Rachel				34					30				33				33
Vargas, Garrett				53					61				57				63
Varkey Chudukatil, Ranjit	39					48				44				44
*/

USE [AdventureWorks2008R2];
SELECT FullName,
	[1] AS [1st Quarter],
	[2] AS [2nd Quarter],
	[3] AS [3rd Quarter],
	[4] AS [4th Quarter]
FROM (
	SELECT per.LastName + ', ' + per.FirstName AS FullName,
	DATEPART(Q, sod.OrderDate) [Quart], 
	sod.SalesOrderID
	FROM
	Sales.SalesOrderHeader sod
		INNER JOIN Person.Person per
			ON sod.SalesPersonID = per.BusinessEntityID
) AS MN
PIVOT
(
	COUNT(SalesOrderID)
	FOR [Quart] IN 
	([1], [2], [3], [4])
)AS PVT;


-- Question 2 (6 points)

/* Using AdventureWorks2008R2, write a query to retrieve the top 3 colors for each year.
   Use UnitPrice * OrderQty (both are in SalesOrderDetail) to calculate
   the sale amount. The top 3 colors have the 3 highest sale amounts of a year.

   Also calculate the top 3 colors' total sale amount as a percentage
   of the overall sale amount of all products for a year.

   Return the data in the following format.

Year	Yearly Total for All Products		% of Total Sale		Top3Colors
2005		11336135.38							99.63			Red, Black, Silver
2006		30859192.31							93.66			Black, Red, Silver
2007		42308575.23							75.11			Black, Yellow, Silver
2008		25869986.41							77.85			Yellow, Black, Blue
*/
USE [AdventureWorks2008R2];

WITH Temp1 AS(
	SELECT DATEPART(YY,sod.ModifiedDate) AS [Year],
		Color,
		SUM(UnitPrice * OrderQty) AS ColorSaleAmount,
		RANK() OVER(PARTITION BY DATEPART(YY,sod.ModifiedDate) ORDER BY SUM(UnitPrice * OrderQty) DESC) AS Rank
	FROM [Sales].[SalesOrderDetail] sod 
		INNER JOIN [Production].[Product] p
			ON p.ProductID = sod.ProductID
	GROUP BY DATEPART(YY,sod.ModifiedDate), Color
	),
Temp2 AS(
	SELECT [Year] [Year], 
		SUM(ColorSaleAmount) AS YearTotal, 
		(SELECT SUM(ColorSaleAmount) FROM Temp1 innerT WHERE rank<4 
			AND innerT.[Year] = outerT.[Year]) SumOfThree, 
		STUFF((SELECT ', ' + RTRIM(CAST(Color AS CHAR)) 
			FROM Temp1 innerT WHERE innerT.[Year] = outerT.[Year] 
				AND rank<4 FOR XML PATH('')) , 1, 2, '')
		AS Top3Colors
	FROM Temp1 outerT
	GROUP BY [Year]
	)
SELECT [Year] AS [YEAR], 
	ROUND(YearTotal,2) [Yearly Total for All Products], 
	(SumOfThree/YearTotal)*100 [% of Total Sale], 
	Top3Colors
FROM Temp2
ORDER BY [Year]



-- Question 3 (6 points)

/* The view below is based on multiple tables. Please write
   a trigger that can allow an item to be inserted through the view.

   Please keep in mind, an item must be associated with an order.
   If an item is inserted without an order number, then a new order
   must be created before the item can be inserted.

CREATE TABLE SalesOrder
(OrderID INT IDENTITY PRIMARY KEY,
 OrderDate DATE);
 go
CREATE TABLE OrderItem
(OrderID INT REFERENCES SalesOrder(OrderID),
 ProductID INT,
 Quantity INT
 PRIMARY KEY (OrderID, ProductID));
 go
CREATE VIEW vOrder
AS SELECT s.OrderID, OrderDate, ProductID, Quantity
   FROM SalesOrder s
   JOIN OrderItem i
   ON s.OrderID = i.OrderID;
   go
   */

USE  KHANDELWAL_APEKSHA_TEST;
CREATE TRIGGER InsertInView
ON vOrder
INSTEAD OF INSERT 
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @Order INT;
	SELECT @Order = max(OrderID) FROM SalesOrder;
	IF NOT EXISTS (SELECT @Order FROM SalesOrder)
	BEGIN
		INSERT INTO SalesOrder SELECT OrderDate FROM INSERTED;
		SELECT @Order = OrderID FROM SalesOrder WHERE OrderDate = (SELECT OrderDate FROM inserted);
	END
	INSERT INTO OrderItem SELECT @Order, ProductID, Quantity FROM INSERTED;
END;



/*
drop TRIGGER InsertInView

insert into vOrder values(5,getDate(),5,6);
insert into vOrder values(1,getDate(),115,3);

select * from SalesOrder;
select * from OrderItem;
select * from vOrder;
