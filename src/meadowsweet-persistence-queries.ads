package Meadowsweet.Persistence.Queries is

   function "+" (Value : String)
                 return Expression;

   function "+" (Value : Boolean)
                 return Expression;

   function "+" (Value : Integer)
                 return Expression;

   function "=" (Left : Expression;
                 Right : Expression)
                 return Expression;

   function "/=" (Left : Expression;
                  Right : Expression)
                  return Expression;

   function "<" (Left : Expression;
                 Right : Expression)
                 return Expression;

   function ">" (Left : Expression;
                 Right : Expression)
                 return Expression;

   function "<=" (Left : Expression;
                  Right : Expression)
                  return Expression;

   function ">=" (Left : Expression;
                  Right : Expression)
                  return Expression;

   function "and" (Left : Expression;
                   Right : Expression)
                   return Expression;

   function "or" (Left : Expression;
                  Right : Expression)
                  return Expression;

   function Like (Left : Expression;
                  Right : Expression)
                  return Expression;

   function Get_Value (Name : String)
                       return Expression;

   function Parameter (DB : GNATCOLL.SQL.Exec.Database_Connection;
                       Position : Positive)
                       return Expression;

   function To_SQL (Root_Table : String;
                    Distinct : Boolean;
                    Joins : String_Array;
                    Where : Expression;
                    Order : Order_Spec;
                    Mappings : Bean_Mappings;
                    B : in out Meadowsweet.Inspectable_Bean'Class;
                    Column_Count : out Positive)
                    return String;

end Meadowsweet.Persistence.Queries;
