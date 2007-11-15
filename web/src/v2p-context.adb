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

with V2P.Database;
with V2P.Settings;
with V2P.Template_Defs.Set_Global;

package body V2P.Context is

   use V2P;
   use Post_Ids;

   ----------
   -- Next --
   ----------

   function Next
     (Posts : in Post_Ids.Vector;
      Id    : in String) return String
   is
      Current : Cursor := Find (Posts, Id);
   begin
      if Current = No_Element then
         return "";
      end if;

      Next (Current);

      if Current /= No_Element then
         return Element (Current);
      else
         return "";
      end if;
   end Next;

   --------------
   -- Previous --
   --------------

   function Previous
     (Posts : in Post_Ids.Vector;
      Id    : in String) return String
   is
      Current : Cursor := Find (Posts, Id);
   begin
      if Current = No_Element then
         return "";
      end if;

      Previous (Current);

      if Current /= No_Element then
         return Element (Current);
      else
         return "";
      end if;
   end Previous;

   ------------
   -- Update --
   ------------

   procedure Update (Context : access Object; SID : in AWS.Session.Id) is
   begin

      --  Set LOGIN and ADMIN in session

      if AWS.Session.Exist (SID, Template_Defs.Set_Global.LOGIN) then

         if not Context.Exist (Template_Defs.Set_Global.LOGIN) then
            Context.Set_Value
              (Template_Defs.Set_Global.LOGIN,
               AWS.Session.Get (SID, Template_Defs.Set_Global.LOGIN));
         end if;

         if AWS.Session.Exist (SID, Template_Defs.Set_Global.ADMIN) then
            if not Context.Exist (Template_Defs.Set_Global.ADMIN) then
               Context.Set_Value
                 (Template_Defs.Set_Global.ADMIN,
                  AWS.Session.Get (SID, Template_Defs.Set_Global.ADMIN));
            end if;
         end if;
      end if;

      --  Set default filter

      if not Context.Exist (Template_Defs.Set_Global.FILTER) then
         Context.Set_Value
           (Template_Defs.Set_Global.FILTER,
            Database.Filter_Mode'Image (Database.All_Messages));

         Context.Set_Value
           (Template_Defs.Set_Global.FILTER_CATEGORY, "");

         Not_Null_Counter.Set_Value
           (Context => Context.all,
            Name    => Template_Defs.Set_Global.FILTER_PAGE_SIZE,
            Value   => 10);

         Not_Null_Counter.Set_Value
           (Context => Context.all,
            Name    => Template_Defs.Set_Global.NAV_FROM,
            Value   => 1);

         --  Should be in config

         if Settings.Descending_Order then
            Context.Set_Value
              (Template_Defs.Set_Global.ORDER_DIR,
               Database.Order_Direction'Image (Database.DESC));
         else
            Context.Set_Value
              (Template_Defs.Set_Global.ORDER_DIR,
               Database.Order_Direction'Image (Database.ASC));
         end if;
      end if;
   end Update;

end V2P.Context;
