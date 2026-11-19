with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Strings.Hash;
with Util.Beans.Basic;
with Util.Beans.Objects;
with Util.Beans.Objects.Vectors;

package Meadowsweet.Beans is

   type Composite_Bean is abstract new Util.Beans.Basic.Bean
     and Meadowsweet.Inspectable_Bean
   with null record;

   overriding function Get_Value
     (From : Composite_Bean;
      Name : String)
      return Object is abstract;

   --  Returns a reference to a child bean instead of a copy
   function Get_Bean
     (From : in out Composite_Bean;
      Name : String)
      return Util.Beans.Basic.Readonly_Bean_Access is abstract;

   function Equals (Left, Right : in out Meadowsweet.Inspectable_Bean'Class)
                    return Boolean;

   --  Compares two objects, handling the case of composite bean objects
   function Equals (Left, Right : Object)
                    return Boolean;

   type Dynamic_Bean is new Inspectable_Bean
      and Util.Beans.Basic.Bean with private;

   overriding function Get_Value (From : Dynamic_Bean;
                                  Name : String)
                                  return Object;

   overriding
   function Property_Names (From : Dynamic_Bean)
                            return String_Array;

   overriding
   procedure Set_Value (This : in out Dynamic_Bean;
                        Name : String;
                        Value : Object);

   function Equal_Elements
     (Left, Right : Vectors.Vector_Bean)
      return Boolean;

   function Contains (Container : Vectors.Vector_Bean;
                      Value : Object)
                      return Boolean;

         --  Converts a vector bean to an array object.
   function To_Object (Source : Vectors.Vector_Bean)
                       return Object;

   function Get_Deep
     (B : in out Util.Beans.Basic.Readonly_Bean'Class;
      Name : String)
      return Object;

   function Get_Bean_Deep
     (B : in out Composite_Bean'Class;
      Name : String)
     return Util.Beans.Basic.Readonly_Bean_Access;

private

   package Bean_Maps is new Ada.Containers.Indefinite_Hashed_Maps
     (Key_Type        => String,
      Element_Type    => Object,
      Hash            => Ada.Strings.Hash,
      Equivalent_Keys => "=");

   type Dynamic_Bean is new Inspectable_Bean
     and Util.Beans.Basic.Bean
   with record
      Attributes : Bean_Maps.Map;
   end record;

end Meadowsweet.Beans;
