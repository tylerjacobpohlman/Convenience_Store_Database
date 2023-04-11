-- creates the table cashiers
DROP TABLE IF EXISTS cashiers;
CREATE TABLE cashiers
(
	cashier_id INT PRIMARY KEY AUTO_INCREMENT,
    -- foreign key, every cashier must be assigned to a stor
    store_id INT NOT NULL,
    -- up 999 employees per store
    -- can always increase later
    cashier_number CHAR(3) NOT NULL UNIQUE,
    -- cashiers might share the same name, so no need for UNIQUE
    cashier_first_name VARCHAR(32),
    cashier_last_name VARCHAR(32),
    CONSTRAINT cashiers_fk_stores FOREIGN KEY (store_id) REFERENCES stores (store_id)
);