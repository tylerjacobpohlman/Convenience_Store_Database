-- ***********************************
-- CREATE AND SELECTS THE HVS DATABASE
-- ***********************************
DROP DATABASE IF EXISTS hvs;
CREATE DATABASE hvs;

USE hvs;

-- *************************
-- CREATE TABLES AND INDEXES
-- *************************
-- CREATES TABLE STATES
-- This table is used for state taxes.
CREATE TABLE states
(
    -- can act as the primary key since CHAR(2) isn't overly complex
    -- also, makes it easier for inputting state into stores table
	state_name CHAR(2) PRIMARY KEY,
    -- each state must have a specified tax percentage
    state_tax_percentage DECIMAL(2,2) NOT NULL
);
-- CREATES THE STORES TABLE
-- *WARNING* must create table states first
CREATE TABLE stores
(
	store_id INT PRIMARY KEY AUTO_INCREMENT,
    store_address VARCHAR(50),
    store_city VARCHAR(50),
	-- for state taxes
    store_state CHAR(2) NOT NULL,
    store_zip VARCHAR(20),
	-- no 2 stores can have the same number, and phone number is numerically important 
    store_phone VARCHAR(20) UNIQUE,
    CONSTRAINT stores_fk_states FOREIGN KEY (store_state) REFERENCES states(state_name)
);
-- CREATES THE CASHIERS TABLE
-- 	*WARNING* must create stores table first
CREATE TABLE cashiers
(
	cashier_id INT PRIMARY KEY AUTO_INCREMENT,
    -- foreign key, every cashier must be assigned to a stor
    store_id INT NOT NULL,
    -- cashiers might share the same name, so no need for UNIQUE
    cashier_first_name VARCHAR(32),
    cashier_last_name VARCHAR(32),
    cashier_password VARCHAR(32),
    CONSTRAINT cashiers_fk_stores FOREIGN KEY (store_id) REFERENCES stores (store_id)
);

