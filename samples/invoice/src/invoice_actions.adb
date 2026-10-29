with Meadowsweet.Jintp;

package body Invoice_Actions is

   use Util.Beans.Objects;

   Renderer : Meadowsweet.Jintp.Jintp_Renderer;

   procedure Customers_Index
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class) is
      pragma Unreferenced (Request);
      Entries : Customers;
   begin
      Entries.Customers := Invoice_DB.Get_All;
      Renderer.Render_Response ("views/customers-index.html", Entries, Response);
   end Customers_Index;

   procedure Customers_New_Form
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class) is
      pragma Unreferenced (Request);
      New_Entry : Customer;
   begin
      Renderer.Render_Response ("views/customers-new.html", New_Entry, Response);
   end Customers_New_Form;

   function Get_Customer (Request : Servlet.Requests.Request'Class)
                          return Customer
   is
      C : Customer;
   begin
      C.Name := To_Unbounded_String
        (Request.Get_Parameter ("name"));
      return C;
   end Get_Customer;

   procedure Customers_Create
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class)
   is
      Address : aliased constant Customer := Get_Customer (Request);
   begin
      Invoice_DB.Insert (Address);
      Response.Send_Redirect ("/invoice/customers");
   end Customers_Create;

   procedure Customers_Show
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class)
   is
      Id : Positive;
      C : Customer;
   begin
      Id := Positive'Value (Meadowsweet.Get_Path_Parameter (Request, "id"));
      C := Invoice_DB.Get (Id);
      Renderer.Render_Response ("views/customers-show.html", C, Response);
   exception
      when Constraint_Error =>
         Response.Send_Error (Servlet.Responses.SC_NOT_FOUND);
   end Customers_Show;

   procedure Customers_Delete
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class)
   is
      Id : Positive;
   begin
      Id := Positive'Value (Meadowsweet.Get_Path_Parameter (Request, "id"));
      Invoice_DB.Delete_Customer (Id);
      Response.Send_Redirect ("/invoice/customers");
   end Customers_Delete;

   overriding function Property_Names (From : Customers)
                                       return Meadowsweet.String_Array is
   begin
      return (1 => To_Unbounded_String ("customers"));
   end Property_Names;

   overriding function Get_Value (From : Customers;
                                  Name : String)
                                  return Util.Beans.Objects.Object is
      C : Customer_Access;
   begin
      if Name = "customers" then
         declare
            Customer_Objects : Object_Array
              (1 .. Integer (From.Customers.Length));
         begin
            for I in 1 .. Natural (From.Customers.Length) loop
               C := new Customer;
               C.all := From.Customers (I);
               Customer_Objects (I) := To_Object (C, DYNAMIC);
            end loop;
            return To_Object (Customer_Objects);
         end;
      end if;
      raise No_Value;
   end Get_Value;

   overriding function Property_Names (From : Invoices)
                                       return Meadowsweet.String_Array is
   begin
      return (1 => To_Unbounded_String ("invoices"));
   end Property_Names;

   overriding function Get_Value (From : Invoices;
                                  Name : String)
                                  return Util.Beans.Objects.Object is
      Invoice_Ptr : Invoice_Access;
   begin
      if Name = "invoices" then
         declare
            Invoice_Objects : Object_Array
              (1 .. Integer (From.Invoices.Length));
         begin
            for I in 1 .. Natural (From.Invoices.Length) loop
               Invoice_Ptr := new Invoice;
               Invoice_Ptr.all := From.Invoices (I);
               Invoice_Objects (I) := To_Object (Invoice_Ptr, DYNAMIC);
            end loop;
            return To_Object (Invoice_Objects);
         end;
      end if;
      raise No_Value;
   end Get_Value;

   procedure Invoices_New_Form
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class) is
      pragma Unreferenced (Request);
      New_Entry : Invoice;
   begin
      Renderer.Render_Response ("views/invoices-new.html", New_Entry, Response);
   end Invoices_New_Form;

   procedure Invoices_Index
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class) is
      pragma Unreferenced (Request);
      Entries : Invoices;
   begin
      Entries.Invoices := Invoice_DB.Get_All;
      Renderer.Render_Response ("views/invoices-index.html", Entries,
                                Response);
   end Invoices_Index;

   procedure Get_Invoice (Request : Servlet.Requests.Request'Class;
                          Target : in out Invoice) is
   begin
      Target.Recipient.Id := Natural'Value
        (Request.Get_Parameter ("customer-id"));
   end Get_Invoice;

   procedure Invoices_Create
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class)
   is
      Source : Invoice;
   begin
      Get_Invoice (Request, Source);
      Invoice_DB.Insert (Source);
      Response.Send_Redirect ("/invoice/invoices");
   end Invoices_Create;

   procedure Invoices_Show
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class)
   is
      Id : Positive;
      Inv : Invoice;
   begin
      Id := Positive'Value (Meadowsweet.Get_Path_Parameter (Request, "id"));
      Invoice_DB.Get (Id, Inv);
      Renderer.Render_Response ("views/invoices-show.html", Inv, Response);
   exception
      when Constraint_Error =>
         Response.Send_Error (Servlet.Responses.SC_NOT_FOUND);
   end Invoices_Show;

   procedure Invoices_Delete
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class)
   is
      Id : Positive;
   begin
      Id := Positive'Value (Meadowsweet.Get_Path_Parameter (Request, "id"));
      Invoice_DB.Delete_Invoice (Id);
      Response.Send_Redirect ("/invoice/invoices");
   end Invoices_Delete;

end Invoice_Actions;
