------------------------------------------------------------------------------
--                                                                          --
--                          PolyORB HI COMPONENTS                           --
--                                                                          --
--                                 P I N G                                  --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--    Copyright (C) 2008-2009 Telecom ParisTech, 2010-2015 ESA & ISAE.      --
--                                                                          --
-- PolyORB-HI is free software; you can redistribute it and/or modify under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion. PolyORB-HI is distributed in the hope that it will be useful, but  --
-- WITHOUT ANY WARRANTY; without even the implied warranty of               --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     --
--                                                                          --
-- As a special exception under Section 7 of GPL version 3, you are granted --
-- additional permissions described in the GCC Runtime Library Exception,   --
-- version 3.1, as published by the Free Software Foundation.               --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
--              PolyORB-HI/Ada is maintained by the TASTE project           --
--                      (taste-users@lists.tuxfamily.org)                   --
--                                                                          --
------------------------------------------------------------------------------

--  $Id: ping.adb 6936 2009-08-18 15:33:06Z lanarre $

with PolyORB_HI.Output;
with User_Types;

package body Ping is

   use PolyORB_HI.Output;
   use User_Types;

   Var   : Simple_Type := 0;
   Var2  : Simple_Type := 0;
   Order : Opaque_Type := False;

   -----------------
   -- Do_Ping_Spg --
   -----------------

   procedure Do_Ping_Spg (Data_Source : out Opaque_Type) is
   begin
      Order := not Order;
      Data_Source := Order;
      Put_Line (Normal, "Sending ORDER: " & Opaque_Type'Image (Order));
   end Do_Ping_Spg;

   --------------------
   -- Do_Convert_Spg --
   --------------------

   procedure Do_Convert_Spg
     (Data_Sink   :     Opaque_Type;
      Data_Source : out Simple_type)
   is
   begin
      Put_Line (Normal, "ORDER: " & Opaque_Type'Image (Data_Sink));

      Var := Var + 1;
      Put_Line (Normal, "Sending (+1) PING" & Simple_Type'Image (Var));

      Data_Source := Var;
   end Do_Convert_Spg;

   ---------------------
   -- Do_Convert_Spg2 --
   ---------------------

   procedure Do_Convert_Spg2
     (Data_Sink   :     Opaque_Type;
      Data_Source : out Simple_type)
   is
   begin
      Put_Line (Normal, "ORDER: " & Opaque_Type'Image (Data_Sink));

      Var2 := Var2 + 5;
      Put_Line (Normal, "Sending (+5) PING" & Simple_Type'Image (Var2));

      Data_Source := Var2;
   end Do_Convert_Spg2;

end Ping;
