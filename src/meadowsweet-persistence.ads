with GNATCOLL.SQL;
with GNATCOLL.SQL.Exec;
with GNATCOLL.Refcount;

package Meadowsweet.Persistence is

   type Direction_Type is (Asc, Desc);

   type Order_Element is record
      Column_Name : Unbounded_String;
      Direction : Direction_Type;
   end record;

   type Order_Spec is array (Positive range <>) of Order_Element;

   No_Order : constant Order_Spec := (1 .. 0 => <>);

   No_Limit : constant Integer := -1;

   type Query is private;

   type Bean_Mapping is private;

   type Bean_Mappings is array (Positive range <>) of Bean_Mapping;

   No_Mappings : constant Bean_Mappings;

   type Expression is private;

   Null_Expression : constant Expression;

   type Bean_Factory is access function return access Inspectable_Bean'Class;

   function Mapping (Property_Name : String;
                     Property_Type : Util.Beans.Objects.Data_Type;
                     Column : String;
                     Is_Primary_Key : Boolean := False;
                     Is_Auto_Generated : Boolean := False;
                     Target_Table : String := "";
                     Factory : Bean_Factory := null;
                     Target_Primary_Key : String := "")
                     return Bean_Mapping;

   function Primary_Key_Mapping
     (Property_Name : String;
      Property_Type : Util.Beans.Objects.Data_Type := TYPE_INTEGER;
      Column : String := "";
      Is_Auto_Generated : Boolean)
      return Bean_Mapping;

   type String_Array is array (Positive range <>) of Unbounded_String;

   generic

      type Bean_Type is new Inspectable_Bean with private;
      --  with function From_Cursor (R : GNATCOLL.SQL.Exec.Forward_Cursor'Class)
      --                             return Bean_Type;
   package Tables is

      type Bean_Array is array (Positive range <>) of Bean_Type;

      --  Reads a single record from the table Table_Name.
      function Get
        (DB : GNATCOLL.SQL.Exec.Database_Connection;
         Table_Name : String;
         Mappings : Bean_Mappings;
         Key : Integer;
         From_Cursor : not null access function
           (R : GNATCOLL.SQL.Exec.Forward_Cursor'Class)
           return Bean_Type)
         return Bean_Type;

      --  Reads a single record using an SQL query and parameters.
      function Get
        (DB : GNATCOLL.SQL.Exec.Database_Connection;
         SQL : String;
         Params : GNATCOLL.SQL.Exec.SQL_Parameters
         := GNATCOLL.SQL.Exec.No_Parameters;
         From_Cursor : not null access function
           (R : GNATCOLL.SQL.Exec.Forward_Cursor'Class)
           return Bean_Type)
         return Bean_Type;

      --  Reads records using an SQL query and parameters and
      --  returns them as an array of beans.
      function Get
        (DB : GNATCOLL.SQL.Exec.Database_Connection;
         SQL : String;
         Params : GNATCOLL.SQL.Exec.SQL_Parameters
         := GNATCOLL.SQL.Exec.No_Parameters;
         From_Cursor : not null access function
           (R : GNATCOLL.SQL.Exec.Forward_Cursor'Class)
           return Bean_Type)
         return Bean_Array;

      --  Reads records from table Table_Name and
      --  returns them as an array of beans.
      function Get_From_Table
        (DB : GNATCOLL.SQL.Exec.Database_Connection;
         Table_Name : String;
         From_Cursor : not null access function
           (R : GNATCOLL.SQL.Exec.Forward_Cursor'Class)
           return Bean_Type;
         Order : Order_Spec := No_Order;
         Limit : Integer := No_Limit;
         Offset : Integer := -1)
         return Bean_Array;

      --  Reads records from table Root_Table and
      --  returns them as an array of beans.
      --  The bean must implement Util.Beans.Basic.Bean.
      --  Child beans are read if the following conditions are met:
      --  1. Mappings contains a mapping with a property type of TYPE-BEAN
      --     and a factory function which allocates the child bean.
      --  2. The query contains a join of the child property.
      --  3. The parent of the child bean is derived from Composite_Bean
      --     implementing Get_Child so that it returns the child bean.
      function Get
        (Q : Query;
         Root_Table : String;
         Mappings : Bean_Mappings;
         Params : GNATCOLL.SQL.Exec.SQL_Parameters
         := GNATCOLL.SQL.Exec.No_Parameters)
         return Bean_Array;

         --  Inserts a single record into the table Table_Name.
      procedure Insert
        (DB : GNATCOLL.SQL.Exec.Database_Connection;
         Table_Name : String;
         Mappings : Bean_Mappings;
         Bean : Bean_Type'Class);

      --  Updates a single record using the key Primary_Key.
      procedure Update
        (DB : GNATCOLL.SQL.Exec.Database_Connection;
         Table_Name : String;
         Mappings : Bean_Mappings;
         Bean : Bean_Type'Class);

      --  Deletes a single record using the key Primary_Key.
      procedure Delete
        (DB : GNATCOLL.SQL.Exec.Database_Connection;
         Table_Name : String;
         Mappings : Bean_Mappings;
         Key : Integer);

   end Tables;

   Persistence_Error : exception;

private

   type Bean_Mapping is record
      Property_Name : Unbounded_String;
      Property_Type : Util.Beans.Objects.Data_Type;
      Column : Unbounded_String;
      Is_Primary_Key : Boolean;
      Is_Auto_Generated : Boolean;
      Target_Table : Unbounded_String := Null_Unbounded_String;
      Factory : Bean_Factory := null;
      Target_Primary_Key : Unbounded_String := Null_Unbounded_String;
   end record;

   No_Mappings : constant Bean_Mappings := (1 .. 0 => <>);

   type Expression_Impl is interface;

   function To_SQL (Self : Expression_Impl;
                    Mappings : Bean_Mappings)
                    return String
                    is abstract;

   package Expression_Pointers is new GNATCOLL.Refcount.Shared_Pointers
     (Expression_Impl'Class);

   type Expression is record
      Ref : Expression_Pointers.Ref;
   end record;

   type Query is record
      DB : GNATCOLL.SQL.Exec.Database_Connection;
      Where : Expression;
      Joins : Name_Vectors.Vector;
   end record;

   Null_Expression : constant Expression
     := (Ref => Expression_Pointers.Null_Ref);

   function Find_Mapping (Mappings : Bean_Mappings;
                          Property : String)
                          return Natural;

end Meadowsweet.Persistence;
