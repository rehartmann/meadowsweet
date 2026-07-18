with GNATCOLL.SQL;
with GNATCOLL.SQL.Exec;
with GNATCOLL.SQL.Postgres;
with GNATCOLL.SQL.Exec.Tasking;
with Meadowsweet.Persistence;

package body Phonebook_DB is

   use GNATCOLL.SQL;
   use GNATCOLL.SQL.Exec;
   use Meadowsweet.Persistence;

   function Address_From_Cursor (R : GNATCOLL.SQL.Exec.Forward_Cursor'Class)
                                 return Address_Entry is
      Result : Address_Entry;
   begin
      Result.Id := Integer_Value (R, 0);
      Result.Given_Name := Unbounded_Value (R, 1);
      Result.Family_Name := Unbounded_Value (R, 2);
      Result.Phone_Number := Unbounded_Value (R, 3);
      Result.E_Mail_Address := Unbounded_Value (R, 4);
      return Result;
   end Address_From_Cursor;

   package Address_Persistence is new Tables
     (Bean_Type => Address_Entry,
      From_Cursor => Address_From_Cursor,
      Primary_Key => "id",
      PK_Is_Auto_Generated => True);

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
              To_Unbounded_String ("e_mail_address"));
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

   function Get (Id : Positive) return Address_Entry is
      DB : constant Database_Connection
        := Tasking.Get_Task_Connection (DB_Descr);
   begin
      return Address_Persistence.Get
        (DB, "addresses", Id);
   end Get;

   function Get_All return Address_Entry_Vectors.Vector is
      DB : constant Database_Connection
        := Tasking.Get_Task_Connection (DB_Descr);
      Result : Address_Entry_Vectors.Vector;
      Objects : constant Address_Persistence.Bean_Array
        := Address_Persistence.Get_From_Table
          (DB,
           "addresses",
           (1 => (To_Unbounded_String ("family_name"), Asc)));
   begin
      for I in Objects'Range loop
         Address_Entry_Vectors.Append (Result, Objects (I));
      end loop;
      return Result;
   end Get_All;

   procedure Insert (E : Address_Entry'Class) is
      DB : constant Database_Connection
        := Tasking.Get_Task_Connection (DB_Descr);
   begin
      Address_Persistence.Insert (DB, "addresses", E);
   end Insert;

   procedure Update (E : Address_Entry'Class) is
      DB : constant Database_Connection
        := Tasking.Get_Task_Connection (DB_Descr);
   begin
      Address_Persistence.Update (DB, "addresses", E);
   end Update;

   procedure Delete (Id : Positive) is
      DB : constant Database_Connection
        := Tasking.Get_Task_Connection (DB_Descr);
   begin
      Address_Persistence.Delete (DB, "addresses", Id);
   end Delete;

end Phonebook_DB;
