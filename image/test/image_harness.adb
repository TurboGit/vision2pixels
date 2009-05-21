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

with Ada.Command_Line;

with AUnit;
with AUnit.Run;
with AUnit.Reporter.Text;

with Image_Suite;

procedure Image_Harness is

   use Ada;

   procedure Run is new AUnit.Run.Test_Runner (Suite => Image_Suite);
   Reporter : AUnit.Reporter.Text.Text_Reporter;

begin
   Run (Reporter);
   Command_Line.Set_Exit_Status (Code => Command_Line.Success);
exception
   when others =>
      Command_Line.Set_Exit_Status (Code => Command_Line.Failure);
end Image_Harness;
