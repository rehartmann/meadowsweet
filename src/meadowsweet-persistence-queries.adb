with Ada.Strings.Fixed;

package body Meadowsweet.Persistence.Queries is

   use Ada.Strings.Fixed;
   use Meadowsweet.Persistence.Expression_Pointers;

   type String_Constant is new Expression_Impl with record
      Value : Unbounded_String;
   end record;

   overriding function To_SQL (Self : String_Constant;
                               Mappings : Bean_Mappings)
                               return String is
   begin
      return To_String (Self.Value);
   end To_SQL;

   type String_Constant_Access is access String_Constant;

   type Boolean_Constant is new Expression_Impl with record
      Value : Boolean;
   end record;

   type Boolean_Constant_Access is access Boolean_Constant;

   overriding
   function To_SQL (Self : Boolean_Constant;
                    Mappings : Bean_Mappings)
                    return String is
   begin
      return Self.Value'Image;
   end To_SQL;

   type Integer_Constant is new Expression_Impl with record
      Value : Integer;
   end record;

   type Integer_Constant_Access is access Integer_Constant;

   overriding
   function To_SQL (Self : Integer_Constant;
                    Mappings : Bean_Mappings)
                    return String is
   begin
      return Self.Value'Image;
   end To_SQL;

   type Binary_Operator is new Expression_Impl with record
      Name : Unbounded_String;
      Left, Right : Expression;
   end record;

   overriding function Max_Parameter_No
     (Self : Binary_Operator)
      return Natural;

   overriding function To_SQL
     (Self : Binary_Operator;
      Mappings : Bean_Mappings)
      return String is
   begin
      return
        "("
        & Expression_Pointers.Get (Self.Left.Ref).To_SQL (Mappings)
        & ' '
        & To_String (Self.Name)
        & ' '
        & Expression_Pointers.Get (Self.Right.Ref).To_SQL (Mappings)
        & ")";
   end To_SQL;

   overriding function Max_Parameter_No
     (Self : Binary_Operator)
      return Natural
   is
      Max_Left : constant Natural := Self.Left.Ref.Get.Max_Parameter_No;
      Max_Right : constant Natural := Self.Right.Ref.Get.Max_Parameter_No;
   begin
      return (if Max_Left >= Max_Right then Max_Left else Max_Right);
   end Max_Parameter_No;

   type Binary_Operator_Access is access Binary_Operator;

   type Property_Value is new Expression_Impl with record
      Name : Unbounded_String;
   end record;

   overriding function To_SQL (Self : Property_Value;
                               Mappings : Bean_Mappings)
                               return String
   is
      Mapping_Index : Natural;
      Separator_Index : constant Natural
        := Index (Self.Name, ".", Ada.Strings.Backward);
      Column_Prefix : Unbounded_String;
      Last_Component : Unbounded_String;
   begin
      if Separator_Index > 0 then
         Mapping_Index := Find_Mapping
           (Mappings, To_String (Self.Name)(1 .. Separator_Index - 1));
         if Mapping_Index = 0 then
            raise Persistence_Error with To_String (Self.Name) & " is not mapped";
         end if;
         if Mappings (Mapping_Index).Property_Type /= TYPE_BEAN then
            raise Persistence_Error with To_String (Self.Name)(1 .. Separator_Index - 1)
              & " is not mapped to a bean";
         end if;
         Column_Prefix := To_Unbounded_String ("T" & Trim (Mapping_Index'Image,
                                               Ada.Strings.Left));
         Last_Component := Unbounded_Slice (Self.Name, Separator_Index + 1,
                                            Length (Self.Name));
      else
         Column_Prefix := To_Unbounded_String ("T0");
         Last_Component := Self.Name;
      end if;
      Mapping_Index := Find_Mapping
                 (Mappings, To_String (Last_Component));
      if Mapping_Index = 0 then
         return To_String (Column_Prefix) & '.' & To_String (Last_Component);
      end if;
      return To_String (Column_Prefix) & '.'
        & To_String (Mappings (Mapping_Index).Column);
   end To_SQL;

   type Property_Value_Access is access Property_Value;

   type Query_Parameter is new Expression_Impl with record
      Position : Positive;
      S : Unbounded_String;
   end record;

   type Query_Parameter_Access is access Query_Parameter;

   overriding function Max_Parameter_No
     (Self : Query_Parameter)
      return Natural;

   overriding function To_SQL (Self : Query_Parameter;
                               Mappings : Bean_Mappings)
                               return String is
   begin
      return To_String (Self.S);
   end To_SQL;

   overriding function Max_Parameter_No
     (Self : Query_Parameter)
      return Natural is
   begin
      return Self.Position;
   end Max_Parameter_No;

   function "+" (Value : String)
                 return Expression
   is
      Result : Expression;
      C : constant String_Constant_Access := new String_Constant'
        (Value => To_Unbounded_String ("'" & Value & "'"));
   begin
      Expression_Pointers.Set (Result.Ref, C.all);
      return Result;
   end "+";

   function "+" (Value : Boolean)
                 return Expression
   is
      Result : Expression;
      C : constant Boolean_Constant_Access := new Boolean_Constant'
        (Value => Value);
   begin
      Expression_Pointers.Set (Result.Ref, C.all);
      return Result;
   end "+";

   function "+" (Value : Integer)
                 return Expression
   is
      Result : Expression;
      C : constant Integer_Constant_Access := new Integer_Constant'
        (Value => Value);
   begin
      Expression_Pointers.Set (Result.Ref, C.all);
      return Result;
   end "+";

   function "=" (Left : Expression;
                 Right : Expression)
                 return Expression
   is
      Result : Expression;
      Exp : constant Binary_Operator_Access := new Binary_Operator'
        (Name => To_Unbounded_String ("="),
         Left => Left,
         Right => Right);
   begin
      Expression_Pointers.Set (Result.Ref, Exp.all);
      return Result;
   end "=";

   function "/=" (Left : Expression;
                  Right : Expression)
                  return Expression
   is
      Result : Expression;
      Exp : constant Binary_Operator_Access := new Binary_Operator'
        (Name => To_Unbounded_String ("<>"),
         Left => Left,
         Right => Right);
   begin
      Expression_Pointers.Set (Result.Ref, Exp.all);
      return Result;
   end "/=";

   function "<" (Left : Expression;
                  Right : Expression)
                  return Expression
   is
      Result : Expression;
      Exp : constant Binary_Operator_Access := new Binary_Operator'
        (Name => To_Unbounded_String ("<"),
         Left => Left,
         Right => Right);
   begin
      Expression_Pointers.Set (Result.Ref, Exp.all);
      return Result;
   end "<";

   function ">" (Left : Expression;
                  Right : Expression)
                  return Expression
   is
      Result : Expression;
      Exp : constant Binary_Operator_Access := new Binary_Operator'
        (Name => To_Unbounded_String (">"),
         Left => Left,
         Right => Right);
   begin
      Expression_Pointers.Set (Result.Ref, Exp.all);
      return Result;
   end ">";

   function "<=" (Left : Expression;
                  Right : Expression)
                  return Expression
   is
      Result : Expression;
      Exp : constant Binary_Operator_Access := new Binary_Operator'
        (Name => To_Unbounded_String ("<="),
         Left => Left,
         Right => Right);
   begin
      Expression_Pointers.Set (Result.Ref, Exp.all);
      return Result;
   end "<=";

   function ">=" (Left : Expression;
                  Right : Expression)
                  return Expression
   is
      Result : Expression;
      Exp : constant Binary_Operator_Access := new Binary_Operator'
        (Name => To_Unbounded_String (">="),
         Left => Left,
         Right => Right);
   begin
      Expression_Pointers.Set (Result.Ref, Exp.all);
      return Result;
   end ">=";

   function "and" (Left : Expression;
                 Right : Expression)
                 return Expression
   is
      Result : Expression;
      Exp : constant Binary_Operator_Access := new Binary_Operator'
        (Name => To_Unbounded_String ("and"),
         Left => Left,
         Right => Right);
   begin
      Expression_Pointers.Set (Result.Ref, Exp.all);
      return Result;
   end "and";

   function "or" (Left : Expression;
                 Right : Expression)
                 return Expression
   is
      Result : Expression;
      Exp : constant Binary_Operator_Access := new Binary_Operator'
        (Name => To_Unbounded_String ("or"),
         Left => Left,
         Right => Right);
   begin
      Expression_Pointers.Set (Result.Ref, Exp.all);
      return Result;
   end "or";

   function Like (Left : Expression;
                  Right : Expression)
                  return Expression
   is
      Result : Expression;
      Exp : constant Binary_Operator_Access := new Binary_Operator'
        (Name => To_Unbounded_String ("LIKE"),
         Left => Left,
         Right => Right);
   begin
      Expression_Pointers.Set (Result.Ref, Exp.all);
      return Result;
   end Like;

   function Get_Value (Name : String)
                       return Expression
   is
      Result : Expression;
      Exp : constant Property_Value_Access := new Property_Value'
        (Name => To_Unbounded_String (Name));
   begin
      Expression_Pointers.Set (Result.Ref, Exp.all);
      return Result;
   end Get_Value;

   function Parameter (DB : GNATCOLL.SQL.Exec.Database_Connection;
                       Position : Positive)
                       return Expression
   is
      Result : Expression;
      Exp : constant Query_Parameter_Access := new Query_Parameter'
        (Position => Position,
         S => To_Unbounded_String (DB.Parameter_String (Position, "")));
   begin
      Expression_Pointers.Set (Result.Ref, Exp.all);
      return Result;
   end Parameter;

   function Select_Columns (B : Inspectable_Bean'Class;
                            Mappings : Bean_Mappings;
                            Prefix : String;
                            Column_Count : in out Natural)
                            return Unbounded_String
   is
      Properties : constant String_Vectors.Vector
        := Meadowsweet.Persistence.Scalar_Properties (B);
      Mapping_Index : Natural;
      SQL : Unbounded_String;
      First : Boolean := True;
   begin
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

   function To_SQL (Order : Order_Spec;
                    Mappings : Bean_Mappings)
                    return String
   is
      Result : Unbounded_String := To_Unbounded_String ("ORDER BY ");
      Separator_Index : Natural;
      Mapping_Index : Natural;
   begin
      for I in Order'Range loop
         if I > Order'First then
            Append (Result, ", ");
         end if;
         Separator_Index := Index (Order (I).Name, ".", Ada.Strings.Backward);
         if Separator_Index = 0 then
            Append (Result, "T0");
         else
            Mapping_Index := Find_Mapping
              (Mappings, To_String (Order (I).Name) (1 .. Separator_Index - 1));
            if Mapping_Index = 0
              or else Mappings (Mapping_Index).Table = ""
            then
               raise Meadowsweet.Persistence.Persistence_Error
               with To_String (Order (I).Name) & " is not mapped to any table";
            end if;
            Append (Result, "T");
            Append (Result, Trim (Mapping_Index'Image, Ada.Strings.Both));
         end if;
         Append (Result, '.');
         Mapping_Index := Find_Mapping (Mappings, To_String (Order (I).Name));
         if Mapping_Index = 0
           or else Mappings (Mapping_Index).Target_Column = Null_Unbounded_String
         then
            if Separator_Index = 0 then
               Append (Result, Order (I).Name);
            else
               Append (Result, Slice (Order (I).Name,
                       Separator_Index + 1,
                       Length (Order (I).Name)));
            end if;
         else
            Append (Result, To_String (Mappings (Mapping_Index).Target_Column));
         end if;
         if Order (I).Direction = Desc then
            Append (Result, " DESC");
         end if;
      end loop;
      return To_String (Result);
   end To_SQL;

   function To_SQL (DB : GNATCOLL.SQL.Exec.Database_Connection;
                    Root_Table : String;
                    Distinct : Boolean;
                    Joins : String_Array;
                    Where : Expression;
                    Order : Order_Spec;
                    Limit : Integer;
                    Offset : Integer;
                    Mappings : Bean_Mappings;
                    B : in out Inspectable_Bean'Class;
                    Column_Count : out Positive)
                    return String
   is
      SQL : Unbounded_String := To_Unbounded_String ("SELECT ");
      Mapping_Index, Source_Mapping_Index : Natural;
      Separator_Index : Natural;
      Column_Count_Total : Natural := 0;
      Param_No : Natural;
      Target_Column : Unbounded_String;
   begin
      if Distinct then
         Append (SQL, "DISTINCT ");
      end if;
      Append (SQL, Select_Columns (B, Mappings, "T0.", Column_Count_Total));
      for I in Joins'Range loop
         Append (SQL, ", ");
         Mapping_Index := Find_Mapping (Mappings,
                                        To_String (Joins (I)));
         if Mapping_Index = 0
           or else Mappings (Mapping_Index).Property_Type /= TYPE_BEAN
         then
            raise Persistence_Error with To_String (Joins (I))
              & " is not mapped to a bean";
         end if;
         declare
            Joined_Bean : Inspectable_Bean_Access
              := Mappings (Mapping_Index).Factory.all;
         begin
            Append (SQL, Select_Columns (Joined_Bean.all, Mappings,
                    "T" & Ada.Strings.Fixed.Trim (Mapping_Index'Image,
                      Ada.Strings.Left)
                    & '.',
                    Column_Count_Total));
            Free_Inspectable_Bean (Joined_Bean);
         end;
      end loop;
      Append (SQL, " FROM ");
      Append (SQL, Root_Table);
      Append (SQL, " T0 ");
      for I in Joins'Range loop
         Mapping_Index := Find_Mapping (Mappings,
                                        To_String (Joins (I)));
         if Mapping_Index = 0
           or else Mappings (Mapping_Index).Table = ""
         then
            raise Meadowsweet.Persistence.Persistence_Error
            with To_String (Joins (I)) & " is not mapped to any table";
         end if;
         if Mappings (Mapping_Index).Column = Null_Unbounded_String
         then
            --  One-to-many relationship
            Append (SQL, "LEFT ");
         end if;
         Append (SQL, "JOIN ");
         Append (SQL, Mappings (Mapping_Index).Table);

         Append (SQL, " T");
         Append (SQL, Ada.Strings.Fixed.Trim (Mapping_Index'Image,
                 Ada.Strings.Left));
         Separator_Index := Index (Joins (I), ".", Ada.Strings.Backward);
         if Separator_Index = 0 then
            --  Join is unqualified, so parent is root table
            Append (SQL, " ON T0.");
            Source_Mapping_Index := 0;
         else
            --  Get parent table by stripping off last component and
            --  getting the mapping
            Source_Mapping_Index := Find_Mapping
              (Mappings,
               Slice (Joins (I), 1, Separator_Index - 1));
            if Source_Mapping_Index = 0
              or else Mappings (Source_Mapping_Index).Table = ""
            then
               raise Meadowsweet.Persistence.Persistence_Error
               with Slice (Joins (I), 1, Separator_Index - 1)
                 & " is not mapped to any table";
            end if;
            Append (SQL, "ON T");
            Append (SQL, Trim (Source_Mapping_Index'Image, Ada.Strings.Both));
            Append (SQL, '.');
         end if;
         if Mappings (Mapping_Index).Column = Null_Unbounded_String
         then
            Append (SQL, Get_Primary_Key (Mappings,
                    (if Separator_Index = 0 then ""
                     else Slice (Joins (I), 1, Separator_Index - 1))));
         else
            Append (SQL, Mappings (Mapping_Index).Column);
         end if;
         Append (SQL, " = T");
         Append (SQL, Ada.Strings.Fixed.Trim (Mapping_Index'Image,
                 Ada.Strings.Both));
         Append (SQL, '.');
         if Mappings (Mapping_Index).Target_Column /= Null_Unbounded_String
         then
            Target_Column := Mappings (Mapping_Index).Target_Column;
         else
            Target_Column := To_Unbounded_String
              (Get_Primary_Key_By_Table
                 (Mappings, To_String (Mappings (Mapping_Index).Table)));
            if Target_Column = Null_Unbounded_String then
               raise Meadowsweet.Persistence.Persistence_Error
               with "no valid mapping for join " & To_String (Joins (I));
            end if;
         end if;
         Append (SQL, Target_Column);
         Append (SQL, ' ');
      end loop;
      Column_Count := Column_Count_Total;
      if not Where.Ref.Is_Null then
         Append (SQL, " WHERE ");
         Append (SQL, Where.Ref.Get.To_SQL (Mappings));
      end if;
      if Order'Length > 0 then
         Append (SQL, ' ');
         Append (SQL, To_SQL (Order, Mappings));
      end if;
      Param_No := (if Where.Ref = Null_Ref then 0
                   else Where.Ref.Get.Max_Parameter_No);
      if Limit /= No_Limit then
         Param_No := Param_No + 1;
         Append (SQL, " LIMIT ");
         Append (SQL, DB.Parameter_String (Param_No, ""));
      end if;
      if Offset /= 0 then
         Param_No := Param_No + 1;
         Append (SQL, " OFFSET ");
         Append (SQL, DB.Parameter_String (Param_No, ""));
      end if;
      return To_String (SQL);
   end To_SQL;

end Meadowsweet.Persistence.Queries;
