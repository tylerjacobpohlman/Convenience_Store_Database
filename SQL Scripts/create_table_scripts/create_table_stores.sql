
-- creates the table stores
DROP TABLE IF EXISTS stores;
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