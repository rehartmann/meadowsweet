# Phonebook sample application

Steps to run the application:

1. Create a PostgreSQL database with the name `mydb`.

2. Create the table `addresses` in this datababase using the definition in
`dbschema/schema.sql`.

3. Run the application, e.g. using `alr run` with a user which has INSERT,
SELECT, UPDATE, and DELETE rights on table `addresses`.

4. Open http://localhost:8080/phonebook/entries in your browser to see the application.

The application depends on the JinTP renderer provided by Meadowsweet_Jintp.
