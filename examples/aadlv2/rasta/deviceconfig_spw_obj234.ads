pragma Style_Checks (Off); -- turn off style checks
-- Code automatically generated by asn1scc tool
-- Date was: 04/28/2011
-- Time was: 13:55:57

WITH Ada.Strings.Fixed;
USE ADA.Strings.Fixed;

WITH Interfaces;
USE Interfaces;

WITH Ada.Characters.latin_1;


WITH AdaAsn1RTL;
USE AdaAsn1RTL;
with POHICDRIVER_SPACEWIRE;
use POHICDRIVER_SPACEWIRE;

package DeviceConfig_spw_obj234 is



pohidrv_spw_obj234_cv:aliased Spacewire_Conf_T:=(devname => "/dev/grspwrasta0" & 4*Character'Val(0) & Character'Val(0),
nodeaddr => 22,
corefreq => 30000,
clockdiv => 0,
remove_prot_id => FALSE,
rxblock => FALSE,
txblock => FALSE, 
exist => (corefreq => 1, clockdiv => 0, remove_prot_id => 0, rxblock => 0, txblock => 0));

--END;
end DeviceConfig_spw_obj234;
