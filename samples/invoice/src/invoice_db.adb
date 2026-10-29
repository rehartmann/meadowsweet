with GNATCOLL.SQL;
with GNATCOLL.SQL.Exec;
with GNATCOLL.SQL.Postgres;
with GNATCOLL.SQL.Exec.Tasking;
with Meadowsweet.Persistence;
with Meadowsweet.Persistence.Queries;

package body Invoice_DB is

   use GNATCOLL.SQL;
   use GNATCOLL.SQL.Exec;
   use Meadowsweet.Persistence;
   use Meadowsweet.Persistence.Queries;

   function Create_Customer return access Meadowsweet.Inspectable_Bean'Class is
   begin
      return new Customer;
   end Create_Customer;

   Customer_Mappings : constant Bean_Mappings
     := (1 => Primary_Key_Mapping
          (Property_Name => "id",
           Property_Type => Util.Beans.Objects.TYPE_INTEGER,
           Is_Auto_Generated => True));

   Invoice_Mappings : constant Bean_Mappings
     := (Primary_Key_Mapping
           (Property_Name => "id",
            Property_Type => Util.Beans.Objects.TYPE_INTEGER,
            Is_Auto_Generated => True),
         Mapping
           (Property_Name => "customer",
            Property_Type => Util.Beans.Objects.TYPE_BEAN,
            Column => "customer_id",
            Target_Table => "customers",
            Factory => Create_Customer'Access,
            Target_Primary_Key => "id"));

   function Customer_From_Cursor (R : GNATCOLL.SQL.Exec.Forward_Cursor'Class)
                                 return Customer is
      Result : Customer;
   begin
      Result.Id := Integer_Value (R, 0);
      Result.Name := Unbounded_Value (R, 1);
      return Result;
   end Customer_From_Cursor;

   package Customer_Persistence is new Tables
     (Bean_Type => Customer);

   package Invoice_Persistence is new Tables
     (Bean_Type => Invoice);

   DB_Descr : constant GNATCOLL.SQL.Exec.Database_Description
     := GNATCOLL.SQL.Postgres.Setup
       (Database => "mydb");

   overriding function Property_Names (From : Customer)
                                       return Meadowsweet.String_Array is
   begin
      return (To_Unbounded_String ("id"),
              To_Unbounded_String ("name"));
   end Property_Names;

   overriding function Get_Value (From : Customer;
                                  Name : String)
                                  return Util.Beans.Objects.Object is
   begin
      if Name = "id" then
         return To_Object (From.Id);
      end if;
      if Name = "name" then
         return To_Object (From.Name);
      end if;
      return Null_Object;
   end Get_Value;

   overriding procedure Set_Value (From : in out Customer;
                                   Name : String;
                                   Value : Util.Beans.Objects.Object) is
   begin
      if Name = "id" then
         From.Id := To_Integer (Value);
      elsif Name = "name" then
         From.Name := To_Unbounded_String (Value);
      else
         raise No_Value;
      end if;
   end Set_Value;

   function Get (Id : Positive) return Customer is
      DB : constant Database_Connection
        := Tasking.Get_Task_Connection (DB_Descr);
   begin
      return Customer_Persistence.Get
        (DB, "customers", Customer_Mappings, Id, Customer_From_Cursor'Access);
   end Get;

   function Get_All return Customer_Vectors.Vector is
      DB : constant Database_Connection
        := Tasking.Get_Task_Connection (DB_Descr);
      Result : Customer_Vectors.Vector;

      Objects : constant Customer_Persistence.Bean_Array
        := Customer_Persistence.Get_From_Table
          (DB,
           "customers",
           Customer_From_Cursor'Access,
           (1 => (To_Unbounded_String ("name"), Asc)));
   begin
      for I in Objects'Range loop
         Customer_Vectors.Append (Result, Objects (I));
      end loop;
      return Result;
   end Get_All;

   procedure Insert (C : Customer'Class) is
      DB : constant Database_Connection
        := Tasking.Get_Task_Connection (DB_Descr);
   begin
      Customer_Persistence.Insert (DB, "customers", Customer_Mappings, C);
   end Insert;

   procedure Delete_Customer (Id : Positive) is
      DB : constant Database_Connection
        := Tasking.Get_Task_Connection (DB_Descr);
   begin
      Customer_Persistence.Delete (DB, "customers", Customer_Mappings, Id);
   end Delete_Customer;

   overriding function Property_Names (From : Invoice)
                                       return Meadowsweet.String_Array is
   begin
      return (To_Unbounded_String ("id"),
              To_Unbounded_String ("customer"));
   end Property_Names;

   --  The object returned on Name = "customer" points to From,
   --  so it will be valid only as long as From is valid
   overriding function Get_Value (From : Invoice;
                                  Name : String)
                                  return Util.Beans.Objects.Object is
      Customer_Ptr : Customer_Access;
   begin
      if Name = "id" then
         return To_Object (From.Id);
      end if;
      if Name = "customer" then
         Customer_Ptr := new Customer;
         Customer_Ptr.all := From.Recipient;
         return To_Object (Customer_Ptr, DYNAMIC);
      end if;
      return Null_Object;
   end Get_Value;

   function Get_Bean (From : in out Invoice;
                      Name : String)
                      return access Meadowsweet.Inspectable_Bean'Class is
   begin
      if Name = "customer" then
         return From.Recipient'Unchecked_Access;
      end if;
      return null;
   end Get_Bean;

   overriding procedure Set_Value (From : in out Invoice;
                                   Name : String;
                                   Value : Util.Beans.Objects.Object) is
   begin
      if Name = "id" then
         From.Id := To_Integer (Value);
      elsif Name = "customer" then
         From.Recipient := Customer_Access (To_Bean (Value)).all;
      else
         raise No_Value with "property " & Name & " does not exist";
      end if;
   end Set_Value;

   procedure Get (Id : Positive; Target : in out Invoice) is
      DB : constant Database_Connection
        := Tasking.Get_Task_Connection (DB_Descr);
      Q : constant Meadowsweet.Persistence.Query
        := Meadowsweet.Persistence.Queries.Create_Query
          (DB => DB,
           Where => Get_Value ("id") = Parameter (DB, 1),
           Joins => (1 => To_Unbounded_String ("customer")));
      Objects : constant Invoice_Persistence.Bean_Array
        := Invoice_Persistence.Get
          (Q,
           "invoices",
           Invoice_Mappings,
           (1 => +Id));
   begin
      if Objects'Length = 0 then
         raise Persistence_Error with "No customer found with ID " & Id'Image;
      end if;
      Target := Objects (1);
   end Get;

   function Get_All return Invoice_Vectors.Vector is
      DB : constant Database_Connection
        := Tasking.Get_Task_Connection (DB_Descr);
      Result : Invoice_Vectors.Vector;
      Q : constant Meadowsweet.Persistence.Query
        := Create_Query
          (DB => DB,
           Joins => (1 => To_Unbounded_String ("customer")));
      Objects : constant Invoice_Persistence.Bean_Array
        := Invoice_Persistence.Get
          (Q,
           "invoices",
           Invoice_Mappings);
   begin
      for I in Objects'Range loop
         Invoice_Vectors.Append (Result, Objects (I));
      end loop;
      return Result;
   end Get_All;

   procedure Insert (Source : Invoice'Class) is
      DB : constant Database_Connection
        := Tasking.Get_Task_Connection (DB_Descr);
   begin
      Invoice_Persistence.Insert (DB, "invoices", Invoice_Mappings, Source);
   end Insert;

   procedure Delete_Invoice (Id : Positive) is
      DB : constant Database_Connection
        := Tasking.Get_Task_Connection (DB_Descr);
   begin
      Customer_Persistence.Delete (DB, "invoices", Invoice_Mappings, Id);
   end Delete_Invoice;

end Invoice_DB;
