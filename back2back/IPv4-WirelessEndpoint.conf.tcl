# This configuration file initializes the necessary variables to run the IPv4.run.tcl back2back example.
# We need to configure the server, ports, mac and ip addresses, as well as traffic parameters.

#------------------------#
#   Test Configuration   #
#------------------------#

# --- ByteBlower Server address
set serverAddress byteblower-dev-1300-1.lab.byteblower.excentis.com
set meetingPointAddress byteblower-dev-1300-1.lab.byteblower.excentis.com

# --- Physical Ports to connect the logical ByteBlowerPorts to
set physicalPort nontrunk-1

# --- Wireless Endpoint to use.
set wirelessEndpointUUID "de949dd3-ea45-40cd-8f84-0a2d9cc2242f"

# --- Layer2 Configuration
set srcMacAddress "00:FF:1F:00:00:01"

# --- Layer3 Configuration
# --- Back-To-Back Source Port Layer3 Configuration
#   - Set to 1 if you want to use DHCP
set srcPerformDhcp 1
#   - else use static IPv4 Configuration
set srcIpAddress "10.10.0.2"
set srcNetmask "255.255.255.0"
set srcIpGW "10.10.0.1"



# ---- Frame configuration
set ethernetLength 124 ;# without CRC!


# --- UDP Configuration
set srcUdpPort 2001
set dstUdpPort 2002

# --- Timing configuration
#   - Number of frames to send
set numberOfFrames 10000
#   - Time between two frames
set interFrameGap 1ms

# ---- Traffic direction configuration
# set to 1 for bidirectional traffic
set bidir 1
