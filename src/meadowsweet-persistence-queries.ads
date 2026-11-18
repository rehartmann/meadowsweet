package Meadowsweet.Persistence.Queries is

   function "+" (Value : String)
                 return Expression;

   function "+" (Value : Boolean)
                 return Expression;

   function "=" (Left : Expression;
                 Right : Expression)
                 return Expression;

   function "/=" (Left : Expression;
                 Right : Expression)
                 return Expression;

   function Get_Value (Name : String)
                       return Expression;

   function Parameter (DB : GNATCOLL.SQL.Exec.Database_Connection;
                       Position : Positive)
                       return Expression;

   function Create_Query
     (DB : GNATCOLL.SQL.Exec.Database_Connection;
      Distinct : Boolean := False;
      Where : Expression := Null_Expression;
      Joins : String_Array := (1 .. 0 => <>))
      return Query;

   function To_SQL (Q : Query;
                    Root_Table : String;
                    Mappings : Bean_Mappings;
                    B : in out Meadowsweet.Inspectable_Bean'Class;
                    Column_Count : out Positive)
                    return String;

end Meadowsweet.Persistence.Queries;
