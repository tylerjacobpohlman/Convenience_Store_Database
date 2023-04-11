-- create table members
DROP TABLE IF EXISTS members;
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
)