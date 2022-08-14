-- Insert data

INSERT INTO currencies (id, name)
VALUES
  (1, 'RSD'), (2, 'EUR')
;

INSERT INTO accounts(name, balance)
VALUES
  ('Nikola', 3000),
  ('other', 0)
;

INSERT INTO payments(description, amount, from_account_id, to_account_id)
VALUES
  ('nagradna igra',
   1200,
   (SELECT id FROM accounts a LEFT JOIN currencies c WHERE a.name like '%other%' AND c.name like 'rsd' LIMIT 1),
   (SELECT id FROM accounts a LEFT JOIN currencies c WHERE a.name like '%nikola%' AND c.name like 'rsd' LIMIT 1)
   )
;
