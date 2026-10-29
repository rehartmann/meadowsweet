with Ada.Strings.Unbounded;
with Meadowsweet;
with Servlet.Requests;
with Servlet.Responses;
with Util.Beans.Objects;
with Invoice_DB;

package Invoice_Actions is

   use Ada.Strings.Unbounded;
   use Invoice_DB;

   type Customers is new Meadowsweet.Inspectable_Bean with record
      Customers : Customer_Vectors.Vector;
   end record;

   overriding function Property_Names (From : Customers)
                                       return Meadowsweet.String_Array;

   overriding function Get_Value (From : Customers;
                                  Name : String)
                                  return Util.Beans.Objects.Object;

   type Invoices is new Meadowsweet.Inspectable_Bean with record
      Invoices : Invoice_Vectors.Vector;
   end record;

   overriding function Property_Names (From : Invoices)
                                       return Meadowsweet.String_Array;

   overriding function Get_Value (From : Invoices;
                                  Name : String)
                                  return Util.Beans.Objects.Object;

   procedure Customers_Index
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class);

   procedure Customers_New_Form
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class);

   procedure Customers_Create
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class);

   procedure Customers_Show
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class);

   procedure Customers_Delete
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class);

   procedure Invoices_New_Form
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class);

   procedure Invoices_Index
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class);

   procedure Invoices_Create
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class);

   procedure Invoices_Show
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class);

   procedure Invoices_Delete
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class);

end Invoice_Actions;
