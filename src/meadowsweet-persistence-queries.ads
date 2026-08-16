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
      Table_Name : String;
      Condition : Expression := Null_Expression)
      return Query;

end Meadowsweet.Persistence.Queries;
