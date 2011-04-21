pragma Style_Checks (Off);

With Interfaces;
with Ada.Unchecked_Conversion;

with Uart.Core; use type UART.Core.UART_Device;
with Uart.HLInterface;
with Uart.Streams;

with PolyORB_HI.Output;
with PolyORB_HI.Messages;

with PolyORB_HI_Generated.Transport;

--  This package provides support for the GRUART device driver as
--  defined in the GRUART AADLv2 model.

with System; use System;

with POHICDRIVER_UART; use POHICDRIVER_UART;

package body PolyORB_HI_Drivers_GRUART is

   type Serial_Conf_T_Acc is access all POHICDRIVER_UART.Serial_Conf_T;
   function To_Serial_Conf_T_Acc is new Ada.Unchecked_Conversion
     (System.Address, Serial_Conf_T_Acc);

   To_GNAT_Baud_Rate : constant array (POHICDRIVER_UART.Baudrate_T) of
     UART.HLInterface.Data_Rate :=
     (B9600 => UART.HLInterface.B9600,
      B19200 => UART.HLInterface.B19200,
      B38400 => UART.HLInterface.B38400,
      B57600 => UART.HLInterface.B57600,
      B115200 => UART.HLInterface.B115200,
      B230400 => UART.HLInterface.B115200);
   --  XXX does not exist in GCC.4.4.4

   To_GNAT_Parity_Check : constant array (POHICDRIVER_UART.Parity_T) of
     UART.HLInterface.Parity_Check :=
     (Even => UART.HLInterface.Even,
      Odd => UART.HLInterface.Odd);

   To_GNAT_Bits : constant array (7 .. 8) of
     UART.HLInterface.Data_Bits :=
     (7 => UART.HLInterface.B7,
      8 => UART.HLInterface.B8);

   pragma Suppress (Elaboration_Check, PolyORB_HI_Generated.Transport);
   --  We do not want a pragma Elaborate_All to be implicitely
   --  generated for Transport.

   use Interfaces;
   use PolyORB_HI.Messages;
   use PolyORB_HI.Utils;
   use PolyORB_HI.Output;

   type Node_Record is record
      --  UART is a simple protocol, we use one port to send, assuming
      --  it can be used in full duplex mode.

      UART_Port   : Uart.HLInterface.Serial_Port;
      UART_Device : Uart.Core.UART_Device;
      UART_Config : Serial_Conf_T;
   end record;

   Nodes : array (Node_Type) of Node_Record;

   subtype AS_Message_Length_Stream is Uart.STreams.Stream_Element_Array
     (1 .. Message_Length_Size);
   subtype Message_Length_Stream is Stream_Element_Array
     (1 .. Message_Length_Size);

   subtype AS_Full_Stream is Uart.Streams.Stream_Element_Array (1 .. PDU_Size);
   subtype Full_Stream is Stream_Element_Array (1 .. PDU_Size);

   function To_PO_HI_Message_Length_Stream is new Ada.Unchecked_Conversion
     (AS_Message_Length_Stream, Message_Length_Stream);
   function To_PO_HI_Full_Stream is new Ada.Unchecked_Conversion
     (AS_Full_Stream, Full_Stream);

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (Name_Table : PolyORB_HI.Utils.Naming_Table_Type) is
      Success : Boolean;
      Use_Asn1 : Boolean := False;
      Parity : UART.HLInterface.Parity_Check;

   begin
      Uart.HLInterface.Initialize (Success);
      if not Success then
         Put_Line (Normal,
                   "Initialization failure: cannot find UART cores");
         raise Program_Error;
      end if;

      for J in Name_Table'Range loop
	 if Name_Table (J).Variable = System.Null_Address then
	    Nodes (J).UART_Device
	      := Uart.Core.UART_Device'Value
	      (To_String (Name_Table (J).Location) (1 .. 1));

	    --  Note: we only consider the first half of the
	    --  configuration string.

	 else
	    Nodes (J).UART_Config := To_Serial_Conf_T_Acc
	      (Name_Table (J).Variable).all;
	    Use_Asn1 := True;
            Put_Line (Normal, "Device: " & Nodes (J).UART_Config.devname);

	    --  Translate the device name into an UART_Device

	    if Nodes (J).UART_Config.Devname (1 .. 14) /= "/dev/apburasta" then
	       Put_Line ("invalid device name");

	    else
	       --  We assume the device name to be "/dev/apburastaX"
	       --  with X in 0 .. 2. We need to move X to the 1 .. 3
	       --  range.

	       Nodes (J).UART_Device
		 := UART.Core.UART_Device
		 (Integer'Value (Nodes (J).UART_Config.Devname (15 .. 15)) + 1);
	    end if;
	 end if;
      end loop;

      Uart.HLInterface.Open (Port   => Nodes (My_Node).UART_Port,
			     Number => Nodes (My_Node).UART_Device);

      if not Use_Asn1 then
	 Uart.HLInterface.Set (Port   => Nodes (My_Node).UART_Port,
			       Rate => Uart.HLInterface.B19200,
			       Block => True);
      else
	 if Nodes (My_Node).UART_Config.Use_Paritybit then
	    Parity := To_GNAT_Parity_Check (Nodes (My_Node).UART_Config.Parity);
	 else
	    Parity := UART.HLInterface.None;
	 end if;

	 UART.HLInterface.Set
	   (Port   => Nodes (My_Node).UART_Port,
	    Rate   => To_GNAT_Baud_Rate (Nodes (My_Node).UART_Config.Speed),
	    Parity => Parity,
	    Bits   => To_GNAT_Bits (Integer (Nodes (My_Node).UART_Config.Bits)),
	    Block  => True);
      end if;
      pragma Debug (Put_Line (Normal, "Initialization of UART subsystem"
                                & " is complete"));
   end Initialize;

   -------------
   -- Receive --
   -------------

   procedure Receive is
      use type Uart.Streams.Stream_Element_Offset;

      SEL : AS_Message_Length_Stream;
      SEA : AS_Full_Stream;
      SEO : Uart.Streams.Stream_Element_Offset;
      Packet_Size : Uart.Streams.Stream_Element_Offset;
      Data_Received_Index : Uart.Streams.Stream_Element_Offset;
   begin

      Main_Loop : loop
         Put_Line ("Using user-provided GRUART stack to receive");
         Put_Line ("Waiting on UART #"
                     & Nodes (My_Node).UART_Device'Img);

         --  UART is a character-oriented protocol

         --  1/ Receive message length

         Uart.HLInterface.Read (Nodes (My_Node).UART_Port, SEL, SEO);

         Packet_Size := Uart.Streams.Stream_Element_Offset
           (To_Length (To_PO_HI_Message_Length_Stream (SEL)));
         SEO := Packet_Size;

         SEA (1 .. Message_Length_Size) := SEL;

         Data_Received_Index := Message_Length_Size + 1;

         while Data_Received_Index <= Packet_Size + Message_Length_Size loop
            --  We must loop to make sure we receive all data

            Uart.HLInterface.Read (Nodes (My_Node).UART_Port,
                                   SEA (Data_Received_Index .. SEO + 1),
                                   SEO);
            Data_Received_Index := 1 + SEO + 1;
         end loop;

         --  2/ Receive full message

         if SEO /= SEA'First - 1 then
            Put_Line
              (Normal,
               "UART #"
                 & Nodes (My_Node).UART_Device'Img
                 & " received"
                 & Uart.Streams.Stream_Element_Offset'Image (SEO)
                 & " bytes");

            --  Deliver to the peer handler

            PolyORB_HI_Generated.Transport.Deliver
              (Corresponding_Entity
                 (Integer_8 (SEA (Message_Length_Size + 1))),
               To_PO_HI_Full_Stream (SEA)
                 (1 .. Stream_Element_Offset (SEO)));
         else
            Put_Line ("Got error");
         end if;
      end loop Main_Loop;
   end Receive;

   ----------
   -- Send --
   ----------

   function Send
     (Node    : Node_Type;
      Message : Stream_Element_Array;
      Size    : Stream_Element_Offset)
     return Error_Kind
   is
      --  We cannot cast both array types using
      --  Ada.Unchecked_Conversion because they are unconstrained
      --  types. We cannot either use direct casting because component
      --  types are incompatible. The only time efficient manner to do
      --  the casting is to use representation clauses.

      Msg : Uart.Streams.Stream_Element_Array
        (1 .. Uart.Streams.Stream_Element_Offset (Size));
      pragma Import (Ada, Msg);
      for Msg'Address use Message'Address;

   begin
      Put_Line ("Using user-provided UART stack to send");
      Put_Line ("Sending through UART #"
                  & Nodes (Node).UART_Device'Img
                  & Size'Img & " bytes");

      Uart.HLInterface.Write (Port   => Nodes (My_Node).UART_Port,
                              Buffer => Msg);

      return Error_Kind'(Error_None);
      --  Note: we have no way to know there was an error here
   end Send;

end PolyORB_HI_Drivers_GRUART;