-- CREATES THE REGISTERS TABLE
-- *WARNING* must create the stores table first
CREATE TABLE registers
(
	register_id INT PRIMARY KEY AUTO_INCREMENT,
    -- foreign key
    store_id INT NOT NULL,
    -- the type is important because self always use a SELF HELP cashier
    register_type ENUM('Self', 'Clerk', 'Other'),
    -- The relationship to the stores table isn't necessarily needed, it just speeds up inquiries since going from registers
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
    -- automatically NOT NULL and UNIQUE
    -- setup in such a way that there can be used at a time
	register_id INT PRIMARY KEY,
    -- setup in such a way that a cashier can be assigned to multiple registers
    -- Also, NULL value means the register is unassigned
    cashier_id INT,
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
-- CREATES TABLE MEMBERS
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
-- phone number is used to look up rewards membership, so it is indexed
CREATE INDEX idx_phone
ON members (member_phone_number);
-- membership are also scanned in, which is basically just the account number
CREATE INDEX idx_account
ON members (member_account_number);
-- CREATES RECEIPTS TABLE
-- *WARNING* must create registers, states, and members tables first
CREATE TABLE receipts
(
	receipt_id INT PRIMARY KEY AUTO_INCREMENT,
    -- foreign keys
    register_id INT NOT NULL,
    -- foreign key, but can be null if customer isn't a member
    member_id INT,
    -- each receipt has a unique number, and it must have that number
    receipt_number INT NOT NULL UNIQUE,
    -- the time and date of purchase
    receipt_date_time DATETIME DEFAULT NOW(),
    receipt_subtotal DECIMAL(9,2) DEFAULT 0.0,
    receipt_total DECIMAL(9,2) DEFAULT 0.0,
    receipt_charge DECIMAL(9,2) DEFAULT 0.0,
    receipt_change_due DECIMAL(9,2) DEFAULT 0.0,
    -- could use JOIN statements to get the same info, but indexing the database takes more time--i.e.,
    -- might as well store this value here too since it's unchanging
    receipt_cashier_full_name VARCHAR(128) NOT NULL,
    CONSTRAINT receipts_fk_registers FOREIGN KEY (register_id) REFERENCES registers(register_id),
    CONSTRAINT receipts_fk_members FOREIGN KEY (member_id) REFERENCES members(member_id)
);
-- CREATES RECEIPT_DETAILS TABLE
-- *WARNING* must create receipts table first
CREATE TABLE receipt_details
(
	-- foreign keys
	receipt_id INT NOT NULL,
    item_id INT NOT NULL,
    item_quantity INT NOT NULL,
    item_total DECIMAL(9,2) DEFAULT 0.0,
    --
    -- The following are copied from the items table since these values can change in that table.
    --
    item_price DECIMAL(9,2) DEFAULT 0.00,
    item_discount_percentage DECIMAL(2,2) DEFAULT 0.00,
    CONSTRAINT details_fk_receipts FOREIGN KEY (receipt_id) REFERENCES receipts(receipt_id),
    CONSTRAINT details_fk_items FOREIGN KEY (item_id) REFERENCES items(item_id)
);
-- CREATES RECEIPT_DETAILS_AUDIT TABLE
CREATE TABLE cashier_assignments_audit
(
    -- stores the assignments
    register_id INT,
    cashier_id INT,
    -- stores the date of the change and what type change took place
    action_type ENUM('Sign in', 'Sign out'),
    action_date DATETIME DEFAULT NOW()
);
-- CREATES ACCUMULATIVE_SALES_PER_PRODUCT
CREATE TABLE accumulative_sales_per_product
(
    item_id INT,
    sold_qty INT DEFAULT 0,
    total_sales DECIMAL(10,2) DEFAULT 0.0
);

-- *****************
-- CREATE FUNCTIONS
-- *****************
-- *WARNING* must create these procedures before complex insert statements
-- creates detailsDiscount procedure used in the receipt_details table
DELIMITER //
CREATE FUNCTION detailsDiscount(
    receipt_id_search INT,
    item_id_search INT
)
RETURNS DECIMAL(2,2)
DETERMINISTIC
BEGIN
	DECLARE discount DECIMAL(2,2);
    
    -- subquery to grab member_id
    IF (SELECT member_id FROM receipts WHERE receipt_id = receipt_id_search) IS NOT NULL THEN
		-- subquery if true, sets the discount to the item discount
		SET discount = (SELECT item_discount_percentage FROM items WHERE item_id = item_id_search);
    ELSEIF (SELECT member_id FROM receipts WHERE receipt_id = receipt_id_search) IS NULL THEN
		-- sets the discount percentage to 0% if false
		SET discount = 0.00;
    END IF;
	
    RETURN(discount);
END //
DELIMITER ;

-- creates function detailsPrice for order_details table
-- *WARNING* must create detailsDiscount procedure first
DELIMITER //
CREATE FUNCTION detailsPrice(
    receipt_id_search INT,
    item_id_search INT
)
RETURNS DECIMAL(9,2)
DETERMINISTIC
BEGIN
    DECLARE price DECIMAL(9,2);

    -- calculates the price with the given discount
    -- subquery grabs the price of the given item
    SET price = (SELECT item_price FROM items WHERE item_id = item_id_search) * (1 - detailsDiscount(receipt_id_search, item_id_search) );
    
    RETURN(price);

END //
DELIMITER ;
-- creates function receiptsStateTax for the receipts table
DELIMITER //
CREATE FUNCTION receiptsStateTax(
    receipt_id_search INT
)
RETURNS DECIMAL(2,2)
DETERMINISTIC
BEGIN
    DECLARE tax DECIMAL(2,2);
    
    SET tax = 
    (
    SELECT state_tax_percentage 
    FROM states 
        JOIN stores ON states.state_name = stores.store_state
        JOIN registers ON stores.store_id = registers.store_id
        JOIN receipts ON registers.register_id = receipts.register_id
    WHERE receipt_id = receipt_id_search
    );

    RETURN(tax);
END //
DELIMITER ;
-- creates function receiptsCashierName for the receipts table
-- function is only ever used when a new receipt is created, so the assignment is current and accurate
DELIMITER //
CREATE FUNCTION receiptsCashierName(
    register_id_search INT
)
RETURNS VARCHAR(128)
DETERMINISTIC
BEGIN
    DECLARE name VARCHAR(128);

    SET name = 
    (
    SELECT CONCAT(cashier_first_name, ' ', cashier_last_name)
    -- joins the cashiers and cashier_assignments tables
    FROM cashier_assignments ca JOIN cashiers c ON ca.cashier_id = c.cashier_id
    -- checks if the date is during a previous assignment range, or checks if the date is during a current assignment
    WHERE register_id = register_id_search
    );

    RETURN(name);
END //
DELIMITER ;
-- memberIDFromNumber
DROP FUNCTION IF EXISTS memberIDFromNumber;
DELIMITER //
CREATE FUNCTION memberIDFromNumber(
    given_member_number VARCHAR(20)
)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE id INT;
    SET id = (SELECT member_id FROM members WHERE member_account_number = given_member_number);

    RETURN(id);
END //
DELIMITER ;
-- receiptIDFromNumber
DROP FUNCTION IF EXISTS receiptIDFromNumber;
DELIMITER //
CREATE FUNCTION receiptIDFromNumber(
    given_receipt_number INT
)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE id INT;
    SET id = (SELECT receipt_id FROM receipts WHERE receipt_number = given_receipt_number);

    RETURN(id);
END //
DELIMITER ;
-- itemIDFromUPC
DROP FUNCTION IF EXISTS itemIDFromUPC;
DELIMITER //
CREATE FUNCTION itemIDFromUPC(
    given_upc VARCHAR(20)
)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE id INT;
    SET id = (SELECT item_id FROM items WHERE item_upc = given_upc);

    RETURN(id);
END //
DELIMITER ;


-- *******************************************************************************************
-- The following have simple insert statements since they lack concrete foreign key restraints
-- *******************************************************************************************
INSERT INTO states
VALUES
('OH', 0.08),
('KY', 0.04),
('NY', 0.10),
('AK', 0.02),
('PA', 0.07)
;
INSERT INTO stores (store_id, store_address, store_city, store_state, store_zip, store_phone)
VALUES 
(3329, '11706 Clifton Boulevard 117th & Clifton', 'Lakewood', 'OH', '44107', '(216) 228-9296'),
(3301, '28100 Chagrin Blvd', 'Woodmere', 'OH', '44122', '(216) 831-1466'),
(5759, '3950 Turkeyfoot Rd', 'Erlanger', 'KY', '41018', '(859) 647-6211'),
(2558, '360 6th Avenue', 'New York City', 'NY', '10011', '(212) 375-9401'),
(3999, '401 Chestnut St.', 'Carnegie', 'PA', '15106', '(412) 279-5020')
;
INSERT INTO cashiers (store_id, cashier_id, cashier_first_name, cashier_last_name, cashier_password)
VALUES
-- for sake of simplicity, the employee number is their password
-- each store has a unique self help cashier for self checkout
(3329, 718111, 'SELF', 'HELP', '718111'),
(3301, 72575, 'SELF', 'HELP', '72575'),
(2558, 648172, 'SELF', 'HELP', '648172'),
(3329, 540367, 'Sally', 'Sue', '540367'),
(2558, 535113, 'Dwanye', 'The Rock', '535113'),
(3301, 394137, 'Liam', 'Wasserman', '394137'),
(3301, 716281, 'Jace', 'Margs', '716281'),
(3999, 347242, 'Josh', 'Margulies', '347242')
;
INSERT INTO registers (store_id, register_id, register_type)
VALUES
(3329, 552, 'Self'),
(3329, 443, 'Self'),
(3301, 987, 'Self'),
(5759, 448, 'Clerk'),
(3329, 580, 'Clerk'),
(3301, 3452, 'Clerk'),
(5759, 1234, 'Clerk'),
(3999, 3344, 'Clerk')
;
INSERT INTO items (item_upc, item_name, item_price, item_discount_percentage)
VALUES 
('4334523664435', 'Sprite Zero Lemon-Lime Soda 20 fl oz', 2.59, 0.0),
('4235234532453', 'Owyn 20 g Plant-Based Drink Dark Chocolate 12 fl oz', 3.69, 0.10),
('8764353453456', '	Eboost Super Fuel Energy Drink Sparkling Blue Raspberry 11.5 fl oz', 2.99, 0.50),
('9723456897324', 'Met-Rx Crispy Apple Pie Meal Replacement Bar 3.52 oz', 3.59, 0.35),
('1224321345435', 'Gold Emblem Abound Dried Organic Mango 4 oz', 2.99, 0.33),
('3232321323444', 'Wrigley Extra Long Lasting Flavor Sugarfree Gum Peppermint 15 sticks', 1.59, 0.0),
('3245345253464', 'Pepto-Bismol 5 Symptom Relief Liquid 4 fl oz', 4.99, 0.0),
('3245786342577', 'MT DEW CD RED BTL 20Z', 2.59, 0.15),
('4378345897689', 'Buncha Crunch Bunches Of Crunchy Milk Chocolate 8 oz', 4.79, 0.0),
('2349082345999', 'TRLI SR DUO CRWLRS 6.3Z', 3.99, 0.0),
('3287237327771', 'pH Perfect Hydration Alkaline Water 12 pack 202 fl oz', 11.99, 0.10),
('9083458976342', 'Life Savers Mints Wint O Green 6.25 oz', 3.59, 0.0),
('2347863425897', 'Swiffer Heavy Duty Dusters 3 dusters', 6.99, 0.0),
('0980983425980', 'Lysol Disinfecting Wipes Lemon & Lime Blossom 80 wet wipes 20.3 oz', 10.29, 0.0);

INSERT INTO members (member_account_number, member_first_name, member_last_name, member_phone_number, member_email_address)
VALUES
('6142965', 'Tyler', 'Pohlman', '2169700354', 'tylerpp@gmail.com'),
('29166057', 'Spencer', 'Kornspan', '4406427483', 'spencervenom@gmail.com'),
('24389822', 'Phillip', 'McCourt', '3125537890', 'prmc64@icloud.com'),
('28305188', 'Duane', 'Pohlman', '2163435478', 'duanedd@gmail.com'),
('49403382', 'John', 'Smith', '9312333387', 'smithingsmith@smith.com')
;

-- Realistically, these inserts shouldn't be here b/c it implies that the given cashiers are signed into the given
-- registers... However, do to how to the following insert statements are structured, they are needed to grab the
-- cashier's name for a receipt.
INSERT INTO cashier_assignments (register_id, cashier_id)
VALUES 
(552, 718111),
(443, 718111),
(987, 648172),
(448, 535113),
(580, 535113),
-- these last 3 rows are needed since the login procedure only updates rows
-- these following rows imply that the registers exist, but no one is logged in
(3452, null),
(1234, null),
(3344, null)
;

-- have to update each time a new product is added
INSERT INTO accumulative_sales_per_product (item_id)
VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12), (13), (14);


