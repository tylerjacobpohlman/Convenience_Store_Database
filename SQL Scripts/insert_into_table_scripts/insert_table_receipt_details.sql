INSERT INTO receipt_details (receipt_id, item_id, member_id, item_discount_percentage, item_price, item_quantity)
VALUES
(
1, 
2,
(SELECT member_id FROM receipts WHERE receipt_id = 1),
IF( (SELECT member_id FROM receipts WHERE receipt_id = 1) IS NOT NULL,
	(SELECT item_discount_percentage FROM items WHERE item_id = 2),
    0.00),
IF( (SELECT member_id FROM receipts WHERE receipt_id = 1) IS NOT NULL, 
	(SELECT item_price FROM items WHERE item_id = 2) * (1 - (SELECT item_discount_percentage FROM items WHERE item_id = 2) ),
    (SELECT item_price FROM items WHERE item_id = 2)
    ),
2
),
(
	1,
    1,
    (SELECT member_id FROM receipts WHERE receipt_id = 1),
    IF( (SELECT member_id FROM receipts WHERE receipt_id = 1) IS NOT NULL,
	(SELECT item_discount_percentage FROM items WHERE item_id = 1),
    0.00),
    IF( (SELECT member_id FROM receipts WHERE receipt_id = 1) IS NOT NULL, 
	(SELECT item_price FROM items WHERE item_id = 1) * (1 - (SELECT item_discount_percentage FROM items WHERE item_id = 1) ),
    (SELECT item_price FROM items WHERE item_id = 1)
    ),
    5
),
(
2,
3,
(SELECT member_id FROM receipts WHERE receipt_id = 2),
IF( (SELECT member_id FROM receipts WHERE receipt_id = 2) IS NOT NULL,
	(SELECT item_discount_percentage FROM items WHERE item_id = 3),
    0.00),
IF( (SELECT member_id FROM receipts WHERE receipt_id = 2) IS NOT NULL, 
	(SELECT item_price FROM items WHERE item_id = 3) * (1 - (SELECT item_discount_percentage FROM items WHERE item_id = 3) ),
    (SELECT item_price FROM items WHERE item_id = 3)
    ),
    4
)
;

UPDATE receipt_details
SET item_total = item_quantity * item_price;

SELECT * FROM receipt_details;
