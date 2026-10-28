with Ada.Strings.Fixed;

package body Meadowsweet.Persistence.Queries is

   use Ada.Strings.Fixed;

   function Create_Query
     (DB : GNATCOLL.SQL.Exec.Database_Connection;
      Where : Expression := Null_Expression;
      Joins : String_Array := (1 .. 0 => <>))
      return Query
   is
      Join_Vector : Name_Vectors.Vector;
   begin
      for I in Joins'Range loop
         Join_Vector.Append (Joins (I));
      end loop;
      return (DB => DB,
              Joins => Join_Vector,
              Where => Where);
   end Create_Query;

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

   overriding function To_SQL (Self : Boolean_Constant;
                               Mappings : Bean_Mappings)
                    return String is
   begin
      return Self.Value'Image;
   end To_SQL;

   type Binary_Operator is new Expression_Impl with record
      Name : Unbounded_String;
      Left, Right : Expression;
   end record;

   overriding function To_SQL (Self : Binary_Operator;
                               Mappings : Bean_Mappings)
                   return String is

   begin
      return Expression_Pointers.Get (Self.Left.Ref).To_SQL (Mappings)
        & To_String (Self.Name)
        & Expression_Pointers.Get (Self.Right.Ref).To_SQL (Mappings);
   end To_SQL;

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
      S : Unbounded_String;
   end record;

   type Query_Parameter_Access is access Query_Parameter;

   overriding function To_SQL (Self : Query_Parameter;
                               Mappings : Bean_Mappings)
                               return String is
   begin
      return To_String (Self.S);
   end To_SQL;

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

   function "=" (Left : Expression;
                 Right : Expression)
                 return Expression
   is
      Result : Expression;
      Exp : constant Binary_Operator_Access := new Binary_Operator'
        (Name => To_Unbounded_String (" = "),
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
        (S => To_Unbounded_String (DB.Parameter_String (Position, "")));
   begin
      Expression_Pointers.Set (Result.Ref, Exp.all);
      return Result;
   end Parameter;

end Meadowsweet.Persistence.Queries;
