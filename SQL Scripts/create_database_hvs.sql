-- ***********************************
-- CREATE AND SELECTS THE HVS DATABASE
-- ***********************************
DROP DATABASE IF EXISTS hvs;
CREATE DATABASE hvs;
USE hvs;

-- CREATES THE STORES TABLE
CREATE TABLE stores
(
	store_id INT PRIMARY KEY AUTO_INCREMENT,
    -- stores the store number as a char since not numeric computations are done on it
    -- "HVS" can have up to 99,999 stores, but an ALTER TABLE command can up the size
    store_number CHAR(5) NOT NULL UNIQUE,
    store_address VARCHAR(50),
    store_city VARCHAR(50),
	-- for state taxes, a state MUST be provided
    store_state CHAR(2) NOT NULL,
    store_zip VARCHAR(20),
	-- no 2 stores can have the same number, and phone number is numerically important 
    store_phone VARCHAR(20) UNIQUE
);

-- CREATES THE CASHIERS TABLE
-- 	*WARNING* must create stores table first
CREATE TABLE cashiers
(
	cashier_id INT PRIMARY KEY AUTO_INCREMENT,
    -- foreign key, every cashier must be assigned to a stor
    store_id INT NOT NULL,
    -- up 1,000,000 employees per store
    -- can always increase later
    cashier_number CHAR(6) NOT NULL UNIQUE,
    -- cashiers might share the same name, so no need for UNIQUE
    cashier_first_name VARCHAR(32),
    cashier_last_name VARCHAR(32),
    CONSTRAINT cashiers_fk_stores FOREIGN KEY (store_id) REFERENCES stores (store_id)
);

-- CREATES THE REGISTERS TABLE
-- *WARNING* must create the stores table first
CREATE TABLE registers
(
	register_id INT PRIMARY KEY AUTO_INCREMENT,
    -- foreign key
    store_id INT NOT NULL,
    -- every unique store has a unique register number, so there's no 2 registers of the same number in different stores
    register_number VARCHAR(16) NOT NULL UNIQUE,
    -- the type is important because self always use a SELF HELP cashier
    register_type ENUM('Self', 'Clerk', 'Other'),
    -- The relationship to the stores table isn't necessarily needed, it just speeds up inquries since going from registers
    -- to stores is faster than going from registers, to cashier_assignments, to cashiers, and then to store. Likewise, cashiers
    -- come and go, so having the relationship between stores and registers depend on cashiers can cause issues
    CONSTRAINT registers_fk_stores FOREIGN KEY (store_id) REFERENCES stores(store_id)
);

-- 	CREATES CASHIER_ASSIGNMENTS TABLE
-- *WARNING* must create cashiers and registers tables first
-- This table is implemented in such a way that it is updated frequently--i.e., cashiers are logging into and 
-- logging out of registers many times a day.
CREATE TABLE cashier_assignments
(
	assignment_sequence INT PRIMARY KEY AUTO_INCREMENT,
    cashier_id INT NOT NULL,
    register_id INT NOT NULL,
    -- the the time window in which a cashier is assigned to a register
    assignment_from DATETIME NOT NULL,
    -- can be null if a cashier is currently assigned to register
    assignment_to DATETIME,
    CONSTRAINT details_fk_cashiers FOREIGN KEY (cashier_id) REFERENCES cashiers(cashier_id),
    CONSTRAINT details_fk_registers FOREIGN KEY (register_id) REFERENCES registers(register_id)
);

-- CREATES TABLE ITEMS
CREATE TABLE items
(
	item_id INT PRIMARY KEY AUTO_INCREMENT,
    -- refers to the barcode for items at the store
    -- each barcode is unique and the item must have a barcode in order to check out
    item_upc VARCHAR(20) NOT NULL UNIQUE,
    -- each item is unique, so there shouldn't be duplicates
    item_name VARCHAR(200) NOT NULL UNIQUE,
    -- up to $99,999.99 for a single item
    -- default ensures no issues when calculations are done on the entire column
    item_price DECIMAL(9,2) DEFAULT 0.00,
    -- range from 0% to 99%
    item_discount_percentage DECIMAL(2,2) DEFAULT 0.00
);
-- items are scanned in order to pull it up from the table, so this index speeds up that process
CREATE INDEX idx_upc
ON items (item_upc);

