
-- creates table items
DROP TABLE IF EXISTS items;
CREATE TABLE items
(
	item_id INT PRIMARY KEY AUTO_INCREMENT,
    -- refers to the barcode for items at the store
    -- each barcode is unique and the item must have a barcode in order to check out
    item_upc VARCHAR(20) NOT NULL UNIQUE,
    -- each item is unique, so there shouldn't be duplicates
    item_name VARCHAR(50) NOT NULL UNIQUE,
    -- up to $99,999.99 for a single item
    -- default ensures no issues when calculations are done on the entire column
    item_price DECIMAL(9,2) DEFAULT 0.00,
    -- range from 0% to 99%
    item_discount_percentage DECIMAL(2,2) DEFAULT 0.00
);