-- *************************
-- COMPLEX INSERT STATEMENTS
-- *************************
INSERT INTO receipts (register_id, member_id, receipt_number, receipt_date_time, receipt_cashier_full_name)
VALUES
(552, 1, 49654864,'2023-01-01 22:10:26', receiptsCashierName(552) ),
(448, NULL, 23930097,'2023-04-08 13:05:00', receiptsCashierName(448) ),
(443, 3, 52286396, NOW(), receiptsCashierName(443) ),
(552, 1, 68883706, '2023-05-01 12:06:53', receiptsCashierName(552) ),
(987, NULL, 44351438, '2023-05-04 10:53', receiptsCashierName(987));

INSERT INTO receipt_details (receipt_id, item_id, item_discount_percentage, item_price, item_quantity)
VALUES
(1, 2, detailsDiscount(1, 2), detailsPrice(1, 2), 2),
(1, 1, detailsDiscount(1, 1), detailsPrice(1, 1), 5),
(2, 3, detailsDiscount(2, 3), detailsPrice(2, 3), 4),
(3, 1, detailsDiscount(3, 1), detailsPrice(3, 1), 10),
(4, 4, detailsDiscount(4, 4), detailsPrice(4, 4), 1),
(5, 4, detailsDiscount(5, 4), detailsPrice(5, 4), 2)
;

