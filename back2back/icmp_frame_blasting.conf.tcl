
#------------------------#
#   Test Configuration   #
#------------------------#

# --- ByteBlower Server address
set serverAddress byteblower-tp-1300.lab.byteblower.excentis.com

# --- Physical Ports to connect the logical ByteBlowerPorts to
set physicalPort1 trunk-1-13
set physicalPort2 trunk-1-14

# --- Layer2 Configuration
set srcMacAddress1 "00:FF:12:00:00:01"
set destMacAddress1 "00:FF:12:00:00:02"

# --- Layer3 Configuration
# --- Back-To-Back Destination Port Layer3 Configuration
#   - Set to 1 if you want to use DHCP
set srcPerformDhcp1 1
#   - else use static IPv4 Configuration
set srcIpAddress1 "10.10.0.2"
set srcNetmask1 "255.255.255.0"
set srcIpGW1 "10.10.0.1"

# --- Back-To-Back Destination Port Layer3 Configuration
#   - Set to 1 if you want to use DHCP
set destPerformDhcp1 1
#   - else use static IPv4 Configuration
set destIpAddress1 "10.10.0.3"
set destNetmask1 "255.255.255.0"
set destIpGW1 "10.10.0.1"

# ---- Frame configuration
set ethernetLength 124 ;# without CRC!

# --- ICMP Configuration
set icmpEchoIdentifier 0x1234
set icmpEchoSequenceNumber 0x5678

# --- Timing configuration
#   - Number of frames to send
set numberOfFrames 10000
#   - Time between two frames
set interFrameGap 1ms

# --- Bidir?
#     set to 1 to run a bi directional test
set bidir 0

