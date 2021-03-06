# This configuration file initializes the necessary variables to run the IPv6.run.tcl script.
# We need to configure the server, ports, mac and ip addresses, as well as traffic parameters.

# --- Define configuration parameters ---
#
#- Define the IP address or hostname of the ByteBlower server to use
set serverAddress byteblower-tp-1300.lab.byteblower.excentis.com
#- Define the physical port you want to use on the ByteBlower server.
set physicalPort1 trunk-1-19
set physicalPort2 trunk-1-20

#- Define source port Layer2 MAC Address
set srcMacAddress "00:FF:0A:00:00:01"

#- Define destination port Layer2 MAC Address
set dstMacAddress "00:FF:0A:00:00:02"

#- Define source port Layer2.5 VLANsettings
#- is the port attached to a VLAN subnet?
set srcOnVlan 1
#- if so, select a VLAN ID
set srcVlanID 2
#- optionally, override the default priority (0-7) and drop eligible (0 or 1) fields
#set srcVlanPriority 7
#set srcVlanDropEligible 1

#- Define destination port Layer2.5 VLANsettings
#- is the port attached to a VLAN subnet?
set dstOnVlan 1
#- if so, select a VLAN ID
set dstVlanID 2
#- optionally, override the default priority (0-7) and drop eligible (0 or 1) fields
#set dstVlanPriority 0
#set dstVlanDropEligible 0

#- Define source port Layer3 IPv6 settings
#- will we use Stateless Auto Configuration?
#set srcAutoConfig "stateless"
#- will we use DHCP instead?
#set srcAutoConfig "dhcp"
#- Fixed IPv6 settings (used when Stateless Auto Configuration, nor DHCP is used)
set srcAutoConfig "dhcp"
set srcIpAddress "2001:0db8:0001:0081:0000:0000:0000:0002/64"
#- If there is a router between the source and destination ByteBlower ports and you want to force the source gateway address, you can uncomment this line
set srcIpRouter "null"
#set srcIpRouter "2001:0db8:0001:0081:0000:0000:0000:0001"

#- Define destination port Layer3 settings
#- will we use Stateless Auto Configuration?
#set dstAutoConfig "stateless"
#- will we use DHCP instead?
#set dstAutoConfig "dhcp"
#- Fixed IPv6 settings (used when Stateless Auto Configuration, nor DHCP is used)
set dstAutoConfig "dhcp"
set dstIpAddress "2001:0db8:0001:0081:0000:0000:0000:0003/64"
#- If there is a router between the source and destination ByteBlower ports and you want to force the destination gateway address, you can uncomment this line
set dstIpRouter "null"
#set dstIpRouter "2001:0db8:0001:0081:0000:0000:0000:0001"

#- We will set up an UDP frame with following settings:
#- Source and destination port for sending from physicalPort1 -> physicalPort2
set srcUdpPort 2001
set dstUdpPort 2002

#- Define frame sizes and frame rate
set ethernetLength 124 ;# ByteBlower requires to set ethernet frames without CRC bytes!
set udpLength 62 ;# ethernetLength - 62
set numberOfFrames 10000
set interFrameGap 1ms

