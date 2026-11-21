with Ada.Containers;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Text_IO;
with Util.Beans.Objects.Vectors;
with Meadowsweet.Persistence.Queries;
with Meadowsweet.Beans;

package body Meadowsweet.Persistence is

   use GNATCOLL.SQL;
   use GNATCOLL.SQL.Exec;
   use Ada.Strings.Fixed;
   use Ada.Containers;
   use Util.Beans.Basic;
   use Util.Beans.Objects.Vectors;
   use Meadowsweet.Beans;

   Null_Mapping : constant Bean_Mapping :=
     (Property_Name => Null_Unbounded_String,
      Property_Type => TYPE_NULL,
      Column => Null_Unbounded_String,
      Is_Primary_Key => False,
      Is_Auto_Generated => False,
      Target_Table => Null_Unbounded_String,
      Factory => null,
      Target_Primary_Key => Null_Unbounded_String,
      Target_Column => Null_Unbounded_String);

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
      return (Property_Name => To_Unbounded_String (Property_Name),
              Property_Type => Property_Type,
              Column => To_Unbounded_String (Column),
              Is_Primary_Key => Is_Primary_Key,
              Is_Auto_Generated => Is_Auto_Generated,
              Target_Table => To_Unbounded_String (Target_Table),
              Factory => Factory,
              Target_Primary_Key => To_Unbounded_String (Target_Primary_Key),
              Target_Column => Null_Unbounded_String);
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
              Target_Primary_Key => Null_Unbounded_String,
              Target_Column => Null_Unbounded_String);
   end Primary_Key_Mapping;

   function To_Many_Mapping
     (Property_Name : String;
      Target_Table : String;
      Target_Column : String;
      Factory : Bean_Factory)
     return Bean_Mapping is
   begin
      return (Property_Name => To_Unbounded_String (Property_Name),
              Property_Type => TYPE_BEAN,
              Column => Null_Unbounded_String,
              Is_Primary_Key => False,
              Is_Auto_Generated => False,
              Target_Table => To_Unbounded_String (Target_Table),
              Factory => Factory,
              Target_Primary_Key => Null_Unbounded_String,
              Target_Column => To_Unbounded_String (Target_Column));
   end To_Many_Mapping;

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

   function Is_Scalar (B : Util.Beans.Basic.Readonly_Bean'Class;
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
      Joins : String_Array;
      Mappings : Bean_Mappings)
      return String_Vectors.Vector
   is
      Result : String_Vectors.Vector;
      Joined : Util.Beans.Objects.Object;
      Joined_Bean : Inspectable_Bean_Access;
      Mapping_Index : Natural;
      Bean_Allocated : Boolean := False;
   begin
      Result := Scalar_Properties (B);
      for I in Joins'Range loop
         Joined := Meadowsweet.Beans.Get_Deep (B, To_String (Joins (I)));
         Joined_Bean := Inspectable_Bean_Access (To_Bean (Joined));
         if Joined_Bean = null then
            --  Bean is not there, try to create one using the factory
            --  in the mappings
            Mapping_Index := Find_Mapping (Mappings, To_String (Joins (I)));
            if Mapping_Index = 0 then
               raise Persistence_Error
                 with "joined property " & To_String (Joins (I))
                 & " is not mapped";
            end if;
            if Mappings (Mapping_Index).Factory = null then
               raise Persistence_Error
                 with "cannot determine properties of joined property "
                 & To_String (Joins (I)) & ", no factory";
            end if;
            Joined_Bean := Mappings (Mapping_Index).Factory.all;
            Bean_Allocated := True;
         end if;
         declare
            Names : constant String_Vectors.Vector
              := Scalar_Properties (Joined_Bean.all);
         begin
            for J in 1 .. String_Vectors.Length (Names) loop
               if Is_Scalar (Joined_Bean.all, Names (Positive (J)))
               then
                  declare
                     Name : constant String := To_String (Joins (I)) & "."
                       & Names (Positive (J));
                  begin
                     Result.Append (Name);
                  end;
               end if;
            end loop;
         end;
      end loop;
      if Bean_Allocated then
         Free_Inspectable_Bean (Joined_Bean);
      end if;
      return Result;
   end Scalar_Properties;

   function Is_Mergeable
     (Left : in out Inspectable_Bean'Class;
      Right : in out Inspectable_Bean'Class)
      return Boolean
   is
      Names : constant Meadowsweet.String_Array := Left.Property_Names;
      Left_Child, Right_Child : Readonly_Bean_Access;
      Left_Object, Right_Object : Object;
      Children_Differ : Boolean := False;
   begin
      if not (Left in Composite_Bean'Class
              and then Right in Composite_Bean'Class)
      then
         return False;
      end if;
      for I in Names'Range loop
         Left_Child := Composite_Bean'Class (Left).Get_Bean (To_String (Names (I)));
         Right_Child := Composite_Bean'Class (Right).Get_Bean (To_String (Names (I)));
         if Left_Child /= null and then Right_Child /= null then
            if Left_Child.all in Inspectable_Bean'Class
              and then Right_Child.all in Inspectable_Bean'Class
            then
               if not Equals (Inspectable_Bean'Class (Left_Child.all),
                              Inspectable_Bean'Class (Right_Child.all))
               then
                  return False;
               end if;
            elsif Left_Child.all in Vector_Bean'Class
              and then Right_Child.all in Vector_Bean'Class
            then
               if not Equal_Elements (Vector_Bean (Left_Child.all),
                                      Vector_Bean (Right_Child.all))
               then
                  Children_Differ := True;
               end if;
            else
               return False;
            end if;
         elsif Left_Child = null and then Right_Child = null then
            Left_Object := Left.Get_Value (To_String (Names (I)));
            Right_Object := Right.Get_Value (To_String (Names (I)));
            if Left_Object /= Right_Object then
               return False;
            end if;
         else
            return False;
         end if;
      end loop;
      return Children_Differ;
   end Is_Mergeable;

   procedure Do_Merge
     (Target : in out Composite_Bean'Class;
      Source : in out Composite_Bean'Class);

   procedure Merge (Target : in out Vector_Bean;
                    Source_Value : Object)
   is
      Source_Bean, Target_Bean : Util.Beans.Basic.Readonly_Bean_Access;
   begin
      for Target_Value of Target loop
         if Get_Type (Source_Value) = TYPE_BEAN
           and then Get_Type (Target_Value) = TYPE_BEAN
         then
            Source_Bean := To_Bean (Source_Value);
            Target_Bean := To_Bean (Target_Value);
            if Source_Bean /= null
              and then Source_Bean.all in Composite_Bean'Class
              and then Target_Bean /= null
              and then Target_Bean.all in Composite_Bean'Class
            then
               if Is_Mergeable (Composite_Bean'Class (Target_Bean.all),
                                Composite_Bean'Class (Source_Bean.all))
               then
                  Do_Merge (Composite_Bean'Class (Target_Bean.all),
                            Composite_Bean'Class (Source_Bean.all));
                  return;
               end if;
            end if;
         end if;
      end loop;
      Target.Append (Source_Value);
   end Merge;

   procedure Merge
     (Target : in out Vector_Bean;
      Source : Vector_Bean) is
   begin
      for Value of Source loop
         if not Meadowsweet.Beans.Contains (Target, Value) then
            Merge (Target, Value);
         end if;
      end loop;
   end Merge;

   procedure Do_Merge
     (Target : in out Composite_Bean'Class;
      Source : in out Composite_Bean'Class)
   is
      Names : constant Meadowsweet.String_Array := Target.Property_Names;
      Target_Child, Source_Child : Readonly_Bean_Access;
   begin
      for I in Names'Range loop
         Target_Child := Target.Get_Bean (To_String (Names (I)));
         Source_Child := Source.Get_Bean (To_String (Names (I)));
         if Target_Child /= null and then Source_Child /= null
         then
            if Target_Child.all in Vector_Bean'Class
              and then Source_Child.all in Vector_Bean'Class
            then
               Merge (Vector_Bean (Target_Child.all),
                      Vector_Bean (Source_Child.all));
            elsif Target_Child.all in Composite_Bean'Class
              and then Source_Child.all in Composite_Bean'Class
            then
               Do_Merge (Composite_Bean'Class (Target_Child.all),
                        Composite_Bean'Class (Source_Child.all));
            end if;
         end if;
      end loop;
   end Do_Merge;

   procedure Merge
     (Target : in out Inspectable_Bean'Class;
      Source : in out Inspectable_Bean'Class) is
   begin
      Do_Merge (Composite_Bean'Class (Target), Composite_Bean'Class (Source));
   end Merge;

   procedure Insert
     (DB : Database_Connection;
      Table_Name : String;
      Mappings : Bean_Mappings;
      Bean : Meadowsweet.Inspectable_Bean'Class)
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
           or else (not Mappings (Mapping_Index).Is_Primary_Key
                    and then Mappings (Mapping_Index).Column /= Null_Unbounded_String)
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
         Value : Object;
      begin
         for I in Property_Names'Range loop
            Mapping_Index := Find_Mapping (Mappings,
                                           To_String (Property_Names (I)));
            if Mapping_Index = 0
              or else (not Mappings (Mapping_Index).Is_Primary_Key
                       and then Mappings (Mapping_Index).Column /= Null_Unbounded_String)
            then
               if Get_Type (Value) /= TYPE_ARRAY then
                  Params (J) := To_Parameter
                    (Bean.Get_Value (To_String (Property_Names (I))),
                     (if Mapping_Index > 0 then Mappings (Mapping_Index)
                      else Null_Mapping));
                  J := J + 1;
               end if;
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
      Mappings : Bean_Mappings;
      Bean : Meadowsweet.Inspectable_Bean'Class)
   is
      Property_Names : constant Meadowsweet.String_Array := Bean.Property_Names;
      Q : Unbounded_String := To_Unbounded_String ("UPDATE ")
        & Table_Name & " SET ";
      Params : SQL_Parameters (1 .. Property_Names'Length);
      J : Positive;
      Key_Value : Object;
      Primary_Key : constant String := Get_Primary_Key (Mappings);
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
      Primary_Key : constant String := Get_Primary_Key (Mappings);
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

   package body Tables is

      procedure Insert
        (DB : Database_Connection;
         Table_Name : String;
         Mappings : Bean_Mappings;
         Bean : Bean_Type'Class) is
      begin
         Meadowsweet.Persistence.Insert (DB, Table_Name, Mappings, Bean);
      end Insert;

      procedure Update
        (DB : Database_Connection;
         Table_Name : String;
         Mappings : Bean_Mappings;
         Bean : Bean_Type'Class) is
      begin
         Meadowsweet.Persistence.Update (DB, Table_Name, Mappings, Bean);
      end Update;

      procedure Delete
        (DB : GNATCOLL.SQL.Exec.Database_Connection;
         Table_Name : String;
         Mappings : Bean_Mappings;
         Key : Integer) is
      begin
         Meadowsweet.Persistence.Delete (DB, Table_Name, Mappings, Key);
      end Delete;

      function Get
        (DB : Database_Connection;
         SQL : String;
         Params : SQL_Parameters := No_Parameters;
         From_Cursor : not null access function
           (R : GNATCOLL.SQL.Exec.Forward_Cursor'Class)
           return Bean_Type)
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
         Key : Integer;
         From_Cursor : not null access function
           (R : GNATCOLL.SQL.Exec.Forward_Cursor'Class)
           return Bean_Type)
         return Bean_Type
      is
         Primary_Key : constant String := Get_Primary_Key (Mappings);
      begin
         return Get (DB, "SELECT * FROM " & Table_Name & " WHERE "
                          & Primary_Key & " =" & DB.Parameter_String (1, ""),
                     (1 => +Key),
                     From_Cursor);
      end Get;

      function Get
        (DB : Database_Connection;
         SQL : String;
         Params : SQL_Parameters := No_Parameters;
         From_Cursor : not null access function
           (R : GNATCOLL.SQL.Exec.Forward_Cursor'Class)
           return Bean_Type)
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
         From_Cursor : not null access function
           (R : GNATCOLL.SQL.Exec.Forward_Cursor'Class)
           return Bean_Type;
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
               Append (Q, Order (I).Name);
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
            return Get (DB, To_String (Q), Params, From_Cursor);
         end;
      end Get_From_Table;

      package Bean_Vectors is new Ada.Containers.Vectors
         (Index_Type => Positive,
          Element_Type => Bean_Type);

      function Get
        (DB : GNATCOLL.SQL.Exec.Database_Connection;
         Root_Table : String;
         Distinct : Boolean := False;
         Where : Expression := Null_Expression;
         Joins : String_Array := (1 .. 0 => <>);
         Order : Order_Spec := No_Order;
         Mappings : Bean_Mappings;
         Params : GNATCOLL.SQL.Exec.SQL_Parameters
         := GNATCOLL.SQL.Exec.No_Parameters)
         return Bean_Array
      is
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
            if GNATCOLL.SQL.Exec.Is_Null
              (R, Field_Index'First + Field_Index (I - 1))
            then
               return Null_Object;
            end if;
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

         procedure Set_To_Vector_Bean
           (Target : in out Vector_Bean'Class;
            Bean_Name : String;
            Property_Name : String;
            Value : Object)
         is
            Bean_Ptr : access Inspectable_Bean'Class;
            Mapping_Index : Natural;
         begin
            if Target.Is_Empty
              and then not Is_Null (Value)
            then
               Mapping_Index := Find_Mapping (Mappings, Bean_Name);
               if Mapping_Index = 0
                 or else Mappings (Mapping_Index).Factory = null
               then
                  raise Persistence_Error
                    with "no factory found for the elements of "
                    & Bean_Name;
               end if;
               Bean_Ptr := Mappings (Mapping_Index).Factory.all;
               Target.Append (To_Object (Bean_Ptr, DYNAMIC));
            end if;
            if not Target.Is_Empty then
               Bean'Class (To_Bean (Target.First_Element).all).Set_Value
                 (Property_Name, Value);
            end if;
         end Set_To_Vector_Bean;

         procedure Set_Deep
           (B : in out Bean'Class;
            Name : String;
            Value : Object)
         is
            Bean_Ptr : access Readonly_Bean'Class;
            Separator_Index : constant Natural
              := Index (Name, ".", Ada.Strings.Backward);
         begin
            if Separator_Index /= 0 then
               if not (B in Composite_Bean'Class) then
                  raise No_Value with "not a composite bean";
               end if;
               Bean_Ptr := Get_Bean_Deep
                 (Composite_Bean'Class (B),
                  Name (Name'First .. Separator_Index - 1));
               if Bean_Ptr.all in Vector_Bean'Class then
                  declare
                     Vector_Bean_Ptr : constant Vector_Bean_Access
                       := Vector_Bean_Access (Bean_Ptr);
                  begin
                     Set_To_Vector_Bean
                       (Vector_Bean_Ptr.all,
                        Name (Name'First .. Separator_Index - 1),
                        Name (Separator_Index + 1 .. Name'Last),
                        Value);
                  end;
               else
                  if not (Bean_Ptr.all in Bean'Class) then
                     raise No_Value with "not a bean";
                  end if;
                  Bean'Class (Bean_Ptr.all).Set_Value
                    (Name (Separator_Index + 1 .. Name'Last), Value);
               end if;
            else
               B.Set_Value (Name, Value);
            end if;
         end Set_Deep;

         procedure Set_Deep
           (B : in out Bean'Class;
            Name : String;
            Value : Inspectable_Bean_Access)
         is
            Obj : constant Object := To_Object (Value, DYNAMIC);
         begin
            Set_Deep (B, Name, Obj);
         end Set_Deep;

         procedure Create_Children
           (B : in out Bean_Type'Class;
            Joins : String_Array;
            Mappings : Bean_Mappings)
         is
            Mapping_Index : Natural;
         begin
            for I in Joins'Range loop
               Mapping_Index := Find_Mapping (Mappings,
                                              To_String (Joins (I)));
               if Mappings (Mapping_Index).Target_Column = Null_Unbounded_String
               then
                  declare
                     Joined : constant access Inspectable_Bean'Class
                       := Mappings (Mapping_Index).Factory.all;
                  begin
                     if not (B in Bean'Class) then
                        raise Persistence_Error
                          with "Bean does not implement Util.Beans.Basic.Bean";
                     end if;
                     Set_Deep (Util.Beans.Basic.Bean'Class (B),
                               To_String (Joins (I)),
                               Inspectable_Bean_Access (Joined));
                  end;
               end if;
            end loop;
         end Create_Children;

         R : GNATCOLL.SQL.Exec.Forward_Cursor;
         Property_Names : String_Vectors.Vector;

         procedure Get_Row (B : in out Bean_Type) is
         begin
            Create_Children (B, Joins, Mappings);
            for I in 1 .. String_Vectors.Length (Property_Names) loop
               Set_Deep (Util.Beans.Basic.Bean'Class (Bean_Type'Class (B)),
                         Property_Names (Positive (I)),
                         To_Object (R, Positive (I),
                           Property_Names (Positive (I))));
            end loop;
         end Get_Row;

         B : Bean_Type;
         Column_Count : Positive;
         Beans : Bean_Vectors.Vector;
      begin
         --  Create children because Scalar_Properties and To_SQL accesses them
         Create_Children (B, Joins, Mappings);
         Property_Names := Scalar_Properties (B, Joins, Mappings);
         declare
            SQL : constant String := Meadowsweet.Persistence.Queries.To_SQL
              (Root_Table, Distinct, Joins, Where, Order, Mappings, B, Column_Count);
            P : constant Prepared_Statement :=
              GNATCOLL.SQL.Exec.Prepare (SQL, On_Server => True);
         begin
            Ada.Text_IO.Put_Line ("SQL: " & SQL);
            R.Fetch (DB, P, Params);
            if not Success (DB) then
               raise Persistence_Error with Last_Error_Message (DB);
            end if;
            while Has_Row (R) loop
               --  Insert bean, then modify to avoid copying the bean and its children
               Beans.Append (B);
               Bean_Vectors.Update_Element (Beans, Bean_Vectors.Last_Index (Beans),
                                            Get_Row'Access);
               --  Try to merge the bean with the previous bean
               if Beans.Length >= 2
                 and then Is_Mergeable
                     (Beans (Positive (Beans.Length) - 1),
                      Beans (Positive (Beans.Length)))
               then
                  Merge (Beans.Reference (Positive (Beans.Length) - 1),
                         Beans.Reference (Positive (Beans.Length)));
                  Beans.Delete_Last;
               end if;
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

   function Get_Primary_Key (Mappings : Bean_Mappings;
                             Bean_Name : String := "")
                             return String is
   begin
      for I in Mappings'Range loop
         if Mappings (I).Is_Primary_Key
           and then Length (Mappings (I).Property_Name) > Bean_Name'Length
           and then Slice (Mappings (I).Property_Name, 1, Bean_Name'Length)
             = Bean_Name
         then
            declare
               Last_Part : constant String := Slice
                 (Mappings (I).Property_Name,
                  Bean_Name'Length + 1,
                  Length (Mappings (I).Property_Name));
            begin
               if Index (Last_Part, ".") = 0 then
                  return Last_Part;
               end if;
            end;
         end if;
      end loop;
      return "";
   end Get_Primary_Key;

end Meadowsweet.Persistence;
