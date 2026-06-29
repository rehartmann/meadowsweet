with Ada.Strings.Unbounded;
with Meadowsweet;
with Servlet.Requests;
with Servlet.Responses;
with Util.Beans.Objects;
with Phonebook_DB;

package Phonebook_Actions is

   use Ada.Strings.Unbounded;
   use Phonebook_DB;

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