-- CREATES TABLE MEMEBRS
-- Basically, this stores whomever rewards members are. Rewards are able to access the given savings, 
-- while nonmembers always pay the full price.
CREATE TABLE members
(
	member_id INT PRIMARY KEY AUTO_INCREMENT,
    -- every member must have an account number, and that account number is unique to each member
    member_account_number VARCHAR(20) NOT NULL UNIQUE,
    member_first_name VARCHAR(32),
    member_last_name VARCHAR(32),
    -- multiple rewards account can't share the same credentials
    member_phone_number VARCHAR(16) UNIQUE,
    member_email_address VARCHAR(64) UNIQUE,
    -- accumulative total of savings
    member_total_savings DECIMAL(12,2) DEFAULT 0.00
);
-- phone number is used to look up rewards memebership, so it is indexed
CREATE INDEX idx_phone
ON members (member_phone_number);
-- membership are also scanned in, which is basically just the account number
CREATE INDEX idx_account
ON members (member_account_number);

-- CREATES TABLE STATES
-- This table is used for state taxes.
CREATE TABLE states
(
	-- the table doesn't store much detail, and state_name is needed to compare to the receipt, so I made it the primary key
	state_name CHAR(2) PRIMARY KEY,
    -- each state must have a specified tax percentage
    state_tax_percentage DECIMAL(2,2) NOT NULL
);

-- CREATES RECEIPTS TABLE
-- *WARNING* must create registers, states, and members tables first
CREATE TABLE receipts
(
	receipt_id INT PRIMARY KEY AUTO_INCREMENT,
    -- foreign keys
    register_id INT NOT NULL,
    state_name CHAR(2) NOT NULL,
    -- foreign key, but can be null if customer isn't a member
    member_id INT,
    -- each receipt has a unique number, and it must have that number
    receipt_number VARCHAR(16) NOT NULL UNIQUE,
    -- the time and date of purchase
    receipt_date_time DATETIME DEFAULT NOW(),
    receipt_subtotal DECIMAL(9,2) DEFAULT 0.0,
    receipt_total DECIMAL(9,2) DEFAULT 0.0,
    receipt_charge DECIMAL(9,2) DEFAULT 0.0,
    receipt_change_due DECIMAL(9,2) DEFAULT 0.0,
    -- could use JOIN statements to get the same info, but indexing the database takes more time--i.e.,
    -- might as well store this value here too since it's unchanging
    receipt_cashier_full_name VARCHAR(64) NOT NULL,
    CONSTRAINT receipts_fk_registers FOREIGN KEY (register_id) REFERENCES registers(register_id),
    CONSTRAINT receipts_fk_states FOREIGN KEY (state_name) REFERENCES states(state_name),
    CONSTRAINT receipts_fk_members FOREIGN KEY (member_id) REFERENCES members(member_id)
);

-- CREATES RECEIPT_DETAILS TABLE
-- *WARNING* must create receipts table first
CREATE TABLE receipt_details
(
	-- foreign keys
	receipt_id INT NOT NULL,
    item_id INT NOT NULL,
    -- can be null... pulled from the receipts table
    member_id INT,
    item_quantity INT NOT NULL,
    item_total DECIMAL(9,2) DEFAULT 0.0,
    --
    -- The following are copied from the items table since these values can change in that table.
    --
    item_price DECIMAL(9,2) DEFAULT 0.00,
    item_discount_percentage DECIMAL(2,2) DEFAULT 0.00,
    CONSTRAINT details_fk_receipts FOREIGN KEY (receipt_id) REFERENCES receipts(receipt_id),
    CONSTRAINT details_fk_items FOREIGN KEY (item_id) REFERENCES items(item_id),
    -- this is a composite key
    -- allowed because the two ids are always a unique combination
    CONSTRAINT pk_receipt_details PRIMARY KEY (receipt_id, item_id)
);

