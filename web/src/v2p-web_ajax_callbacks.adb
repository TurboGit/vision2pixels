------------------------------------------------------------------------------
--                              Vision2Pixels                               --
--                                                                          --
--                         Copyright (C) 2007                               --
--                      Pascal Obry - Olivier Ramonat                       --
--                                                                          --
--  This library is free software; you can redistribute it and/or modify    --
--  it under the terms of the GNU General Public License as published by    --
--  the Free Software Foundation; either version 2 of the License, or (at   --
--  your option) any later version.                                         --
--                                                                          --
--  This library is distributed in the hope that it will be useful, but     --
--  WITHOUT ANY WARRANTY; without even the implied warranty of              --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU       --
--  General Public License for more details.                                --
--                                                                          --
--  You should have received a copy of the GNU General Public License       --
--  along with this library; if not, write to the Free Software Foundation, --
--  Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.       --
------------------------------------------------------------------------------

with AWS.Parameters;
with AWS.Session;

with Image.Metadata.Geographic;

with V2P.Database;
with V2P.Wiki;

with V2P.Template_Defs.Forum_Entry;
with V2P.Template_Defs.Global;
with V2P.Template_Defs.Block_New_Comment;
with V2P.Template_Defs.Block_New_Post;
with V2P.Template_Defs.Block_Metadata;
with V2P.Template_Defs.Block_User_Tmp_Photo_Select;
with V2P.Template_Defs.Block_Forum_Filter;
with V2P.Template_Defs.Block_Forum_List_Select;
with V2P.Template_Defs.Block_User_Page;
with V2P.Template_Defs.R_Block_Login;
with V2P.Template_Defs.R_Block_Comment_Form_Enter;
with V2P.Template_Defs.R_Block_Post_Form_Enter;
with V2P.Template_Defs.R_Block_User_Page_Edit_Form_Enter;
with Ada.Strings.Unbounded;

