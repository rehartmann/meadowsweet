with GNATCOLL.SQL;
with GNATCOLL.SQL.Exec;

package Meadowsweet.Persistence is

   generic

      type Bean_Type is new Inspectable_Bean with private;
      with function From_Cursor (R : GNATCOLL.SQL.Exec.Forward_Cursor'Class)
                                 return Bean_Type;
      Primary_Key : String;
      PK_Is_Auto_Generated : Boolean;

   package Tables is

      procedure Insert
        (DB : GNATCOLL.SQL.Exec.Database_Connection;
         Table_Name : String;
         Bean : Bean_Type);

      procedure Update
        (DB : GNATCOLL.SQL.Exec.Database_Connection;
         Table_Name : String;
         Bean : Bean_Type);

      function Get
        (DB : GNATCOLL.SQL.Exec.Database_Connection;
         SQL : String;
         Params : GNATCOLL.SQL.Exec.SQL_Parameters
         := GNATCOLL.SQL.Exec.No_Parameters)
         return Bean_Type;

      function Get
        (DB : GNATCOLL.SQL.Exec.Database_Connection;
         SQL : String;
         Params : GNATCOLL.SQL.Exec.SQL_Parameters
         := GNATCOLL.SQL.Exec.No_Parameters)
         return Util.Beans.Objects.Object_Array;

      function Get_From_Table
        (DB : GNATCOLL.SQL.Exec.Database_Connection;
         Table_Name : String)
         return Util.Beans.Objects.Object_Array;

   end Tables;

   Persistence_Error : exception;

end Meadowsweet.Persistence;