-- *******************************************************************************************
-- The following have simple insert statements since they lack concrete foreign key restraints
-- *******************************************************************************************
INSERT INTO stores (store_number, store_address, store_city, store_state, store_zip, store_phone)
VALUES 
('3329', '11706 Clifton Boulevard 117th & Clifton', 'Lakewood', 'OH', '44107', '(216) 228-9296'),
('3301', '28100 Chagrin Blvd', 'Woodmere', 'OH', '44122', '(216) 831-1466'),
('5759', '3950 Turkeyfoot Rd', 'Erlanger', 'KY', '41018', '(859) 647-6211')
;
INSERT INTO cashiers (store_id, cashier_number, cashier_first_name, cashier_last_name)
VALUES
-- each store has a unique self help cashier for self checkout
(1, '98', 'SELF', 'HELP'),
(2, '93', 'SELF', 'HELP'),
(3, '46', 'SELF', 'HELP'),
(1, '462', 'Sally', 'Sue'),
(3, '873', 'Dwanye', 'The Rock'),
(2, '221', 'Liam', 'Wasserman'),
(2, '324', 'Jace', 'Margs')
;
INSERT INTO registers (store_id, register_number, register_type)
VALUES
(1, '552', 'Self'),
(1, '443', 'Self'),
(2, '987', 'Self'),
(3, '448', 'Clerk'),
(1, '580', 'Clerk'),
(2, '3452', 'Clerk'),
(3, '1234', 'Clerk')
;
INSERT INTO states
VALUES
('OH', 0.08),
('KY', 0.04),
('NY', 0.10)
;
INSERT INTO items (item_upc, item_name, item_price, item_discount_percentage)
VALUES 
('4334523', 'Sprite Zero Lemon-Lime Soda 20 fl oz', 2.59, 0.0),
('42352345324532', 'Owyn 20 g Plant-Based Drink Dark Chocolate 12 fl oz', 3.69, 0.10),
('8764353453456', '	Eboost Super Fuel Energy Drink Sparkling Blue Raspberry 11.5 fl oz', 2.99, 0.50),
('9723456897324', 'Met-Rx Crispy Apple Pie Meal Replacement Bar 3.52 oz', 3.59, 0.35)
;
INSERT INTO members (member_account_number, member_first_name, member_last_name, member_phone_number, member_email_address)
VALUES
('456365', 'Tyler', 'Pohlman', '(216) 970-0354', 'tylerjacobpohlman@gmail.com'),
('98567843567', 'Spencer', 'Kornspan', '(440)-642-7483', 'spencervenom@gmail.com'),
('74268343', 'Phillip', 'McCourt', '(312)-553-7890', 'prmc64@icloud.com')
;
INSERT INTO cashier_assignments (cashier_id, register_id, assignment_from, assignment_to)
VALUES 
(1, 1, '2020-04-01 00:00:00', NULL),
(1, 2, '2020-04-01 00:00:00', NULL),
(5, 4, '2023-04-08 13:00:00', '2023-04-12 20:59:59')
;

-- ***********************************************************************************************
-- The following insert statements are complex since I plan to use them for a cashier Java program
-- ***********************************************************************************************
INSERT INTO receipts (register_id, state_name, member_id, receipt_number, receipt_date_time, receipt_cashier_full_name)
VALUES
(
1,
-- sets the state equal to the state of the store the register is assigned to
(SELECT store_state FROM stores s JOIN registers r ON s.store_id = r.store_id WHERE register_id = 1),
1,
'67544567',
'2023-01-01 22:10:26',
(
-- 
SELECT CONCAT(cashier_first_name, ' ', cashier_last_name)
-- joins the cashiers and cashier_assignments tables
FROM cashier_assignments ca JOIN cashiers c ON ca.cashier_id = c.cashier_id
-- checks if the date is during a previous assignment range, or checks if the date is during a current assignment
-- WARNING: reach register can only have one cashier on it during a specific time period
WHERE ( ('2023-01-01 22:10:26' BETWEEN assignment_from AND assignment_to) OR ('2023-01-01 22:10:26' > assignment_from AND assignment_to IS NULL) )
AND register_id = 1
)
),
(
4,
(SELECT store_state FROM stores s JOIN registers r ON s.store_id = r.store_id WHERE register_id = 4),
NULL,
'444237778',
'2023-04-08 13:05:00',
(
SELECT CONCAT(cashier_first_name, ' ', cashier_last_name)
FROM cashier_assignments ca JOIN cashiers c ON ca.cashier_id = c.cashier_id
WHERE ( ('2023-04-08 13:05:00' BETWEEN assignment_from AND assignment_to) OR ('2023-04-08 13:05:00' > assignment_from AND assignment_to IS NULL) )
AND register_id = 4
)
),
(2,
(SELECT store_state FROM stores s JOIN registers r ON s.store_id = r.store_id WHERE register_id = 1),
3,
'444238578',
NOW(),
(
SELECT CONCAT(cashier_first_name, ' ', cashier_last_name)
FROM cashier_assignments ca JOIN cashiers c ON ca.cashier_id = c.cashier_id
WHERE  ( (NOW() BETWEEN assignment_from AND assignment_to) OR (NOW() > assignment_from AND assignment_to IS NULL) )
AND register_id = 2
)
);

