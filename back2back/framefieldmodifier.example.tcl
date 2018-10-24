
##
# In this test scenario, we will create up- and downstream traffic on 50 modems. The traffic will have a variable size and variable
#  interframe gap, but will have some constraints on the maximum up/down stream speed.
#
#  The addresses of the CPE devices will be retrieved using DHCP.
#  The netport will have a fixed address.
# @author Dries Decock - dries.decock@excentis.com
# @date   20070417
# @version 1.0
##

source [ file join [ file dirname [ info script ]]  .. general.proc.tcl ]




# Create the ports
# First create the netport, then create all cpe ports.
puts "I will create 1 netport and 1 cpe port"
set bb [ ByteBlower Instance.Get ]
puts "Creating the netport : "

set port_net [ [ $bb Server.Add $net(Server1) ] Port.Create $net(PhysicalPort1) ]
set nsiL2 [ $port_net Layer2.EthII.Set ]
$nsiL2 Mac.Set $net(MacAddress1)

# --- NSI Port Layer3 setup
set nsiL3 [ $port_net Layer3.IPv4.Set ]
if { $net(PerformDhcp1) == 1 } {
    # --- Using DHCP
    [ $nsiL3 Protocol.Dhcp.Get ] Perform
} else {
    # --- Using static IP
    $nsiL3 Ip.Set $net(IpAddress1)
    $nsiL3 Netmask.Set $net(Netmask1)
    $nsiL3 Gateway.Set $net(IpGW1)
}

# --- Announce us to the network
$nsiL3 Protocol.GratuitousArp.Reply

puts [ $port_net Description.Get ]

puts "Creating cpe : "

set port [ [ $bb Server.Add $cpe(Server1) ] Port.Create $cpe(PhysicalPort1) ]

set cpeL2 [ $port Layer2.EthII.Set ]
$cpeL2 Mac.Set $cpe(MacAddress1)

# --- NSI Port Layer3 setup
set cpeL3 [ $port Layer3.IPv4.Set ]
if { $cpe(PerformDhcp1) == 1 } {
    # --- Using DHCP
    [ $cpeL3 Protocol.Dhcp.Get ] Perform
} else {
    # --- Using static IP
    $cpeL3 Ip.Set $cpe(IpAddress1)
    $cpeL3 Netmask.Set $cpe(Netmask1)
    $cpeL3 Gateway.Set $cpe(IpGW1)
}
# --- Announce us to the network
$cpeL3 Protocol.GratuitousArp.Reply

puts [ $port Description.Get ]
set port_cpe_1 $port


puts "Creating flows"    
set flows [ list ]

set destUdpPort 100

set port_cpe $port_cpe_1
foreach { srcPort destPort speed } [ list \
    $port_net $port_cpe $downstreamRate \
    $port_cpe $port_net $upstreamRate \
 ] {

    set framespersecond [ expr $speed * 1000 / ( $frameSize * 8 ) ]
    set numberOfFrames [ expr $duration * $framespersecond ]

    puts "Flow will send $framespersecond frames per second."
    set ipg [ expr 1000000000 / $framespersecond ]
    set destIp [ [ $destPort Layer3.IPv4.Get ] Ip.Get ]
    
    # ARP for the destination IP, the ByteBlower will ARP for the gateway if
    # the destination IP is on another subnet.  The returned Layer2 address
    # should be used as destination for the frame then.
    
    set destmac [ [ $srcPort Layer3.IPv4.Get ] Protocol.Arp $destIp ]
    
    #[$destPort Layer3.IPv4.Get ] Protocol.Arp [ [$destPort Layer3.IPv4.Get ] Gateway.Get ]
    [ $destPort Layer3.IPv4.Get ] Protocol.Arp [ [ $srcPort Layer3.IPv4.Get ] Ip.Get ]
     
    set trigMac [ [ $destPort Layer2.EthII.Get ] Mac.Get ]

    # Create the (UDP) scouting frame, leaving the IP and ethernet settings to default
    set scoutingFramePayload "BYTEBLOWER SCOUTING FRAME"
    if { [ binary scan $scoutingFramePayload H* scoutingFramePayloadHex ] != 1 } {
        error "UDP flow setup error: Unable to generate ByteBlower scouting frame payload."
    }
    set scoutingFramePayloadData [ ::excentis::basic::String.To.Hex $scoutingFramePayloadHex ]
    set scoutingFrame [ ::excentis::basic::Frame.Udp.Set $destmac [ [ $srcPort Layer2.EthII.Get ] Mac.Get ] \
        [ [ $destPort Layer3.IPv4.Get ] Ip.Get ] [ [ $srcPort Layer3.IPv4.Get ] Ip.Get ] \
        $destUdpPort 100 $scoutingFramePayloadData \
    ]
    
    set frame [ ::excentis::basic::Frame.Udp.Set $destmac [ [ $srcPort Layer2.EthII.Get ] Mac.Get ] \
        [ [ $destPort Layer3.IPv4.Get ] Ip.Get ] [ [ $srcPort Layer3.IPv4.Get ] Ip.Get ] \
        $destUdpPort 100 [ list -Length $frameSize ] \
    ]
    set flow [ list \
        -tx [ list -port $srcPort \
            -scoutingframe [ list \
                -bytes $scoutingFrame \
                ] \
            -frame [ list \
                -bytes $frame \
                -fieldmodifier [ list \
                    -type $fieldModifierType \
                    -offset $fieldModifierOffset \
                    -length $fieldModifierLength \
                    -minimum $fieldModifierMinimum \
                    -maximum $fieldModifierMaximum \
                    -step $fieldModifierStep \
                    -initialvalue $fieldModifierInitialValue \
                    ] \
                ] \
            -numberofframes $numberOfFrames \
            -interframegap [ subst $ipg ]ns  \
        ] \
        -rx [ list -port $destPort \
            -trigger [ list -type basic \
                -filterFormat bpf \
                -filter "(ether dst $trigMac) and (ip dst $destIp) and (udp dst port $destUdpPort)" \
        ] ] ]
    puts "Flow Configuration: $flow"
    lappend flows $flow
    
    incr destUdpPort
    
}



puts "Starting the test"
set result [ ::excentis::ByteBlower::ExecuteScenario $flows -finaltimetowait 5000 ]
puts "result: $result"

puts "Cleaning up:"
foreach server [ $bb Server.Get ] {
    $server Destructor
}



