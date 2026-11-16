with Ada.Strings.Fixed;

package body Meadowsweet is

   use Ada.Strings.Fixed;
   use Ada.Containers;
   use GNAT.Regpat;
   use Util.Beans.Objects.Vectors;

   Servlet_Name : constant String := "meadowsweet-dispatcher";

   function Contains (Container : Vector_Bean;
                      Value : Object)
                      return Boolean is
   begin
      for I in 1 .. Natural (Container.Length) loop
         if Equals (Container.Element (I), Value) then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   function Equal_Elements (Left, Right : Vector_Bean)
                            return Boolean
   is
   begin
      if Left.Length /= Right.Length then
         return False;
      end if;
      for I in 1 .. Natural (Right.Length) loop
         if not Contains (Left, Right (I)) then
            return False;
         end if;
      end loop;
      return True;
   end Equal_Elements;

   function Equals (Left, Right : Object)
                    return Boolean
   is
      Left_Type : constant Data_Type := Get_Type (Left);
      Right_Type : constant Data_Type := Get_Type (Right);
      Left_Bean, Right_Bean : access Util.Beans.Basic.Readonly_Bean'Class;
   begin
      if Left_Type /= Right_Type then
         return False;
      end if;
      if Left_Type = TYPE_BEAN then
         Left_Bean := To_Bean (Left);
         Right_Bean := To_Bean (Right);
         if Left_Bean = null or else Right_Bean = null then
            return Left_Bean = null and then Right_Bean = null;
         end if;
         if Left_Bean.all in Composite_Bean'Class
                 and then Right_Bean.all in Composite_Bean'Class
         then
            return Composite_Bean'Class (Left_Bean.all)
              = Composite_Bean'Class (Right_Bean.all);
         end if;
         if Left_Bean.all in Vector_Bean'Class
               and then Right_Bean.all in Vector_Bean'Class
         then
            return Equal_Elements (Vector_Bean (Left_Bean.all),
                                   Vector_Bean (Right_Bean.all));
         end if;
         return False;
      end if;
      return Left = Right;
   end Equals;

   function Equals (Left, Right : in out Inspectable_Bean'Class)
                    return Boolean
   is
      Names : constant String_Array := Left.Property_Names;
      Left_Child, Right_Child : access Util.Beans.Basic.Readonly_Bean'Class;
      Left_Object, Right_Object : Object;
   begin
      for I in Names'Range loop
         if Left in Composite_Bean'Class and then Right in Composite_Bean'Class
         then
            Left_Child := Composite_Bean'Class (Left).Get_Bean (To_String (Names (I)));
            Right_Child := Composite_Bean'Class (Right).Get_Bean (To_String (Names (I)));
         end if;
         if Left_Child /= null and then Right_Child /= null then
            if Left_Child.all in Composite_Bean'Class
              and then Right_Child.all in Composite_Bean'Class
            then
               if not Composite_Bean (Left_Child.all).Equals (Composite_Bean (Right_Child.all))
               then
                  return False;
               end if;
            elsif (Left_Child.all in Vector_Bean'Class)
              and then (Right_Child.all in Vector_Bean'Class)
            then
               if not Equal_Elements (Vector_Bean (Left_Child.all),
                                      Vector_Bean (Right_Child.all))
               then
                  return False;
               end if;
            else
               return False;
            end if;
         elsif Left_Child = null and then Right_Child = null then
            Left_Object := Left.Get_Value (To_String (Names (I)));
            Right_Object := Right.Get_Value (To_String (Names (I)));
            if not Equals (Left_Object, Right_Object) then
               return False;
            end if;
         else
            return False;
         end if;
      end loop;
      return True;
   end Equals;

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

   overriding function Get_Value (From : Dynamic_Bean;
                                  Name : String)
                                  return Util.Beans.Objects.Object
   is
   begin
      return From.Attributes (Name);
   end Get_Value;

   overriding
   function Property_Names (From : Dynamic_Bean)
                                       return String_Array
   is
      Names : String_Array (1 .. Integer (From.Attributes.Length));
      I : Natural := Names'First;
   begin
      for C in From.Attributes.Iterate loop
         Names (I) := To_Unbounded_String (Bean_Maps.Key (C));
         I := I + 1;
      end loop;
      return Names;
   end Property_Names;

   overriding
   procedure Set_Value (This : in out Dynamic_Bean;
                        Name : String;
                        Value : Util.Beans.Objects.Object)
   is
   begin
      This.Attributes.Include (Name, Value);
   end Set_Value;

   function To_Object (Source : Util.Beans.Objects.Vectors.Vector_Bean)
                       return Object
   is
      Objects : Object_Array (1 .. Integer (Source.Length));
   begin
      for I in Objects'Range loop
         Objects (I) := Source (I);
      end loop;
      return To_Object (Objects);
   end To_Object;

   function Get_Bean_Deep
     (B : in out Composite_Bean'Class;
      Name : String)
     return access Util.Beans.Basic.Readonly_Bean'Class
   is
      Bean_Ptr : access Util.Beans.Basic.Readonly_Bean'Class;
      Composite_Bean_Ptr : access Composite_Bean'Class := B'Access;
      Separator_Index : Natural;
      Remaining_Name : String := Name (Name'Range);
   begin
      loop
         Separator_Index := Index (Remaining_Name, ".");
         if Separator_Index = 0 then
            return Composite_Bean_Ptr.all.Get_Bean (Remaining_Name);
         end if;
         Bean_Ptr := Composite_Bean_Ptr.all.Get_Bean
           (Remaining_Name (Remaining_Name'First .. Separator_Index - 1));
         if Bean_Ptr = null then
            return null;
         end if;
         Remaining_Name := Remaining_Name (Separator_Index + 1 .. Remaining_Name'Last);
         if not (Bean_Ptr.all in Composite_Bean'Class) then
            return null;
         end if;
         Composite_Bean_Ptr := Composite_Bean'Class (Bean_Ptr.all)'Access;
      end loop;
   end Get_Bean_Deep;

   function Get_Deep
     (B : in out Util.Beans.Basic.Readonly_Bean'Class;
      Name : String)
      return Object
   is
      Bean_Ptr : access Util.Beans.Basic.Readonly_Bean'Class;
      Separator_Index : constant Natural := Index (Name, ".");
   begin
      if Separator_Index /= 0 then
         if not (B in Composite_Bean'Class) then
            return Null_Object;
         end if;
         Bean_Ptr := Get_Bean_Deep (Composite_Bean'Class (B),
                                    Name (Name'First .. Separator_Index - 1));
         return Bean_Ptr.Get_Value (Name (Separator_Index + 1 .. Name'Last));
      else
         return B.Get_Value (Name);
      end if;
   end Get_Deep;

end Meadowsweet;
