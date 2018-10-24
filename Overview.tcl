#
# ByteBlower Higher Layer API
#
#  consists of
#    - basic.utils.tcl
#        Several utility procedures used in the ByteBlower HL API (MAC- and IP-conversion procedures, ... )
#    - basic.converttobpf.tcl
#        Utility to convert ethereal filters to bpf filters
#    - basic.framev4v6.tcl
#        For creation of common frame structures (EthII, IP, ICMP, IGMP, ... )
#    - ByteBlower.executescenario.tcl
#        Implementation of ExecuteScenario
#        proc, the low level flow execution engine
#    - ByteBlower.flowlossrate.tcl
#    - ByteBlower.flowlatency.tcl
#        Two reference implementations using the ExecuteScenario
#        flow execution engine.
#        Flow lossrate and latency are
#        based on RFC1242 and RFC 2544
#    - ByteBlower.NAT.tcl
#        Contains utilities for sending traffic over a natted device
#    - ByteBlower.tcp-ack-suppression.tcl
#        Procedure to execute a TcpAckSuppresion test
#    - ByteBlower.utils.tcl
#        procedures to create multiple ports on a ByteBlower server, with different mac and Ip addresses
#
#    - example.*.tcl
#        Various demonstration scripts showing how to use the
#        ByteBlower API
#

package require ByteBlower

#
# I - Initialize the ByteBlower and configure some ports
#

# Initializing the ByteBlower
#-------------------------------
# o change IP to your ByteBlower IP
set bb [ ByteBlower Instance.Get ]
set server [ $bb Server.Add byteblower-tp-1300.lab.excentis.com ]

# Setting up  port1
#-------------------------------------
# o change port
# o change MAC
set port1 [ $server Port.Create trunk-1-1 ]

set portEth1 [ $port1 Layer2.EthII.Set ]
$portEth1 Mac.Set 00:00:00:01:01:0A
$portEth1 Type.Set DIX

set portIp1 [ $port1 Layer3.IPv4.Set ]
[ $portIp1 Protocol.Dhcp.Get ] Perform

# Setting up  port2
#-------------------------------------
# o change port
# o change MAC
set port2 [ $server Port.Create trunk-1-2 ]

set portEth2 [ $port2 Layer2.EthII.Set ]
$portEth2 Mac.Set 00:00:00:01:02:0A
$portEth2 Type.Set DIX

set portIp2 [ $port2 Layer3.IPv4.Set ]
[ $portIp2 Protocol.Dhcp.Get ] Perform

# Setting up  port3
#-------------------------------------
# o change port
# o change MAC
set port3 [ $server Port.Create trunk-1-3 ]

set portEth3 [ $port3 Layer2.EthII.Set ]
$portEth3 Mac.Set 00:00:00:01:03:0A
$portEth3 Type.Set DIX

set portIp3 [ $port3 Layer3.IPv4.Set ]
[ $portIp3 Protocol.Dhcp.Get ] Perform

# Setting up  port4
#-------------------------------------
# o change port
# o change MAC
set port4 [ $server Port.Create trunk-1-4 ]

set portEth4 [ $port4 Layer2.EthII.Set ]
$portEth4 Mac.Set 00:00:00:01:04:0A
$portEth4 Type.Set DIX

set portIp4 [ $port4 Layer3.IPv4.Set ]
[ $portIp4 Protocol.Dhcp.Get ] Perform

#
# II - Build some frames and use the fames in flow definitions
#

# Building the scouting frame that will be sent to prepare
# the network for the actual frames in the tx path
#---------------------------------------------------------

set scoutingFramePayload "BYTEBLOWER SCOUTING FRAME"
if { [ binary scan $scoutingFramePayload H* scoutingFramePayloadHex ] != 1 } {
    error "UDP flow setup error: Unable to generate ByteBlower scouting frame payload."
}
set scoutingFramePayloadData [ ::excentis::basic::String.To.Hex $scoutingFramePayloadHex ]

