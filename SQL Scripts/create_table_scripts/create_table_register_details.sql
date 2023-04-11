-- creates the register_details
DROP TABLE IF EXISTS register_details;
CREATE TABLE register_details
(
	register_details_sequence INT NOT NULL AUTO_INCREMENT,
    -- foreign keys
    cashier_id INT NOT NULL,
    register_id INT NOT NULL,
    -- a specific register has a specific cashier on it in a specific time window
    -- limitations include the possibility of multiple cashiers on one register 
    register_datetime_from DATETIME NOT NULL,
    register_datetime_to DATETIME NOT NULL,
    CONSTRAINT details_fk_cashiers FOREIGN KEY (cashier_id) REFERENCES cashiers(cashier_id),
    CONSTRAINT details_fk_registers FOREIGN KEY (register_id) REFERENCES registers(register_id),
    -- this constraint allows the index of the the three
    CONSTRAINT details_pk PRIMARY KEY (register_details_sequence, cashier_id, register_id)
);