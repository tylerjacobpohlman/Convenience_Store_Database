-- creates the registers table
DROP TABLE IF EXISTS registers;
CREATE TABLE registers
(
	register_id INT PRIMARY KEY AUTO_INCREMENT,
    -- every unique store has a unique register number, so there's no 2 registers of the same number in different stores
    register_number VARCHAR(16) NOT NULL UNIQUE,
    -- the type is important because self always use a SELF HELP cashier
    register_type ENUM('Self', 'Clerk', 'Other')
);