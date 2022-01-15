-- Tables

CREATE TABLE  IF NOT EXISTS  currencies (
  id  INTEGER  PRIMARY KEY  NOT NULL,
  name  TEXT  NOT NULL
);
INSERT INTO currencies (id, name)
VALUES
  (1, 'RSD'), (2, 'EUR')
;

CREATE TABLE  IF NOT EXISTS  accounts (
  id  INTEGER  PRIMARY KEY  NOT NULL,
  created_at  INTEGER  NOT NULL  DEFAULT (strftime('%s','now')),
  updated_at  INTEGER  NOT NULL  DEFAULT (strftime('%s','now')),
  name  TEXT  NOT NULL,
  balance  NUMERIC  NOT NULL,
  currency_id  INTEGER  NOT NULL  REFERENCES currencies (id)  DEFAULT 1
);

CREATE TABLE  IF NOT EXISTS  payments (
  id  INTEGER  PRIMARY KEY  NOT NULL,
  created_at  INTEGER  NOT NULL  DEFAULT (strftime('%s','now')),
  updated_at  INTEGER  NOT NULL  DEFAULT (strftime('%s','now')),
  from_account_id  INTEGER  NULL  REFERENCES accounts (id),
  to_account_id  INTEGER  NULL  REFERENCES accounts (id),
  description  TEXT  NULL,
  amount  NUMERIC  NOT NULL
);


-- Views

CREATE VIEW  IF NOT EXISTS  v_accounts  AS
  SELECT
    a.id AS account_id,
    a.created_at,
    a.updated_at,
    a.name,
    a.balance,
    c.name AS currency
  FROM accounts a
    LEFT JOIN currencies c ON a.currency_id = c.id
;

CREATE VIEW  IF NOT EXISTS  v_payments  AS
  SELECT
    p.id AS payment_id,
    p.created_at,
    p.updated_at,
    a_from.name AS from_account,
    a_to.name AS to_account,
    p.description,
    p.amount,
    c.name AS currency
  FROM payments p
    LEFT JOIN accounts a_from ON a_from.id = p.from_account_id
    LEFT JOIN currencies c ON a_from.currency_id = c.id
    LEFT JOIN accounts a_to ON a_to.id = p.to_account_id
;


-- Insert data

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
