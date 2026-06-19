with Ada.Containers;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Servlet.Core;
with Servlet.Server;
with Servlet.Requests;
with Servlet.Responses;
with Util.Beans.Basic;
with GNAT.Regpat;

package Meadowsweet is

   use Ada.Strings.Unbounded;

   type Web_Context is limited private;

   type String_Array is array (Positive range <>) of Unbounded_String;

   type Inspectable_Bean is abstract new Util.Beans.Basic.Readonly_Bean
   with null record;

   function Property_Names (This : Inspectable_Bean)
                            return String_Array is abstract;

   function Get_Path_Parameter
     (Request : in out Servlet.Requests.Request'Class;
      Name : String)
      return String;

   type Renderer is interface;

   procedure Render_Response
     (This : Renderer;
      View : String;
      Model : Inspectable_Bean'Class;
      Response : in out Servlet.Responses.Response'Class)
   is abstract;

   type Renderer_Access is access all Renderer'Class;

   type Action_Access is access procedure
     (Request : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class);

   procedure Initialize
     (Context : aliased in out Web_Context;
      Registry : aliased in out Servlet.Core.Servlet_Registry;
      WS : in out Servlet.Server.Container'Class;
      URI : String;
      Pattern : String);

   procedure Add_Route
     (Context : aliased in out Web_Context;
      Method : String;
      Path : String;
      Action : Action_Access);

private

   Pattern_Size : constant GNAT.Regpat.Program_Size := 1024;

   type Web_Context_Access is access all Web_Context;

   type Dispatcher_Servlet is new Servlet.Core.Servlet with record
      Context : Web_Context_Access;
   end record;

   overriding procedure Do_Get
     (Server   : Dispatcher_Servlet;
      Request  : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class);

   overriding procedure Do_Head
     (Server   : Dispatcher_Servlet;
      Request  : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class);

   overriding procedure Do_Post
     (Server   : Dispatcher_Servlet;
      Request  : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class);

   overriding procedure Do_Put
     (Server   : Dispatcher_Servlet;
      Request  : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class);

   overriding procedure Do_Delete
     (Server   : Dispatcher_Servlet;
      Request  : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class);

   overriding procedure Do_Patch
     (Server   : Dispatcher_Servlet;
      Request  : in out Servlet.Requests.Request'Class;
      Response : in out Servlet.Responses.Response'Class);

   package Name_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive,
      Element_Type => Unbounded_String);

   type Route is record
      Method : Unbounded_String;
      Path : Unbounded_String;
      Matcher : GNAT.Regpat.Pattern_Matcher (Pattern_Size);
      Parameter_Names : Name_Vectors.Vector;
      Action : Action_Access;
   end record;

   package Route_Vector is new Ada.Containers.Vectors
     (Index_Type => Positive,
      Element_Type => Route);

   type Web_Context is record
      Dispatcher : aliased Dispatcher_Servlet;
      Routes : Route_Vector.Vector;
   end record;

end Meadowsweet;
