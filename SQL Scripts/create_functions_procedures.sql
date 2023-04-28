USE hvs;

-- Drops the previous version if it exists
DROP FUNCTION IF EXISTS detailsDiscount;
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

-- *WARNING* must create detailsDiscount procedure first
DROP FUNCTION IF EXISTS detailsPrice;
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
    SET price = (SELECT item_price FROM items WHERE item_id = item_id_search) * (1 + detailsDiscount(receipt_id_search, item_id_search) );
    
    RETURN(price);

END //
DELIMITER ;
    

DROP FUNCTION IF EXISTS receiptsStateName;
DELIMITER //
CREATE FUNCTION receiptsStateName(
    receipt_id_search INT
)
RETURNS CHAR(2)
DETERMINISTIC
BEGIN
    DECLARE state CHAR(2);
    
    SET state = 
    (
    SELECT state_name 
    FROM states 
        JOIN stores ON states.state_name = stores.store_state
        JOIN registers ON stores.store_id = registers.store_id
        JOIN receipts ON registers.register_id = receipts.register_id
    WHERE receipt_id = receipt_id_search
    );
    
    RETURN(state);
END //
DELIMITER ;

DROP FUNCTION IF EXISTS receiptsCashierName;
DELIMITER //
CREATE FUNCTION receiptsCashierName(
    register_id_search INT,
    given_datetime DATETIME
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
    WHERE ( (given_date BETWEEN assignment_from AND assignment_to) OR (given_date > assignment_from AND assignment_to IS NULL) )
    AND register_id = register_id_search
    );

    RETURN(name)
END //
DELIMITER ;

-- **************************************************
-- FUNCTIONS/PROCEDURES SPECIFIC TO JAVA APPLICATIONS
-- **************************************************
DROP PROCEDURE IF EXISTS addItem;
DELIMITER //
CREATE PROCEDURE addItem(
    given_upc VARCHAR(20),
    given_name VARCHAR(200),
    given_price DECIMAL(9,2),
    given_discount DECIMAL(2,2)
)
BEGIN 
    INSERT INTO items (item_upc, item_name, item_price, item_discount_percentage) 
    VALUES (given_upc, given_name, given_price, given_discount);
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS addStore;
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
    INSERT INTO stores (store_number, store_address, store_city, store_state, store_zip, store_phone)
    VALUES (given_number, given_street, given_city, given_state, given_zip, given_phone);
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS addCashier;
DELIMITER //
CREATE PROCEDURE addCashier(
    given_store_number CHAR(5),
    given_cashier_number CHAR(6),
    given_first_name VARCHAR(32),
    given_last_name VARCHAR(32)
)
BEGIN
    INSERT INTO cashiers (store_id, cashier_number, cashier_first_name, cashier_last_name)
    VALUES 
    (
    (SELECT store_id FROM stores WHERE store_number = given_store_number),
    given_cashier_number,
    given_first_name,
    given_last_name
    );
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS addRegister;
DELIMITER //
CREATE PROCEDURE addRegister(
    given_store_number CHAR(5),
    given_register_number VARCHAR(16),
    given_register_type ENUM('Self', 'Clerk', 'Other')
)
BEGIN
    INSERT INTO registers (store_id, register_number, register_type)
    VALUES ( (SELECT store_id FROM stores WHERE store_number = given_store_number),
    given_register_number, given_register_type);
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS addMember;
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