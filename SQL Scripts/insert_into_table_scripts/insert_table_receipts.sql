INSERT INTO receipts (register_id, state_name, member_id, receipt_number, receipt_date_time)
VALUES
(
1, 
(SELECT store_state FROM stores s JOIN registers r ON s.store_id = r.store_id WHERE register_id = 1),
1,
'67544567',
'2023-01-01 22:10:26'
),
(
4,
(SELECT store_state FROM stores s JOIN registers r ON s.store_id = r.store_id WHERE register_id = 4),
NULL,
'444237778',
'2021-08-21 13:05:34'
),
(2,
(SELECT store_state FROM stores s JOIN registers r ON s.store_id = r.store_id WHERE register_id = 1),
3,
'444238578',
NOW()
)
;

SELECT * FROM receipts;


