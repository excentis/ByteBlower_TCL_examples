# This configuration file initializes the necessary variables to run the IPv4.run.tcl back2back example.
# We need to configure the server, ports, mac and ip addresses, as well as traffic parameters.

#------------------------#
#   Test Configuration   #
#------------------------#

# --- ByteBlower Server address
set serverAddress byteblower-dev-2200-1.lab.byteblower.excentis.com

# --- Physical Ports to connect the logical ByteBlowerPorts to
set physicalPort1 trunk-1-1
set physicalPort2 trunk-3-1

# --- Layer2 Configuration
set nsiMacAddress1 "00:FF:1F:00:00:01"
set cpeMacAddress1 "00:FF:1F:00:00:02"

# --- Layer3 Configuration
# --- Back-To-Back Source Port Layer3 Configuration
#   - Set to 1 if you want to use DHCP
set nsiPerformDhcp1 0
#   - else use static IPv4 Configuration
set nsiIpAddress1 "10.10.0.2"
set nsiNetmask1 "255.255.255.0"
set nsiIpGW1 "10.10.0.1"

# --- Back-To-Back Destination Port Layer3 Configuration
#   - Set to 1 if you want to use DHCP
set cpePerformDhcp1 0
#   - else use static IPv4 Configuration
set cpeIpAddress1 "10.10.0.3"
set cpeNetmask1 "255.255.255.0"
set cpeIpGW1 "10.10.0.1"

# ---- Frame configuration
set ethernetLength 124 ;# without CRC!

set nrOfFlows 2

# --- UDP flows will go from baseUDPport to baseUDPport + 1
# Flow 1: $baseUdpPort --> $baseUdpPort +1
# Flow 2: $baseUdpPort + 2 --> $baseUdpPort + 3
set baseUdpPort 1000



# --- Timing configuration
#   - Number of frames to send
set numberOfFrames 10000
#   - Time in ns between two frames
set interFrameGap 1000000

# ---- Traffic direction configuration
# set to 1 for bidirectional traffic
set bidir 1