-- could have done in the insert statement, but it would have gotten too long
UPDATE receipt_details
SET item_total = item_quantity * item_price;

-- How does this work? I have no clue because I copied it from someone on StackOverflow...
-- The purpose of this update is to set the receipt_subtotal equal to all the receipt_details item_totals
UPDATE receipts 
SET receipt_subtotal 
    = (SELECT SUM(item_total) FROM receipt_details WHERE receipts.receipt_id = receipt_details.receipt_id)
;

-- sets the total equal to the the subtotal plus state tax
UPDATE receipts
SET receipt_total = receipt_subtotal * (1 + receiptsStateTax(receipt_id) )
;

-- I'm lazy, so I assumed all the receipts were paid for in the exact amount
UPDATE receipts
SET receipt_charge = receipt_total
;

-- here for future-proofing...
UPDATE receipts
SET receipt_change_due = receipt_charge - receipt_total
;

-- **************************************************
-- FUNCTIONS/PROCEDURES SPECIFIC TO JAVA APPLICATIONS
-- **************************************************
-- addStore
DELIMITER //
CREATE PROCEDURE addStore(
    given_number CHAR(5),
    given_street VARCHAR(50),
    given_city VARCHAR(50),
    given_state CHAR(2),
    given_zip VARCHAR(20),
    given_phone VARCHAR(20)
)
BEGIN
    INSERT INTO stores (store_id, store_address, store_city, store_state, store_zip, store_phone)
    VALUES (given_number, given_street, given_city, given_state, given_zip, given_phone);
END //
DELIMITER ;
-- addCashier
DELIMITER //
CREATE PROCEDURE addCashier(
    given_store_id CHAR(5),
    given_cashier_id INT,
    given_first_name VARCHAR(32),
    given_last_name VARCHAR(32)
)
BEGIN
    INSERT INTO cashiers (store_id, cashier_id, cashier_first_name, cashier_last_name)
    VALUES 
    (
    (SELECT store_id FROM stores WHERE store_id = given_store_id),
    given_cashier_id,
    given_first_name,
    given_last_name
    );
END //
DELIMITER ;
-- addRegister
-- NEED TO REWORK! CREATE TWO OF THE SAME FUNCTIONS... ONE AUTO INCREMENTS REGISTER_ID AND THE OTHER
-- ALLOWS MANUAL ENTRY OF REGISTER_ID (WITH CHECK IF REGISTER_ID IS ALREADY IN REGISTERS TABLE)
DELIMITER //
CREATE PROCEDURE addRegister(
    given_store_id CHAR(5),
    given_register_id VARCHAR(16),
    given_register_type ENUM('Self','Clerk','Other')
)
BEGIN
    INSERT INTO registers (store_id, register_id, register_type)
    VALUES ((SELECT store_id FROM stores WHERE store_id = given_store_id), 
    given_register_id, given_register_type);
