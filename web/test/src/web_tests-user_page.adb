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

with AWS.Client;
with AWS.Response;
with AWS.Utils;

package body Web_Tests.User_Page is

   procedure Turbo_Page (T : in out AUnit.Test_Cases.Test_Case'Class);
   --  User's obry page

   procedure Close (T : in out AUnit.Test_Cases.Test_Case'Class);
   --  Close the Web connection

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

   ----------
   -- Name --
   ----------

   overriding function Name (T : in Test_Case) return Message_String is
   begin
      return Format ("Web_Tests.User_Page");
   end Name;

   ----------------
   -- Turbo_Page --
   ----------------

   procedure Turbo_Page (T : in out AUnit.Test_Cases.Test_Case'Class) is
      Result : Response.Data;
   begin
      Client.Create (Connection, "http://" & Host & ':' & Utils.Image (Port));

      Call (Connection, Result, URI => "/");

      Web_Tests.Login (Connection, "turbo", "turbopass");

      Call (Connection, Result, URI => "/~turbo");

      Check
        (Response.Message_Body (Result),
         Word_Set'(+"Forum photographies", +"Forum mat",
           +"20 photographies", +"15 messages", +"9 commentaires",
           +"3 coups-de", +"diter votre page",
           +"/67-", +"/66-", +"/65-", +"/64-", +"/75-",
           +"/74-", +"/73-", +"/72-", +"/71-", +"/70-",
           not ">#17", not ">#19", +">#21", +">#20"),
         "wrong content for obry's personal page:");
   end Turbo_Page;

   --------------------
   -- Register_Tests --
   --------------------

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Turbo_Page'Access, "turbo page");
      Register_Routine (T, Close'Access, "close connection");
   end Register_Tests;

end Web_Tests.User_Page;
