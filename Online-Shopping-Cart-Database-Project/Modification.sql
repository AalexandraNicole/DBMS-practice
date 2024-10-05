-- SELECT * FROM COMMAND

-- Query the address, starttime, and endtime of the service points in the same city as userid 5
SELECT streetaddr, starttime, endtime
FROM ServicePoint
WHERE city IN (SELECT city FROM Address WHERE userid = 5);

-- Query the information of laptops
SELECT *
FROM Product
WHERE type = 'laptop';

-- Query the total quantity of products from store with storeid 8 in the shopping cart
SELECT SUM(quantity) AS totalQuantity
FROM Save_to_Shopping_Cart
WHERE pid IN (SELECT pid FROM Product WHERE sid = 8);

-- Query the name and address of orders delivered on 2017-02-17
SELECT name, streetaddr, city
FROM Address
WHERE addrid IN (SELECT addrid FROM Deliver_To WHERE TimeDelivered = TO_DATE('2017-02-17', 'YYYY-MM-DD'));

-- Query the comments of product 12345678
SELECT *
FROM Comments
WHERE pid = 12345678;

-- ------------------------------------------- --
-- Data Modification

-- Insert the user id of sellers whose name starts with A into buyer
INSERT INTO Buyer (userid)
SELECT userid
FROM Seller
WHERE userid IN (SELECT userid FROM Users WHERE name LIKE 'A%');

-- Update the payment state of orders to unpaid which were created after year 2017 and with a total amount greater than 50
UPDATE Orders
SET paymentState = 'Unpaid'
WHERE creationTime > TO_DATE('2017-01-01', 'YYYY-MM-DD') AND totalAmount > 50;

-- Update the name and contact phone number of address where the province is Quebec and city is Montreal
UPDATE Address
SET name = 'Awesome Lady', contactPhoneNumber = '1234567'
WHERE province = 'Quebec' AND city = 'Montreal';

-- Delete the store which opened before year 2017
DELETE FROM Save_to_Shopping_Cart
WHERE addTime < TO_DATE('2017-01-01', 'YYYY-MM-DD');

-- ------------------------------------------- --
-- Views 
-- Create a view of all products whose price is above the average price
CREATE VIEW Products_Above_Average_Price AS
SELECT pid, name, price 
FROM Product
WHERE price > (SELECT AVG(price) FROM Product);

-- Select all from the view
SELECT * FROM Products_Above_Average_Price;

-- Update the view
-- Note: Updating a view directly might not be allowed in some SQL implementations
-- Consider updating the underlying table instead

-- Example of updating the underlying table instead:
UPDATE Product
SET price = 1
WHERE name = 'GoPro HERO5' AND pid IN (SELECT pid FROM Products_Above_Average_Price);

-- Create a view of all product sales in 2016
CREATE VIEW Product_Sales_For_2016 AS
SELECT pid, name, price
FROM Product
WHERE pid IN (SELECT pid FROM OrderItem WHERE itemid IN 
              (SELECT itemid FROM Contain WHERE orderNumber IN
               (SELECT orderNumber FROM Payment WHERE payTime BETWEEN TO_DATE('2016-01-01', 'YYYY-MM-DD') AND TO_DATE('2016-12-31', 'YYYY-MM-DD'))
              )
             );

-- Select all from the view
SELECT * FROM Product_Sales_For_2016;

-- Update the view
-- Note: Updating a view directly might not be allowed in some SQL implementations
-- Consider updating the underlying table instead

-- Example of updating the underlying table instead:
UPDATE Product
SET price = 2
WHERE name = 'GoPro HERO5' AND pid IN (SELECT pid FROM Product_Sales_For_2016);

-- ------------------------------------------- --
-- Check Constraints

-- Check whether the products saved to the shopping cart after the year 2017 have quantities of smaller than 10

-- Drop the table if it exists (Oracle specific syntax)
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE Save_to_Shopping_Cart';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/

-- Create the table with the check constraint
CREATE TABLE Save_to_Shopping_Cart
(
    userid INT NOT NULL,
    pid INT NOT NULL,
    addTime DATE,
    quantity INT,
    PRIMARY KEY (userid, pid),
    FOREIGN KEY (userid) REFERENCES Buyer (userid),
    FOREIGN KEY (pid) REFERENCES Product (pid),
    CHECK (quantity <= 10 OR addTime > TO_DATE('2017-01-01', 'YYYY-MM-DD'))
);

-- Insert into the table
INSERT INTO Save_to_Shopping_Cart VALUES (18, 67890123, TO_DATE('2016-11-23', 'YYYY-MM-DD'), 9);
INSERT INTO Save_to_Shopping_Cart VALUES (24, 67890123, TO_DATE('2017-02-22', 'YYYY-MM-DD'), 8);
-- The following insert will fail due to the check constraint
-- INSERT INTO Save_to_Shopping_Cart VALUES (5, 56789012, TO_DATE('2016-10-17', 'YYYY-MM-DD'), 11);

-- Check whether the ordered item has 0 to 10 quantities

-- Drop the view if it exists (Oracle specific syntax)
BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW Product_Sales_For_2016';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/

-- Drop the table if it exists (Oracle specific syntax)
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE Contain';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/

-- Create the table with the check constraint
CREATE TABLE Contain
(
    orderNumber INT NOT NULL,
    itemid INT NOT NULL,
    quantity INT CHECK (quantity > 0 AND quantity <= 10),
    PRIMARY KEY (orderNumber, itemid),
    FOREIGN KEY (orderNumber) REFERENCES Orders (orderNumber),
    FOREIGN KEY (itemid) REFERENCES OrderItem (itemid)
);

-- Insert into the table
-- The following insert will fail due to the check constraint
-- INSERT INTO Contain VALUES (76023921, 23543245, 11);
INSERT INTO Contain VALUES (23924831, 65738929, 8);