END //
DELIMITER ;
-- addMember
DELIMITER //
CREATE PROCEDURE addMember(
    given_account_number VARCHAR(20),
    given_first_name VARCHAR(32),
    given_last_name VARCHAR(32),
    given_phone_number VARCHAR(16),
    given_email_address VARCHAR(64)
)
BEGIN
    INSERT INTO members (member_account_number, member_first_name, member_last_name,
        member_phone_number, member_email_address)
    VALUES (given_account_number, given_first_name, given_last_name,
        given_phone_number, given_email_address);
END //
DELIMITER ;
-- cashierRegisterLogin
DELIMITER //
CREATE PROCEDURE cashierRegisterLogin(
    given_cashier_id INT,
    given_register_id INT
)
BEGIN
    -- creates exception for invalid register_id and/or cashier_id
    DECLARE no_such_register_cashier CONDITION FOR SQLSTATE '45000';
    IF given_cashier_id NOT IN (SELECT cashier_id FROM cashiers) 
    OR given_register_id NOT IN (SELECT register_id FROM registers) THEN
        SIGNAL no_such_register_cashier SET MESSAGE_TEXT = 'No such register_id and/or cashier_id exists';
    END IF;

    UPDATE cashier_assignments
    SET cashier_id = (SELECT cashier_id FROM cashiers WHERE cashier_id = given_cashier_id)
    WHERE register_id = (SELECT register_id FROM registers WHERE register_id = given_register_id);
END //
DELIMITER ;
-- cashierRegisterLogoff
DELIMITER //
CREATE PROCEDURE cashierRegisterLogoff(
    given_register_id INT
)
BEGIN
    -- creates exception for invalid register_id and/or cashier_id
    DECLARE no_such_register CONDITION FOR SQLSTATE '45000';
    IF given_register_id NOT IN (SELECT register_id FROM registers) THEN
        SIGNAL no_such_register SET MESSAGE_TEXT = 'No such register_id exists';
    END IF;

    UPDATE cashier_assignments
    SET cashier_id = null
    WHERE register_id = (SELECT register_id FROM registers WHERE register_id = given_register_id);
END //
DELIMITER ;
-- storeAddressLookupFromRegister
DELIMITER //
CREATE PROCEDURE storeAddressLookupFromRegister(
    given_register_id INT
)
BEGIN
    SELECT CONCAT(store_address, ', ', store_city, ', ', store_state, ' ', store_zip)
    FROM stores
    WHERE store_id = (SELECT store_id FROM registers WHERE register_id = given_register_id)
    ;

END //
DELIMITER ;
-- itemUPCLookup
DELIMITER //
CREATE PROCEDURE itemUPCLookup(
    given_upc VARCHAR(20)
)
BEGIN
    -- creates exception for invalid upc
    DECLARE no_such_upc CONDITION FOR SQLSTATE '45001';
    IF given_upc NOT IN (SELECT item_upc FROM items) 
    THEN
        SIGNAL no_such_upc SET MESSAGE_TEXT = 'No such item_upc exists';
    END IF;
    SELECT item_name, item_price, item_discount_percentage
    FROM items
    WHERE item_upc = given_upc;
END //
DELIMITER ;
-- memberPhoneLookup
DELIMITER //
CREATE PROCEDURE memberPhoneLookup(
    given_phone_number VARCHAR(16)
)
BEGIN
    -- creates exception member no matching member is found
    DECLARE no_such_member CONDITION FOR SQLSTATE '45000';

    IF given_phone_number NOT IN (SELECT member_phone_number FROM members)
    THEN
        SIGNAL no_such_member SET MESSAGE_TEXT = 'No such phone_number exists';
    END IF;

    SELECT member_account_number, member_first_name, member_last_name
    FROM members
    WHERE member_phone_number = given_phone_number;
END //
DELIMITER ;
-- memberAccountNumberLookup
DELIMITER //
CREATE PROCEDURE memberAccountNumberLookup(
    given_account_number VARCHAR(20)
)
BEGIN
    -- creates exception member no matching member is found
    DECLARE no_such_account_num CONDITION FOR SQLSTATE '45000';

    IF given_account_number NOT IN (SELECT member_account_number FROM members)
    THEN
        SIGNAL no_such_account_num SET MESSAGE_TEXT = 'No such account_number exists';
    END IF;

    SELECT member_first_name, member_last_name
    FROM members
    WHERE member_account_number = given_account_number;
END //
DELIMITER ;  
-- createReceipt
DROP PROCEDURE IF EXISTS createReceipt;
DELIMITER //
CREATE PROCEDURE createReceipt(
    given_register_id INT,
    given_member_number VARCHAR(20)
)
BEGIN
    DECLARE created_receipt_number INT;
    -- grabs the greatest receipt number and adds 1 to it
    SET created_receipt_number = (SELECT MAX(receipt_number) FROM receipts) + 1;


    INSERT INTO receipts (register_id, member_id, receipt_number, receipt_date_time, receipt_cashier_full_name)
    VALUES
    (
    given_register_id,
    memberIDFromNumber(given_member_number),
    created_receipt_number,
    -- null for now before items are added
    null,
    receiptsCashierName((SELECT register_id FROM registers WHERE register_id = given_register_id))

    );

    -- the newest receipt is the greatest receipt, so it is returned by this procedure
    -- in order to be stored in the java application
    SELECT MAX(receipt_number) FROM receipts;