set scoutingFrame1 [ ::excentis::basic::Frame.Udp.Set [ $portEth2 Mac.Get ] [ $portEth1 Mac.Get ]\
    [ $portIp2 Ip.Get ] [ $portIp1 Ip.Get ]\
    8000 8000 $scoutingFramePayloadData\
]

set scoutingFrame2 [ ::excentis::basic::Frame.Udp.Set [ $portEth1 Mac.Get ] [ $portEth2 Mac.Get ] \
    [ $portIp1 Ip.Get ] [ $portIp2 Ip.Get ]\
    8000 8000 $scoutingFramePayloadData\
]

set scoutingFrame3 [ ::excentis::basic::Frame.Udp.Set [ $portEth4 Mac.Get ] [ $portEth3 Mac.Get ]\
    [ $portIp4 Ip.Get ] [ $portIp3 Ip.Get ]\
    8000 8000 $scoutingFramePayloadData\
]

set scoutingFrame4 [ ::excentis::basic::Frame.Udp.Set [ $portEth3 Mac.Get ] [ $portEth4 Mac.Get ]\
    [ $portIp3 Ip.Get ] [ $portIp4 Ip.Get ]\
    8000 8000 $scoutingFramePayloadData\
]

# Building the frame that will be used in the flows
#--------------------------------------------------

package require excentis_basic

set frame1 [ ::excentis::basic::Frame.Udp.Set [ $portEth2 Mac.Get ] [ $portEth1 Mac.Get ]\
    [ $portIp2 Ip.Get ] [ $portIp1 Ip.Get ]\
    8000 8000 {-Length 256}\
]

set frame2 [ ::excentis::basic::Frame.Udp.Set [ $portEth1 Mac.Get ] [ $portEth2 Mac.Get ] \
    [ $portIp1 Ip.Get ] [ $portIp2 Ip.Get ]\
    8000 8000\
    {-Length 256}\
]

set frame3 [ ::excentis::basic::Frame.Udp.Set [ $portEth4 Mac.Get ] [ $portEth3 Mac.Get ]\
    [ $portIp4 Ip.Get ] [ $portIp3 Ip.Get ]\
    8000 8000\
    {-Length 512}\
]

set frame4 [ ::excentis::basic::Frame.Udp.Set [ $portEth3 Mac.Get ] [ $portEth4 Mac.Get ]\
    [ $portIp3 Ip.Get ] [ $portIp4 Ip.Get ]\
    8000 8000\
    {-Length 512}\
]

# Define the number of frames that will be sent
set nof 1000

# Then we make some FLOWS
#---------------------------------------------------------------------------------
# Flows are structured lists:
#   - flows are logical constructs to be used by other ByteBlower API
#     procedures.
#   - are a group (struct) of elements which define a one to many topology.
#   - based on a TX and zero, one or more RX part(s)
#   - a list of flows is a scenario which can be executed through executescenario
#   - the TX part defines for 1 ByteBlower port the traffic to be transmitted
#     during the execution of the scenario
#   - the RX part defines for one or multiple ByteBlower ports what information
#     needs to be collected during execution of a scenario. Only one type of
#	  information per RX part can be collected.
#   - flows are always defined as lists containing {-option value} tuples
#	- if you want to test latency you have to enable latency in the TX part
#

set flow1 [ list -tx [ list -port $port1					\
    -scoutingframe [ list \
        -bytes $scoutingFrame1 \
        ]					\
    -frame [ list \
        -bytes $frame1 \
        -sizemodifier { -type growing   \
                        -minimum 64	    \
                        -maximum 1500	\
                        -step 20 }		\
        -l3autochecksum 1 -l3autolength 1 -l4autochecksum 1 -l4autolength 1 \
        ]					\
    -numberofframes $nof			\
    -interframegap 10ms				\
    -timingmodifier { -type none } ]	\
    -rx [ list -port $port2 		\
    -trigger {} ]		\
    -rx [ list -port $port2 		\
    -trigger {} ]		\
    -rx [ list -port $port3 		\
    -trigger { -type basic -filter {} } ]	\
]

