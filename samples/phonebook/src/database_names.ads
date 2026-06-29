with GNATCOLL.SQL; use GNATCOLL.SQL;
package Database_Names is
   pragma Style_Checks (Off);
   TC_Public_Addresses : aliased constant String := "public.addresses";
   Ta_Public_Addresses : constant Cst_String_Access := TC_Public_Addresses'Access;

   NC_E_Mail_Address : aliased constant String := "e_mail_address";
   N_E_Mail_Address : constant Cst_String_Access := NC_e_mail_address'Access;
   NC_Family_Name : aliased constant String := "family_name";
   N_Family_Name : constant Cst_String_Access := NC_family_name'Access;
   NC_Given_Name : aliased constant String := "given_name";
   N_Given_Name : constant Cst_String_Access := NC_given_name'Access;
   NC_Id : aliased constant String := "id";
   N_Id : constant Cst_String_Access := NC_id'Access;
   NC_Phone_Number : aliased constant String := "phone_number";
   N_Phone_Number : constant Cst_String_Access := NC_phone_number'Access;
end Database_Names;
