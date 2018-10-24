# This tcl script contains the main script to execute a source specific multicast test with traffic.
# Before you can use this script, you need to source following tcl scripts:
#  * ssm_with_traffic.conf.tcl
#  * general.proc.tcl
#  * ssm_with_traffic.proc.tcl

source [ file join [ file dirname [ info script ]] ssm_with_traffic.proc.tcl ]

# Test Setup 
set setup [ ssm_with_traffic.Setup	-serverIp 				$serverIp \
									-sourcePortName 		$sourcePortName \
									-portName1 				$portName1 \
									-portName2 				$portName2 \
									-performDhcp_sourcePort $performDhcp_sourcePort \
									-performDhcp_port1 		$performDhcp_port1 \
									-performDhcp_port2 		$performDhcp_port2 \
									-sourceMacAddress 		$sourceMacAddress \
									-sourceIpAddress		$sourceIpAddress \
									-sourceIpGateway 		$sourceIpGateway \
									-sourceIpNetmask 		$sourceIpNetmask \
									-macAddress1			$macAddress1 \
									-ipAddress1 			$ipAddress1 \
									-ipGateway1 			$ipGateway1 \
									-ipNetmask1 			$ipNetmask1 \
									-macAddress2			$macAddress2 \
									-ipAddress2 			$ipAddress2 \
									-ipGateway2 			$ipGateway2 \
									-ipNetmask2 			$ipNetmask2 \
									-multicastAddress1		$multicastAddress1 \
									-multicastAddress2 		$multicastAddress2 \
									-sourceIp1 				$sourceIp1 \
									-sourceIp2 				$sourceIp2 \
									-sourceIp3 				$sourceIp3 \
									-sourceIp4 				$sourceIp4 ]

# Test Run
set ::result [ ssm_with_traffic.Run 	-port1 				[ lindex $setup 1 ] \
									-port2 				[ lindex $setup 2 ] \
									-serverIp 			$serverIp \
									-sourceStream1 		[ lindex $setup 4 ] \
									-sourceStream2 		[ lindex $setup 5 ] \
									-ip1 				[ lindex $setup 6 ] \
									-ip2 				[ lindex $setup 7 ] \
									-multicastAddress1	$multicastAddress1 \
									-multicastAddress2	$multicastAddress2 \
									-sourceIp1 			$sourceIp1 \
									-sourceIp2 			$sourceIp2 \
									-sourceIp3 			$sourceIp3 \
									-sourceIp4 			$sourceIp4 \
									-trigger1_1			[ lindex $setup 8 ] \
									-trigger1_2			[ lindex $setup 9 ] \
									-trigger2_1			[ lindex $setup 10 ] \
									-trigger2_2			[ lindex $setup 11 ]
]

# Test Cleanup Server and Port List
#Cleanup [lindex $setup 0] [ lrange $setup 1 3 ]


            
