package body Meadowsweet.Persistence is

   use GNATCOLL.SQL;

   package body Tables is

      use GNATCOLL.SQL.Exec;

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
        (Table_Name : String;
         DB : Database_Connection;
         Bean : Bean_Type)
      is
         Column_Names : constant String_Array := Bean.Property_Names;
         Q : Unbounded_String := To_Unbounded_String ("INSERT INTO ")
           & Table_Name & '(';
         Params_Length : Natural;

      begin
         for I in Column_Names'Range loop
            Append (Q, Column_Names (I));
            if I < Column_Names'Last then
               Append (Q, ", ");
            end if;
         end loop;
         Append (Q, "Values (");
         for I in Column_Names'Range loop
            Append (Q, '?');
            if I < Column_Names'Last then
               Append (Q, ", ");
            end if;
         end loop;
         Append (Q, ')');
         if PK_Is_Auto_Generated then
            Params_Length := 0;
            for I in Column_Names'Range loop
               if Column_Names (I) /= Primary_Key then
                  Params_Length := Params_Length + 1;
               end if;
            end loop;
         else
            Params_Length := Column_Names'Length;
         end if;
         declare
            P : constant Prepared_Statement :=
              GNATCOLL.SQL.Exec.Prepare (To_String (Q),
                                         On_Server => True);
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
        (Table_Name : String;
         DB : Database_Connection;
         Bean : Bean_Type)
      is
         Column_Names : constant String_Array := Bean.Property_Names;
         Q : Unbounded_String := To_Unbounded_String ("UPDATE ")
           & Table_Name & " SET ";
         Params : SQL_Parameters (1 .. Column_Names'Length);
         Set_List_Empty : Boolean := True;
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
         for I in Column_Names'Range loop
            if Column_Names (I) /= Primary_Key then
               if not Set_List_Empty then
                  Append (Q, ", ");
               end if;
               Append (Q, Column_Names (I));
               Append (Q, " = ? ");
               Set_List_Empty := False;
            end if;
         end loop;
         Append (Q, "WHERE ");
         Append (Q, Primary_Key);
         Append (Q, " = ?");
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

      function Get (SQL : String;
                    Params : SQL_Parameters := No_Parameters;
                    DB : Database_Connection)
                    return Bean_Type is
         R : GNATCOLL.SQL.Exec.Forward_Cursor;
         P : constant Prepared_Statement :=
           GNATCOLL.SQL.Exec.Prepare (SQL,
                                      On_Server => True);
      begin
         R.Fetch (DB, P, Params);
         if not Success (DB) then
            raise Persistence_Error with Last_Error_Message (DB);
         end if;
         if GNATCOLL.SQL.Exec.Has_Row (R) then
            return From_Cursor (R);
         end if;
         raise Persistence_Error with "no object found";
      end Get;

      type Bean_Type_Access is access Bean_Type;

      function Get
        (SQL : String;
         Params : SQL_Parameters := No_Parameters;
         DB : Database_Connection)
         return Util.Beans.Objects.Object_Array
      is
         R : GNATCOLL.SQL.Exec.Direct_Cursor;
         Bean : Bean_Type_Access;
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
            Result : Util.Beans.Objects.Object_Array (1 .. Row_Count);
         begin
            for I in 1 .. Row_Count loop
               Bean := new Bean_Type;
               Bean.all := From_Cursor (R);
               Result (I) := Util.Beans.Objects.To_Object (Bean, DYNAMIC);
            end loop;
            return Result;
         end;
      end Get;

      function Get_From_Table
        (Table_Name : String;
         Params : SQL_Parameters := No_Parameters;
         DB : Database_Connection)
         return Util.Beans.Objects.Object_Array is
      begin
         return Get ("SELECT * FROM " & Table_Name, Params, DB);
      end Get_From_Table;

   end Tables;

end Meadowsweet.Persistence;
