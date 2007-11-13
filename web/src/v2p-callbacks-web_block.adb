------------------------------------------------------------------------------
--                              Vision2Pixels                               --
--                                                                          --
--                           Copyright (C) 2007                             --
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

with V2P.URL;
with V2P.Database;
with V2P.Context;
with V2P.Settings;
with V2P.Template_Defs.Block_New_Comment;
with V2P.Template_Defs.Block_User_Page;
with V2P.Template_Defs.Block_Metadata;
with V2P.Template_Defs.Set_Global;

package body V2P.Callbacks.Web_Block is

   ----------
   -- Exif --
   ----------

   procedure Exif
     (Request      : in     Status.Data;
      Context      : access Services.Web_Block.Context.Object;
      Translations : in out Templates.Translate_Set)
   is
      pragma Unreferenced (Request);
   begin
      if Context.Exist ("TID") then
         Templates.Insert
           (Translations,
            Database.Get_Exif (Context.Get_Value ("TID")));
      end if;
   end Exif;

   ------------------
   -- Forum_Filter --
   ------------------

   procedure Forum_Filter
     (Request      : in     Status.Data;
      Context      : access Services.Web_Block.Context.Object;
      Translations : in out Templates.Translate_Set)
   is
      pragma Unreferenced (Request);
   begin
      Templates.Insert
        (Translations,
         Templates.Assoc
           (Template_Defs.Set_Global.FILTER,
            Context.Get_Value (Template_Defs.Set_Global.FILTER)));
   end Forum_Filter;

   ----------------------------
   -- Forum_Filter_Page_Size --
   ----------------------------

   procedure Forum_Filter_Page_Size
     (Request      : in     Status.Data;
      Context      : access Services.Web_Block.Context.Object;
      Translations : in out Templates.Translate_Set)
   is
      pragma Unreferenced (Request);
   begin
      Templates.Insert
        (Translations,
         Templates.Assoc
           (Template_Defs.Set_Global.FILTER_PAGE_SIZE,
            Context.Get_Value (Template_Defs.Set_Global.FILTER_PAGE_SIZE)));
   end Forum_Filter_Page_Size;

   ----------------
   -- Forum_List --
   ----------------

   procedure Forum_List
     (Request      : in     Status.Data;
      Context      : access Services.Web_Block.Context.Object;
      Translations : in out Templates.Translate_Set)
   is
      pragma Unreferenced (Request, Context);
   begin
      Templates.Insert
        (Translations,
         Database.Get_Forums (Filter => Database.Forum_All));
   end Forum_List;

   -----------------------------
   -- Forum_Photo_List_Select --
   -----------------------------

   procedure Forum_Photo_List_Select
     (Request      : in     Status.Data;
      Context      : access Services.Web_Block.Context.Object;
      Translations : in out Templates.Translate_Set)
   is
      pragma Unreferenced (Request, Context);
   begin
      Templates.Insert
        (Translations,
         Database.Get_Forums (Filter => Database.Forum_Photo));
   end Forum_Photo_List_Select;

   ----------------------------
   -- Forum_Text_List_Select --
   ----------------------------

   procedure Forum_Text_List_Select
     (Request      : in     Status.Data;
      Context      : access Services.Web_Block.Context.Object;
      Translations : in out Templates.Translate_Set)
   is
      pragma Unreferenced (Request, Context);
   begin
      Templates.Insert
        (Translations,
         Database.Get_Forums (Filter => Database.Forum_Text));
   end Forum_Text_List_Select;

   -------------------
   -- Forum_Threads --
   -------------------

   procedure Forum_Threads
     (Request      : in     Status.Data;
      Context      : access Services.Web_Block.Context.Object;
      Translations : in out Templates.Translate_Set)
   is
      pragma Unreferenced (Request);
      use V2P.Context;

      Admin     : constant Boolean :=
                    Context.Exist (Template_Defs.Set_Global.ADMIN)
                  and then Context.Get_Value
                    (Template_Defs.Set_Global.ADMIN) = "TRUE";
      Page_Size : constant Positive :=
                    V2P.Context.Counter.Get_Value
                      (Context => Context.all,
                       Name    => Template_Defs.Set_Global.FILTER_PAGE_SIZE);
      Nav_Links : V2P.Context.Post_Ids.Vector;
      Nb_Lines  : Natural;
   begin
      Database.Get_Threads
        (FID        => Context.Get_Value (Template_Defs.Set_Global.FID),
         From       => Navigation_From.Get_Value
           (Context.all, Template_Defs.Set_Global.NAV_FROM),
         Admin      => Admin,
         Filter     => Database.Filter_Mode'Value (Context.Get_Value
           (Template_Defs.Set_Global.FILTER)),
         Page_Size  => Page_Size,
         Order_Dir  => Database.Order_Direction'Value
           (Context.Get_Value (Template_Defs.Set_Global.ORDER_DIR)),
         Navigation => Nav_Links,
         Set        => Translations,
         Nb_Lines   => Nb_Lines);

      V2P.Context.Navigation_Links.Set_Value
        (Context.all, "Navigation_Links", Nav_Links);

      V2P.Context.Counter.Set_Value
        (Context => Context.all,
         Name    => Template_Defs.Set_Global.NB_LINE_RETURNED,
         Value   => Nb_Lines);
   end Forum_Threads;

   -------------------
   -- Global_Rating --
   -------------------

   procedure Global_Rating
     (Request      : in     Status.Data;
      Context      : access Services.Web_Block.Context.Object;
      Translations : in out Templates.Translate_Set)
   is
      pragma Unreferenced (Request);
   begin
      if Context.Exist ("TID") then
         Templates.Insert
           (Translations,
            Database.Get_Global_Rating (Context.Get_Value ("TID")));
      end if;
   end Global_Rating;

   ------------------
   -- Latest_Posts --
   ------------------

   procedure Latest_Posts
     (Request      : in     Status.Data;
      Context      : access Services.Web_Block.Context.Object;
      Translations : in out Templates.Translate_Set)
   is
      pragma Unreferenced (Request, Context);
   begin
      Templates.Insert
        (Translations,
         Database.Get_Latest_Posts (Settings.Number_Latest_Posts));
   end Latest_Posts;

   ------------------
   -- Latest_Users --
   ------------------

   procedure Latest_Users
     (Request      : in     Status.Data;
      Context      : access Services.Web_Block.Context.Object;
      Translations : in out Templates.Translate_Set)
   is
      pragma Unreferenced (Request, Context);
   begin
      Templates.Insert
        (Translations,
         Database.Get_Latest_Users (Settings.Number_Latest_Users));
   end Latest_Users;

   --------------
   -- Metadata --
   --------------

   procedure Metadata
     (Request      : in     Status.Data;
      Context      : access Services.Web_Block.Context.Object;
      Translations : in out Templates.Translate_Set)
   is
      pragma Unreferenced (Request);

      Login : constant String :=
                Context.Get_Value (Template_Defs.Set_Global.LOGIN);
   begin
      if Context.Exist ("TID") then
         Templates.Insert
           (Translations,
            Templates.Assoc
              (V2P.Template_Defs.Block_Metadata.IS_OWNER,
               Boolean'Image (V2P.Database.Is_Author
                 (Login, Context.Get_Value ("TID")))));

         if Context.Exist
           (V2P.Template_Defs.Set_Global.ERROR_METADATA_NULL_METADATA) then
            Templates.Insert
              (Translations,
               Templates.Assoc
                 (V2P.Template_Defs.Set_Global.ERROR_METADATA_NULL_METADATA,
                  "ERROR"));
            Context.Remove
              (V2P.Template_Defs.Set_Global.ERROR_METADATA_NULL_METADATA);

         elsif Context.Exist
           (V2P.Template_Defs.Set_Global.ERROR_METADATA_UNKNOWN_PHOTO) then
            Templates.Insert
              (Translations,
               Templates.Assoc
                 (V2P.Template_Defs.Set_Global.ERROR_METADATA_UNKNOWN_PHOTO,
                  "ERROR"));
            Context.Remove
              (V2P.Template_Defs.Set_Global.ERROR_METADATA_UNKNOWN_PHOTO);

         elsif Context.Exist
           (V2P.Template_Defs.Set_Global.ERROR_METADATA_WRONG_METADATA) then
            Templates.Insert
              (Translations,
               Templates.Assoc
                 (V2P.Template_Defs.Set_Global.ERROR_METADATA_WRONG_METADATA,
                  "ERROR"));
            Context.Remove
              (V2P.Template_Defs.Set_Global.ERROR_METADATA_WRONG_METADATA);

         else
            Templates.Insert
              (Translations,
               Database.Get_Metadata (Context.Get_Value ("TID")));
         end if;
      end if;
   end Metadata;

   -----------------
   -- New_Comment --
   -----------------

   procedure New_Comment
     (Request      : in     Status.Data;
      Context      : access Services.Web_Block.Context.Object;
      Translations : in out Templates.Translate_Set)
   is
      pragma Unreferenced (Request);
      use AWS.Templates;

      Ratings : Templates.Tag;

   begin
      if Context.Exist ("FID") then
         Templates.Insert
           (Translations,
            Database.Get_Categories (Context.Get_Value ("FID")));
      end if;

      if Context.Exist ("TID") then
         Templates.Insert
           (Translations,
            Templates.Assoc
              (Template_Defs.Block_New_Comment.Current_TID,
               Context.Get_Value ("TID")));

         if Context.Exist (Template_Defs.Set_Global.LOGIN) then
            Templates.Insert
              (Translations,
               Database.Get_User_Rating_On_Post
                 (Uid => Context.Get_Value (Template_Defs.Set_Global.LOGIN),
                  Tid => Context.Get_Value ("TID")));
         end if;
      end if;

      Ratings := Ratings & "1" & "2" & "3" & "4" & "5";

      Templates.Insert
        (Translations,
         Templates.Assoc
           (Template_Defs.Block_New_Comment.RATING, Ratings));
   end New_Comment;

   --------------
   -- New_Post --
   --------------

   procedure New_Post
     (Request      : in     Status.Data;
      Context      : access Services.Web_Block.Context.Object;
      Translations : in out Templates.Translate_Set)
   is
      pragma Unreferenced (Request, Translations);
   begin
      if Context.Exist ("TID") then
         Context.Remove ("TID");
      end if;
   end New_Post;

   -----------------
   -- Quick_Login --
   -----------------

   procedure Quick_Login
     (Request      : in     Status.Data;
      Context      : access Services.Web_Block.Context.Object;
      Translations : in out Templates.Translate_Set)
   is
      pragma Unreferenced (Request);
   begin
      if Context.Exist (Template_Defs.Set_Global.LOGIN) then
         Templates.Insert
           (Translations,
            Templates.Assoc
              (Template_Defs.Set_Global.LOGIN,
               String'(Context.Get_Value  (Template_Defs.Set_Global.LOGIN))));
      end if;
   end Quick_Login;

   -----------------------
   -- User_Comment_List --
   -----------------------

   procedure User_Comment_List
     (Request      : in     Status.Data;
      Context      : access Services.Web_Block.Context.Object;
      Translations : in out Templates.Translate_Set)
   is
      pragma Unreferenced (Context);
      URI       : constant String := Status.URI (Request);
      User_Name : constant String := URL.User_Name (URI);
   begin
      Templates.Insert
        (Translations,
         Database.Get_User_Comment (Uid => User_Name, Textify => True));
   end User_Comment_List;

   ---------------
   -- User_Page --
   ---------------

   procedure User_Page
     (Request      : in Status.Data;
      Context      : access Services.Web_Block.Context.Object;
      Translations : in out Templates.Translate_Set)
   is
      pragma Unreferenced (Context);
      URI       : constant String := Status.URI (Request);
      User_Name : constant String := URL.User_Name (URI);

   begin
      Templates.Insert
        (Translations, Database.Get_User_Page (Uid => User_Name));

      Templates.Insert
        (Translations,
         Templates.Assoc (Template_Defs.Block_User_Page.USER_NAME, User_Name));
   end User_Page;

   ----------------------
   -- User_Thread_List --
   ----------------------

   procedure User_Thread_List
     (Request      : in     Status.Data;
      Context      : access Services.Web_Block.Context.Object;
      Translations : in out Templates.Translate_Set)
   is

      Admin      : constant Boolean :=
                     Context.Exist (Template_Defs.Set_Global.ADMIN)
                   and then Context.Get_Value
                     (Template_Defs.Set_Global.ADMIN) = "TRUE";
      URI        : constant String     := Status.URI (Request);
      User_Name  : constant String     := URL.User_Name (URI);
      Set        : Templates.Translate_Set;
      Navigation : V2P.Context.Post_Ids.Vector;
      Nb_Lines   : Natural;

   begin
      Database.Get_Threads
        (User       => User_Name,
         Navigation => Navigation,
         Set        => Set,
         Admin      => Admin,
         Nb_Lines   => Nb_Lines);

      Templates.Insert (Translations, Set);
      V2P.Context.Counter.Set_Value
        (Context => Context.all,
         Name    => Template_Defs.Set_Global.NB_LINE_RETURNED,
         Value   => Nb_Lines);
   end User_Thread_List;

end V2P.Callbacks.Web_Block;
