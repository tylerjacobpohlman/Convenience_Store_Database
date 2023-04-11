-- creates table receipts
DROP TABLE IF EXISTS receipts;
CREATE TABLE receipts
(
	receipt_id INT PRIMARY KEY AUTO_INCREMENT,
    -- foreign keys
    register_id INT NOT NULL,
    state_name CHAR(2) NOT NULL,
    -- foreign key, but can be null is customer isn't a member
    member_id INT,
    -- each receipt has a unique number, and it must have that number
    receipt_number VARCHAR(16) NOT NULL UNIQUE,
    -- the time and date of purchase
    receipt_date_time DATETIME DEFAULT NOW(),
    receipt_subtotal DECIMAL(9,2) DEFAULT 0.0,
    receipt_total DECIMAL(9,2) DEFAULT 0.0,
    receipt_charge DECIMAL(9,2) DEFAULT 0.0,
    receipt_change_due DECIMAL(9,2) DEFAULT 0.0,
    -- dependent upon a valid member_id
    receipt_total_saved DECIMAL(9,2) DEFAULT 0.0,
    receipt_savings_percentage DECIMAL(4,2) DEFAULT 0.0,
    CONSTRAINT receipts_fk_registers FOREIGN KEY (register_id) REFERENCES registers(register_id),
    CONSTRAINT receipts_fk_states FOREIGN KEY (state_name) REFERENCES states(state_name),
    CONSTRAINT receipts_fk_members FOREIGN KEY (member_id) REFERENCES members(member_id)
);