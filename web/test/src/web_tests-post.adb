------------------------------------------------------------------------------
--                              Vision2Pixels                               --
--                                                                          --
--                         Copyright (C) 2007-2010                          --
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

with Ada.Calendar.Formatting;
with Ada.Calendar.Time_Zones;
with Ada.Directories;

with AUnit.Assertions;

with GNAT.MD5;

with AWS.Client;
with AWS.Response;
with AWS.Utils;

with V2P.Template_Defs.Block_Forum_Filter;
with V2P.Template_Defs.Block_Login;
with V2P.Template_Defs.Block_New_Comment;
with V2P.Template_Defs.Page_Forum_New_Photo_Entry;
with V2P.Template_Defs.Page_Forum_New_Text_Entry;
with V2P.Template_Defs.Page_Forum_Threads;

package body Web_Tests.Post is

   use Ada;
   use AWS;

   procedure Main_Page (T : in out AUnit.Test_Cases.Test_Case'Class);
   --  The very first thing to do is to get the main page

   procedure Close (T : in out AUnit.Test_Cases.Test_Case'Class);
   --  Closes the Web connection

   procedure Check_Post (T : in out AUnit.Test_Cases.Test_Case'Class);
   --  Checks a single post in a forum

   procedure Check_New_Post (T : in out AUnit.Test_Cases.Test_Case'Class);
   --  Checks the new post, must be called after Post_New_Photo

   procedure Post_New_Photo (T : in out AUnit.Test_Cases.Test_Case'Class);
   --  Posts a new photo

   procedure Post_New_Comment (T : in out AUnit.Test_Cases.Test_Case'Class);
   --  Post a comment on the new photo

   procedure Post_New_Message (T : in out AUnit.Test_Cases.Test_Case'Class);
   --  Posts a new photo

   Connection : Client.HTTP_Connection;
   --  Server connection used by all tests

   -----------
   -- Close --
   -----------

   procedure Close (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Client.Close (Connection);
   end Close;

   --------------------
   -- Check_New_Post --
   --------------------

   procedure Check_New_Post (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use V2P.Template_Defs;
      use Ada.Directories;
      Result : Response.Data;
      I_Name : constant String :=
                 Compose (Name      => GNAT.MD5.Digest ("troll.jpg"),
                          Extension => "jpg");
   begin
      Call (Connection, Result, URI => "/forum/entry?TID=142");

      Check
        (Response.Message_Body (Result),
         Word_Set'(+"Un_Troll", +"Un_Troll", +I_Name,
           +"révélé dans 71", +"un<em>petit</em>troll"),
         "wrong entry for post 142" & Response.Message_Body (Result));
   end Check_New_Post;

   ----------------
   -- Check_Post --
   ----------------

   procedure Check_Post
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      use V2P.Template_Defs;
      Result : Response.Data;
   begin
      Call (Connection, Result, URI => "/forum/entry?TID=89");

      Check
        (Response.Message_Body (Result),
         Word_Set'(+"Invasion", +"Portrait",
           +"révélé dans 71", +"commentaire pour invasion",
           +"L'auteur", +"Alors qu'en pensez-vous?",
           +"enzbang", +"Bof!",
           +"L'auteur", +"Mais encore ?"),
         "wrong entry for post 89");
   end Check_Post;

   ---------------
   -- Main_Page --
   ---------------

   procedure Main_Page (T : in out AUnit.Test_Cases.Test_Case'Class) is
      Result : Response.Data;
   begin
      Client.Create (Connection, "http://" & Host & ':' & Utils.Image (Port));

      Call (Connection, Result, URI => "/");

      Check_Page : declare
         use AUnit.Assertions;
         Page : constant String := Response.Message_Body (Result);
      begin
         Check
           (Page,
            Word_Set'(1 => +"Forum photographies", 2 => +"Forum mat"),
            "cannot get the first page");
      end Check_Page;
   end Main_Page;

   ----------
   -- Name --
   ----------

   overriding function Name (T : in Test_Case) return Message_String is
   begin
      return Format ("Web_Tests.Post");
   end Name;

   ------------------
   -- Post_Comment --
   ------------------

   procedure Post_New_Comment (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use V2P.Template_Defs;
      use type Ada.Calendar.Time;

      Now    : constant Calendar.Time := Calendar.Clock;
      H      : constant Calendar.Formatting.Hour_Number :=
                 Calendar.Formatting.Hour (Now);
      Result : Response.Data;
   begin
      Login (Connection, "turbo", "turbopass");

      Call
        (Connection, Result,
         URI => Block_New_Comment.Ajax.onsubmit_bnc_comment_register & '?'
           & "forum_photo=t&TID=142&global_comment_input=mon_commentaire"
           & "&bnc_comment_type=txt&CHECK=V%C3%A9rifier&pfe_PARENT_ID="
         & "&bnc_comment_pid=&REGISTER_COMMENT=Envoyer");

      Call (Connection, Result, URI => "/forum/entry?TID=142");

      Check
        (Response.Message_Body (Result),
         Word_Set'(+Utils.Image (H) & ':', +"turbo", +"mon_commentaire"),
         "wrong date for new comment");
   end Post_New_Comment;

   --------------------
   -- Post_New_Photo --
   --------------------

   procedure Post_New_Photo (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use V2P.Template_Defs;
      Result : Response.Data;
   begin
      Logout (Connection);

      --  Go to the upload page (anonymous)

      Call (Connection, Result, URI => "/add_photo");

      Check_Anonymous_Upload_Page : declare
         use AUnit.Assertions;
         Page : constant String := Response.Message_Body (Result);
      begin
         Check
           (Page,
            Word_Set'
              (1 => +"Vous devez être connecté pour poster un message"),
            "Must be connected to upload a photo");
      end Check_Anonymous_Upload_Page;

      --  Go to the upload page (turbo)

      Login (Connection, "turbo", "turbopass");

      Call (Connection, Result, URI => "/add_photo");

      Check_Turbo_Upload_Page : declare
         use AUnit.Assertions;
         Page : constant String := Response.Message_Body (Result);
      begin
         Check
           (Page,
            Word_Set'(1 => +"Vous devez attendre jusqu'au"),
            "Turbo should not have the right to upload at this time");
      end Check_Turbo_Upload_Page;

      --  Go to the upload page (test)

      Logout (Connection);
      Login (Connection, "test", "test");

      delay 1.5;

      Call (Connection, Result, URI => "/add_photo");

      Check_Upload_Page : declare
         use AUnit.Assertions;
         Page : constant String := Response.Message_Body (Result);
      begin
         Check
           (Page,
            Word_Set'(1 => +"Ajouter une nouvelle photo",
                      2 => +"<form",
                      3 => +"/forum/new_photo_entry",
                      4 => +"<input",
                      5 => +"FILENAME",
                      6 => +"<input",
                      7 => +"ENTER",
                      8 => +"submit"),
            "cannot get the add_photo (for uploading) page");
      end Check_Upload_Page;

      --  Upload new photo

      Upload
        (Connection, Result,
         Filename => "./troll.jpg",
         URI      => "/forum/new_photo_entry?FILENAME=troll.jpg");

      Check_Post_Page : declare
         use AUnit.Assertions;
         Page : constant String := Response.Message_Body (Result);
      begin
         Check
           (Page,
            Word_Set'(1 => +"Choisir un forum",
                      2 => +"Forum photographies",
                      3 => +"<select",
                      4 => +"CATEGORY",
                      5 => +"Titre",
                      6 => +"Ajouter un commentaire"),
            "Upload has failed");
      end Check_Post_Page;

      --  Post the photo now into the corresponding forum

      Call
        (Connection, Result,
         URI => Page_Forum_New_Photo_Entry.
           Ajax.onsubmit_pfnpe_new_entry_form_submit & '?'
         & "NAME=Un_Troll&comment_input=un_petit_troll"
         & "&PID=91&CATEGORY=1");

      Check_Forum_Page : declare
         use AUnit.Assertions;
         Page : constant String := Response.Message_Body (Result);
      begin
         Check
           (Page,
            Word_Set'(1 => +"<location",
                      2 => +"/forum/entry?",
                      3 => +"TID",
                      4 => +"142"),
            "Not returned on the proper forum after upload");
      end Check_Forum_Page;

      delay 1.5;
   end Post_New_Photo;

   ----------------------
   -- Post_New_Message --
   ----------------------

   procedure Post_New_Message (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use V2P.Template_Defs;
      Result : Response.Data;
   begin
      Logout (Connection);

      --  Go to the post test page (anonymous)

      Call (Connection, Result, URI => "/forum/new_entry");

      Check_Anonymous_Post_Page : declare
         use AUnit.Assertions;
         Page : constant String := Response.Message_Body (Result);
      begin
         Check
           (Page,
            Word_Set'
              (1 => +"Vous devez être connecté pour poster un message"),
            "Must be connected to post a message");
      end Check_Anonymous_Post_Page;

      --  Go to the post text page (turbo)

      Login (Connection, "turbo", "turbopass");

      Call (Connection, Result, URI => "/forum/new_entry");

      Check_Post_Page : declare
         use AUnit.Assertions;
         Page : constant String := Response.Message_Body (Result);
      begin
         Check
           (Page,
            Word_Set'(1 => +"Poster un nouveau message",
                      2 => +"Choisir un forum",
                      3 => +"<select",
                      4 => +"MatCat1",
                      5 => +"MatCat2",
                      6 => +"ENTER",
                      7 => +"submit"),
            "cannot get the post message page");
      end Check_Post_Page;

      --  Post the message

      Call
        (Connection, Result,
         URI => Page_Forum_New_Text_Entry.
           Ajax.onsubmit_pfnte_new_entry_form_submit & '?'
         & "NAME=""une vente""&comment_input=""une sourie pour DELL M70"""
         & "&CATEGORY=7");

      Check_Forum_Page : declare
         use AUnit.Assertions;
         Page : constant String := Response.Message_Body (Result);
      begin
         Check
           (Page,
            Word_Set'(1 => +"<location",
                      2 => +"/forum/entry?",
                      3 => +"TID",
                      4 => +"143"),
            "Not returned on the proper forum after posting a message");
      end Check_Forum_Page;
   end Post_New_Message;

   --------------------
   -- Register_Tests --
   --------------------

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Main_Page'Access, "main page");
      Register_Routine (T, Check_Post'Access, "check post");
      Register_Routine (T, Post_New_Photo'Access, "post new photo");
      Register_Routine (T, Check_New_Post'Access, "check new post");
      Register_Routine (T, Post_New_Message'Access, "post new message");
      Register_Routine (T, Post_New_Comment'Access, "post new comment");
      Register_Routine (T, Close'Access, "close connection");
   end Register_Tests;

end Web_Tests.Post;
