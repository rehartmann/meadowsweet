with Servlet.Core;
with Servlet.Server;
with Servlet.Server.Web;
with Servlet.Core.Files;
with Meadowsweet;
with Phonebook_Actions;
with Util.Log.Loggers;

procedure Phonebook is
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

   Meadowsweet.Initialize (Context, App, WS, "/phonebook", "/*");

   Meadowsweet.Add_Route (Context, "GET", "/entries/new",
                  Phonebook_Actions.New_Form'Access);
   Meadowsweet.Add_Route (Context, "GET", "/entries",
                  Phonebook_Actions.Index'Access);
   Meadowsweet.Add_Route (Context, "POST", "/entries",
                  Phonebook_Actions.Create'Access);
   Meadowsweet.Add_Route (Context, "GET", "/entries/{id}/edit",
                  Phonebook_Actions.Edit'Access);
   Meadowsweet.Add_Route (Context, "GET", "/entries/{id}",
                  Phonebook_Actions.Show'Access);
   Meadowsweet.Add_Route (Context, "POST", "/entries/{id}",
                  Phonebook_Actions.Update'Access);
   Meadowsweet.Add_Route (Context, "DELETE", "/entries/{id}",
                  Phonebook_Actions.Delete'Access);

   WS.Start;
   delay 6000.0;
end Phonebook;
