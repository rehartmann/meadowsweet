with Ada.Strings.Fixed;
with Util.Beans.Objects;

package body Meadowsweet is

   use Ada.Strings.Fixed;
   use GNAT.Regpat;

   Servlet_Name : constant String := "meadowsweet-dispatcher";

   procedure Initialize
     (Context : aliased in out Web_Context;
      Registry : aliased in out Servlet.Core.Servlet_Registry;
      WS : in out Servlet.Server.Container'Class;
      URI : String;
      Pattern : String)
   is
   begin
      Registry.Add_Servlet
        (Name => Servlet_Name, Server => Context.Dispatcher'Unchecked_Access);
      Registry.Add_Mapping (Name => Servlet_Name, Pattern => Pattern);

      WS.Register_Application (URI, Registry'Unchecked_Access);

      Context.Dispatcher.Context := Context'Unchecked_Access;
   end Initialize;

   procedure Get_Parameter_Names
     (Route_Path : String;
      Names : in out Name_Vectors.Vector)
   is
      Route_Path_Position : Natural := Route_Path'First;
      Param_Name_End : Natural;
   begin
      Names.Clear;
      loop
         Route_Path_Position := Index (Route_Path, "{", Route_Path_Position);
         if Route_Path_Position = 0 then
            return;
         end if;
         Param_Name_End := Index (Route_Path, "}", Route_Path_Position);
         if Param_Name_End = 0 then
            return;
         end if;
         Names.Append (To_Unbounded_String
                       (Route_Path
                          (Route_Path_Position + 1 .. Param_Name_End - 1)));
         Route_Path_Position := Param_Name_End;
      end loop;
   end Get_Parameter_Names;

   function To_Regexp (Path : String)
                       return String is
      I : Positive := Path'First;
      Parameter_Start, Parameter_End : Natural;
      Result : Unbounded_String;
   begin
      --  Replace each occurrence of {name}
      loop
         Parameter_Start := Index (Path, "{", I);
         if Parameter_Start = 0 then
            Append (Result, Path (I .. Path'Last));
            exit;
         end if;
         Parameter_End := Index (Path, "}", Parameter_Start);
         if Parameter_End = 0 then
            Append (Result, Path (Parameter_Start .. Path'Last));
            exit;
         end if;
         Append (Result, Path (I .. Parameter_Start - 1));
         Append (Result, "([^/]+)");
         I := Parameter_End + 1;
         if I > Path'Last then
            exit;
         end if;
      end loop;
      return To_String (Result);
   end To_Regexp;

   procedure Add_Route
     (Context : aliased in out Web_Context;
      Method : String;
      Path : String;
      Action : Action_Access)
   is
      Names : Name_Vectors.Vector;
      Matcher : Pattern_Matcher (Pattern_Size);
   begin
      Get_Parameter_Names (Path, Names);
      Compile (Matcher, '^' & To_Regexp (Path) & "/?$");
      Context.Routes.Append
        ((Method => To_Unbounded_String (Method),
          Path => To_Unbounded_String (Path),
          Matcher => Matcher,
          Parameter_Names => Names,
          Action => Action));
   end Add_Route;

   procedure Set_Path_Parameters
     (Request : in out Servlet.Requests.Request'Class;
      Path_Info : String;
      Names : Name_Vectors.Vector;
      Matches : Match_Array) is
   begin
      for I in 1 .. Matches'Last loop
         Request.Set_Attribute
           ("path-parameter." & To_String (Names (I)),
            Util.Beans.Objects.To_Object
              (Path_Info (Matches (I).First .. Matches (I).Last)));
      end loop;
   end Set_Path_Parameters;

   procedure Dispatch
     (Method : String;
      Dispatcher : Dispatcher_Servlet;
      Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class)
   is
      Path_Info : constant String := Request.Get_Path_Info;
      Parameter_Method : constant String := Request.Get_Parameter ("_method");
      Effective_Method : constant String :=
        (if Parameter_Method = "" then Method else Parameter_Method);
   begin
      for R of Dispatcher.Context.Routes loop
         if R.Method = Effective_Method then
            declare
               Matches : Match_Array (0 .. Natural (R.Parameter_Names.Length));
            begin
               GNAT.Regpat.Match (R.Matcher, Path_Info, Matches);
               if Matches (0) /= No_Match then
                  Set_Path_Parameters (Request, Path_Info,
                                       R.Parameter_Names, Matches);
                  R.Action (Request, Response);
                  return;
               end if;
            end;
         end if;
      end loop;
      Response.Send_Error (Servlet.Responses.SC_NOT_FOUND);
   end Dispatch;

   overriding procedure Do_Get
     (Server : Dispatcher_Servlet;
      Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class)
   is
   begin
      Dispatch ("GET", Server, Request, Response);
   end Do_Get;

   overriding procedure Do_Head
     (Server : Dispatcher_Servlet;
      Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class)
   is
   begin
      Dispatch ("HEAD", Server, Request, Response);
   end Do_Head;

   overriding procedure Do_Post
     (Server : Dispatcher_Servlet;
      Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class)
   is
   begin
      Dispatch ("POST", Server, Request, Response);
   end Do_Post;

   overriding procedure Do_Put
     (Server : Dispatcher_Servlet;
      Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class)
   is
   begin
      Dispatch ("PUT", Server, Request, Response);
   end Do_Put;

   overriding procedure Do_Delete
     (Server : Dispatcher_Servlet;
      Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class)
   is
   begin
      Dispatch ("DELETE", Server, Request, Response);
   end Do_Delete;

   overriding procedure Do_Patch
     (Server : Dispatcher_Servlet;
      Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class)
   is
   begin
      Dispatch ("PATCH", Server, Request, Response);
   end Do_Patch;

   function Get_Path_Parameter
     (Request : in out Servlet.Requests.Request'Class;
      Name : String)
      return String is
   begin
      return Util.Beans.Objects.To_String
        (Request.Get_Attribute ("path-parameter." & Name));
   end Get_Path_Parameter;

end Meadowsweet;
