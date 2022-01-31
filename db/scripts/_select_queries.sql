-- accounts overview
SELECT
  a.id,
  datetime(a.created_at, 'unixepoch') as acc_created_at,
  datetime(a.updated_at, 'unixepoch') as acc_updated_at,
  a.name, a.balance, c.name
FROM accounts a
  LEFT JOIN currencies c ON a.currency_id = c.id
;

-- payments overview
SELECT
  p.id,
  datetime(p.created_at, 'unixepoch') as p_created_at,
  datetime(p.updated_at, 'unixepoch') as p_updated_at,
  a_from.name, a_to.name,
  p.description, p.amount, c.name
FROM payments p
  LEFT JOIN accounts a_from ON a_from.id = p.from_account_id
  LEFT JOIN currencies c ON a_from.currency_id = c.id
  LEFT JOIN accounts a_to ON a_to.id = p.to_account_id
;
