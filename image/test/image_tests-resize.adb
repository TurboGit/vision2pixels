------------------------------------------------------------------------------
--                              Vision2Pixels                               --
--                                                                          --
--                            Copyright (C) 2008                            --
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

with Ada.Calendar;
with Ada.Directories;

with GNAT.Calendar.Time_IO;

with V2P.Settings;

with Image.Data;
with MagickWand;

package body Image_Tests.Resize is

   use Ada;
   use Ada.Directories;
   use V2P;

   use AUnit.Test_Cases.Registration;
   use AUnit.Assertions;

   procedure Create_Resized_Image
     (T : in out AUnit.Test_Cases.Test_Case'Class);
   --  Create Resized Images

   --------------------------
   -- Create_Resized_Image --
   --------------------------

   procedure Create_Resized_Image
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Image.Data;
      S_Name          : constant String := "gnu.jpg";
      Now             : constant Calendar.Time := Calendar.Clock;
      Year            : constant String :=
                          GNAT.Calendar.Time_IO.Image (Now, "%Y");
      Filename_Prefix : constant String :=
                          GNAT.Calendar.Time_IO.Image (Now, "%Y%m%d%H%M-");
      Thumb_Name      : constant String := Compose
        (Containing_Directory => Compose
           (Containing_Directory => Settings.Get_Thumbs_Path,
            Name                 => Year),
         Name                 => Filename_Prefix & S_Name);
      Test_Image      : Image.Data.Image_Data;

   begin
      --  Read image info and create resized image
      Image.Data.Init (Img => Test_Image, Root_Dir => ".", Filename => S_Name);

      Assert (Test_Image.Init_Status = Image_Created,
              "Error. Test_Image has not been created");

      Assert
        (Ada.Directories.Exists (Thumb_Name),
         Thumb_Name & "does not exist");
   end Create_Resized_Image;

   ----------
   -- Name --
   ----------

   function Name (T : in Test_Case) return Message_String is
      pragma Unreferenced (T);
   begin
      return New_String ("Create medium image size");
   end Name;

   --------------------
   -- Register_Tests --
   --------------------

   procedure Register_Tests (T : in out Test_Case) is
   begin
      Register_Routine (T, Create_Resized_Image'Access,
                        "Create medium size images");
   end Register_Tests;

   ---------------
   -- Tear_Down --
   ---------------

   procedure Tear_Down (T : in out Test_Case) is
      pragma Unreferenced (T);
   begin
      MagickWand.Terminus;
   end Tear_Down;

end Image_Tests.Resize;
