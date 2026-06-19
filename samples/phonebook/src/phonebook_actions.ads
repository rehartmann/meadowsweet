with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Meadowsweet;
with Servlet.Requests;
with Servlet.Responses;
with Util.Beans.Objects;

package Phonebook_Actions is

   use Ada.Strings.Unbounded;

   type Address_Entry is new Meadowsweet.Inspectable_Bean with record
      Given_Name : Unbounded_String;
      Family_Name : Unbounded_String;
      Phone_Number : Unbounded_String;
      E_Mail_Address : Unbounded_String;
      Id : Natural := 0;
      Message : Unbounded_String;
   end record;

   type Address_Entry_Access is access Address_Entry;

   overriding function Property_Names (This : Address_Entry)
                                       return Meadowsweet.String_Array;

   overriding function Get_Value (From : Address_Entry;
                                  Name : String)
                                  return Util.Beans.Objects.Object;

   package Address_Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive,
      Element_Type => Address_Entry);

   type Address_Entries is new Meadowsweet.Inspectable_Bean with record
      Addresses : Address_Entry_Vectors.Vector;
   end record;

   overriding function Property_Names (This : Address_Entries)
                                       return Meadowsweet.String_Array;

   overriding function Get_Value (From : Address_Entries;
                                  Name : String)
                                  return Util.Beans.Objects.Object;

   procedure Index
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class);

   procedure New_Form
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class);

   procedure Create
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class);

   procedure Edit
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class);

   procedure Show
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class);

   procedure Update
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class);

   procedure Delete
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class);

end Phonebook_Actions;
