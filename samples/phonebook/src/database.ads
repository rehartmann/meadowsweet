with GNATCOLL.SQL; use GNATCOLL.SQL;
pragma Warnings (Off, "no entities of * are referenced");
pragma Warnings (Off, "use clause for package * has no effect");
with GNATCOLL.SQL_Fields; use GNATCOLL.SQL_Fields;
pragma Warnings (On, "no entities of * are referenced");
pragma Warnings (On, "use clause for package * has no effect");
with Database_Names; use Database_Names;
package Database is
   pragma Style_Checks (Off);
   pragma Elaborate_Body;

   ------------
   -- Public --
   ------------

   package Public is

      type T_Abstract_Public_Addresses
         (Instance : Cst_String_Access;
          Index    : Integer)
      is abstract new SQL_Table (Ta_Public_Addresses, Instance, Index) with
      record
         E_Mail_Address : SQL_Field_Text (Ta_Public_Addresses, Instance, N_E_Mail_Address, Index);
         Family_Name : SQL_Field_Text (Ta_Public_Addresses, Instance, N_Family_Name, Index);
         Given_Name : SQL_Field_Text (Ta_Public_Addresses, Instance, N_Given_Name, Index);
         Id : SQL_Field_Integer (Ta_Public_Addresses, Instance, N_Id, Index);
         Phone_Number : SQL_Field_Text (Ta_Public_Addresses, Instance, N_Phone_Number, Index);
      end record;

      type T_Public_Addresses (Instance : Cst_String_Access)
         is new T_Abstract_Public_Addresses (Instance, -1) with null record;
      --  To use named aliases of the table in a query
      --  Use Instance=>null to use the default name.

      type T_Numbered_Public_Addresses (Index : Integer)
         is new T_Abstract_Public_Addresses (null, Index) with null record;
      --  To use aliases in the form name1, name2,...

      Addresses : T_Public_Addresses (null);
   end Public;
end Database;
