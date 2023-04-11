-- creates table states
DROP TABLE IF EXISTS states;
CREATE TABLE states
(
	-- the table doesn't store much detail, and state_name is needed to compare to the receipt, so I made it the primary key
	state_name CHAR(2) PRIMARY KEY,
    -- each state must have a specified tax percentage
    state_tax_percentage DECIMAL(2,2) NOT NULL
);