set flow2 [ list -tx [ list -port $port2							\
    -scoutingframe [ list \
        -bytes $scoutingFrame2 \
        ]					\
    -frame [ list \
         -bytes $frame2 \
         -sizemodifier { -type random			\
     					  -minimum 60			\
						  -maximum 1514 }		\
		 -l3autochecksum 1 -l3autolength 1 -l4autochecksum 1 -l4autolength 1 \
         ] 						\
    -numberofframes $nof					\
    -interframegap 10ms						\
    -timingmodifier { -type multiburst		\
						   					  -burstsize 10			\
											  -interburstgap 10ms } ]	\
    -rx [ list -port $port1 	\
    -trigger { } ]	\
]

set flow3 [ list -tx [ list -port $port3			\
    -scoutingframe [ list \
        -bytes $scoutingFrame3 \
        ]					\
    -frame [ list -bytes $frame3 ]			\
    -numberofframes $nof	\
    -interframegap 10ms ]	\
    -rx [ list -port $port4		\
    -trigger { } ]		\
]

set flow4 [ list -tx [ list -port $port4			\
    -scoutingframe [ list \
        -bytes $scoutingFrame4 \
        ]					\
    -frame [ list \
            -bytes $frame4 \
            -sizemodifier { -type growing } ]	\
            -l3autochecksum 1 -l3autolength 1 -l4autochecksum 1 -l4autolength 1 \
         ]			\
    -numberofframes $nof	\
    -interframegap 10ms 	\
    -rx [ list -port $port3		\
    -trigger { } ]		\
]

set flow5 [ list -tx [ list -port $port4			\
    -scoutingframe [ list \
        -bytes $scoutingFrame4 \
        ]					\
    -frame [ list -bytes $frame4 ]			\
    -numberofframes $nof	\
    -interframegap 10ms		\
    -latency 1	]	\
    -rx [ list -port $port3		\
    -latency { -type basic -filter {} } ]		\
]

set flow6 [ list -tx [ list -port $port4			\
    -scoutingframe [ list \
        -bytes $scoutingFrame4 \
        ]					\
    -frame [ list -bytes $frame4 ]			\
    -numberofframes $nof	\
    -interframegap 10ms ]	\
    -rx [ list -port $port3		\
    -capture { -filter {} } ]		\
]

set flow7 [ list -tx [ list -port $port4			\
    -scoutingframe [ list \
        -bytes $scoutingFrame4 \
        ]					\
    -frame [ list -bytes $frame4 ]			\
    -numberofframes $nof	\
    -interframegap 10ms		\
    -latency 1	]	\
    -rx [ list -port $port3		\
    -trigger { -type sizedistribution -filter {} } ] \
    -rx [ list -port $port3		\
    -latency { -type basic -filter {} }	] \
    -rx [ list -port $port3		\
    -capture { -filter {} }]
]

#
# III - do something with these flows
#

package require ByteBlowerHL

proc ExecuteScenario { flowlist args } {
    # A scenario is a group of flows to be executed at the same time using a ByteBlower.
    # A scenario sets up the flows, plays the flows and collects information about the flows.
    # After execution of the flows all defined triggers/streams are removed from the
    # ByteBlower port, as a result the port is as clean as it was before the start
    # of this procedure.
    #
    # Flows are structured lists:
    #   - flows are logical constructs to be used by other ByteBlower API
    #     procedures.
    #   - are a group (struct) of elements which define a one to many topology.
    #   - based on a TX and zero, one or more RX part(s)
    #   - a list of flows is a scenario which can be executed through executescenario
    #   - the TX part defines for 1 ByteBlower port the traffic to be transmitted
    #     during the execution of the scenario
    #   - the RX part defines for one or multiple ByteBlower ports what information
    #     needs to be collected during execution of a scenario. Only one type of
    #	  information per RX part can be collected.
    #   - flows are always defined as lists containing {-option value} tuples
    #	- if you want to test latency you have to enable latency in the TX part
    #
    # @param flowlist
    #   the list of flowsstructures that define the scenario
    # @args
    #   @option tbd
    # @return
    #   Counter values collected during this execution
    #   @list
    #      Per given flow a list of -tx and -rx counters values are returned
    #      Depending on the -tx and -rx arguments in the flow definition less or more info
    #      is returned.
    #      The data is returned in the same order as the flow definition
    #      and @param flowlist definition

}

