------------------------------------------------------------------------------
--                              Vision2Pixels                               --
--                                                                          --
--                           Copyright (C) 2006                             --
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
--  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.          --
------------------------------------------------------------------------------

with Ada.Finalization;
with G2F;
with G2F.IO;

package Image is

   type Image_Data is private;

   Thumbnail_Size : constant G2F.IO.Image_Size := (150, 150);

   procedure Initialize (Img : in out Image_Data);
   --  Initialize Image_Ptr and Image_Info_Ptr structures

   procedure Finalize (Img : in Image_Data);
   --  Destroys Image

   procedure Init_Image_Data (Img : in out Image_Data; Filename : in String);
   --  Set image filename, read image info and create thumbnail

private

   type Image_Data is new Ada.Finalization.Controlled with
      record
         Info_Ptr  : G2F.Image_Info_Ptr;
         Image_Ptr : G2F.Image_Ptr;
      end record;

end Image;
