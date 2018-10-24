#------------------------#
#   Test Configuration   #
#------------------------#

# --- ByteBlower Server address
set serverAddress byteblower-tp-1300-beta.lab.byteblower.excentis.com


# --- this will be the WAN side port.  
#   -- Physical port to use
set nsiPhysicalPort1 "trunk-1-13"
#   -- Port Layer2 Configuration
set nsiMacAddress1 "00:ff:1f:00:00:01"
#   -- Port Layer3 Configuration
#      + Set to 1 if you want to use DHCP
set nsiPerformDhcp1 1
#      + if DHCP is not used, fill in the desired IP address
set nsiIpAddress1 "10.10.0.2"
#      + if DHCP is not used, fill in the desired network mask
set nsiNetmask1 "255.255.255.0"
#      + if DHCP is not used, fill in the desired gateway
set nsiIpGW1 "10.10.0.1"

# --- these will be the CPE side ports.
#   -- Physical port to use
set cpe(PhysicalPort1) "trunk-1-19"
#   -- Port Layer2 Configuration
set cpe(MacAddress1) "00:ff:1f:00:00:02"
#   -- Port Layer3 Configuration
#      + Set to 1 if you want to use DHCP
set cpe(PerformDhcp1) 1
#      + if DHCP is not used, fill in the desired IP address
set cpe(IpAddress1) "10.10.0.3"
#      + if DHCP is not used, fill in the desired network mask
set cpe(Netmask1) "255.255.255.0"
#      + if DHCP is not used, fill in the desired gateway
set cpe(IpGW1) "10.10.0.1"

#   -- Physical port to use
set cpe(PhysicalPort2) "trunk-1-20"
#   -- Port Layer2 Configuration
set cpe(MacAddress2) "00:ff:1f:00:00:03"

#   -- Port Layer3 Configuration
#      + Set to 1 if you want to use DHCP
set cpe(PerformDhcp2) 1 
#      + if DHCP is not used, fill in the desired IP address
set cpe(IpAddress2) "10.10.0.4"
#      + if DHCP is not used, fill in the desired network mask
set cpe(Netmask2) "255.255.255.0"
#      + if DHCP is not used, fill in the desired gateway
set cpe(IpGW2) "10.10.0.1"

# --- number of cpe ports to be used.
set numberOfCpePorts 2


# ---- Frame configuration
set ethernetLength 1000 ;# --- REMARK --- This is the frame size without CRC! ---

# --- UDP Configuration
set nsiUdpPort 2001
set cpeUdpPort 2002

# --- Timing configuration
#   + Downstream traffic rate [Bytes/s]
#     Set to '0' if you want to disable downstream traffic
set downstreamRate 1500000
#set downstreamRate 0
#   + Upstream traffic rate [Bytes/s]
#     Set to '0' if you want to disable upstream traffic
set upstreamRate 128000
#set upstreamRate 0
#   + Test time [seconds]
set testTime 10

# --- Define the logFile to write the results to a file.
#set logFile "results.txt"
#   + Adding date and time to the log file name ('result_<date>_<time>.txt'):
set logFile [ format "results_%s.txt" [ clock format [ clock seconds ] -format "%Y%m%d_%H%M%S" ] ]