INSERT INTO receipt_details (receipt_id, item_id, member_id, item_discount_percentage, item_price, item_quantity)
VALUES
(
1, 
2,
-- can be null if the customer doesn't have a membership
(SELECT member_id FROM receipts WHERE receipt_id = 1),
-- copies the discount percentage value to receipt_details if a member id was given in the receipt
IF( (SELECT member_id FROM receipts WHERE receipt_id = 1) IS NOT NULL,
	(SELECT item_discount_percentage FROM items WHERE item_id = 2),
    0.00),
-- applies the discount if there's a member id, otherwise the price is copied from the items table
IF( (SELECT member_id FROM receipts WHERE receipt_id = 1) IS NOT NULL, 
	(SELECT item_price FROM items WHERE item_id = 2) * (1 - (SELECT item_discount_percentage FROM items WHERE item_id = 2) ),
    (SELECT item_price FROM items WHERE item_id = 2)
    ),
2
),
(
	1,
    1,
    (SELECT member_id FROM receipts WHERE receipt_id = 1),
    IF( (SELECT member_id FROM receipts WHERE receipt_id = 1) IS NOT NULL,
	(SELECT item_discount_percentage FROM items WHERE item_id = 1),
    0.00),
    IF( (SELECT member_id FROM receipts WHERE receipt_id = 1) IS NOT NULL, 
	(SELECT item_price FROM items WHERE item_id = 1) * (1 - (SELECT item_discount_percentage FROM items WHERE item_id = 1) ),
    (SELECT item_price FROM items WHERE item_id = 1)
    ),
    5
),
(
2,
3,
(SELECT member_id FROM receipts WHERE receipt_id = 2),
IF( (SELECT member_id FROM receipts WHERE receipt_id = 2) IS NOT NULL,
	(SELECT item_discount_percentage FROM items WHERE item_id = 3),
    0.00),
IF( (SELECT member_id FROM receipts WHERE receipt_id = 2) IS NOT NULL, 
	(SELECT item_price FROM items WHERE item_id = 3) * (1 - (SELECT item_discount_percentage FROM items WHERE item_id = 3) ),
    (SELECT item_price FROM items WHERE item_id = 3)
    ),
    4
)
;

-- could have done in the insert statement, but it would have gotten too long
UPDATE receipt_details
SET item_total = item_quantity * item_price;

-- How does this work? I have no clue because I copied it from someone on StackOverflow.
-- The purpose of this update is to set the receipt_subtotal equal to all the receipt_details item_totals
UPDATE receipts 
SET receipt_subtotal = (SELECT SUM(item_total) FROM receipt_details WHERE receipts.receipt_id = receipt_details.receipt_id)
;

-- sets the total equal to the the subtotal plus state tax
UPDATE receipts, states
SET receipt_total = receipt_subtotal * (1 + state_tax_percentage)
WHERE receipts.state_name = states.state_name
;

-- I'm lazy, so I assumed all the receipts were paid for in the exact amount
UPDATE receipts
SET receipt_charge = receipt_total
;

-- here for future-proofing...
UPDATE receipts
SET receipt_change_due = receipt_charge - receipt_total
;




