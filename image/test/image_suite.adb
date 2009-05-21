------------------------------------------------------------------------------
--                              Vision2Pixels                               --
--                                                                          --
--                         Copyright (C) 2006-2009                          --
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

with AUnit;             use AUnit;
with AUnit.Test_Suites; use AUnit.Test_Suites;

with Image_Tests.Resize;
--  with Image_Tests.Thumbnails;
with Image_Tests.Metadata;
with Image_Tests.Embedded_Metadata;

pragma Style_Checks (Off);

function Image_Suite return Access_Test_Suite is
   Result : Access_Test_Suite := new Test_Suite;
   pragma Warnings (Off, Result);
begin
--   Add_Test (Result, new Image_Tests.Thumbnails.Test_Case);
   Add_Test (Result, new Image_Tests.Resize.Test_Case);
   Add_Test (Result, new Image_Tests.Metadata.Test_Case);
   Add_Test (Result, new Image_Tests.Embedded_Metadata.Test_Case);
   return Result;
end Image_Suite;
