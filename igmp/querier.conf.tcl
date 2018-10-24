#------------------------#
#   Test Configuration   #
#------------------------#

# --- ByteBlower Server address
#set serverAddress byteblower-dev-2-1.lab.excentis.com
set ::serverAddress byteblower-tp-p860.lab.excentis.com

# --- Physical Ports to connect the logical ByteBlowerPorts to
#   + Physical Port where the IGMP Querier side is connected.
#set querierPhysicalPort nontrunk-1
set ::querierPhysicalPort trunk-1-1
#   + List of Physical Port to use as IGMP Host Ports.
#     NOTE: When using > 251 CPEs, you should check the IPv4 subnet
#           and gateway for IGMP Hosts: <hostNetmask> and <hostIpGW>!
# Using random/fixed list:
#set hostPhysicalPortList [ list \
#    trunk-1-12 \
#    trunk-1-3 \
#    trunk-1-7 \
#]
#set hostPhysicalPortList [ list \
#    trunk-1-14 \
#    trunk-1-14 \
#]
# Using sequential list:
#   + Number of Physical Ports to use (starting from 'trunk-1-2' to 'trunk-1-<numberOfHostPorts>')
set ::numberOfHostPorts 2

set ::hostPhysicalPortList [ list ]
for { set i 2 } { $i <= $::numberOfHostPorts } { incr i 1 } {
    lappend ::hostPhysicalPortList [ format "trunk-1-%u" $i ]
}

# --- Layer2 Configuration
set ::querierMacAddress "00:FF:12:00:00:01"
#   + First IGMP Host will have this MAC address, following IGMP Hosts will use the previous IGMP Host MAC address incremented by 1
set ::hostMacAddressBase "00:FF:12:00:01:01"

# --- Layer3 Configuration
# --- IGMP Querier Port Layer3 Configuration
#   + Set to 1 if you want to use DHCP
set ::querierPerformDhcp 1
#   + else use static IPv4 Configuration
#set querierIpAddress "10.10.0.2"
#set querierNetmask "255.255.255.0"
#set querierIpGW "10.10.0.1"
set ::querierIpAddress "10.8.1.4"
set ::querierNetmask "255.255.255.0"
set ::querierIpGW "10.8.1.1"

# --- IGMP Host Port Layer3 Configuration
#   + Set to 1 if you want to use DHCP
set ::hostPerformDhcp 1
#   + else use static IPv4 Configuration
#     First IGMP Host will have this IPv4 address, following CPEs will use the previous IPv4 MAC address incremented by 1
#     NOTE: When using fixed IPv4 addresses, the CPEs MUSt be located in the same subnet.
set ::hostIpAddressBase "10.10.0.3"
set ::hostNetmask "255.255.255.0"
set ::hostIpGW "10.10.0.1"

# --- Multicast Group Address used for Joining and leaving Multicast Group and sending Multicast traffic
set ::multicastGroupAddress "230.1.2.3"

# --- IGMP configuration
#   + Robustness Variable
set ::robustnessVariable 2 ;# [#] default: 2

#   + Query Interval
set ::queryInterval 125 ;# [s] default: 125s
#   + Query Response Interval
set ::queryResponseInterval 100 ;# [1/10 s] default: 100 (10s)
#   + Group Membership Interval
set ::groupMembershipInterval [ expr ( 10 * $::robustnessVariable * $::queryInterval ) + $::queryResponseInterval ] ;# [1/10 s] MUST
#   + Other Querier Present Interval
set ::otherQuerierPresentInterval [ expr ( 10 * $::robustnessVariable * $::queryInterval ) + ( $::queryResponseInterval / 2 ) ] ;# [1/10 s] MUST
#   + Startup Query Interval
set ::startupQueryInterval [ expr $::queryInterval / 4 ] ;# [s] default: 1/4 of "General Query Interval"
#   + Startup Query Count
set ::startupQueryCount $::robustnessVariable ;# [#] default: Robustness Variable
#   + Last Member Query Interval
set ::lastMemberQueryInterval 10 ;# [1/10 s] default: 10 (1s)
#   + Last Member Query Count
set ::lastMemberQueryCount $::robustnessVariable ;# [#] default: Robustness Variable
#   + Unsolicited Report Interval
set ::unsolicitedReportInterval 10 ;# [s] default: 10s
#   + Version 1 Router Present Timeout
set ::version1RouterPresentTimeout 400 ;# [s] default: 400s

# --- Multicast Data Frame configuration
#   + Ethernet length (without CRC)
set ::ethernetLength 1000 ;# --- REMARK --- This is the frame size without CRC! ---

#   + UDP Configuration
set ::multicastSrcUdpPort 2001
set ::multicastDstUdpPort 2002

# --- Timing configuration
#   + Multicast traffic rate [Bytes/s]
#     Set to '0' if you want to disable multicast traffic
set ::trafficRate 100000 ;# [Bps]
#set trafficRate 0
#   + Test time [seconds]
set ::testTime 600 ;# [s]
#   + Time after which IGMP hosts will Join the Multicast Group [seconds]
set ::hostJoinTime 0 ;# [s]
#   + Time between IGMP hosts Joining the Multicast Group [seconds]
set ::hostJoinInterval 15 ;# [s]
#   + Time after which IGMP hosts will Leave the Multicast Group [seconds]
set ::hostLeaveTime [ expr 3 * ${::testTime} / 4 ] ;# [s]
#   + Time between IGMP hosts Leaving the Multicast Group [seconds]
set ::hostLeaveInterval 20 ;# [s]

# --- Specify a filename if you want to store the IGMP traffic
#     that has been captured at the IGMP Querier.
#     the Querier OID and and '.pcap' will be append by default
set ::querierDebugCapture "igmp.querier.DEBUG"
#set querierDebugCapture ""

# --- Define the logFile to write the results to a file.
#set logFile "results.txt"
#   + Adding date and time to the log file name ('result_<date>_<time>.txt'):
set ::logFile [ format "results_%s.txt" [ clock format [ clock seconds ] -format "%Y%m%d_%H%M%S" ] ]

