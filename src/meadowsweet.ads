with Ada.Containers;
with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Containers.Vectors;
with Ada.Strings;
with Ada.Strings.Hash;
with Ada.Strings.Unbounded;
with Ada.Strings.Unbounded.Hash;
with Servlet.Core;
with Servlet.Server;
with Servlet.Requests;
with Servlet.Responses;
with Util.Beans.Basic;
with GNAT.Regpat;
with Util.Beans.Objects;

package Meadowsweet is

   use Ada.Strings.Unbounded;
   use Util.Beans.Objects;

   type Web_Context is limited private;

   type String_Array is array (Positive range <>) of Unbounded_String;

   type Inspectable_Bean is abstract new Util.Beans.Basic.Readonly_Bean
   with null record;

   type Inspectable_Bean_Access is access all Meadowsweet.Inspectable_Bean;

   function Property_Names (This : Inspectable_Bean)
                            return String_Array is abstract;

   --  Returns the value of the path parameter with the given name.
   --  A path parameter is delimited by curly brackets, e.g. {id}.
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

   type Dynamic_Bean is new Inspectable_Bean with private;

   overriding function Get_Value (From : Dynamic_Bean;
                                  Name : String)
                                  return Util.Beans.Objects.Object;

   overriding function Property_Names (From : Dynamic_Bean)
                                       return String_Array;

   procedure Set_Value (This : in out Dynamic_Bean;
                        Name : String;
                        Value : Util.Beans.Objects.Object);

   --  Initializes a web context. This procedure must be called before
   --  calling Add_Route.
   procedure Initialize
     (Context : aliased in out Web_Context;
      Registry : aliased in out Servlet.Core.Servlet_Registry;
      WS : in out Servlet.Server.Container'Class;
      URI : String;
      Pattern : String);

   --  Adds a route to the web context.
   --  A route consists of a HTTP method, a path, and an action.
   --  When a request is received which matches the path and method of a route,
   --  the specified action procedure is invoked.
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

   package Route_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive,
      Element_Type => Route);

   type Web_Context is record
      Dispatcher : aliased Dispatcher_Servlet;
      Routes : Route_Vectors.Vector;
   end record;

   package Bean_Maps is new Ada.Containers.Indefinite_Hashed_Maps
     (Key_Type        => String,
      Element_Type    => Util.Beans.Objects.Object,
      Hash            => Ada.Strings.Hash,
      Equivalent_Keys => "=");

   type Dynamic_Bean is new Inspectable_Bean with record
      Attributes : Bean_Maps.Map;
   end record;

end Meadowsweet;