END //
DELIMITER;
-- addItemToReceipt
DROP PROCEDURE IF EXISTS addItemToReceipt;
DELIMITER //
CREATE PROCEDURE addItemToReceipt(
    given_upc VARCHAR(20),
    given_receipt_number INT
)
BEGIN
    INSERT INTO receipt_details (receipt_id, item_id, item_total, item_discount_percentage, item_price, item_quantity)
    VALUES
    (
    receiptIDFromNumber(given_receipt_number),
    itemIDFromUPC(given_upc),
    null,
    detailsDiscount(receiptIDFromNumber(given_receipt_number), itemIDFromUPC(given_upc)),
    detailsPrice(receiptIDFromNumber(given_receipt_number), itemIDFromUPC(given_upc)),
    1
    );
END //
-- finalizeReceipt
DROP PROCEDURE IF EXISTS finalizeReceipt;
DELIMITER //
CREATE PROCEDURE finalizeReceipt(
    given_receipt_number INT,
    given_cash DECIMAL(9,2)
)
BEGIN
    -- spit out an error if given_cash is less than receipt_total

    UPDATE receipts
    SET receipt_subtotal 
    = (SELECT SUM(item_total) FROM receipt_details WHERE receipt_id = receiptIDFromNumber(given_receipt_number))
    -- avoid wasting time and only change the receipt_detail that correspond to the receipt
    WHERE receipt_id = receiptIDFromNumber(given_receipt_number);

    UPDATE receipts
    SET receipt_total = receipt_subtotal * (1 + receiptsStateTax(receiptIDFromNumber(given_receipt_number)))
    WHERE receipt_id = receiptIDFromNumber(given_receipt_number);

    UPDATE receipts
    SET receipt_date_time = NOW()
    WHERE receipt_id = receiptIDFromNumber(given_receipt_number);

    UPDATE receipts
    SET receipt_charge = given_cash
    WHERE receipt_id = receiptIDFromNumber(given_receipt_number);

    UPDATE receipts
    SET receipt_change_due = receipt_charge - receipt_total
    WHERE receipt_id = receiptIDFromNumber(given_receipt_number);
END //
DELIMITER ;
-- getStateTax
DROP PROCEDURE IF EXISTS getStateTax;
DELIMITER //
CREATE PROCEDURE getStateTax(
    given_receipt_number INT
)
BEGIN
    SELECT receiptsStateTax(receiptIDFromNumber(given_receipt_number));
END //
DELIMITER ;

-- *****
-- ROLES
-- *****
-- cashier 
DROP ROLE IF EXISTS cashier;
CREATE ROLE cashier;
-- here so the role can even select the database in the first place
GRANT SELECT, INSERT ON hvs.* TO cashier;
-- given the procedures used in the cashier terminal application
GRANT EXECUTE ON PROCEDURE hvs.cashierRegisterLogin TO cashier;
GRANT EXECUTE ON PROCEDURE hvs.cashierRegisterLogoff TO cashier;
GRANT EXECUTE ON PROCEDURE hvs.storeAddressLookupFromRegister TO cashier;
GRANT EXECUTE ON PROCEDURE hvs.storeAddressLookupFromRegister TO cashier;
GRANT EXECUTE ON PROCEDURE hvs.itemUPCLookup TO cashier;
GRANT EXECUTE ON PROCEDURE hvs.memberPhoneLookup TO cashier;
GRANT EXECUTE ON PROCEDURE hvs.memberAccountNumberLookup TO cashier;
GRANT EXECUTE ON PROCEDURE hvs.createReceipt TO cashier;
GRANT EXECUTE ON PROCEDURE hvs.addItemToReceipt TO cashier;
GRANT EXECUTE ON PROCEDURE hvs.finalizeReceipt TO cashier;
GRANT EXECUTE ON PROCEDURE hvs.getStateTax TO cashier;

-- *****
-- USERS
-- *****
-- creates accounts for all the previously defined cashiers with a default password
-- of their employee number
-- their password expire every 90 days and they cannot reuse a password that was a previous 10 passwords
DROP USER IF EXISTS '718111';
CREATE USER '718111' IDENTIFIED BY '718111';
GRANT cashier TO '718111';
SET DEFAULT ROLE cashier to '718111';
ALTER USER '718111'
PASSWORD HISTORY 10
PASSWORD EXPIRE INTERVAL 90 DAY;

