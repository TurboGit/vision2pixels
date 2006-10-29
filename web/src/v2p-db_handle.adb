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

with DB.SQLite;

package body V2P.DB_Handle is

   ---------
   -- Get --
   ---------

   function Get return DB.Handle'Class is
      H : DB.SQLite.Handle;
   begin
      return H;
   end Get;

   ------------------
   -- Get_Iterator --
   ------------------

   function Get_Iterator return DB.Iterator'Class is
      I : DB.SQLite.Iterator;
      pragma Warnings (Off, I);
   begin
      return I;
   end Get_Iterator;

end V2P.DB_Handle;
