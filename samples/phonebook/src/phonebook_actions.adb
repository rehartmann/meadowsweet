with Meadowsweet.Jintp;

package body Phonebook_Actions is

   use Util.Beans.Objects;

   Entries : Address_Entries;

   Renderer : Meadowsweet.Jintp.Jintp_Renderer;

   procedure Index
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class) is
      pragma Unreferenced (Request);
   begin
      Renderer.Render_Response ("views/index.html", Entries, Response);
   end Index;

   procedure New_Form
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class) is
      pragma Unreferenced (Request);
      New_Entry : Address_Entry;
   begin
      Renderer.Render_Response ("views/new.html", New_Entry, Response);
   end New_Form;

   function Get_Address (Request : Servlet.Requests.Request'Class)
                         return Address_Entry
   is
      Address : Address_Entry;
   begin
      Address.Given_Name := To_Unbounded_String
        (Request.Get_Parameter ("given_name"));
      Address.Family_Name := To_Unbounded_String
        (Request.Get_Parameter ("family_name"));
      Address.Phone_Number := To_Unbounded_String
        (Request.Get_Parameter ("phone_number"));
      Address.E_Mail_Address := To_Unbounded_String
        (Request.Get_Parameter ("e_mail_address"));
      return Address;
   end Get_Address;

   function Validate (Address : in out Address_Entry;
                      Ok : out Boolean)
                      return String is
   begin
      if Ada.Strings.Unbounded.Index (Address.E_Mail_Address, "@") = 0 then
         Ok := False;
         return "E-mail address is invalid.";
      end if;
      Ok := True;
      return "";
   end Validate;

   procedure Create
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class)
   is
      Address : aliased Address_Entry := Get_Address (Request);
      Ok : Boolean;
      Message : constant String := Validate (Address, Ok);
   begin
      if not Ok then
         declare
            Model : Meadowsweet.Dynamic_Bean;
         begin
            Model.Set_Value ("address", To_Object (Address'Access, STATIC));
            Model.Set_Value ("message", To_Object (Message));
            Renderer.Render_Response ("views/new.html", Model, Response);
            return;
         end;
      end if;
      Entries.Addresses.Append (Address);
      Response.Send_Redirect ("/phonebook/entries");
   end Create;

   procedure Edit
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class)
   is
      Address : aliased Address_Entry;
      Model : Meadowsweet.Dynamic_Bean;
      Id : constant Positive
        := Positive'Value (Meadowsweet.Get_Path_Parameter (Request, "id"));
      Empty_Message : constant String := "";
   begin
      Address := Entries.Addresses (Id);
      Address.Id := Id;
      Model.Set_Value ("address", To_Object (Address'Access, STATIC));
      Model.Set_Value ("message", To_Object (Empty_Message));
      Renderer.Render_Response ("views/edit.html", Model, Response);
   exception
      when Constraint_Error =>
         Response.Send_Error (Servlet.Responses.SC_NOT_FOUND);
   end Edit;

   procedure Show
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class)
   is
      Id : Positive;
      Address : Address_Entry;
   begin
      Id := Positive'Value (Meadowsweet.Get_Path_Parameter (Request, "id"));
      Address := Entries.Addresses (Id);
      Renderer.Render_Response ("views/show.html", Address, Response);
   exception
      when Constraint_Error =>
         Response.Send_Error (Servlet.Responses.SC_NOT_FOUND);
   end Show;

   procedure Update
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class)
   is
      Address : aliased Address_Entry := Get_Address (Request);
      Id : constant Positive
        := Positive'Value (Meadowsweet.Get_Path_Parameter (Request, "id"));
      Ok : Boolean;
      Message : constant String := Validate (Address, Ok);
   begin
      if not Ok then
         Address.Id := Id;
         declare
            Model : Meadowsweet.Dynamic_Bean;
         begin
            Model.Set_Value ("address", To_Object (Address'Access, STATIC));
            Model.Set_Value ("message", To_Object (Message));
            Renderer.Render_Response ("views/edit.html", Model, Response);
         end;
         return;
      end if;
      Entries.Addresses.Replace_Element (Id, Address);
      Response.Send_Redirect ("/phonebook/entries");
   exception
      when Constraint_Error =>
         Response.Send_Error (Servlet.Responses.SC_NOT_FOUND);
   end Update;

   procedure Delete
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class)
   is
      Id : Positive;
   begin
      Id := Positive'Value (Meadowsweet.Get_Path_Parameter (Request, "id"));
      Entries.Addresses.Delete (Id);
      Response.Send_Redirect ("/phonebook/entries");
   end Delete;

   overriding function Property_Names (This : Address_Entry)
                                       return Meadowsweet.String_Array is
   begin
      return (To_Unbounded_String ("given_name"),
              To_Unbounded_String ("family_name"),
              To_Unbounded_String ("phone_number"),
              To_Unbounded_String ("e_mail_address"),
              To_Unbounded_String ("id"));
   end Property_Names;

   overriding function Get_Value (From : Address_Entry;
                                  Name : String)
                                  return Object is
   begin
      if Name = "given_name" then
         return To_Object (From.Given_Name);
      end if;
      if Name = "family_name" then
         return To_Object (From.Family_Name);
      end if;
      if Name = "phone_number" then
         return To_Object (From.Phone_Number);
      end if;
      if Name = "given_name" then
         return To_Object (From.Given_Name);
      end if;
      if Name = "e_mail_address" then
         return To_Object (From.E_Mail_Address);
      end if;
      if Name = "id" then
         return To_Object (From.Id);
      end if;
      return Null_Object;
   end Get_Value;

   overriding function Property_Names (This : Address_Entries)
                                       return Meadowsweet.String_Array is
   begin
      return (1 => To_Unbounded_String ("entries"));
   end Property_Names;

   overriding function Get_Value (From : Address_Entries;
                                  Name : String)
                                  return Util.Beans.Objects.Object is
      AE : Address_Entry_Access;
   begin
      if Name = "entries" then
         declare
            Entry_Objects : Object_Array
              (1 .. Integer (From.Addresses.Length));
         begin
            for I in 1 .. Natural (From.Addresses.Length) loop
               AE := new Address_Entry;
               AE.Family_Name := From.Addresses (I).Family_Name;
               AE.Given_Name := From.Addresses (I).Given_Name;
               AE.Phone_Number := From.Addresses (I).Phone_Number;
               AE.E_Mail_Address := From.Addresses (I).E_Mail_Address;
               Entry_Objects (I) := To_Object (AE, DYNAMIC);
            end loop;
            return To_Object (Entry_Objects);
         end;
      end if;
      return Null_Object;
   end Get_Value;

end Phonebook_Actions;
