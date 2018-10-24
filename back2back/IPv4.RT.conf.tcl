# This configuration file initializes the necessary variables to run the IPv4 RT script.
# We need to configure the server, ports, mac and ip addresses, as well as traffic parameters.

#------------------------#
#   Test Configuration   #
#------------------------#

# --- ByteBlower Server address
set serverAddress byteblower-tp-p860.lab.excentis.com

# --- Physical Ports to connect the logical ByteBlowerPorts to
set physicalPort1 trunk-1-1
set physicalPort2 trunk-1-2

# --- Layer2 Configuration
set srcMacAddress1 "00:FF:12:00:00:01"
set dstMacAddress1 "00:FF:12:00:00:02"

# --- Layer3 Configuration
# --- Back-To-Back Source Port Layer3 Configuration
#   - Set to 1 if you want to use DHCP
set srcPerformDhcp1 1
#   - else use static IPv4 Configuration
set srcIpAddress1 "10.10.0.2"
set srcNetmask1 "255.255.255.0"
set srcIpGW1 "10.10.0.1"

# --- Back-To-Back Destination Port Layer3 Configuration
#   - Set to 1 if you want to use DHCP
set dstPerformDhcp1 1
#   - else use static IPv4 Configuration
set dstIpAddress1 "10.10.0.3"
set dstNetmask1 "255.255.255.0"
set dstIpGW1 "10.10.0.1"

# ---- Frame configuration
set ethernetLength 124 ;# without CRC!

# --- UDP Configuration
set srcUdpPort1 2001
set dstUdpPort1 2002

# --- Timing configuration
#   - Number of frames to send
set numberOfFrames 10000
#   - Time between two frames
set interFrameGap 1ms

# ---- Traffic direction configuration
# set to 1 for bidirectional traffic
set bidir 1
# --- Output of the intermediate results in a CSV file 
# You can choose to use the standard output like this:
#set outputChannel stdout;
# Or you can choose to use a file
set outputChannel [open "/tmp/result.csv" "w"];