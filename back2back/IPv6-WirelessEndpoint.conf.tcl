# This configuration file initializes the necessary variables to run the IPv6.run.tcl script.
# We need to configure the server, ports, mac and ip addresses, as well as traffic parameters.

# --- Define configuration parameters ---
#
#- Define the IP address or hostname of the ByteBlower server to use
set serverAddress byteblower-dev-1300-1.lab.byteblower.excentis.com
set meetingPointAddress byteblower-dev-1300-1.lab.byteblower.excentis.com

#- Define the physical port you want to use on the ByteBlower server.
set physicalPort1 trunk-1-13

#- Wireless Endpoint to use.
set wirelessEndpointUUID "196e48d2-6c91-4f4d-bad5-9b16c55c8777"

#- Define source port Layer2 MAC Address
set srcMacAddress "00:FF:0A:00:00:01"

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

#- We will set up an UDP frame with following settings:
#- Source and destination port for sending from physicalPort1 -> physicalPort2
set srcUdpPort 2001
set dstUdpPort 2002

#- Define frame sizes and frame rate
set ethernetLength 124 ;# ByteBlower requires to set ethernet frames without CRC bytes!
set udpLength 62 ;# ethernetLength - 62
set numberOfFrames 10000
set interFrameGap 1ms

set bidir 1
