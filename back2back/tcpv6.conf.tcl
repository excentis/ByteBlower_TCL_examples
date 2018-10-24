#------------------------#
#   Test Configuration   #
#------------------------#

# --- ByteBlower Server address
set ::serverAddress byteblower-dev-1-1.lab.byteblower.excentis.com

# --- Physical Ports to connect the logical ByteBlowerPorts to
set ::physicalPort1 trunk-1-1
set ::physicalPort2 trunk-1-2

# --- Layer2 Configuration
set ::serverMacAddress "00:ff:bb:ff:ee:dd"
set ::clientMacAddress "00:ff:bb:ff:ee:ee"

# --- Layer3 Configuration
# --- HTTP Server Port Layer3 Configuration
#- will we use Stateless Auto Configuration?
#set ::serverAutoConfig "stateless"
#- will we use DHCP instead?
#set ::serverAutoConfig "dhcp"
#- Fixed IPv6 settings (used when Stateless Auto Configuration, nor DHCP is used)
set ::serverAutoConfig "manual"
set ::serverIpAddress "2001:0db8:0001:0081:0000:0000:0000:0002/64"
#- If there is a router between the source and destination ByteBlower ports and you want to force the source gateway address, you can uncomment this line
set ::serverIpRouter "null"
#set ::serverIpRouter "2001:0db8:0001:0081:0000:0000:0000:0001"

# --- HTTP Client Port Layer3 Configuration
#- will we use Stateless Auto Configuration?
#set ::clientAutoConfig "stateless"
#- will we use DHCP instead?
#set ::clientAutoConfig "dhcp"
#- Fixed IPv6 settings (used when Stateless Auto Configuration, nor DHCP is used)
set ::clientAutoConfig "manual"
set ::clientIpAddress "2001:0db8:0001:0081:0000:0000:0000:0003/64"
#- If there is a router between the source and destination ByteBlower ports and you want to force the source gateway address, you can uncomment this line
set ::clientIpRouter "null"
#set ::clientIpRouter "2001:0db8:0001:0081:0000:0000:0000:0001"

# --- HTTP Session setup
# --- Override the default used TCP ports
#set ::serverTcpPort 5555
#set ::serverTcpPort 80
#set ::clientTcpPort 6666

# --- Number of bytes to request
set ::requestSize 100000000 ;# 100 MB

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
