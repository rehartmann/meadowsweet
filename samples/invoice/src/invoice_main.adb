with Servlet.Core;
with Servlet.Server;
with Servlet.Server.Web;
with Servlet.Core.Files;
with Meadowsweet;
with Invoice_Actions;
with Util.Log.Loggers;

procedure Invoice_Main is
   App : aliased Servlet.Core.Servlet_Registry;
   Config : Servlet.Server.Configuration;
   WS : Servlet.Server.Web.AWS_Container;
   File_Server : aliased Servlet.Core.Files.File_Servlet;
   Context : aliased Meadowsweet.Web_Context;
begin
   Util.Log.Loggers.Initialize ("config.properties", "log4j.");

   WS.Configure (Config);

   App.Set_Init_Parameter (Servlet.Core.Files.VIEW_DIR_PARAM, "static");

   App.Add_Servlet
     (Name => "static", Server => File_Server'Unchecked_Access);
   App.Add_Mapping (Name => "static", Pattern => "*.css");

   Meadowsweet.Initialize (Context, App, WS, "/invoice", "/*");

   Meadowsweet.Add_Route (Context, "GET", "/customers/new",
                  Invoice_Actions.Customers_New_Form'Access);
   Meadowsweet.Add_Route (Context, "GET", "/customers",
                  Invoice_Actions.Customers_Index'Access);
   Meadowsweet.Add_Route (Context, "POST", "/customers",
                  Invoice_Actions.Customers_Create'Access);
   Meadowsweet.Add_Route (Context, "GET", "/customers/{id}",
                  Invoice_Actions.Customers_Show'Access);
   Meadowsweet.Add_Route (Context, "DELETE", "/customers/{id}",
                  Invoice_Actions.Customers_Delete'Access);

   Meadowsweet.Add_Route (Context, "GET", "/invoices/new",
                  Invoice_Actions.Invoices_New_Form'Access);
   Meadowsweet.Add_Route (Context, "GET", "/invoices",
                  Invoice_Actions.Invoices_Index'Access);
   Meadowsweet.Add_Route (Context, "POST", "/invoices",
                  Invoice_Actions.Invoices_Create'Access);
   Meadowsweet.Add_Route (Context, "GET", "/invoices/{id}",
                  Invoice_Actions.Invoices_Show'Access);
   Meadowsweet.Add_Route (Context, "DELETE", "/invoices/{id}",
                  Invoice_Actions.Invoices_Delete'Access);

   WS.Start;
   delay 6000.0;

end Invoice_Main;
