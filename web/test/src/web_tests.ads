------------------------------------------------------------------------------
--                              Vision2Pixels                               --
--                                                                          --
--                         Copyright (C) 2006-2008                          --
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

with Ada.Strings.Unbounded;
with AWS.Client;

package Web_Tests is

   use Ada.Strings.Unbounded;
   use AWS;

   Host : constant String := "127.0.0.10";
   --  v2p web server host

   Port : constant := 8042;
   --  v2p web server port

   type Word_Set is array (Positive range <>) of Unbounded_String;

   procedure Check (Page : in String; Word : in Word_Set; Message : in String);
   --  Does nothing if the set of Word appears (in the right order) in Page.
   --  Otherwise it raises an AUnit assertion and log the web page.

   function Get (Page, Regpat : in String; Index : in Positive) return String;
   --  Returns the Index-th match for regpat in Page or the null string if not
   --  found.

   function "+"
     (Str : in String)
      return Unbounded_String
      renames To_Unbounded_String;

   function "not" (Word : in String) return Unbounded_String;
   --  A word that should not be found into the results, this is intended to be
   --  used to build a Word_Set.

   --  V2P common routines

   procedure Login
     (Connection     : in out Client.HTTP_Connection;
      User, Password : in     String);
   --  Login the specified user

   function Login_Parameters (Login, Password : in String) return String;
   --  Returns the HTTP login parameters

   procedure Logout (Connection : in out Client.HTTP_Connection);
   --  Logout current connected user

   procedure Set_Context (Page : in String := "");
   --  Set context from page content, if Page is empty string the context is
   --  deleted.

   function URL_Context return String;
   --  Returns the context as an HTTP URL parameter

end Web_Tests;
