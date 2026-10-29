with Ada.Containers;
with Ada.Containers.Vectors;
with Meadowsweet;
with Ada.Strings.Unbounded;
with Util.Beans.Basic;
with Util.Beans.Objects;

package Invoice_DB is

   use Ada.Strings.Unbounded;
   use Util.Beans.Objects;

   type Customer is new Util.Beans.Basic.Bean
     and Meadowsweet.Inspectable_Bean with record
      Id : Natural := 0;
      Name : Unbounded_String;
   end record;

   overriding function Property_Names (From : Customer)
                                       return Meadowsweet.String_Array;

   overriding function Get_Value (From : Customer;
                                  Name : String)
                                  return Util.Beans.Objects.Object;

   overriding procedure Set_Value (From : in out Customer;
                                   Name : String;
                                   Value : Util.Beans.Objects.Object);

   type Customer_Access is access all Customer;

   function Get (Id : Positive) return Customer;

   package Customer_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive,
      Element_Type => Customer);

   function Get_All return Customer_Vectors.Vector;

   procedure Insert (C : Customer'Class);

   procedure Delete_Customer (Id : Positive);

   type Invoice is new Meadowsweet.Composite_Bean
     and Meadowsweet.Inspectable_Bean with record
      Id : Natural := 0;
      Recipient : aliased Customer;
   end record;

   overriding function Property_Names (From : Invoice)
                                       return Meadowsweet.String_Array;

   overriding function Get_Value (From : Invoice;
                                  Name : String)
                                  return Util.Beans.Objects.Object;

   function Get_Bean (From : in out Invoice;
                                 Name : String)
                                 return access Meadowsweet.Inspectable_Bean'Class;

   overriding procedure Set_Value (From : in out Invoice;
                                   Name : String;
                                   Value : Util.Beans.Objects.Object);

   type Invoice_Access is access Invoice;

   procedure Get (Id : Positive; Target : in out Invoice);

   package Invoice_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive,
      Element_Type => Invoice);

   function Get_All return Invoice_Vectors.Vector;

   procedure Insert (Source : Invoice'Class);

   procedure Delete_Invoice (Id : Positive);

end Invoice_DB;