package body V2P.Web_Ajax_Callbacks is

   use Ada.Strings.Unbounded;

   --------------------
   -- Login_Callback --
   --------------------

   procedure Login_Callback
     (Request      : in     Status.Data;
      Context      : access Services.Web_Block.Context.Object;
      Translations : in out Templates.Translate_Set)
   is
      pragma Unreferenced (Context);
      SID       : constant Session.Id := Status.Session (Request);
      P         : constant Parameters.List := Status.Parameters (Request);
      Login     : constant String :=
                    Parameters.Get (P, Template_Defs.Global.LOGIN);
      User_Data : constant Database.User_Data :=
                    Database.Get_User_Data (Login);
   begin
      if To_String (User_Data.Password) =
        Parameters.Get (P, Template_Defs.Global.PASSWORD)
      then
         Session.Set (SID, Template_Defs.Global.LOGIN, Login);
         Session.Set
           (SID,
            Template_Defs.Global.PASSWORD, To_String (User_Data.Password));
         Session.Set (SID, Template_Defs.Global.ADMIN, User_Data.Admin);

         --  Set user's filtering preference
         --  ??? to be done when user's preferences are implemented

         Templates.Insert
           (Translations,
            Templates.Assoc
              (Template_Defs.R_Block_Login.LOGIN,
               String'(Session.Get (SID, Template_Defs.Global.LOGIN))));
      end if;
   end Login_Callback;

   ---------------------
   -- Logout_Callback --
   ---------------------

   procedure Logout_Callback
     (Request      : in     Status.Data;
      Context      : access Services.Web_Block.Context.Object;
      Translations : in out Templates.Translate_Set)
   is
      pragma Unreferenced (Context);
      SID : constant Session.Id := Status.Session (Request);
   begin
      Session.Delete (SID);

      --  Remove the login information from the translate table

      Templates.Remove (Translations, Template_Defs.Global.LOGIN);
   end Logout_Callback;

   ---------------------------
   -- Onchange_Filter_Forum --
   ---------------------------

   procedure Onchange_Filter_Forum
     (Request      : in     Status.Data;
      Context      : access Services.Web_Block.Context.Object;
      Translations : in out Templates.Translate_Set)
   is
      pragma Unreferenced (Translations);
      P      : constant Parameters.List := Status.Parameters (Request);
      Filter : constant String :=
                 Parameters.Get
                   (P, Template_Defs.Block_Forum_Filter.HTTP.forum_filter_set);
   begin
      --  Keep the sorting scheme into the session
      --  ?? we need to add this into the user's preferences
      Context.Set_Value (Template_Defs.Global.FILTER, Filter);
   end Onchange_Filter_Forum;

   ----------------------------------
   -- Onchange_Forum_List_Callback --
   ----------------------------------

   procedure Onchange_Forum_List_Callback
     (Request      : in     Status.Data;
      Context      : access Services.Web_Block.Context.Object;
      Translations : in out Templates.Translate_Set)
   is
      pragma Unreferenced (Context);
      P   : constant Parameters.List := Status.Parameters (Request);
      Fid : constant String :=
              Parameters.Get
                (P, Template_Defs.Block_Forum_List_Select.HTTP.sel_forum_list);
   begin
      Templates.Insert (Translations, Database.Get_Categories (Fid));
   end Onchange_Forum_List_Callback;

   ----------------------------------
   -- Onclick_Hidden_Status_Toggle --
   ----------------------------------

   procedure Onclick_Hidden_Status_Toggle
     (Request      : in     Status.Data;
      Context      : access Services.Web_Block.Context.Object;
      Translations : in out Templates.Translate_Set)
   is
      pragma Unreferenced (Request);
      TID : constant String := Context.Get_Value (Template_Defs.Global.TID);
   begin
      Templates.Insert (Translations, Database.Toggle_Hidden_Status (TID));
   end Onclick_Hidden_Status_Toggle;

   ------------------------------------------
   -- Onsubmit_Comment_Form_Enter_Callback --
   ------------------------------------------

   procedure Onsubmit_Comment_Form_Enter_Callback
     (Request      : in     Status.Data;
      Context      : access Services.Web_Block.Context.Object;
      Translations : in out Templates.Translate_Set)
   is
      use Template_Defs;
      use Template_Defs.Block_User_Tmp_Photo_Select;

      SID          : constant Session.Id := Status.Session (Request);
      P            : constant Parameters.List := Status.Parameters (Request);
      Login        : constant String :=
                       Session.Get (SID, Template_Defs.Global.LOGIN);
      Anonymous    : constant String :=
                       Parameters.Get
                         (P, Block_New_Comment.HTTP.ANONYMOUS_USER);
      Name         : constant String :=
                       Parameters.Get (P, Block_New_Comment.HTTP.NAME);
      Comment      : constant String :=
                       Parameters.Get (P, Block_New_Comment.HTTP.COMMENT);
      Parent_Id    : constant String :=
                       Parameters.Get (P, Forum_Entry.HTTP.PARENT_ID);
      Pid          : constant String :=
                       Parameters.Get
                         (P, HTTP.block_user_tmp_photo_select);
      Tid          : constant String :=
                       Parameters.Get (P, Block_New_Comment.HTTP.TID);
      Comment_Wiki : constant String := V2P.Wiki.Wiki_To_HTML (Comment);
      Last_Comment : constant String :=
                       Context.Get_Value (Global.CONTEXT_LAST_COMMENT);

      function Is_Valid_Comment (Comment : in String) return Boolean;
      --  Check if the comment is valid

      ----------------------
      -- Is_Valid_Comment --
      ----------------------

      function Is_Valid_Comment (Comment : in String) return Boolean is
         Is_Valid : Boolean := True;
      begin
         if Comment = "" then
            --  Does not accept empty comment
            Is_Valid := False;
         end if;

         return Is_Valid;
      end Is_Valid_Comment;

   begin
      if Login = "" and then Anonymous = "" then
         Templates.Insert
           (Translations,
            Templates.Assoc
              (R_Block_Comment_Form_Enter.ERROR, "ERROR_NO_LOGIN"));

      elsif Last_Comment = Comment & '@' & Tid then
         --   This is a duplicated post

         Templates.Insert
           (Translations,
            Templates.Assoc
              (R_Block_Comment_Form_Enter.ERROR_DUPLICATED, "ERROR"));

      elsif Tid /= "" and then not Is_Valid_Comment (Comment_Wiki) then
         Templates.Insert
           (Translations,
            Templates.Assoc
              (R_Block_Comment_Form_Enter.ERROR, "ERROR"));
            --  ??? Adds an error message
      else
         Insert_Comment : declare
            Cid : constant String := Database.Insert_Comment
              (Login, Anonymous, Tid, Name, Comment_Wiki, Pid);
         begin
            --  Adds the new comment in context to prevent duplicated post

            Context.Set_Value
              (Global.CONTEXT_LAST_COMMENT, Comment & '@' & Tid);

            Templates.Insert (Translations, Database.Get_Comment (Cid));
            Templates.Insert
              (Translations,
               Templates.Assoc
                 (R_Block_Comment_Form_Enter.PARENT_ID, Parent_Id));
            Templates.Insert
              (Translations,
               Templates.Assoc
                 (R_Block_Comment_Form_Enter.COMMENT_LEVEL, "1"));
            --  Does not support threaded view for now
         end Insert_Comment;
      end if;
   end Onsubmit_Comment_Form_Enter_Callback;

   -------------------------------------------
   -- Onsubmit_Metadata_Form_Enter_Callback --
   -------------------------------------------

   procedure Onsubmit_Metadata_Form_Enter_Callback
     (Request      : in     Status.Data;
      Context      : access Services.Web_Block.Context.Object;
      Translations : in out Templates.Translate_Set)
   is
      pragma Unreferenced (Translations);
      use Image.Metadata.Geographic;

      function Get (Parameter_Name : in String) return Geo_Coordinate;
      --  Returns the given parameter or zero if not found

      P : constant Parameters.List := Status.Parameters (Request);

      ---------
      -- Get --
      ---------

      function Get (Parameter_Name : in String) return Geo_Coordinate is
         Param : constant String := Parameters.Get (P, Parameter_Name);
         Coordinate : Geo_Coordinate := 0.0;
      begin
         if Param /= "" then
            Coordinate := Geo_Coordinate'Value (Param);
         end if;
         return Coordinate;
      end Get;

   begin

      Insert_Metadata :
      declare
         Latitude_Coord      : constant Geo_Coordinate := Get
           (Template_Defs.Block_Metadata.HTTP.latitude);
         Longitude_Coord     : constant Geo_Coordinate := Get
           (Template_Defs.Block_Metadata.HTTP.longitude);
         Latitude_Position   : Latitude;
         Longitude_Postition : Longitude;
      begin
         if Latitude_Coord = 0.0 or else Longitude_Coord = 0.0 then
            Context.Set_Value
              (V2P.Template_Defs.Global.ERROR_METADATA_NULL_METADATA, "ERROR");
         elsif not Context.Exist (Template_Defs.Global.TID) then
            Context.Set_Value
              (V2P.Template_Defs.Global.ERROR_METADATA_UNKNOWN_PHOTO, "ERROR");
         else
            Latitude_Position.Format (Latitude_Coord);
            Longitude_Postition.Format (Longitude_Coord);

            Database.Insert_Metadata
              (Context.Get_Value (Template_Defs.Global.TID),
               Float (Latitude_Coord),
               Float (Longitude_Coord),
               Image.Metadata.Geographic.Image (Latitude_Position),
               Image.Metadata.Geographic.Image (Longitude_Postition));
         end if;
      end Insert_Metadata;

   exception
      when Constraint_Error =>
         Context.Set_Value
           (V2P.Template_Defs.Global.ERROR_METADATA_WRONG_METADATA, "ERROR");
   end Onsubmit_Metadata_Form_Enter_Callback;

   ---------------------------------------
   -- Onsubmit_Post_Form_Enter_Callback --
   ---------------------------------------

   procedure Onsubmit_Post_Form_Enter_Callback
     (Request      : in     Status.Data;
      Context      : access Services.Web_Block.Context.Object;
      Translations : in out Templates.Translate_Set)
   is
      use Template_Defs;
      use Template_Defs.Block_User_Tmp_Photo_Select;

      SID          : constant Session.Id := Status.Session (Request);
      P            : constant Parameters.List := Status.Parameters (Request);
      Login        : constant String :=
                       Session.Get (SID, Template_Defs.Global.LOGIN);
      Name         : constant String :=
                       Parameters.Get (P, Block_New_Post.HTTP.NAME);
      Comment      : constant String :=
                       Parameters.Get (P, Block_New_Post.HTTP.COMMENT);
      Pid          : constant String :=
                       Parameters.Get
                         (P, HTTP.block_user_tmp_photo_select);
      CID          : constant String :=
                       Parameters.Get (P, Block_New_Post.HTTP.CATEGORY);
      Last_Name    : constant String :=
                       Context.Get_Value (Global.CONTEXT_LAST_POST_NAME);
      Comment_Wiki : constant String := V2P.Wiki.Wiki_To_HTML (Comment);
   begin
      if Login = "" and then CID = "" then
         Templates.Insert
           (Translations,
            Templates.Assoc
              (Template_Defs.R_Block_Post_Form_Enter.ERROR,
               "POST SUBMIT ERROR"));
         --  ??? Adds an error message
      else

         if Last_Name = Name then
            Templates.Insert
              (Translations,
               Templates.Assoc
                 (Template_Defs.R_Block_Post_Form_Enter.ERROR_DUPLICATED,
                  "ERROR_DUPLICATE_POST"));

         else
            Insert_Post : declare
               Post_Id : constant String :=
                           Database.Insert_Post
                             (Login, CID, Name, Comment_Wiki, Pid);
            begin
               if Post_Id /= "" then
                  --  Set new context TID (needed by
                  --  Onsubmit_Metadata_Form_Enter_Callback)

                  Context.Set_Value (Global.TID, Post_Id);
                  Context.Set_Value (Global.CONTEXT_LAST_POST_NAME, Name);

                  Templates.Insert
                    (Translations,
                     Templates.Assoc
                       (R_Block_Post_Form_Enter.URL,
                        Forum_Entry.URL & '?' &
                        Forum_Entry.HTTP.TID & '=' & Post_Id));

               else
                  Templates.Insert
                    (Translations,
                     Templates.Assoc
                       (R_Block_Post_Form_Enter.ERROR,
                        "DATABASE INSERT FAILED"));
               end if;
            end Insert_Post;
         end if;

         if Pid /= "" and then Context.Exist (Global.TID) then
            Onsubmit_Metadata_Form_Enter_Callback
              (Request, Context, Translations);
         end if;
      end if;
   end Onsubmit_Post_Form_Enter_Callback;

   -------------------------------------------------
   -- Onsubmit_User_Page_Edit_Form_Enter_Callback --
   -------------------------------------------------

   procedure Onsubmit_User_Page_Edit_Form_Enter_Callback
     (Request      : in     Status.Data;
      Context      : access Services.Web_Block.Context.Object;
      Translations : in out Templates.Translate_Set)
   is
      pragma Unreferenced (Context);
      use Template_Defs;

      SID          : constant Session.Id := Status.Session (Request);
      P            : constant Parameters.List := Status.Parameters (Request);
      Login        : constant String :=
                       Session.Get (SID, Template_Defs.Global.LOGIN);
      Content      : constant String :=
                       Parameters.Get (P, Block_User_Page.HTTP.CONTENT);
      Content_HTML : constant String := V2P.Wiki.Wiki_To_HTML (Content);

   begin
      Database.Update_Page
        (Uid          => Login,
         Content      => Content,
         Content_HTML => Content_HTML);

      Templates.Insert
        (Translations,
         Templates.Assoc
           (R_Block_User_Page_Edit_Form_Enter.USER_PAGE_HTML_CONTENT,
            Content_HTML));
   end Onsubmit_User_Page_Edit_Form_Enter_Callback;

end V2P.Web_Ajax_Callbacks;
