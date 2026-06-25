package Meadowsweet.Json is

   type Json_Renderer is new Meadowsweet.Renderer with null record;

   overriding procedure Render_Response
     (This : Json_Renderer;
      View : String;
      Model : Meadowsweet.Inspectable_Bean'Class;
      Response : in out Servlet.Responses.Response'Class);

end Meadowsweet.Json;
