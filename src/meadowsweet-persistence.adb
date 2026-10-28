with Ada.Containers;
with Ada.Containers.Indefinite_Vectors;
with Ada.Containers.Vectors;
with Ada.Text_IO;
with Ada.Strings;
with Ada.Strings.Fixed;
with Meadowsweet.Persistence;
with Util.Beans.Objects;

package body Meadowsweet.Persistence is

   use GNATCOLL.SQL;
   use GNATCOLL.SQL.Exec;
   use Ada.Strings.Fixed;

   Null_Mapping : Bean_Mapping;

   function Mapping (Property_Name : String;
                     Property_Type : Util.Beans.Objects.Data_Type;
                     Column : String;
                     Is_Primary_Key : Boolean := False;
                     Is_Auto_Generated : Boolean := False;
                     Target_Table : String := "";
                     Factory : Bean_Factory := null;
                     Target_Primary_Key : String := "")
                     return Bean_Mapping is
   begin
      return (To_Unbounded_String (Property_Name),
              Property_Type,
              To_Unbounded_String (Column),
              Is_Primary_Key,
              Is_Auto_Generated,
              To_Unbounded_String (Target_Table),
              Factory,
              To_Unbounded_String (Target_Primary_Key));
   end Mapping;

   function Primary_Key_Mapping
     (Property_Name : String;
      Property_Type : Util.Beans.Objects.Data_Type := TYPE_INTEGER;
      Column : String := "";
      Is_Auto_Generated : Boolean)
      return Bean_Mapping is
   begin
      return (Property_Name => To_Unbounded_String (Property_Name),
              Property_Type => Property_Type,
              Column => (if Column /= ""
                         then To_Unbounded_String (Column)
                         else To_Unbounded_String (Property_Name)),
              Is_Primary_Key => True,
              Is_Auto_Generated => Is_Auto_Generated,
              Target_Table => Null_Unbounded_String,
              Factory => null,
              Target_Primary_Key => Null_Unbounded_String);
   end Primary_Key_Mapping;

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

   function To_Parameter (Value : Object;
                          Mapping : Bean_Mapping)
                          return SQL_Parameter
   is
         --  ID : Object;
   begin
      case Get_Type (Value) is
         when TYPE_BOOLEAN =>
            return +To_Boolean (Value);
         when TYPE_INTEGER =>
            return +To_Integer (Value);
         when TYPE_FLOAT =>
            return +To_Float (Value);
         when TYPE_BEAN =>
            if Mapping.Target_Primary_Key = Null_Unbounded_String then
               raise Persistence_Error with "no target primary key provided for "
                 & To_String (Mapping.Property_Name);
            end if;
            return To_Parameter (Get_Value (Value, To_String (Mapping.Target_Primary_Key)),
                                 Null_Mapping);
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

   package body Tables is

      use Util.Beans.Basic;

      procedure Insert
        (DB : Database_Connection;
         Table_Name : String;
         Mappings : Bean_Mappings;
         Bean : Bean_Type'Class)
      is
         Property_Names : constant Meadowsweet.String_Array := Bean.Property_Names;
         Q : Unbounded_String := To_Unbounded_String ("INSERT INTO ")
           & Table_Name & '(';
         Params_Length : Natural := 0;
         Mapping_Index : Natural;
      begin
         for I in Property_Names'Range loop
            Mapping_Index := Find_Mapping (Mappings,
                                           To_String (Property_Names (I)));
            if Mapping_Index = 0
              or else not Mappings (Mapping_Index).Is_Primary_Key
            then
               if Params_Length > 0 then
                  Append (Q, ", ");
               end if;
               if Mapping_Index = 0 then
                  Append (Q, Property_Names (I));
               else
                  Append (Q, Mappings (Mapping_Index).Column);
               end if;
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
            Mapping_Index : Natural;
         begin
            for I in Property_Names'Range loop
               Mapping_Index := Find_Mapping (Mappings,
                                              To_String (Property_Names (I)));

               if Mapping_Index = 0
                 or else not Mappings (Mapping_Index).Is_Auto_Generated
               then
                  Params (J) := To_Parameter
                    (Bean.Get_Value (To_String (Property_Names (I))),
                     (if Mapping_Index > 0 then Mappings (Mapping_Index)
                      else Null_Mapping));
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

      function Get_Primary_Key (Mappings : Bean_Mappings)
                                return String is
      begin
         for I in Mappings'Range loop
            if Index (Mappings (I).Property_Name, ".") = 0
              and then Mappings (I).Is_Primary_Key
            then
               return To_String (Mappings (I).Property_Name);
            end if;
         end loop;
         return "";
      end Get_Primary_Key;

      procedure Update
        (DB : Database_Connection;
         Table_Name : String;
         Mappings : Bean_Mappings;
         Bean : Bean_Type'Class)
      is
         Property_Names : constant Meadowsweet.String_Array := Bean.Property_Names;
         Q : Unbounded_String := To_Unbounded_String ("UPDATE ")
           & Table_Name & " SET ";
         Params : SQL_Parameters (1 .. Property_Names'Length);
         J : Positive;
         Key_Value : Object;
         Primary_Key : String := Get_Primary_Key (Mappings);
         Mapping_Index : Natural;
      begin
         if Primary_Key = "" then
            raise Persistence_Error with "Update requires primary key";
         end if;
         Key_Value := Bean.Get_Value (Primary_Key);
         if Key_Value = Null_Object then
            raise Persistence_Error with "No key value provided";
         end if;
         J := 1;
         for I in Property_Names'Range loop
            if Property_Names (I) /= Primary_Key then
               if J > 1 then
                  Append (Q, ", ");
               end if;
               Append (Q, Property_Names (I));
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
         for I in Property_Names'Range loop
            if Property_Names (I) /= Primary_Key then
               Mapping_Index := Find_Mapping (Mappings,
                                              To_String (Property_Names (I)));
               Params (J) := To_Parameter
                 (Bean.Get_Value (To_String (Property_Names (I))),
                  (if Mapping_Index > 0 then Mappings (Mapping_Index)
                   else Null_Mapping));
               J := J + 1;
            end if;
         end loop;
         Params (Params'Last) := To_Parameter (Key_Value, Null_Mapping);
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
         Mappings : Bean_Mappings;
         Key : Integer)
      is
         Primary_Key : String := Get_Primary_Key (Mappings);
         P : Prepared_Statement;
      begin
         if Primary_Key = "" then
            raise Persistence_Error with "Update requires primary key";
         end if;
         P := GNATCOLL.SQL.Exec.Prepare
             ("DELETE FROM " & Table_Name & " WHERE " & Primary_Key
              & " =" & DB.Parameter_String (1, ""),
              On_Server => True);
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
         Mappings : Bean_Mappings;
         Key : Integer)
         return Bean_Type
      is
         Primary_Key : String := Get_Primary_Key (Mappings);
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

      package Bean_Vectors is new Ada.Containers.Vectors
        (Index_Type => Positive,
         Element_Type => Bean_Type);

      package String_Vectors is new Ada.Containers.Indefinite_Vectors
        (Index_Type => Positive,
         Element_Type => String);
      use String_Vectors;

      type Bean_Access is access all Inspectable_Bean'Class;

      function Get_Deep
        (B : in out Readonly_Bean'Class;
         Name : String)
         return Object
      is
         Result : Object;
      begin
         if B in Composite_Bean'Class then
            Result := Composite_Bean'Class (B).Get_Child (Name);
            if Get_Type (Result) /= TYPE_NULL then
               return Result;
            end if;
         end if;
         return B.Get_Value (Name);
      end Get_Deep;

      function Is_Scalar (B : Readonly_Bean'Class;
                          Name : String)
                          return Boolean is
         Typ : constant Data_Type := Get_Type (B.Get_Value (Name));
      begin
         return Typ /= TYPE_NULL and then Typ /= TYPE_ARRAY and then Typ /= TYPE_BEAN;
      end Is_Scalar;

      function Scalar_Properties
        (B : Inspectable_Bean'Class)
         return String_Vectors.Vector
      is
         Root_Properties : constant Meadowsweet.String_Array := B.Property_Names;
         Result : String_Vectors.Vector;
      begin
         for I in Root_Properties'Range loop
            if Is_Scalar (B, To_String (Root_Properties (I))) then
               Result.Append (To_String (Root_Properties (I)));
            end if;
         end loop;
         return Result;
      end Scalar_Properties;

      function Scalar_Properties
        (B : in out Inspectable_Bean'Class;
         Q : Query)
         return String_Vectors.Vector
      is
         Result : String_Vectors.Vector;
         Joined : Util.Beans.Objects.Object;
         Joined_Bean : access Inspectable_Bean'Class;
      begin
         Result := Scalar_Properties (B);
         for I in Q.Joins.First_Index .. Q.Joins.Last_Index loop
            Joined := Get_Deep (B, To_String (Q.Joins (I)));
            Joined_Bean := Bean_Access (To_Bean (Joined));
            if Joined_Bean = null then
               raise Persistence_Error with "joined property "
                 & To_String (Q.Joins (I)) & " not found";
            end if;
            declare
               Names : constant String_Vectors.Vector
                 := Scalar_Properties (Joined_Bean.all);
            begin
               for J in 1 .. Length (Names) loop
                  if Is_Scalar (Joined_Bean.all, Names (Positive (J)))
                  then
                     declare
                        Name : constant String := To_String (Q.Joins (I)) & "."
                          & Names (Positive (J));
                     begin
                        Result.Append (Name);
                     end;
                  end if;
               end loop;
            end;
         end loop;
         return Result;
      end Scalar_Properties;

         --  function Property_Names
         --    (B : Bean_Type;
         --     Q : Query)
         --     return String_Vectors.Vector
         --  is
         --     Root_Property_Names : constant Meadowsweet.String_Array
         --       := B.Property_Names;
         --     Result : String_Vectors.Vector;
         --     Joined : Util.Beans.Objects.Object;
         --  begin
         --     for I in Root_Property_Names'Range loop
         --        Result.Append (To_String (Root_Property_Names (I)));
         --     end loop;
         --     for I in Q.Joins.First_Index .. Q.Joins.Last_Index loop
         --        Joined := Get_Deep (B, To_String (Q.Joins (I)));
         --        Result.Append (To_String (Joined));
         --     end loop;
         --     return Result;
         --  end Property_Names;

      function Get
        (Q : Query;
         Root_Table : String;
         Mappings : Bean_Mappings;
         Params : GNATCOLL.SQL.Exec.SQL_Parameters
         := GNATCOLL.SQL.Exec.No_Parameters)
         return Bean_Array
      is

         function Select_Columns (B : Inspectable_Bean'Class;
                                  Prefix : String;
                                  Column_Count : in out Natural)
                                  return Unbounded_String
         is
            Properties : constant String_Vectors.Vector := Scalar_Properties (B);
            Mapping_Index : Natural;
            SQL : Unbounded_String;
            First : Boolean := True;
         begin
            if not (B in Util.Beans.Basic.Bean'Class)
            then
               raise Meadowsweet.Persistence.Persistence_Error
               with "Bean_Type must be of type Util.Beans.Basic.Bean";
            end if;
            for P of Properties loop
               if First then
                  First := False;
               else
                  Append (SQL, ", ");
               end if;
               Append (SQL, Prefix);
               Mapping_Index := Find_Mapping (Mappings, P);
               if Mapping_Index = 0 then
                  Append (SQL, P);
               else
                  Append (SQL, Mappings (Mapping_Index).Column);
               end if;
               Column_Count := Column_Count + 1;
            end loop;
            return SQL;
         end Select_Columns;

         function To_SQL (B : Bean_Type'Class;
                          Column_Count : out Positive)
                          return String
         is
            SQL : Unbounded_String := To_Unbounded_String ("SELECT ");
            Mapping_Index : Natural;
            Column_Count_Total : Natural := 0;
         begin
            Append (SQL, Select_Columns (B, "T0.", Column_Count_Total));
            for I in Q.Joins.First_Index .. Q.Joins.Last_Index loop
               Append (SQL, ", ");
               Mapping_Index := Find_Mapping (Mappings,
                                              To_String (Q.Joins (I)));
               if Mapping_Index = 0
                 or else Mappings (Mapping_Index).Property_Type /= TYPE_BEAN
               then
                  raise Persistence_Error with To_String (Q.Joins (I))
                    & " is not mapped to a bean";
               end if;
               declare
                  Joined : constant access Inspectable_Bean'Class
                    := Mappings (Mapping_Index).Factory.all;
               begin
                  Append (SQL, Select_Columns (Joined.all,
                          "T" & Ada.Strings.Fixed.Trim (Mapping_Index'Image,
                            Ada.Strings.Left)
                          & '.',
                          Column_Count_Total));
               end;
            end loop;
            Append (SQL, " FROM ");
            Append (SQL, Root_Table);
            Append (SQL, " T0 ");
            for I in Q.Joins.First_Index .. Q.Joins.Last_Index loop
               Append (SQL, "JOIN ");
               Mapping_Index := Find_Mapping (Mappings,
                                              To_String (Q.Joins (I)));
               if Mapping_Index = 0
                 or else Mappings (Mapping_Index).Target_Table = ""
               then
                  raise Meadowsweet.Persistence.Persistence_Error
                  with To_String (Q.Joins (I)) & " is not mapped to any table";
               end if;
               Append (SQL, Mappings (Mapping_Index).Target_Table);
               Append (SQL, " T");
               Append (SQL, Ada.Strings.Fixed.Trim (Mapping_Index'Image,
                       Ada.Strings.Left));
               Append (SQL, " ON T0.");
               Append (SQL, Mappings (Mapping_Index).Column);
               Append (SQL, " = T");
               Append (SQL, Ada.Strings.Fixed.Trim (Mapping_Index'Image, Ada.Strings.Left));
               Append (SQL, ".");
               Append (SQL, Mappings (Mapping_Index).Target_Primary_Key);
            end loop;
            if not Q.Where.Ref.Is_Null then
               Append (SQL, " WHERE ");
               Append (SQL, Q.Where.Ref.Get.To_SQL (Mappings));
            end if;
            Ada.Text_IO.Put_Line ("SQL: " & To_String (SQL));
            Column_Count := Column_Count_Total;
            return To_String (SQL);
         end To_SQL;

         function To_Object (R : Forward_Cursor;
                             I : Positive;
                             Name : String)
                             return Object
         is
            Mapping_Index : constant Natural := Find_Mapping
              (Mappings, Name);
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

         procedure Set_Deep
           (B : in out Bean_Type'Class;
            Name : String;
            Obj : Object)
         is
            Pos : constant Natural := Index (Name, ".", Name'First);
            Parent : Object;
            Parent_Bean : Bean_Access;
         begin
            if Pos > 0 then
               Parent := Get_Deep (B, Name (Name'First .. Pos - 1));
               Parent_Bean := Bean_Access (To_Bean (Parent));
               Util.Beans.Basic.Bean'Class (Parent_Bean.all).Set_Value
                 (Name (Pos + 1 .. Name'Last), Obj);
            else
               Util.Beans.Basic.Bean'Class (B).Set_Value (Name, Obj);
            end if;
         end Set_Deep;

         procedure Set_Deep
           (B : in out Bean_Type'Class;
            Name : String;
            Value : Bean_Access)
         is
            Obj : constant Object := To_Object (Value, DYNAMIC);
         begin
            Set_Deep (B, Name, Obj);
         end Set_Deep;

         procedure Create_Children
           (B : in out Bean_Type'Class;
            Q : Query;
            Mappings : Bean_Mappings)
         is
            Mapping_Index : Natural;
         begin
            for I in Q.Joins.First_Index .. Q.Joins.Last_Index loop
               Mapping_Index := Find_Mapping (Mappings,
                                              To_String (Q.Joins (I)));
               declare
                  Joined : constant access Inspectable_Bean'Class
                    := Mappings (Mapping_Index).Factory.all;
               begin
                  Set_Deep (B, To_String (Q.Joins (I)), Bean_Access (Joined));
               end;
            end loop;
         end Create_Children;

         R : GNATCOLL.SQL.Exec.Forward_Cursor;
         Property_Names : String_Vectors.Vector;

         procedure Fetch (B : in out Bean_Type) is
         begin
            Create_Children (B, Q, Mappings);
            for I in 1 .. Length (Property_Names)
            loop
               Set_Deep (B, Property_Names (Positive (I)),
                         To_Object (R, Positive (I),
                           Property_Names (Positive (I))));
            end loop;
         end Fetch;

         B : Bean_Type;
         Column_Count : Positive;
         Beans : Bean_Vectors.Vector;
      begin
         --  Create children because Scalar_Properties and To_SQL accesses them
         Create_Children (B, Q, Mappings);
         Property_Names := Scalar_Properties (B, Q);
         declare
            SQL : constant String := To_SQL (B, Column_Count);
            P : constant Prepared_Statement :=
              GNATCOLL.SQL.Exec.Prepare (SQL, On_Server => True);
         begin
            R.Fetch (Q.DB, P, Params);
            if not Success (Q.DB) then
               raise Persistence_Error with Last_Error_Message (Q.DB);
            end if;
            while Has_Row (R) loop
               --  Insert bean, then modify to avoid copying the bean and its children
               Beans.Append (B);
               Bean_Vectors.Update_Element (Beans, Bean_Vectors.Last_Index (Beans),
                                            Fetch'Access);
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
         end;
      end Get;

   end Tables;

end Meadowsweet.Persistence;
