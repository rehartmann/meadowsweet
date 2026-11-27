with Ada.Containers.Indefinite_Vectors;
with Ada.Unchecked_Deallocation;
with GNATCOLL.SQL;
with GNATCOLL.SQL.Exec;
with GNATCOLL.Refcount;
with Util.Beans.Basic;
with Util.Beans.Objects;

package Meadowsweet.Persistence is

   type Direction_Type is (Asc, Desc);

   type Order_Element is record
      Name : Unbounded_String;
      Direction : Direction_Type;
   end record;

   type Order_Spec is array (Positive range <>) of Order_Element;

   No_Order : constant Order_Spec := (1 .. 0 => <>);

   No_Limit : constant Integer := -1;

   type Bean_Mapping is private;

   type Bean_Mappings is array (Positive range <>) of Bean_Mapping;

   No_Mappings : constant Bean_Mappings;

   type Expression is private;

   Null_Expression : constant Expression;

   type Bean_Factory is access function
     return access Inspectable_Bean'Class;

   --  Returns a mapping of a bean property to a table column
   function Mapping
     (Property_Path : String; --  The path by which the property can be reached
                              --  from the top of the bean hierarchy
      Property_Type : Util.Beans.Objects.Data_Type;
      Is_Primary_Key : Boolean := False;
      Is_Auto_Generated : Boolean := False;
      Table : String := "";
      Column : String;
      Factory : Bean_Factory := null;
      Target_Column : String := "")
      return Bean_Mapping;

   --  Defines a mapping to a primary key column.
   function Primary_Key_Mapping
     (Property_Path : String;
      Property_Type : Util.Beans.Objects.Data_Type
      := Util.Beans.Objects.TYPE_INTEGER;
      Table : String := "";
      Column : String;
      Is_Auto_Generated : Boolean)
      return Bean_Mapping;

   --  Defines a mapping of a bean property refering to columns in another table.
   --  The property must be a Vector_Bean. The source bean must implement
   --  Composite_Bean and implement Get_Bean and Set_Bean for the property.
   function To_Many_Mapping
     (Property_Path : String;
      Table : String;
      Target_Column : String;
      Factory : not null Bean_Factory)
     return Bean_Mapping;

   type String_Array is array (Positive range <>) of Unbounded_String;

   --  Inserts a single record into the table Table_Name.
   procedure Insert
     (DB : GNATCOLL.SQL.Exec.Database_Connection;
      Table_Name : String;
      Mappings : Bean_Mappings;
      Bean : Meadowsweet.Inspectable_Bean'Class;
      Property_Path : String := "");

   --  Updates a single record using the primary key.
   procedure Update
     (DB : GNATCOLL.SQL.Exec.Database_Connection;
      Table_Name : String;
      Mappings : Bean_Mappings;
      Bean : Meadowsweet.Inspectable_Bean'Class);

   --  Deletes a single record using the primary ley.
   procedure Delete
     (DB : GNATCOLL.SQL.Exec.Database_Connection;
      Table_Name : String;
      Mappings : Bean_Mappings;
      Key : Integer);

   generic

      type Bean_Type is new Meadowsweet.Inspectable_Bean with private;

   package Tables is

      type Bean_Array is array (Positive range <>) of Bean_Type;

      --  Reads a single record from the table Table_Name by key.
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
         Offset : Integer := 0)
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
        (DB : GNATCOLL.SQL.Exec.Database_Connection;
         Root_Table : String;
         Distinct : Boolean := False;
         Where : Expression := Null_Expression;
         Joins : String_Array := (1 .. 0 => <>);
         Order : Order_Spec := No_Order;
         Limit : Integer := No_Limit;
         Offset : Integer := 0;
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

      --  Updates a single record using the primary key.
      procedure Update
        (DB : GNATCOLL.SQL.Exec.Database_Connection;
         Table_Name : String;
         Mappings : Bean_Mappings;
         Bean : Bean_Type'Class);

      --  Deletes a single record using the primary key.
      procedure Delete
        (DB : GNATCOLL.SQL.Exec.Database_Connection;
         Table_Name : String;
         Mappings : Bean_Mappings;
         Key : Integer);

   end Tables;

   Persistence_Error : exception;

private

   type Bean_Mapping is record
      Property_Path : Unbounded_String;
      Property_Type : Util.Beans.Objects.Data_Type;
      Is_Primary_Key : Boolean;
      Is_Auto_Generated : Boolean;
      Table : Unbounded_String := Null_Unbounded_String;
      Column : Unbounded_String := Null_Unbounded_String;
      Factory : Bean_Factory := null;
      Target_Column : Unbounded_String := Null_Unbounded_String;
   end record;

   No_Mappings : constant Bean_Mappings := (1 .. 0 => <>);

   type Expression_Impl is abstract tagged null record;

   function To_SQL (Self : Expression_Impl;
                    Mappings : Bean_Mappings)
                    return String
                    is abstract;

   function Max_Parameter_No (Self : Expression_Impl)
                              return Natural;

   package Expression_Pointers is new GNATCOLL.Refcount.Shared_Pointers
     (Expression_Impl'Class);

   type Expression is record
      Ref : Expression_Pointers.Ref;
   end record;

   Null_Expression : constant Expression
     := (Ref => Expression_Pointers.Null_Ref);

   function Find_Mapping (Mappings : Bean_Mappings;
                          Property : String)
                          return Natural;

   package String_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type => Positive,
      Element_Type => String);

   function Scalar_Properties
     (B : Meadowsweet.Inspectable_Bean'Class)
      return String_Vectors.Vector;

   function Get_Primary_Key (Mappings : Bean_Mappings;
                             Bean_Name : String := "")
                             return String;

   function Get_Primary_Key_By_Table (Mappings : Bean_Mappings;
                                      Table_Name : String)
                                      return String;

   function Is_Scalar (B : Util.Beans.Basic.Readonly_Bean'Class;
                       Name : String)
                       return Boolean;

   procedure Free_Inspectable_Bean is new Ada.Unchecked_Deallocation
     (Object => Meadowsweet.Inspectable_Bean'Class,
      Name => Meadowsweet.Inspectable_Bean_Access);

end Meadowsweet.Persistence;
