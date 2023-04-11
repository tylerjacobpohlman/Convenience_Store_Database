-- creates table receipt_details
DROP TABLE IF EXISTS receipt_details;
CREATE TABLE receipt_details
(
	-- foreign keys
	receipt_id INT NOT NULL,
    item_id INT NOT NULL,
    -- this foreign key can be null
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
    CONSTRAINT details_fk_members FOREIGN KEY (member_id) REFERENCES members(member_id),
    -- this is a composite key
    -- allowed because the two ids are always a unique combination
    CONSTRAINT pk_receipt_details PRIMARY KEY (receipt_id, item_id)
);