CREATE table invoices (
   id SERIAL PRIMARY KEY,
   customer_id INTEGER);

CREATE TABLE customers (
   id SERIAL PRIMARY KEY,
   name TEXT);

CREATE TABLE items (
   id SERIAL PRIMARY KEY,
   invoice_id INTEGER,
   product TEXT,
   quantity INTEGER);
