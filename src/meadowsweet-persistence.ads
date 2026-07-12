with GNATCOLL.SQL;
with GNATCOLL.SQL.Exec;
with Util.Beans.Objects;

package Meadowsweet.Persistence is

   generic

      type Bean_Type is new Inspectable_Bean with private;
      with function From_Cursor (R : GNATCOLL.SQL.Exec.Forward_Cursor'Class)
                                 return Bean_Type;
      Primary_Key : String;
      PK_Is_Auto_Generated : Boolean;

   package Tables is

      procedure Insert
        (Table_Name : String;
         DB : GNATCOLL.SQL.Exec.Database_Connection;
         Bean : Bean_Type);

      procedure Update
        (Table_Name : String;
         DB : GNATCOLL.SQL.Exec.Database_Connection;
         Bean : Bean_Type);

      function Get
        (SQL : String;
         Params : GNATCOLL.SQL.Exec.SQL_Parameters
         := GNATCOLL.SQL.Exec.No_Parameters;
         DB : GNATCOLL.SQL.Exec.Database_Connection)
         return Bean_Type;

      function Get
        (SQL : String;
         Params : GNATCOLL.SQL.Exec.SQL_Parameters
         := GNATCOLL.SQL.Exec.No_Parameters;
         DB : GNATCOLL.SQL.Exec.Database_Connection)
         return Util.Beans.Objects.Object_Array;

      function Get_From_Table
        (Table_Name : String;
         Params : GNATCOLL.SQL.Exec.SQL_Parameters
         := GNATCOLL.SQL.Exec.No_Parameters;
         DB : GNATCOLL.SQL.Exec.Database_Connection)
         return Util.Beans.Objects.Object_Array;

   end Tables;

   Persistence_Error : exception;

end Meadowsweet.Persistence;
