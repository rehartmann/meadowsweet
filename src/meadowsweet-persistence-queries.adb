package body Meadowsweet.Persistence.Queries is

   function Create_Query
     (DB : GNATCOLL.SQL.Exec.Database_Connection;
      Table_Name : String;
      Condition : Expression := Null_Expression)
      return Query
   is
      Q : constant Query := (DB => DB,
                             Table_Name => To_Unbounded_String (Table_Name),
                             Where => Condition);
   begin
      return Q;
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
      return Expression_Pointers.Get (Self.Left).To_SQL (Mappings)
        & To_String (Self.Name)
        & Expression_Pointers.Get (Self.Right).To_SQL (Mappings);
   end To_SQL;

   type Binary_Operator_Access is access Binary_Operator;

   type Property_Value is new Expression_Impl with record
      Name : Unbounded_String;
   end record;

   overriding function To_SQL (Self : Property_Value;
                               Mappings : Bean_Mappings)
                               return String
   is
      Mapping_Index : constant Natural := Find_Mapping
                 (Mappings, To_String (Self.Name));
   begin
      if Mapping_Index = 0 then
         return To_String (Self.Name);
      end if;
      return To_String (Mappings (Mapping_Index).Column);
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
      Ref : Expression;
      C : constant String_Constant_Access := new String_Constant'
        (Value => To_Unbounded_String ("'" & Value & "'"));
   begin
      Expression_Pointers.Set (Ref, C.all);
      return Ref;
   end "+";

   function "+" (Value : Boolean)
                 return Expression
   is
      Ref : Expression;
      C : constant Boolean_Constant_Access := new Boolean_Constant'
        (Value => Value);
   begin
      Expression_Pointers.Set (Ref, C.all);
      return Ref;
   end "+";

   function "=" (Left : Expression;
                 Right : Expression)
                 return Expression
   is
      Ref : Expression;
      Exp : constant Binary_Operator_Access := new Binary_Operator'
        (Name => To_Unbounded_String ("="),
         Left => Left,
         Right => Right);
   begin
      Expression_Pointers.Set (Ref, Exp.all);
      return Ref;
   end "=";

   function "/=" (Left : Expression;
                  Right : Expression)
                  return Expression
   is
      Ref : Expression;
      Exp : constant Binary_Operator_Access := new Binary_Operator'
        (Name => To_Unbounded_String ("<>"),
         Left => Left,
         Right => Right);
   begin
      Expression_Pointers.Set (Ref, Exp.all);
      return Ref;
   end "/=";

   function Get_Value (Name : String)
                       return Expression
   is
      Ref : Expression;
      Exp : constant Property_Value_Access := new Property_Value'
        (Name => To_Unbounded_String (Name));
   begin
      Expression_Pointers.Set (Ref, Exp.all);
      return Ref;
   end Get_Value;

   function Parameter (DB : GNATCOLL.SQL.Exec.Database_Connection;
                       Position : Positive)
                       return Expression
   is
      Ref : Expression;
      Exp : constant Query_Parameter_Access := new Query_Parameter'
        (S => To_Unbounded_String (DB.Parameter_String (Position, "")));
   begin
      Expression_Pointers.Set (Ref, Exp.all);
      return Ref;
   end Parameter;

end Meadowsweet.Persistence.Queries;
