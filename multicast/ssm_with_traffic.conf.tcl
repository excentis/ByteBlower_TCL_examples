#***********************#
#**   Configuration   **#
#***********************#

#- Server and interfaces
#set serverIp byteblower-6.lab.excentis.com
set serverIp byteblower-tp-p860.lab.excentis.com
set sourcePortName trunk-1-1
set portName1 trunk-1-2
set portName2 trunk-1-3

#- ByteBlower source port layer2 and layer3
set sourceMacAddress "00:ff:12:00:00:03"
#set sourceIpAddress "10.10.10.4"
#set sourceIpGateway "10.10.10.1"
set performDhcp_sourcePort 1
set sourceIpAddress "10.8.1.4"
set sourceIpGateway "10.8.1.1"
set sourceIpNetmask "255.255.255.0"

#- ByteBlower port 1 layer2 and layer3
set macAddress1 "00:ff:12:00:00:01"
#set ipAddress1 "10.10.10.2"
#set ipGateway1 "10.10.10.1"
set performDhcp_port1 1
set ipAddress1 "10.8.1.5"
set ipGateway1 "10.8.1.1"
set ipNetmask1 "255.255.255.0"

#- ByteBlower port 2 layer2 and layer3
set macAddress2 "00:ff:12:00:00:02"
#set ipAddress2 "10.10.10.2"
#set ipGateway2 "10.10.10.1"
set performDhcp_port2 1
set ipAddress2 "10.8.1.6"
set ipGateway2 "10.8.1.1"
set ipNetmask2 "255.255.255.0"

#- Multicast addresses used during test (see IANA assignments for multicast-addresses http://www.iana.org/assignments/multicast-addresses)
# set multicastAddress1 "232.10.10.1"
# set multicastAddress2 "232.10.10.2"
set multicastAddress1 "232.8.1.1"
set multicastAddress2 "232.8.1.2"

#- Multicast source addresses
#set sourceIp1 "10.10.10.11"
#set sourceIp2 "10.10.10.12"
#set sourceIp3 "10.10.10.13"
#set sourceIp4 "10.10.10.14"
set sourceIp1 "10.8.1.11"
set sourceIp2 "10.8.1.12"
set sourceIp3 "10.8.1.13"
set sourceIp4 "10.8.1.14"

