with Ada.Strings;
with Ada.Strings.Fixed;

package body Meadowsweet.Beans is

   use Ada.Strings;
   use Ada.Strings.Fixed;
   use Ada.Containers;
   use Util.Beans.Objects.Vectors;

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
               if not Equals (Inspectable_Bean'Class (Left_Child.all),
                              Inspectable_Bean'Class (Right_Child.all))
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

end Meadowsweet.Beans;
