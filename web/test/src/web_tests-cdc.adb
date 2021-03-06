------------------------------------------------------------------------------
--                              Vision2Pixels                               --
--                                                                          --
--                         Copyright (C) 2008-2011                          --
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

with AUnit.Assertions;

with AWS.Client;
with AWS.Response;
with AWS.Utils;

with V2P.Template_Defs.Page_Forum_Threads;
with V2P.Template_Defs.Block_Forum_Filter;
with V2P.Template_Defs.Block_Forum_Filter_Page_Size;

package body Web_Tests.CdC is

   use AWS;

   procedure CdC (T : in out AUnit.Test_Cases.Test_Case'Class);
   --  The very first thing to do is to get the main page

   procedure CdC_Data (T : in out AUnit.Test_Cases.Test_Case'Class);
   --  Check for the CdC data on a given TID

   procedure CdC_Info (T : in out AUnit.Test_Cases.Test_Case'Class);
   --  Check for the CdC info page

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

   ---------------
   -- Main_Page --
   ---------------

   procedure CdC (T : in out AUnit.Test_Cases.Test_Case'Class) is
      Result : Response.Data;
   begin
      Client.Create (Connection, "http://" & Host & ':' & Utils.Image (Port));

      Call (Connection, Result, URI => "/cdc");

      Check_Page : declare
         use AUnit.Assertions;
         Page : constant String := Response.Message_Body (Result);
      begin
         Check
           (Page,
            Word_Set'
              (1 => +"pc_cdc",
               2 => +"/141-",
               3 => +"/67-",
               4 => +"/87-",
               5 => +"/90-",
               6 => +"/99-",
               7 => +"/134-"),
            "wrong entries in the CdC page");
      end Check_Page;
   end CdC;

   --------------
   -- CdC_Data --
   --------------

   procedure CdC_Data (T : in out AUnit.Test_Cases.Test_Case'Class) is
      Result : Response.Data;
   begin
      Call (Connection, Result, URI => "/forum/entry?TID=141");

      Check_Page : declare
         use AUnit.Assertions;
         Page : constant String := Response.Message_Body (Result);
      begin
         Check
           (Page,
            Word_Set'
              (1 => +"bcd_data",
               2 => +" score ",
               3 => +"1.75",
               4 => +" par :",
               5 => +"turbo",
               6 => +"test",
               7 => +"pfe_comments_section"),
            "wrong CdC data for TID 141");
      end Check_Page;
   end CdC_Data;

   --------------
   -- CdC_Info --
   --------------

   procedure CdC_Info (T : in out AUnit.Test_Cases.Test_Case'Class) is
      Result : Response.Data;
   begin
      Call (Connection, Result, URI => "/votes/6");

      Check_Page : declare
         use AUnit.Assertions;
         Page : constant String := Response.Message_Body (Result);
      begin
         Check
           (Page,
            Word_Set'
              (1  => +"Votes pour le CdC",
               2  => +"6",
               3  => +"1.75",
               4  => +"turbo",
               5  => +"test",
               6  => +"1.12",
               7  => +"enzbang",
               8  => +"test",
               9  => +"0.37",
               10 => +"enzbang",
               11 => +"0.37",
               12 => +"enzbang",
               13 => +"0.37",
               14 => +"enzbang",
               15 => +"0.37",
               16 => +"enzbang",
               17 => +"0.37",
               18 => +"enzbang",
               19 => +"0.37",
               20 => +"enzbang",
               21 => +"Votes par utilisateur",
               22 => +"test",
               23 => +"2",
               24 => +"enzbang",
               25 => +"7",
               26 => +"turbo",
               27 => +"1"),
            "wrong CdC info for /votes/6");
      end Check_Page;
   end CdC_Info;

   ----------
   -- Name --
   ----------

   overriding function Name (T : in Test_Case) return Message_String is
   begin
      return Format ("Web_Tests.CdC");
   end Name;

   --------------------
   -- Register_Tests --
   --------------------

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, CdC'Access, "cdc page");
      Register_Routine (T, CdC_Data'Access, "cdc data");
      Register_Routine (T, CdC_Info'Access, "cdc info");
      Register_Routine (T, Close'Access, "close connection");
   end Register_Tests;

end Web_Tests.CdC;
