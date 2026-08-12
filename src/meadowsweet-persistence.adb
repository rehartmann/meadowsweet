with Ada.Containers;
with Ada.Containers.Vectors;

package body Meadowsweet.Persistence is

   use GNATCOLL.SQL;

   function Mapping (Property_Name : String;
                     Property_Type : Util.Beans.Objects.Data_Type;
                     Column : String)
                     return Bean_Mapping is
   begin
      return (To_Unbounded_String (Property_Name),
              Property_Type,
              To_Unbounded_String (Column));
   end Mapping;

   function Create_Query
     (DB : GNATCOLL.SQL.Exec.Database_Connection;
      Table_Name : String)
         return Query
   is
      Q : constant Query := (DB => DB,
                             Table_Name => To_Unbounded_String (Table_Name));
   begin
      return Q;
   end Create_Query;

   package body Tables is

      use GNATCOLL.SQL.Exec;
      use Util.Beans.Basic;

      function To_Parameter (Value : Object)
                             return SQL_Parameter is
      begin
         case Get_Type (Value) is
            when TYPE_BOOLEAN =>
               return +To_Boolean (Value);
            when TYPE_INTEGER =>
               return +To_Integer (Value);
            when TYPE_FLOAT =>
               return +To_Float (Value);
            when TYPE_BEAN =>
               raise Persistence_Error with "nested beans are not supported";
            when TYPE_ARRAY =>
               raise Persistence_Error
                 with "array properties are not supported";
            when TYPE_RECORD =>
               raise Persistence_Error
                 with "record properties are not supported";
            when TYPE_BLOB =>
               raise Persistence_Error
                 with "blob properties are not supported";
            when TYPE_STRING =>
               return +To_String (Value);
            when TYPE_WIDE_STRING =>
               raise Persistence_Error
                 with "wide string properties are not supported";
            when TYPE_TIME =>
               raise Persistence_Error
                 with "time is not supported yet";
            when TYPE_NULL =>
               return Null_Parameter;
         end case;
      end To_Parameter;

      procedure Insert
        (DB : Database_Connection;
         Table_Name : String;
         Bean : Bean_Type'Class)
      is
         Column_Names : constant String_Array := Bean.Property_Names;
         Q : Unbounded_String := To_Unbounded_String ("INSERT INTO ")
           & Table_Name & '(';
         Params_Length : Natural := 0;
      begin
         for I in Column_Names'Range loop
            if Column_Names (I) /= Primary_Key then
               if Params_Length > 0 then
                  Append (Q, ", ");
               end if;
               Append (Q, Column_Names (I));
               Params_Length := Params_Length + 1;
            end if;
         end loop;
         Append (Q, ") VALUES (");
         for I in 1 .. Params_Length loop
            Append (Q, DB.Parameter_String (I, ""));
            if I < Params_Length then
               Append (Q, ", ");
            end if;
         end loop;
         Append (Q, ')');
         declare
            P : constant Prepared_Statement :=
              Prepare (To_String (Q), On_Server => True);
            Params : SQL_Parameters (1 .. Params_Length);
            J : Natural := 1;
         begin
            for I in Column_Names'Range loop
               if not PK_Is_Auto_Generated
                 or else Column_Names (I) /= Primary_Key
               then
                  Params (J) := To_Parameter
                    (Bean.Get_Value (To_String (Column_Names (I))));
                  J := J + 1;
               end if;
            end loop;
            Execute (DB, P, Params);
         end;
         Commit_Or_Rollback (DB);
         if not Success (DB) then
            raise Persistence_Error with Last_Error_Message (DB);
         end if;
      end Insert;

      procedure Update
        (DB : Database_Connection;
         Table_Name : String;
         Bean : Bean_Type'Class)
      is
         Column_Names : constant String_Array := Bean.Property_Names;
         Q : Unbounded_String := To_Unbounded_String ("UPDATE ")
           & Table_Name & " SET ";
         Params : SQL_Parameters (1 .. Column_Names'Length);
         J : Positive;
         Key_Value : Object;
      begin
         if Primary_Key = "" then
            raise Persistence_Error with "Update requires primary key";
         end if;
         Key_Value := Bean.Get_Value (Primary_Key);
         if Key_Value = Null_Object then
            raise Persistence_Error with "No key value provided";
         end if;
         J := 1;
         for I in Column_Names'Range loop
            if Column_Names (I) /= Primary_Key then
               if J > 1 then
                  Append (Q, ", ");
               end if;
               Append (Q, Column_Names (I));
               Append (Q, "=");
               Append (Q, DB.Parameter_String (J, ""));
               J := J + 1;
            end if;
         end loop;
         Append (Q, " WHERE ");
         Append (Q, Primary_Key);
         Append (Q, '=');
         Append (Q, DB.Parameter_String (J, ""));
         J := 1;
         for I in Column_Names'Range loop
            if Column_Names (I) /= Primary_Key then
               Params (J) := To_Parameter
                 (Bean.Get_Value (To_String (Column_Names (I))));
               J := J + 1;
            end if;
         end loop;
         Params (Params'Last) := To_Parameter (Key_Value);
         declare
            P : constant Prepared_Statement :=
              GNATCOLL.SQL.Exec.Prepare (To_String (Q),
                                         On_Server => True);
         begin
            Execute (DB, P, Params);
         end;
         Commit_Or_Rollback (DB);
         if not Success (DB) then
            raise Persistence_Error with Last_Error_Message (DB);
         end if;
      end Update;

      procedure Delete
        (DB : GNATCOLL.SQL.Exec.Database_Connection;
         Table_Name : String;
         Key : Integer)
      is
         P : constant Prepared_Statement :=
           GNATCOLL.SQL.Exec.Prepare
             ("DELETE FROM " & Table_Name & " WHERE " & Primary_Key
              & " =" & DB.Parameter_String (1, ""),
              On_Server => True);
      begin
         Execute (DB, P, (1 => +Key));
         Commit_Or_Rollback (DB);
         if not Success (DB) then
            raise Persistence_Error with Last_Error_Message (DB);
         end if;
      end Delete;

      function Get
        (DB : Database_Connection;
         SQL : String;
         Params : SQL_Parameters := No_Parameters)
         return Bean_Type
      is
         R : GNATCOLL.SQL.Exec.Forward_Cursor;
         P : constant Prepared_Statement :=
           GNATCOLL.SQL.Exec.Prepare (SQL, On_Server => True);
         Result : Bean_Type;
      begin
         R.Fetch (DB, P, Params);
         if not Success (DB) then
            raise Persistence_Error with Last_Error_Message (DB);
         end if;
         if Has_Row (R) then
            Result := From_Cursor (R);
            Next (R);
            if Has_Row (R) then
               raise Persistence_Error with "more than one object found";
            end if;
            return Result;
         end if;
         raise Persistence_Error with "no object found";
      end Get;

      function Get
        (DB : GNATCOLL.SQL.Exec.Database_Connection;
         Table_Name : String;
         Key : Integer)
         return Bean_Type is
      begin
         return Get (DB, "SELECT * FROM " & Table_Name & " WHERE "
                     & Primary_Key & " =" & DB.Parameter_String (1, ""),
                     (1 => +Key));
      end Get;

      function Get
        (DB : Database_Connection;
         SQL : String;
         Params : SQL_Parameters := No_Parameters)
         return Bean_Array
      is
         R : GNATCOLL.SQL.Exec.Direct_Cursor;
         P : constant Prepared_Statement := GNATCOLL.SQL.Exec.Prepare
           (SQL,
            On_Server => True);
      begin
         R.Fetch (DB, P, Params);
         if not Success (DB) then
            raise Persistence_Error with Last_Error_Message (DB);
         end if;
         declare
            Row_Count : constant Natural := R.Rows_Count;
            Result : Bean_Array (1 .. Row_Count);
         begin
            for I in 1 .. Row_Count loop
               Result (I) := From_Cursor (R);
               Next (R);
            end loop;
            return Result;
         end;
      end Get;

      function Get_From_Table
        (DB : Database_Connection;
         Table_Name : String;
         Order : Order_Spec := No_Order;
         Limit : Integer := No_Limit;
         Offset : Integer := -1)
         return Bean_Array
      is
         Q : Unbounded_String := To_Unbounded_String
           ("SELECT * FROM " & Table_Name);
         Param_Length : Natural := 0;
      begin
         if Order'Length > 0 then
            Append (Q, " ORDER BY ");
            for I in Order'Range loop
               Append (Q, Order (I).Column_Name);
               if Order (I).Direction = Desc then
                  Append (Q, " DESC");
               end if;
               if I < Order'Last then
                  Append (Q, ", ");
               end if;
            end loop;
         end if;
         if Limit /= -1 then
            Append (Q, " LIMIT ");
            Param_Length := Param_Length + 1;
            Append (Q, DB.Parameter_String (Param_Length, ""));
         end if;
         if Offset /= -1 then
            Append (Q, " OFFSET ");
            Param_Length := Param_Length + 1;
            Append (Q, DB.Parameter_String (Param_Length, ""));
         end if;
         declare
            Params : SQL_Parameters (1 .. Param_Length);
            I : Positive := 1;
         begin
            if Limit /= -1 then
               Params (I) := +Limit;
               I := I + 1;
            end if;
            if Offset /= -1 then
               Params (I) := +Offset;
            end if;
            return Get (DB, To_String (Q), Params);
         end;
      end Get_From_Table;

      function Find_Mapping (Mappings : Bean_Mappings;
                             Property : String)
                             return Natural is
      begin
         for I in Mappings'Range loop
            if Mappings (I).Property_Name = Property then
               return I;
            end if;
         end loop;
         return 0;
      end Find_Mapping;

      procedure Set_Value (Dest : in out Bean_Type'Class;
                           Index : Positive;
                           Value : Util.Beans.Objects.Object) is
      begin
         Util.Beans.Basic.Bean'Class (Dest).Set_Value
           (To_String (Dest.Property_Names (Index)), Value);
      end Set_Value;

      package Bean_Vectors is new Ada.Containers.Vectors
        (Index_Type => Positive,
         Element_Type => Bean_Type);

      function Get
        (Q : Query;
         Mappings : Bean_Mappings;
         Params : GNATCOLL.SQL.Exec.SQL_Parameters
         := GNATCOLL.SQL.Exec.No_Parameters)
         return Bean_Array
      is

         function To_SQL (B : Bean_Type'Class;
                          Column_Count : out Positive)
                       return String
         is
            SQL : Unbounded_String := To_Unbounded_String ("SELECT ");
            Properties : constant String_Array := B.Property_Names;
            Mapping_Index : Natural;
         begin
            if not (B in Util.Beans.Basic.Bean'Class)
            then
               raise Meadowsweet.Persistence.Persistence_Error
               with "Bean_Type must be of type Util.Beans.Basic.Bean";
            end if;
            for I in Properties'Range loop
               Mapping_Index := Find_Mapping
                 (Mappings, To_String (B.Property_Names (I)));
               if Mapping_Index = 0 then
                  Append (SQL, Properties (I));
               else
                  Append (SQL, Mappings (Mapping_Index).Column);
               end if;
               if I < Properties'Last then
                  Append (SQL, ", ");
               end if;
            end loop;
            Append (SQL, " FROM ");
            Append (SQL, Q.Table_Name);
            Column_Count := Properties'Length;
            return To_String (SQL);
         end To_SQL;

         function To_Object (B : Bean_Type'Class;
                             R : Forward_Cursor;
                             I : Positive)
                             return Object
         is
            Mapping_Index : constant Natural := Find_Mapping
              (Mappings, To_String (B.Property_Names (I)));
            Typ : constant Util.Beans.Objects.Data_Type :=
              (if Mapping_Index = 0 then TYPE_STRING
               else Mappings (Mapping_Index).Property_Type);
         begin
            case Typ is
            when TYPE_INTEGER =>
               return To_Object
                 (GNATCOLL.SQL.Exec.Bigint_Value
                    (R, Field_Index'First + Field_Index (I - 1)));
            when others =>
               return To_Object
                 (GNATCOLL.SQL.Exec.Value
                    (R, Field_Index'First + Field_Index (I - 1)));
            end case;
         end To_Object;

         B : Bean_Type;
         Column_Count : Positive;
         SQL : constant String := To_SQL (B, Column_Count);
         R : GNATCOLL.SQL.Exec.Forward_Cursor;
         P : constant Prepared_Statement :=
           GNATCOLL.SQL.Exec.Prepare (SQL, On_Server => True);
         Beans : Bean_Vectors.Vector;
      begin
         R.Fetch (Q.DB, P, Params);
         if not Success (Q.DB) then
            raise Persistence_Error with Last_Error_Message (Q.DB);
         end if;
         while Has_Row (R) loop
            for I in 1 .. Column_Count loop
               Set_Value (B, I, To_Object (B, R, I));
            end loop;
            Beans.Append (B);
            Next (R);
         end loop;
         declare
            Result : Bean_Array (1 .. Integer (Beans.Length));
         begin
            for I in Result'Range loop
               Result (I) := Beans (I);
            end loop;
            return Result;
         end;
      end Get;

   end Tables;

end Meadowsweet.Persistence;
