INSERT INTO cashiers (store_id, cashier_number, cashier_first_name, cashier_last_name)
VALUES
-- each store has a unique self help cashier for self checkout
(1, '98', 'SELF', 'HELP'),
(2, '93', 'SELF', 'HELP'),
(3, '46', 'SELF', 'HELP'),
(1, '462', 'Sally', 'Sue'),
(3, '873', 'Dwanye', 'The Rock'),
(2, '221', 'Liam', 'Wasserman'),
(2, '324', 'Jace', 'Margs')
;

SELECT * FROM hvs.cashiers;