set scenario1 [ ExecuteScenario [ list $flow1 $flow2 $flow3 ] ]
set scenario2 [ ExecuteScenario [ list $flow1 ] ]
set scenario3 [ ExecuteScenario [ list $flow3 $flow4 ] ]

puts "scenario1 <$scenario1>"
puts "scenario2 <$scenario2>"
puts "scenario3 <$scenario3>"

# Based on executescenario several
# higher level 'tests' are provided
#   - flowlossrate
#   - flowlatency
#

proc FlowLossRate { flowlist } {
    # Calculates the lossrate for the provided @param flowlist according to RFC 1242
    # Definition:
    #    Percentage of frames that should have been forwarded
    #    by a network device under steady state (constant)
    #    load that were not forwarded due to lack of
    #    resources.
    # @param args - option list
    #	@option -return
    #		@description: Defines the output mode
    #		@value percentage
    #			@description : Percentage of frames lost during transmission vs offered load
    #    			as an aggregate over all flows in the @param flowratelist
    #		@value numbers
    #			@description : Number of transmitted and received frames per flow in the flowlist.
    #		@default: percentage
    # @return losspercentage or number of transmitted and received frames per flow
    #	@example 0.02
    #	@example { {-tx 100} {-tx 100 -rx 100} {-tx 100 -rx NA} {-tx 100 -rx 100 -rx 100} }
    # Note: A trigger must be defined per receiving flow
    # Note: If non-basic triggers are defined in the flows then
    #       these triggers are ignored
    #       E.g.: sizedistribution and rate triggers are ignored
    #		If Latency and Capture options are defined, they will be ignored too.
    # 		So if besides tx parameters, rx parameters are defined, and these rx
    #   	parameters do not include a basic trigger option, the flow will transmit, but
    #		we will not be able to determine the received frames.
    # Note: When for a particular flow only tx parameters are given, this
    # 		flow will provide background traffic. This flow will be used
    # 		to send traffic, but will not be taken into account for the
    #		calculation of the frame loss rate.

    set result [ executescenario $flow ]
    set losspercenatage [ calculate loss on $result ]

    # Note:
    # Given multiple -rx { -port x -trigger y } elements
    # then the aggregate loss percenatge is calculated as sumallreceived/alltransmitted

    return $losspercentage
}

proc FlowLatency { flowlist } {
    # Calculates the latency for the given @param flowlist.
    # Note: If multiple triggers are defined then the aggregate latency is returned
    #       for the multiple latency triggers
    # Note: All non latency triggers are ignored during the calculation of the
    #       latency.
    # @param args - option list
    #	@option -return
    #		@description: Defines the output mode
    #		@value numbers
    #			@description : Number of transmitted, received frames and latency values per flow in the flowlist.
    #		@default: numbers
    # @return latency in ns calculated per flows in the flowlist where the latency result is a list of
    #		MinLatency AvgLatency MaxLatency Jitter values
    # Note: Latency triggers must be defined per receiving flow
    # Note: If non-basic latency triggers are defined in the flows then
    #       these triggers are ignored
    #       E.g.: distribution trigger is ignored
    #		If Trigger and Capture options are defined, they will be ignored too.
    # 		So if besides tx parameters, rx parameters are defined, and these rx
    #   	parameters do not include a basic latency option, the flow will transmit, but
    #		we will not be able to determine the latency.
    # Note: When for a particular flow only tx parameters are given, this
    # 		flow will provide background traffic. This flow will be used
    # 		to send traffic, but will not be taken into account for the
    #		calculation of the latency.

}