DROP USER IF EXISTS '72575';
CREATE USER '72575' IDENTIFIED BY '72575';
GRANT cashier TO '72575';
SET DEFAULT ROLE cashier to '72575';
ALTER USER '72575'
PASSWORD HISTORY 10
PASSWORD EXPIRE INTERVAL 90 DAY;

DROP USER IF EXISTS '648172';
CREATE USER '648172' IDENTIFIED BY '648172';
GRANT cashier TO '648172';
SET DEFAULT ROLE cashier to '648172';
ALTER USER '648172'
PASSWORD HISTORY 10
PASSWORD EXPIRE INTERVAL 90 DAY;

DROP USER IF EXISTS '540367';
CREATE USER '540367' IDENTIFIED BY '540367';
GRANT cashier TO '540367';
SET DEFAULT ROLE cashier to '540367';
ALTER USER '540367'
PASSWORD HISTORY 10
PASSWORD EXPIRE INTERVAL 90 DAY;

DROP USER IF EXISTS '535113';
CREATE USER '535113' IDENTIFIED BY '535113';
GRANT cashier TO '535113';
SET DEFAULT ROLE cashier to '535113';
ALTER USER '535113'
PASSWORD HISTORY 10
PASSWORD EXPIRE INTERVAL 90 DAY;

DROP USER IF EXISTS '394137';
CREATE USER '394137' IDENTIFIED BY '394137';
GRANT cashier TO '394137';
SET DEFAULT ROLE cashier to '394137';
ALTER USER '394137'
PASSWORD HISTORY 10
PASSWORD EXPIRE INTERVAL 90 DAY;

DROP USER IF EXISTS '716281';
CREATE USER '716281' IDENTIFIED BY '716281';
GRANT cashier TO '716281';
SET DEFAULT ROLE cashier to '716281';
ALTER USER '716281'
PASSWORD HISTORY 10
PASSWORD EXPIRE INTERVAL 90 DAY;

DROP USER IF EXISTS '347242';
CREATE USER '347242' IDENTIFIED BY '347242';
GRANT cashier TO '347242';
SET DEFAULT ROLE cashier to '347242';
ALTER USER '347242'
PASSWORD HISTORY 10
PASSWORD EXPIRE INTERVAL 90 DAY;

-- ********
-- TRIGGERS
-- ********
-- cashier_assignments_after_update
DROP TRIGGER IF EXISTS cashier_assignments_after_update;
DELIMITER //
CREATE TRIGGER cashier_assignments_after_update
    BEFORE UPDATE ON cashier_assignments
    FOR EACH ROW
BEGIN
    -- only limitation is that, if the register has a NULL cashier_id, then there will be a sign out
    -- for a NULL cashier
    INSERT INTO cashier_assignments_audit
    VALUES (OLD.register_id, OLD.cashier_id, 'Sign out', NOW() );

    INSERT INTO cashier_assignments_audit
    VALUES (NEW.register_id, NEW.cashier_id, 'Sign in', NOW() );

    -- fixes edge case, removing rows where a NULL employee logins
    DELETE FROM cashier_assignments_audit
    WHERE cashier_id IS NULL;
END //
DELIMITER ;
-- after_insert_receipt_details
DROP TRIGGER IF EXISTS after_insert_receipt_details;
DELIMITER //
CREATE TRIGGER after_insert_receipt_details
	BEFORE INSERT ON receipt_details
    FOR EACH ROW
BEGIN
    SET NEW.item_total = NEW.item_quantity * NEW.item_price;
END //
DELIMITER ;

-- ******
-- EVENTS
-- ******
-- ensure event scheduler is enabled
SET GLOBAL event_scheduler = ON;

DROP EVENT IF EXISTS monthly_items_total;
DELIMITER //
CREATE EVENT monthly_items_total
    -- every month of the 9th, the accumulative_sales_per_product
    -- table is updated
    ON SCHEDULE AT '2023-05-09 10:30:00' + INTERVAL 1 MONTH
