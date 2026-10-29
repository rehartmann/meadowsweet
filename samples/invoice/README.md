# Phonebook sample application

Steps to run the application:

1. Create a PostgreSQL database with the name `mydb`.

2. Create the tables `customers` and `invoices` in this datababase using the definition in
`dbschema/schema.sql`.

3. Run the application, e.g. using `alr run` with a user which has INSERT,
SELECT, UPDATE, and DELETE rights on the tables created in step 2.

4. Open http://localhost:8080/invoice/invoices in your browser to see the application.

The application depends on the JinTP renderer provided by Meadowsweet_Jintp.
