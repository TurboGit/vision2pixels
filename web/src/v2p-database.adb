------------------------------------------------------------------------------
--                              Vision2Pixels                               --
--                                                                          --
--                         Copyright (C) 2006-2007                          --
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

with Ada.Directories;
with Ada.Exceptions;
with Ada.Task_Attributes;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with DB;
with Settings;

with V2P.Web_Server;
with V2P.DB_Handle;
with V2P.Template_Defs.Forum_Entry;
with V2P.Template_Defs.Comment;
with V2P.Template_Defs.Block_Forum_Threads;
with V2P.Template_Defs.Block_Forum_Navigate;
with V2P.Template_Defs.Block_Forum_List;
with V2P.Template_Defs.Block_Login;
with V2P.Template_Defs.Block_New_Comment;
with V2P.Template_Defs.Block_User_Tmp_Photo_Select;
with V2P.Template_Defs.Block_Metadata;
with V2P.Template_Defs.R_Block_Forum_List;

package body V2P.Database is

   use Ada;
   use Ada.Exceptions;
   use Ada.Strings.Unbounded;

   use V2P.Context;
   use V2P.Template_Defs;

   type TLS_DBH is record
      Handle    : access DB.Handle'Class;
      Connected : Boolean;
   end record;

   Null_DBH : constant TLS_DBH := (null, False);

   package DBH_TLS is new Task_Attributes (TLS_DBH, Null_DBH);

   procedure Connect (DBH : in out TLS_DBH);
   --  Connect to the database if needed

   function F (F : in Float) return String;
   pragma Inline (F);
   --  Returns float image

   function I (Int : in Integer) return String;
   pragma Inline (I);
   --  Returns Integer image

   function Q (Str : in String) return String;
   pragma Inline (Q);
   --  Quote the string and double all single quote in Str to be able to insert
   --  a quote into the database.
   --  Returns Null if empty string

   function Threads_Ordered_Select
     (Fid        : in String := "";
      User       : in String := "";
      From       : in Natural := 0;
      Filter     : in Filter_Mode := All_Messages;
      Where_Cond : in String := "";
      Order_Dir  : in Order_Direction := DESC;
      Limit      : in Natural := 0)
      return Unbounded_String;
   --  Returns the select SQL query for listing threads with Filter

   -------------
   -- Connect --
   -------------

   procedure Connect (DBH : in out TLS_DBH) is
   begin
      if not DBH.Connected then
         DBH.Handle := new DB.Handle'Class'(DB_Handle.Get);
         DBH.Handle.Connect (Settings.Get_DB_Name);
         DBH.Connected := True;
         DBH_TLS.Set_Value (DBH);
      end if;
   end Connect;

   -------
   -- F --
   -------

   function F (F : in Float) return String is
   begin
      return Float'Image (F);
   end F;

   --------------------
   -- Get_Categories --
   --------------------

   function Get_Categories (Fid : in String) return Templates.Translate_Set is
      use type Templates.Tag;
      DBH  : TLS_DBH := DBH_TLS.Value;
      Set  : Templates.Translate_Set;
      Iter : DB.Iterator'Class := DB_Handle.Get_Iterator;
      Line : DB.String_Vectors.Vector;
      Id   : Templates.Tag;
      Name : Templates.Tag;
   begin
      Connect (DBH);

      DBH.Handle.Prepare_Select
        (Iter, "select id, name from category"
         & " where forum_id=" & Q (Fid));

      while Iter.More loop
         Iter.Get_Line (Line);

         Id   := Id & DB.String_Vectors.Element (Line, 1);
         Name := Name & DB.String_Vectors.Element (Line, 2);

         Line.Clear;
      end loop;

      Iter.End_Select;

      Templates.Insert
        (Set, Templates.Assoc (R_Block_Forum_List.CATEGORY_ID, Id));
      Templates.Insert
        (Set, Templates.Assoc (R_Block_Forum_List.CATEGORY, Name));

      return Set;
   end Get_Categories;

   ------------------
   -- Get_Category --
   ------------------

   function Get_Category (Tid : in String) return Templates.Translate_Set is
      use type Templates.Tag;
      DBH  : TLS_DBH := DBH_TLS.Value;
      Set  : Templates.Translate_Set;
      Iter : DB.Iterator'Class := DB_Handle.Get_Iterator;
      Line : DB.String_Vectors.Vector;
      Id   : Templates.Tag;
      Name : Templates.Tag;
   begin
      Connect (DBH);

      DBH.Handle.Prepare_Select
        (Iter, "select id, name from category"
           & " where post.category_id=category.id post.id=" & Q (Tid));

      if Iter.More then
         Iter.Get_Line (Line);

         Id   := Id & DB.String_Vectors.Element (Line, 1);
         Name := Name & DB.String_Vectors.Element (Line, 2);

         Line.Clear;
      end if;

      Iter.End_Select;

      Templates.Insert
        (Set, Templates.Assoc (Block_New_Comment.Category_Id, Id));
      Templates.Insert
        (Set, Templates.Assoc (R_Block_Forum_List.CATEGORY, Name));

      return Set;
   end Get_Category;

   ----------------------------
   -- Get_Category_Full_Name --
   ----------------------------

   function Get_Category_Full_Name (CID : in String) return String is
      DBH  : TLS_DBH := DBH_TLS.Value;
      Iter : DB.Iterator'Class := DB_Handle.Get_Iterator;
      Line : DB.String_Vectors.Vector;
      Name : Unbounded_String;
   begin
      Connect (DBH);

      DBH.Handle.Prepare_Select
        (Iter, "select f.name, c.name from category c, "
           & "forum f where f.id = c.forum_id and c.id = " & Q (CID));

      if Iter.More then
         Iter.Get_Line (Line);

         Name := To_Unbounded_String
           (Directories.Compose
              (DB.String_Vectors.Element (Line, 1),
               DB.String_Vectors.Element (Line, 2)));
         Line.Clear;
      end if;

      Iter.End_Select;

      return To_String (Name);
   end Get_Category_Full_Name;

   -----------------
   -- Get_Comment --
   -----------------

   function Get_Comment (Cid : in String) return Templates.Translate_Set is
      use type Templates.Tag;
      DBH  : TLS_DBH := DBH_TLS.Value;
      Set  : Templates.Translate_Set;
      Iter : DB.Iterator'Class := DB_Handle.Get_Iterator;
      Line : DB.String_Vectors.Vector;

   begin
      Connect (DBH);

      DBH.Handle.Prepare_Select
        (Iter,
         "select strftime('%Y-%m-%dT%H:%M:%SZ', date), "
         & "date(date, 'localtime'), time(date, 'localtime'), "
         & "user_login, anonymous_user, "
         & "comment"
         --  & "(select filename from photo where id=comment.photo_id) "
         --  ??? Filename is not used for now
         & " from comment where id=" & Cid);

      if Iter.More then
         Iter.Get_Line (Line);

         Templates.Insert
           (Set, Templates.Assoc (Template_Defs.Comment.COMMENT_ID, Cid));

         Templates.Insert
           (Set, Templates.Assoc
              (Template_Defs.Comment.DATE_ISO_8601,
               DB.String_Vectors.Element (Line, 1)));

         Templates.Insert
           (Set, Templates.Assoc (Template_Defs.Comment.DATE,
            DB.String_Vectors.Element (Line, 2)));

         Templates.Insert
           (Set, Templates.Assoc (Template_Defs.Comment.TIME,
            DB.String_Vectors.Element (Line, 3)));

         Templates.Insert
           (Set, Templates.Assoc (Template_Defs.Comment.USER,
            DB.String_Vectors.Element (Line, 4)));

         Templates.Insert
           (Set, Templates.Assoc
              (Template_Defs.Comment.ANONYMOUS_USER,
               DB.String_Vectors.Element (Line, 5)));

         Templates.Insert
           (Set, Templates.Assoc (Template_Defs.Comment.COMMENT,
            DB.String_Vectors.Element (Line, 6)));
         Line.Clear;
      end if;

      Iter.End_Select;
      return Set;
   end Get_Comment;

   ---------------
   -- Get_Entry --
   ---------------

   function Get_Entry (Tid : in String) return Templates.Translate_Set is
      use type Templates.Tag;
      DBH                : TLS_DBH := DBH_TLS.Value;
      Set                : Templates.Translate_Set;
      Iter               : DB.Iterator'Class := DB_Handle.Get_Iterator;
      Line               : DB.String_Vectors.Vector;
      Comment_Id         : Templates.Tag;
      Comment_Level      : Templates.Tag;
      Nb_Levels_To_Close : Templates.Tag;
      User               : Templates.Tag;
      Anonymous          : Templates.Tag;
      Date_Iso_8601      : Templates.Tag;
      Date               : Templates.Tag;
      Time               : Templates.Tag;
      Comment            : Templates.Tag;
      Filename           : Templates.Tag;

   begin
      Connect (DBH);

      --  Get thread information

      DBH.Handle.Prepare_Select
        (Iter, "select post.name, post.comment, "
         & "(select filename from photo where id=post.photo_id)"
         & "from post where "
         & "post.id=" & Q (Tid));

      if Iter.More then
         Iter.Get_Line (Line);

         Templates.Insert
           (Set, Templates.Assoc
              (Forum_Entry.NAME, DB.String_Vectors.Element (Line, 1)));

         Templates.Insert
           (Set, Templates.Assoc
              (Forum_Entry.IMAGE_COMMENT,
               DB.String_Vectors.Element (Line, 2)));

         Templates.Insert
           (Set, Templates.Assoc
              (Forum_Entry.IMAGE_SOURCE_PREFIX,
               V2P.Web_Server.Images_Source_Prefix));

         --  Insert the image path

         Templates.Insert
           (Set, Templates.Assoc
              (Forum_Entry.IMAGE_SOURCE,
               DB.String_Vectors.Element (Line, 3)));
         Line.Clear;
      end if;

      Iter.End_Select;

      --  Get threads

      DBH.Handle.Prepare_Select
        (Iter,
         "select comment.id, strftime('%Y-%m-%dT%H:%M:%SZ', date), "
         & "date(date, 'localtime'), time(date, 'localtime'), "
         & "user_login, anonymous_user, "
         & "comment, "
         & "(select filename from photo where id=comment.photo_id) "
         & " from comment, post_comment"
         & " where post_id=" & Q (Tid)
         & " and post_comment.comment_id=comment.id");

      while Iter.More loop
         Iter.Get_Line (Line);

         Comment_Id    := Comment_Id & DB.String_Vectors.Element (Line, 1);
         Date_Iso_8601 := Date_Iso_8601 & DB.String_Vectors.Element (Line, 2);
         Date          := Date &  DB.String_Vectors.Element (Line, 3);
         Time          := Time   & DB.String_Vectors.Element (Line, 4);
         User          := User       & DB.String_Vectors.Element (Line, 5);
         Anonymous     := Anonymous  & DB.String_Vectors.Element (Line, 6);
         Comment       := Comment & DB.String_Vectors.Element (Line, 7);
         Filename      := Filename & DB.String_Vectors.Element (Line, 8);

         --  Unthreaded view

         Comment_Level      := Comment_Level      & 1;
         Nb_Levels_To_Close := Nb_Levels_To_Close & 1;

         Line.Clear;
      end loop;

      Iter.End_Select;

      Templates.Insert
        (Set, Templates.Assoc (Template_Defs.Comment.COMMENT_ID, Comment_Id));
      Templates.Insert
        (Set, Templates.Assoc
           (Template_Defs.Comment.DATE_ISO_8601, Date_Iso_8601));
      Templates.Insert
        (Set, Templates.Assoc (Template_Defs.Comment.DATE, Date));
      Templates.Insert
        (Set, Templates.Assoc (Template_Defs.Comment.TIME, Time));
      Templates.Insert
        (Set, Templates.Assoc (Template_Defs.Comment.USER, User));
      Templates.Insert
        (Set, Templates.Assoc
           (Template_Defs.Comment.ANONYMOUS_USER, Anonymous));
      Templates.Insert
        (Set, Templates.Assoc (Template_Defs.Comment.COMMENT, Comment));
      Templates.Insert
        (Set, Templates.Assoc (Forum_Entry.COMMENT_LEVEL, Comment_Level));
      Templates.Insert
        (Set,
         Templates.Assoc (Forum_Entry.NB_LEVELS_TO_CLOSE, Nb_Levels_To_Close));

      return Set;
   end Get_Entry;

   ---------------
   -- Get_Forum --
   ---------------

   function Get_Forum (Fid : in String) return String is
      DBH  : TLS_DBH := DBH_TLS.Value;
      Iter : DB.Iterator'Class := DB_Handle.Get_Iterator;
      Line : DB.String_Vectors.Vector;
   begin
      Connect (DBH);

      DBH.Handle.Prepare_Select
        (Iter, "select name from forum where id=" & Q (Fid));

      if Iter.More then
         Iter.Get_Line (Line);

         declare
            Name : constant String := DB.String_Vectors.Element (Line, 1);
         begin
            Line.Clear;
            Iter.End_Select;
            return Name;
         end;

      else
         Iter.End_Select;
         return "";
      end if;
   end Get_Forum;

   ----------------
   -- Get_Forums --
   ----------------

   function Get_Forums return Templates.Translate_Set is
      use type Templates.Tag;

      DBH  : TLS_DBH := DBH_TLS.Value;
      Set  : Templates.Translate_Set;
      Iter : DB.Iterator'Class := DB_Handle.Get_Iterator;
      Line : DB.String_Vectors.Vector;
      Id   : Templates.Tag;
      Name : Templates.Tag;
   begin
      Connect (DBH);

      DBH.Handle.Prepare_Select (Iter, "select id, name from forum");

      while Iter.More loop
         Iter.Get_Line (Line);

         Id   := Id & DB.String_Vectors.Element (Line, 1);
         Name := Name & DB.String_Vectors.Element (Line, 2);

         Line.Clear;
      end loop;

      Iter.End_Select;

      Templates.Insert (Set, Templates.Assoc (Block_Forum_List.FID, Id));
      Templates.Insert
        (Set, Templates.Assoc (Block_Forum_List.FORUM_NAME, Name));

      return Set;
   end Get_Forums;

   ------------------
   -- Get_Metadata --
   ------------------

   function Get_Metadata (Pid : in String) return Templates.Translate_Set is
      use type Templates.Tag;

      DBH  : TLS_DBH := DBH_TLS.Value;
      Iter : DB.Iterator'Class := DB_Handle.Get_Iterator;
      Line : DB.String_Vectors.Vector;
      Set  : Templates.Translate_Set;

   begin
      if Pid = "" then
         --  ???
         return Set;
      end if;

      Connect (DBH);

      DBH.Handle.Prepare_Select
        (Iter, "select geo_latitude, geo_longitude, "
         & "geo_latitude_formatted, geo_longitude_formatted "
         & "from photo_metadata "
         & "where photo_id = (select photo_id from post where id=" & Pid
         & ')');

      if Iter.More then
         Iter.Get_Line (Line);

         Templates.Insert
           (Set, Templates.Assoc
              (Block_Metadata.METADATA_LATITUDE,
               DB.String_Vectors.Element (Line, 1)));

         Templates.Insert
           (Set, Templates.Assoc
              (Block_Metadata.METADATA_LONGITUDE,
               DB.String_Vectors.Element (Line, 2)));

         Templates.Insert
           (Set, Templates.Assoc
              (Block_Metadata.METADATA_LATITUDE_FORMATTED,
               DB.String_Vectors.Element (Line, 3)));

         Templates.Insert
           (Set, Templates.Assoc
              (Block_Metadata.METADATA_LONGITUDE_FORMATTED,
               DB.String_Vectors.Element (Line, 4)));

         Line.Clear;
      end if;

      Iter.End_Select;
      return Set;
   end Get_Metadata;

   ------------------
   -- Get_Password --
   ------------------

   function Get_Password (Uid : in String) return String is
      use type Templates.Tag;

      DBH  : TLS_DBH := DBH_TLS.Value;
      Iter : DB.Iterator'Class := DB_Handle.Get_Iterator;
      Line : DB.String_Vectors.Vector;
   begin
      if Uid = "" then
         return "";
      end if;

      Connect (DBH);

      DBH.Handle.Prepare_Select
        (Iter, "select password from user where login=" & Q (Uid));

      if Iter.More then
         Iter.Get_Line (Line);

         declare
            Password : constant String := DB.String_Vectors.Element (Line, 1);
         begin
            Line.Clear;
            return Password;
         end;

      else
         return "";
      end if;
   end Get_Password;

   -----------------
   -- Get_Threads --
   -----------------

   procedure Get_Threads
     (Fid        : in String := "";
      User       : in String := "";
      From       : in Natural := 0;
      Filter     : in Filter_Mode := All_Messages;
      Order_Dir  : in Order_Direction := DESC;
      Navigation : out Post_Ids.Vector;
      Set        : out Templates.Translate_Set)
   is
      use type Templates.Tag;
      use Post_Ids;

      DBH             : TLS_DBH := DBH_TLS.Value;
      Iter            : DB.Iterator'Class := DB_Handle.Get_Iterator;
      Line            : DB.String_Vectors.Vector;
      Id              : Templates.Tag;
      Name            : Templates.Tag;
      Category        : Templates.Tag;
      Comment_Counter : Templates.Tag;
      Visit_Counter   : Templates.Tag;
      Thumb           : Templates.Tag;
      Select_Stmt     : Unbounded_String;

   begin
      Navigation := Post_Ids.Empty_Vector;

      Connect (DBH);

      Select_Stmt := Threads_Ordered_Select
        (Fid       => Fid,
         User      => User,
         From      => From,
         Filter    => Filter,
         Order_Dir => Order_Dir);

      if Filter = Fifty_Messages then
         --  ???

         --  Add next and previous information into the translate set

         if From /= 0 then
            Templates.Insert
              (Set, Templates.Assoc
                 (Block_Forum_Navigate.PREVIOUS, From - 50));
         end if;

         --  ??? need to check if there is more data !
         Templates.Insert
           (Set, Templates.Assoc
              (Block_Forum_Navigate.NEXT, From + 50));
      end if;

      DBH.Handle.Prepare_Select (Iter, To_String (Select_Stmt));

      while Iter.More loop
         Iter.Get_Line (Line);

         Id              := Id       & DB.String_Vectors.Element (Line, 1);
         Name            := Name     & DB.String_Vectors.Element (Line, 2);
         Thumb           := Thumb    & DB.String_Vectors.Element (Line, 3);
         Category        := Category & DB.String_Vectors.Element (Line, 4);
         Comment_Counter := Comment_Counter
           & DB.String_Vectors.Element (Line, 5);
         Visit_Counter   := Visit_Counter
           & DB.String_Vectors.Element (Line, 6);

         --  Insert this post id in navigation links

         Navigation := Navigation
           & To_Unbounded_String (DB.String_Vectors.Element (Line, 1));

         Line.Clear;
      end loop;

      Iter.End_Select;

      Templates.Insert
        (Set, Templates.Assoc ("THUMB_SOURCE", Thumb));

      Templates.Insert (Set, Templates.Assoc (Block_Forum_Threads.TID, Id));
      Templates.Insert (Set, Templates.Assoc (Block_Forum_Threads.NAME, Name));
      Templates.Insert
        (Set, Templates.Assoc (Block_Forum_Threads.CATEGORY, Category));
      Templates.Insert
        (Set, Templates.Assoc
           (Block_Forum_Threads.COMMENT_COUNTER, Comment_Counter));
      Templates.Insert
        (Set, Templates.Assoc
           (Block_Forum_Threads.VISIT_COUNTER, Visit_Counter));
   end Get_Threads;

   -------------------
   -- Get_Thumbnail --
   -------------------

   function Get_Thumbnail (Post : in String) return String is
      DBH      : TLS_DBH := DBH_TLS.Value;
      Iter     : DB.Iterator'Class := DB_Handle.Get_Iterator;
      Line     : DB.String_Vectors.Vector;
      Filename : Unbounded_String;
   begin
      Connect (DBH);

      DBH.Handle.Prepare_Select
        (Iter, "select filename from photo, post "
         & "where photo.id = post.photo_id and post.id = " & Post);

      if Iter.More then
         Iter.Get_Line (Line);

         Filename := To_Unbounded_String (DB.String_Vectors.Element (Line, 1));

         Line.Clear;
      end if;

      Iter.End_Select;

      return To_String (Filename);
   end Get_Thumbnail;

   --------------
   -- Get_User --
   --------------

   function Get_User (Uid : in String) return Templates.Translate_Set is
      use type Templates.Tag;

      Set : Templates.Translate_Set;
   begin
      Templates.Insert
        (Set, Templates.Assoc (Block_Login.LOGIN, Uid));
      Templates.Insert
        (Set, Templates.Assoc (Block_Login.HTTP.PASSWORD, Get_Password (Uid)));

      return Set;
   end Get_User;

   function Get_User_Tmp_Photo
     (Uid : in String) return Templates.Translate_Set
   is
      use type Templates.Tag;

      DBH          : TLS_DBH := DBH_TLS.Value;
      Set          : Templates.Translate_Set;
      Iter         : DB.Iterator'Class := DB_Handle.Get_Iterator;
      Line         : DB.String_Vectors.Vector;
      Tmp_Id       : Templates.Tag;
      Tmp_Filename : Templates.Tag;
   begin
      Connect (DBH);

      DBH.Handle.Prepare_Select
        (Iter, "select photo_id, filename from user_tmp_photo, photo "
         & "where photo.id = photo_id and user_login=" & Q (Uid));

      while Iter.More loop
         Iter.Get_Line (Line);
         Tmp_Id       := Tmp_Id       & DB.String_Vectors.Element (Line, 1);
         Tmp_Filename := Tmp_Filename & DB.String_Vectors.Element (Line, 2);

         Line.Clear;
      end loop;

      Iter.End_Select;

      Templates.Insert
        (Set, Templates.Assoc (Block_User_Tmp_Photo_Select.TMP_ID, Tmp_Id));
      Templates.Insert
        (Set, Templates.Assoc
           (Block_User_Tmp_Photo_Select.TMP_FILENAME, Tmp_Filename));

      return Set;

   end Get_User_Tmp_Photo;

   -------
   -- I --
   -------

   function I (Int : in Integer) return String is
   begin
      return Integer'Image (Int);
   end I;

   -----------------------------
   -- Increment_Visit_Counter --
   -----------------------------

   procedure Increment_Visit_Counter (Pid : in String) is
      DBH : TLS_DBH := DBH_TLS.Value;
      SQL : constant String :=
              "update post set visit_counter = visit_counter + 1 where "
                & "id = " & Q (Pid);
   begin
      Connect (DBH);
      DBH.Handle.Execute (SQL);
   end Increment_Visit_Counter;

   --------------------
   -- Insert_Comment --
   --------------------

   function  Insert_Comment
     (Uid       : in String;
      Anonymous : in String;
      Thread    : in String;
      Name      : in String;
      Comment   : in String;
      Pid       : in String) return String
   is
      pragma Unreferenced (Name);

      procedure Insert_Table_Comment
        (User_Login, Anonymous, Comment : in String);
      --  Insert row into Comment table

      procedure Insert_Table_Post_Comment (post_Id, Comment_Id : in String);
      --  Insert row into post_Comment table

      DBH : TLS_DBH := DBH_TLS.Value;

      --------------------------
      -- Insert_Table_Comment --
      --------------------------

      procedure Insert_Table_Comment
        (User_Login, Anonymous, Comment : in String)
      is
         SQL : constant String :=
                 "insert into comment ('user_login', 'anonymous_user', "
                   & "'comment', 'photo_id')"
                   & " values ("
                   & Q (User_Login) & ',' & Q (Anonymous) & ',' & Q (Comment)
                   & ',' & Q (Pid) & ')';
      begin
         DBH.Handle.Execute (SQL);
      end Insert_Table_Comment;

      --------------------------------
      -- Insert_Table_post_Comment --
      --------------------------------

      procedure Insert_Table_Post_Comment
        (post_Id, Comment_Id : in String)
      is
         SQL : constant String :=
                 "insert into post_comment values ("
                   & post_Id & "," & Comment_Id & ')';
      begin
         DBH.Handle.Execute (SQL);
      end Insert_Table_Post_Comment;

   begin
      Connect (DBH);
      DBH.Handle.Begin_Transaction;
      Insert_Table_Comment (Uid, Anonymous, Comment);

      declare
         Cid : constant String := DBH.Handle.Last_Insert_Rowid;
      begin
         Insert_Table_Post_Comment (Thread, Cid);
         DBH.Handle.Commit;
         return Cid;
      end;
   exception
      when E : DB.DB_Error =>
         DBH.Handle.Rollback;
         Text_IO.Put_Line (Exception_Message (E));
         return "";
   end Insert_Comment;

   ---------------------
   -- Insert_Metadata --
   ---------------------

   procedure Insert_Metadata
     (Pid                     : in String;
      Geo_Latitude            : in Float;
      Geo_Longitude           : in Float;
      Geo_Latitude_Formatted  : in String;
      Geo_Longitude_Formatted : in String)
   is
      DBH : TLS_DBH := DBH_TLS.Value;

      SQL : constant String := "insert into photo_metadata (photo_id, "
        & "geo_latitude, geo_longitude, geo_latitude_formatted, "
        & "geo_longitude_formatted) values ("
        & "(select photo_id from post where id=" & Pid & "), "
        & F (Geo_Latitude) & ", " & F (Geo_Longitude) & ", "
        & Q (Geo_Latitude_Formatted) & ", "
        & Q (Geo_Longitude_Formatted) & ")";
   begin
      Connect (DBH);
      DBH.Handle.Execute (SQL);
   exception
      when E : DB.DB_Error =>
         Text_IO.Put_Line (Exception_Message (E));
   end Insert_Metadata;



   ------------------
   -- Insert_Photo --
   ------------------

   function Insert_Photo
     (Uid         : in String;
      Filename    : in String;
      Height      : in Integer;
      Width       : in Integer;
      Size        : in Integer) return String
   is

      procedure Insert_Table_Photo
        (Filename : in String;
         Height   : in Integer;
         Width    : in Integer;
         Size     : in Integer);
      --  Insert row into the photo table

      procedure Insert_Table_User_Tmp_Photo (Uid, Pid : in String);
      --  Insert row into the user_tmp_photo table

      DBH : TLS_DBH := DBH_TLS.Value;

      ------------------------
      -- Insert_Table_Photo --
      ------------------------

      procedure Insert_Table_Photo
        (Filename : in String;
         Height   : in Integer;
         Width    : in Integer;
         Size     : in Integer) is
         SQL : constant String :=
           "insert into photo ('filename', 'height', 'width', 'size') "
           & "values (" & Q (Filename) & ',' & I (Height) & ','
           & I (Width) & ',' & I (Size) & ')';
      begin
         DBH.Handle.Execute (SQL);
      end Insert_Table_Photo;

      procedure Insert_Table_User_Tmp_Photo (Uid, Pid : in String) is
         SQL : constant String :=
           "insert into user_tmp_photo values (" & Q (Uid) & ','
           & Pid & ')';
      begin
         DBH.Handle.Execute (SQL);
      end Insert_Table_User_Tmp_Photo;

   begin
      Connect (DBH);

      DBH.Handle.Begin_Transaction;

      Insert_Table_Photo (Filename, Height, Width, Size);

      --  ??? A limit should be added for user temporaries photos

      declare
         Pid : constant String := DBH.Handle.Last_Insert_Rowid;
      begin
         Insert_Table_User_Tmp_Photo (Uid, Pid);
         DBH.Handle.Commit;
         return Pid;
      end;
   exception
      when others =>
         DBH.Handle.Rollback;
         return "";
   end Insert_Photo;

   -----------------
   -- Insert_Post --
   -----------------

   function Insert_Post
     (Uid         : in String;
      Category_Id : in String;
      Name        : in String;
      Comment     : in String;
      Pid         : in String) return String
   is
      procedure Insert_Table_Post
        (Name, Category_Id, Comment, Photo_Id : in String);
      --  Insert row into the post table

      procedure Insert_Table_User_Post (Uid, Post_Id : in String);
      --  Insert row into the user_post table

      DBH : TLS_DBH := DBH_TLS.Value;

      ------------------------
      -- Insert_Table_post --
      ------------------------

      procedure Insert_Table_Post
        (Name, Category_Id, Comment, Photo_Id : in String)
      is
         SQL : constant String :=
                 "insert into post ('name', 'comment', 'category_id',"
                   & "'template_id', 'visit_counter', 'comment_counter',"
                   & "'photo_id') values (" & Q (Name) &  ',' & Q (Comment)
                   & ',' & Category_Id & ", 1, 0, 0," & Photo_Id & ')';
      begin
         DBH.Handle.Execute (SQL);
      end Insert_Table_Post;

      -----------------------------
      -- Insert_Table_User_post --
      -----------------------------

      procedure Insert_Table_User_Post (Uid, Post_Id : in String) is
         SQL : constant String :=
                 "insert into user_post values ("
                   & Q (Uid) & ',' & Post_Id & ")";
      begin
         DBH.Handle.Execute (SQL);
      end Insert_Table_User_Post;

   begin
      Connect (DBH);

      DBH.Handle.Begin_Transaction;

      if Pid /= "" then
         Insert_Table_Post (Name, Category_Id, Comment, Pid);
      else
         Insert_Table_Post (Name, Category_Id, Comment, "NULL");
      end if;

      declare
         Post_Id : constant String :=
           DBH.Handle.Last_Insert_Rowid;
      begin
         Insert_Table_User_Post (Uid, Post_Id);
         DBH.Handle.Commit;
         return Post_Id (Post_Id'First + 1 .. Post_Id'Last);
      end;

   exception
      when E : DB.DB_Error =>
         DBH.Handle.Rollback;
         Text_IO.Put_Line (Exception_Message (E));
         return "";
      when E : others =>
         DBH.Handle.Rollback;
         Text_IO.Put_Line (Exception_Message (E));
         return "";
   end Insert_Post;

   ---------------
   -- Is_Author --
   ---------------

   function Is_Author (Uid, Pid : in String) return Boolean is
      DBH    : TLS_DBH := DBH_TLS.Value;
      Iter   : DB.Iterator'Class := DB_Handle.Get_Iterator;
      Result : Boolean := False;
   begin
      Connect (DBH);

      --  Get post Pid posted by user Uid

      DBH.Handle.Prepare_Select
        (Iter,
         "select * from user_post where post_id  = "
           & Q (Pid) & " and user_login = " & Q (Uid));

      if Iter.More then
         Result := True;
      end if;

      Iter.End_Select;

      return Result;
   end Is_Author;

   -------
   -- Q --
   -------

   function Q (Str : in String) return String is
      S : String (1 .. 2 + Str'Length * 2);
      J : Positive := S'First;
   begin
      if Str = "" then
         return "NULL";
      end if;

      S (J) := ''';

      for K in Str'Range loop
         if Str (K) = ''' then
            J := J + 1;
            S (J) := ''';
         end if;
         J := J + 1;
         S (J) := Str (K);
      end loop;

      J := J + 1;
      S (J) := ''';

      return S (1 .. J);
   end Q;

   ----------------------------
   -- Threads_Ordered_Select --
   ----------------------------

   function Threads_Ordered_Select
     (Fid        : in String  := "";
      User       : in String  := "";
      From       : in Natural := 0;
      Filter     : in Filter_Mode := All_Messages;
      Where_Cond : in String  := "";
      Order_Dir  : in Order_Direction := DESC;
      Limit      : in Natural := 0) return Unbounded_String
   is
      SQL_Select  : constant String :=
                      "select post.id, post.name, "
                        & "(select filename from photo "
                        & "Where Id = Post.Photo_Id)"
                        & ", category.name, comment_counter,"
                        & "visit_counter ";
      SQL_From    : constant String := " from post, category";
      SQL_Where   : constant String :=
                      " where post.category_id = category.id " & Where_Cond;
      Ordering    : constant String :=
                      " order by post.date_post "
                      & Order_Direction'Image (Order_Dir);

      Select_Stmt : Unbounded_String := To_Unbounded_String ("");
   begin
      if User /= "" and then Fid /= "" then
         --  ???

         Select_Stmt := Select_Stmt & SQL_Select & SQL_From & ", user_post"
           & SQL_Where
           & "and category.forum_id = " & Q (Fid)
           & "and user_post.post_id = post.id"
           & "and user_post.user_id = " & Q (User);

      elsif User /= "" and then Fid = "" then
         --  ???

         Select_Stmt := Select_Stmt & SQL_Select & SQL_From & ", user_post "
           & SQL_Where
           & " and user_post.post_id = post.id "
           & " and user_post.user_login = " & Q (User);

      else
         --  Anonymous login

         Select_Stmt := Select_Stmt & SQL_Select & SQL_From
           & SQL_Where & " and category.forum_id = " & Q (Fid);
      end if;

      --  Add filtering into the select statement

      case Filter is
         when Today =>
            Select_Stmt := Select_Stmt
              & " and date(post.date_post) = date(current_date)"
              & Ordering;

         when Two_Days =>
            Select_Stmt := Select_Stmt
              & " and date(post.date_post) > date(current_date, '-2 days')"
              & Ordering;

         when Seven_Days =>
            Select_Stmt := Select_Stmt
              & " and date(post.date_post) > date(current_date, '-7 days')"
              & Ordering;

         when Fifty_Messages =>
            Select_Stmt := Select_Stmt & Ordering;

            if Limit = 0 then
               Select_Stmt := Select_Stmt
                 & " limit 50 offset" & Positive'Image (From);
            end if;

         when All_Messages =>
            Select_Stmt := Select_Stmt & Ordering;
      end case;

      if Limit /= 0 then
         Select_Stmt := Select_Stmt & " limit " & Natural'Image (Limit);
      end if;

      return Select_Stmt;
   end Threads_Ordered_Select;

end V2P.Database;
