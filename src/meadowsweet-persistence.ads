with GNATCOLL.SQL;
with GNATCOLL.SQL.Exec;

package Meadowsweet.Persistence is

   type Direction_Type is (Asc, Desc);

   type Order_Element is record
      Column_Name : Unbounded_String;
      Direction : Direction_Type;
   end record;

   type Order_Spec is array (Positive range <>) of Order_Element;

   No_Order : constant Order_Spec := (1 .. 0 => <>);

   No_Limit : constant Integer := -1;

   generic

      type Bean_Type is new Inspectable_Bean with private;
      with function From_Cursor (R : GNATCOLL.SQL.Exec.Forward_Cursor'Class)
                                 return Bean_Type;
      Primary_Key : String;
      PK_Is_Auto_Generated : Boolean;

   package Tables is

      type Bean_Array is array (Positive range <>) of Bean_Type;

      --  Reads a single record from the table Table_Name.
      function Get
        (DB : GNATCOLL.SQL.Exec.Database_Connection;
         Table_Name : String;
         Key : Integer)
         return Bean_Type;

      --  Reads a single record using an SQL query and parameters.
      function Get
        (DB : GNATCOLL.SQL.Exec.Database_Connection;
         SQL : String;
         Params : GNATCOLL.SQL.Exec.SQL_Parameters
         := GNATCOLL.SQL.Exec.No_Parameters)
         return Bean_Type;

      --  Reads records using an SQL query and parameters and
      --  returns them as an array of beans.
      function Get
        (DB : GNATCOLL.SQL.Exec.Database_Connection;
         SQL : String;
         Params : GNATCOLL.SQL.Exec.SQL_Parameters
         := GNATCOLL.SQL.Exec.No_Parameters)
         return Bean_Array;

      --  Reads records from table Table_Name and
      --  returns them as an array of beans.
      function Get_From_Table
        (DB : GNATCOLL.SQL.Exec.Database_Connection;
         Table_Name : String;
         Order : Order_Spec := No_Order;
         Limit : Integer := No_Limit;
         Offset : Integer := -1)
         return Bean_Array;

      --  Inserts a single record into the table Table_Name.
      procedure Insert
        (DB : GNATCOLL.SQL.Exec.Database_Connection;
         Table_Name : String;
         Bean : Bean_Type'Class);

      --  Updates a single record using the key Primary_Key.
      procedure Update
        (DB : GNATCOLL.SQL.Exec.Database_Connection;
         Table_Name : String;
         Bean : Bean_Type'Class);

      --  Deletes a single record using the key Primary_Key.
      procedure Delete
        (DB : GNATCOLL.SQL.Exec.Database_Connection;
         Table_Name : String;
         Key : Integer);

   end Tables;

   Persistence_Error : exception;

end Meadowsweet.Persistence;
