with GNATCOLL.SQL;
with GNATCOLL.SQL.Exec;
with GNATCOLL.SQL.Postgres;
with GNATCOLL.SQL.Exec.Tasking;
with Database;

package body Phonebook_DB is

   use GNATCOLL.SQL;
   use GNATCOLL.SQL.Exec;
   use Database.Public;

   DB_Descr : constant GNATCOLL.SQL.Exec.Database_Description
     := GNATCOLL.SQL.Postgres.Setup
       (Database => "mydb");

   overriding function Property_Names (This : Address_Entry)
                                       return Meadowsweet.String_Array is
   begin
      return (To_Unbounded_String ("id"),
              To_Unbounded_String ("given_name"),
              To_Unbounded_String ("family_name"),
              To_Unbounded_String ("phone_number"),
              To_Unbounded_String ("e_mail_address"),
              To_Unbounded_String ("id"));
   end Property_Names;

   overriding function Get_Value (From : Address_Entry;
                                  Name : String)
                                  return Object is
   begin
      if Name = "given_name" then
         return To_Object (From.Given_Name);
      end if;
      if Name = "family_name" then
         return To_Object (From.Family_Name);
      end if;
      if Name = "phone_number" then
         return To_Object (From.Phone_Number);
      end if;
      if Name = "given_name" then
         return To_Object (From.Given_Name);
      end if;
      if Name = "e_mail_address" then
         return To_Object (From.E_Mail_Address);
      end if;
      if Name = "id" then
         return To_Object (From.Id);
      end if;
      return Null_Object;
   end Get_Value;

   function Get (Id : Natural) return Address_Entry is
      DB : constant Database_Connection
        := Tasking.Get_Task_Connection (DB_Descr);
      Q : constant SQL_Query := SQL_Select
        (Addresses.Given_Name
         & Addresses.Family_Name & Addresses.Phone_Number
         & Addresses.E_Mail_Address,
         From => Addresses,
         Where => Addresses.Id = Id);
      R : GNATCOLL.SQL.Exec.Forward_Cursor;
   begin
      R.Fetch (DB, Q);
      if not Success (DB) then
         raise Database_Error with Last_Error_Message (DB);
      end if;
      if GNATCOLL.SQL.Exec.Has_Row (R) then
         return ((Id => Id,
                  Given_Name => Unbounded_Value (R, 0),
                  Family_Name => Unbounded_Value (R, 1),
                  Phone_Number => Unbounded_Value (R, 2),
                  E_Mail_Address => Unbounded_Value (R, 3)
                 ));
      end if;
      return ((Id => 0,
               Given_Name => Null_Unbounded_String,
               Family_Name => Null_Unbounded_String,
               Phone_Number => Null_Unbounded_String,
               E_Mail_Address => Null_Unbounded_String
              ));
   end Get;

   function Get_All return Address_Entry_Vectors.Vector is
      DB : constant Database_Connection
        := Tasking.Get_Task_Connection (DB_Descr);
      Q : constant SQL_Query := SQL_Select
        (Fields => Addresses.Id & Addresses.Given_Name
         & Addresses.Family_Name & Addresses.Phone_Number
         & Addresses.E_Mail_Address,
         From => Addresses);
      R : GNATCOLL.SQL.Exec.Forward_Cursor;
      Result : Address_Entry_Vectors.Vector;
   begin
      R.Fetch (DB, Q);
      if not Success (DB) then
         raise Database_Error with Last_Error_Message (DB);
      end if;
      while GNATCOLL.SQL.Exec.Has_Row (R) loop
         Result.Append ((Id => Integer_Value (R, 0),
                         Given_Name => Unbounded_Value (R, 1),
                         Family_Name => Unbounded_Value (R, 2),
                         Phone_Number => Unbounded_Value (R, 3),
                         E_Mail_Address => Unbounded_Value (R, 4)
                        ));
         Next (R);
      end loop;
      return Result;
   end Get_All;

   procedure Insert (E : Address_Entry'Class) is
      DB : constant Database_Connection
        := Tasking.Get_Task_Connection (DB_Descr);
      Q : constant SQL_Query := SQL_Insert
        (Values =>
           (Addresses.Given_Name = To_String (E.Given_Name))
         & (Addresses.Family_Name = To_String (E.Family_Name))
         & (Addresses.Phone_Number = To_String (E.Phone_Number))
         & (Addresses.E_Mail_Address = To_String (E.E_Mail_Address))
        );
   begin
      GNATCOLL.SQL.Exec.Execute (Connection => DB,
                                 Query => Q);
      Commit_Or_Rollback (DB);
      if not Success (DB) then
         raise Database_Error with Last_Error_Message (DB);
      end if;
   end Insert;

   procedure Update (E : Address_Entry'Class) is
      DB : constant Database_Connection
        := Tasking.Get_Task_Connection (DB_Descr);
      Q : constant SQL_Query := SQL_Update
        (Table => Addresses,
         Set =>
           (Addresses.Given_Name = To_String (E.Given_Name))
         & (Addresses.Family_Name = To_String (E.Family_Name))
         & (Addresses.Phone_Number = To_String (E.Phone_Number))
         & (Addresses.E_Mail_Address = To_String (E.E_Mail_Address)),
         Where => Addresses.Id = E.Id);
   begin
      GNATCOLL.SQL.Exec.Execute (Connection => DB,
                                 Query => Q);
      Commit_Or_Rollback (DB);
      if not Success (DB) then
         raise Database_Error with Last_Error_Message (DB);
      end if;
   end Update;

   procedure Delete (Id : Positive) is
      DB : constant Database_Connection
        := Tasking.Get_Task_Connection (DB_Descr);
      Q : constant SQL_Query := SQL_Delete
        (From => Addresses,
         Where => Addresses.Id = Id);
   begin
      GNATCOLL.SQL.Exec.Execute (Connection => DB,
                                 Query => Q);
      Commit_Or_Rollback (DB);
      if not Success (DB) then
         raise Database_Error with Last_Error_Message (DB);
      end if;
   end Delete;

end Phonebook_DB;
