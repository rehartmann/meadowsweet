with Ada.Containers;
with Ada.Containers.Vectors;
with Meadowsweet;
with Ada.Strings.Unbounded;
with Util.Beans.Objects;

package Phonebook_DB is

   use Ada.Strings.Unbounded;
   use Util.Beans.Objects;

   type Address_Entry is new Meadowsweet.Inspectable_Bean with record
      Id : Natural;
      Given_Name : Unbounded_String;
      Family_Name : Unbounded_String;
      Phone_Number : Unbounded_String;
      E_Mail_Address : Unbounded_String;
   end record;

   overriding function Property_Names (This : Address_Entry)
                                       return Meadowsweet.String_Array;

   overriding function Get_Value (From : Address_Entry;
                                  Name : String)
                                  return Util.Beans.Objects.Object;

   type Address_Entry_Access is access Address_Entry;

   function Get (Id : Positive) return Address_Entry;

   package Address_Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive,
      Element_Type => Address_Entry);

   function Get_All return Address_Entry_Vectors.Vector;

   procedure Insert (E : Address_Entry'Class);

   procedure Update (E : Address_Entry'Class);

   procedure Delete (Id : Positive);

   Database_Error : exception;

end Phonebook_DB;