DO BEGIN
    -- item_id 1
    UPDATE accumulative_sales_per_product
    SET sold_qty = (SELECT SUM(item_quantity) FROM receipt_details WHERE item_id = 1)
    WHERE item_id = 1;
    UPDATE accumulative_sales_per_product
    SET total_sales = (SELECT SUM(item_total) FROM receipt_details WHERE item_id = 1)
    WHERE item_id = 1;

    -- item_id 2
    UPDATE accumulative_sales_per_product
    SET sold_qty = (SELECT SUM(item_quantity) FROM receipt_details WHERE item_id = 2)
    WHERE item_id = 2;
    UPDATE accumulative_sales_per_product
    SET total_sales = (SELECT SUM(item_total) FROM receipt_details WHERE item_id = 2)
    WHERE item_id = 2;

    -- item_id 3
    UPDATE accumulative_sales_per_product
    SET sold_qty = (SELECT SUM(item_quantity) FROM receipt_details WHERE item_id = 3)
    WHERE item_id = 3;
    UPDATE accumulative_sales_per_product
    SET total_sales = (SELECT SUM(item_total) FROM receipt_details WHERE item_id = 3)
    WHERE item_id = 3;

    -- item_id 4
    UPDATE accumulative_sales_per_product
    SET sold_qty = (SELECT SUM(item_quantity) FROM receipt_details WHERE item_id = 4)
    WHERE item_id = 4;
    UPDATE accumulative_sales_per_product
    SET total_sales = (SELECT SUM(item_total) FROM receipt_details WHERE item_id = 4)
    WHERE item_id = 4;

    -- item_id 5
    UPDATE accumulative_sales_per_product
    SET sold_qty = (SELECT SUM(item_quantity) FROM receipt_details WHERE item_id = 5)
    WHERE item_id = 5;
    UPDATE accumulative_sales_per_product
    SET total_sales = (SELECT SUM(item_total) FROM receipt_details WHERE item_id = 5)
    WHERE item_id = 5;

    -- item_id 6
    UPDATE accumulative_sales_per_product
    SET sold_qty = (SELECT SUM(item_quantity) FROM receipt_details WHERE item_id = 6)
    WHERE item_id = 6;
    UPDATE accumulative_sales_per_product
    SET total_sales = (SELECT SUM(item_total) FROM receipt_details WHERE item_id = 6)
    WHERE item_id = 6;

    -- item_id 7
    UPDATE accumulative_sales_per_product
    SET sold_qty = (SELECT SUM(item_quantity) FROM receipt_details WHERE item_id = 7)
    WHERE item_id = 7;
    UPDATE accumulative_sales_per_product
    SET total_sales = (SELECT SUM(item_total) FROM receipt_details WHERE item_id = 7)
    WHERE item_id = 7;

    -- item_id 8
    UPDATE accumulative_sales_per_product
    SET total_sales = (SELECT SUM(item_total) FROM receipt_details WHERE item_id = 8)
    WHERE item_id = 8;
    UPDATE accumulative_sales_per_product
    SET sold_qty = (SELECT SUM(item_quantity) FROM receipt_details WHERE item_id = 8)
    WHERE item_id = 8;

    -- item_id 9
    UPDATE accumulative_sales_per_product
    SET total_sales = (SELECT SUM(item_total) FROM receipt_details WHERE item_id = 9)
    WHERE item_id = 9;
    UPDATE accumulative_sales_per_product
    SET sold_qty = (SELECT SUM(item_quantity) FROM receipt_details WHERE item_id = 9)
    WHERE item_id = 9;

    -- item_id 10
    UPDATE accumulative_sales_per_product
    SET total_sales = (SELECT SUM(item_total) FROM receipt_details WHERE item_id = 10)
    WHERE item_id = 10;
    UPDATE accumulative_sales_per_product
    SET sold_qty = (SELECT SUM(item_quantity) FROM receipt_details WHERE item_id = 10)
    WHERE item_id = 10;

    -- item_id 11
    UPDATE accumulative_sales_per_product
    SET total_sales = (SELECT SUM(item_total) FROM receipt_details WHERE item_id = 11)
    WHERE item_id = 11;
    UPDATE accumulative_sales_per_product
    SET sold_qty = (SELECT SUM(item_quantity) FROM receipt_details WHERE item_id = 11)
    WHERE item_id = 11;

    -- item_id 12
    UPDATE accumulative_sales_per_product
    SET total_sales = (SELECT SUM(item_total) FROM receipt_details WHERE item_id = 12)
    WHERE item_id = 12;
    UPDATE accumulative_sales_per_product
    SET sold_qty = (SELECT SUM(item_quantity) FROM receipt_details WHERE item_id = 12)
    WHERE item_id = 12;

    -- item_id 13
    UPDATE accumulative_sales_per_product
    SET total_sales = (SELECT SUM(item_total) FROM receipt_details WHERE item_id = 13)
    WHERE item_id = 13;
    UPDATE accumulative_sales_per_product
    SET sold_qty = (SELECT SUM(item_quantity) FROM receipt_details WHERE item_id = 13)
    WHERE item_id = 13;
    
        -- item_id 14
    UPDATE accumulative_sales_per_product
    SET total_sales = (SELECT SUM(item_total) FROM receipt_details WHERE item_id = 14)
    WHERE item_id = 14;
    UPDATE accumulative_sales_per_product
    SET sold_qty = (SELECT SUM(item_quantity) FROM receipt_details WHERE item_id = 14)
    WHERE item_id = 14;
END //
DELIMITER ;

-- *****
-- VIEWS
-- *****
CREATE VIEW receipts_view AS
SELECT receipt_number, receipt_total
FROM receipts
WHERE receipt_total > (SELECT AVG(receipt_total) FROM receipts);