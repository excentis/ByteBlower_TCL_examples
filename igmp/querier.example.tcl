# This tcl script contains the main script to execute a igmp.querier test.
# Before you can use this script, you need to source following tcl scripts:
#  * igmp.querier.conf.tcl
#  * general.proc.tcl
#  * igmp.querier.proc.tcl

source [ file join [ file dirname [ info script ]] querier.proc.tcl ]

# Test Setup 
set setup [ IGMP.Querier.Setup $::serverAddress $::querierPhysicalPort $::hostPhysicalPortList $::querierMacAddress $::hostMacAddressBase $::querierPerformDhcp $::querierIpAddress $::querierNetmask $::querierIpGW $::hostPerformDhcp $::hostIpAddressBase $::hostNetmask $::hostIpGW $::multicastGroupAddress $::robustnessVariable $::queryInterval $::queryResponseInterval $::groupMembershipInterval $::otherQuerierPresentInterval $::startupQueryInterval $::startupQueryCount $::lastMemberQueryInterval $::lastMemberQueryCount $::unsolicitedReportInterval $::version1RouterPresentTimeout $::ethernetLength $::multicastSrcUdpPort $::multicastDstUdpPort $::trafficRate $::testTime $::hostJoinTime $::hostJoinInterval $::hostLeaveTime $::hostLeaveInterval $::querierDebugCapture $::logFile ]

# Test Run
set result [ IGMP.Querier.Run [ lindex $setup 1 ] [ lindex $setup 2 ] $::hostJoinTime $::hostJoinInterval $::multicastGroupAddress $::hostLeaveTime $::hostLeaveInterval $::trafficRate $::testTime $::ethernetLength $::multicastDstUdpPort $::multicastSrcUdpPort ]

# Test Cleanup Server and Port List
#Cleanup [lindex $setup 0] [ concat [ lindex $setup 1 ] [ lindex $setup 2 ] ]

            
