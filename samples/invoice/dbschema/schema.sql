CREATE table invoices (
   id SERIAL PRIMARY KEY,
   customer_id INTEGER);

CREATE TABLE customers (
   id SERIAL PRIMARY KEY,
   name TEXT);
