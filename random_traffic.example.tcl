
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

source [ file join [ file dirname [ info script ]]  general.proc.tcl ]




# Create the ports
# First create the netport, then create all cpe ports.
puts "I will create 1 netport and $numberOfPorts cpe ports"
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

# --- NSI Port online, announce ourselves
$nsiL3 Protocol.GratuitousArp.Reply

puts [ $port_net Description.Get ]
set port_cpe_list [ list ]
for { set i 1 } { $i <= $numberOfPorts  } { incr i } {
    puts "Creating cpe $i : "
    
    set port [ [ $bb Server.Add $cpe(Server$i) ] Port.Create $cpe(PhysicalPort$i) ]
    
    set cpeL2 [ $port Layer2.EthII.Set ]
    $cpeL2 Mac.Set $cpe(MacAddress$i)

    # --- NSI Port Layer3 setup
    set cpeL3 [ $port Layer3.IPv4.Set ]
    if { $cpe(PerformDhcp$i) == 1 } {
        # --- Using DHCP
        [ $cpeL3 Protocol.Dhcp.Get ] Perform
    } else {
        # --- Using static IP
        $cpeL3 Ip.Set $cpe(IpAddress$i)
        $cpeL3 Netmask.Set $cpe(Netmask$i)
        $cpeL3 Gateway.Set $cpe(IpGW$i)
    }

    
    puts [ $port Description.Get ]
    set port_cpe_$i $port
    lappend port_cpe_list $port
    
    # --- CPE Port online, announce ourselves
    $cpeL3 Protocol.GratuitousArp.Reply
}

puts "Creating flows"    
set flows [ list ]

set destUdpPort 100
for { set i 1 } { $i <= $numberOfPorts } { incr i } {
    set port_cpe [ lindex $port_cpe_list [ expr $i - 1 ] ]
    foreach { srcPort destPort speed } [ list \
        $port_net $port_cpe $downstreamRate \
        $port_cpe $port_net $upstreamRate \
     ] {
        set averageSize [ expr ( $minFrameSize + $maxFrameSize  ) / 2 ]

        set framespersecond [ expr $speed * 1000 / ( $averageSize * 8 ) ]
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
            $destUdpPort 100 { -Length 200 } \
        ]
        set flow [ list \
            -tx [ list -port $srcPort \
                -scoutingframe [ list \
                    -bytes $scoutingFrame \
                ] \
                -frame [ list \
                    -bytes $frame \
                    -sizemodifier [ list  -type random -minimum $minFrameSize -maximum $maxFrameSize ] \
                    -l3autochecksum 1 -l3autolength 1 -l4autochecksum 1 -l4autolength 1 \
                ] \
                -numberofframes $numberOfFrames \
                -interframegap [ subst $ipg ]ns  \
            ] \
            -rx [ list -port $destPort \
                -trigger [ list -type basic \
                    -filterFormat bpf \
                    -filter "(ether dst $trigMac) and (ip dst $destIp) and (udp dst port $destUdpPort)" \
            ] ] ]
            #            -timingmodifier [list  -type normaldistribution -variance [expr $ipg / 2 ] ] ] \
            #
        puts "Flow Configuration: $flow"
        lappend flows $flow
        
        incr destUdpPort
        
    }

}

puts "Starting the test"
set result [ ::excentis::ByteBlower::ExecuteScenario $flows -finaltimetowait 5000 ]
puts "result: $result"

puts "Cleaning up:"
foreach server [ $bb Server.Get ] {
    $server Destructor
}



