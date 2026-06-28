with GNATCOLL.JSON;
with Servlet.Streams;

package body Meadowsweet.Json is

   use GNATCOLL.JSON;

   function To_JSON (Source : Meadowsweet.Inspectable_Bean'Class)
                     return JSON_Value;

   function To_JSON (Source : Object)
                     return JSON_Value
   is
      Value_Type : constant Data_Type := Get_Type (Source);
   begin
      case Value_Type is
         when TYPE_BOOLEAN =>
            return Create (To_Boolean (Source));
         when TYPE_INTEGER =>
            return Create (To_Integer (Source));
         when TYPE_FLOAT =>
            return Create (To_Long_Float (Source));
         when TYPE_BEAN =>
            return To_JSON (Meadowsweet.Inspectable_Bean_Access
                             (To_Bean (Source)).all);
         when TYPE_ARRAY =>
            declare
               A : JSON_Array := Empty_Array;
            begin
               for I in 1 .. Get_Count (Source) loop
                  Append (A, To_JSON (Get_Value (Source, I)));
               end loop;
               return Create (A);
            end;
         when others =>
            return Create (To_String (Source));
      end case;
   end To_JSON;

   function To_JSON (Source : Meadowsweet.Inspectable_Bean'Class)
                     return JSON_Value
   is
      Result : constant JSON_Value := Create_Object;
      Property_Names : constant Meadowsweet.String_Array
        := Source.Property_Names;
      Value : Object;
   begin
      for I in Property_Names'Range loop
         Value := Source.Get_Value (To_String (Property_Names (I)));
         Result.Set_Field (To_String (Property_Names (I)),
                           To_JSON (Value));
      end loop;
      return Result;
   end To_JSON;

   overriding procedure Render_Response
     (This : Json_Renderer;
      View : String;
      Model : Meadowsweet.Inspectable_Bean'Class;
      Response : in out Servlet.Responses.Response'Class)
   is
      Stream : Servlet.Streams.Print_Stream := Response.Get_Output_Stream;
      Content : constant String := Write (To_JSON (Model));
   begin
      Response.Set_Content_Type ("application/json");
      Response.Set_Content_Length (Content'Length);
      Stream.Write (Content);
   end Render_Response;

end Meadowsweet.Json;
