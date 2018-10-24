#------------------------#
#   Test Configuration   #
#------------------------#

# --- ByteBlower Server address
set ::serverAddress byteblower-dev-1300-2.lab.byteblower.excentis.com
set ::meetingPointAddress localhost

# --- Physical Ports to connect the logical ByteBlowerPorts to
set ::physicalPort1 nontrunk-1

# --- Wireless Endpoint to use.
set ::wirelessEndpointUUID "de949dd3-ea45-40cd-8f84-0a2d9cc2242f"

# --- Layer2 Configuration
set ::serverMacAddress "00:ff:bb:ff:ee:dd"

# --- Layer3 Configuration
# --- HTTP Server Port Layer3 Configuration
#   - Set to 1 if you want to use DHCP
set ::serverPerformDhcp 1
#   - else use static IPv4 Configuration
set ::serverIpAddress "10.8.1.61"
set ::serverNetmask "255.255.255.0"
set ::serverIpGW "10.8.1.1"

# --- HTTP Session setup
# --- Override the default used TCP ports
#set ::serverTcpPort 5555
#set ::serverTcpPort 80
#set ::clientTcpPort 6666

# --- Duration of the request
set ::requestDuration 10000000000;#ns

# --- Configure the used HTTP Request Method
#
# - ByteBlower Server > version 1.4.8 and ByteBlower Client API > version 1.4.4
#   support configuring the used HTTP Method to transfer the data.
#   note: older versions always used HTTP GET
#
#   using HTTP GET :
#       HTTP Server -----D-A-T-A----> HTTP Client
#
#   using HTTP PUT :
#       HTTP Server <----D-A-T-A----- HTTP Client
#
set ::httpMethod "GET" ;# ByteBlower default
#set ::httpMethod "PUT"

#  - Uncomment this to set the initial TCP window size
#set ::tcpInitialWindowSize 16384
#  - Uncomment this to enable TCP window scaling and set the window scale factor
#set ::windowScale 4
