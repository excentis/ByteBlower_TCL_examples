# This tcl script contains procedures to execute a back-to-back test.
# It is intended to be used in conjunction with the following scripts:
#  * general.proc.tcl

source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

proc  BackToBackSetup { serverAddress publicPhysicalPort privatePhysicalPort publicMacAddress privateMacAddress publicIpConfig privateIpConfig publicUdpPort privateUdpPort natPublicUdpPort ethernetLength flowParam } {
    # This procedure will create a server and 2 ByteBlower ports. It also configures the mac and IPv4 addresses for these ports.
    # Next, one or two UDP flows are created (depending on flowParam values) between the source and destination port.
    # Input arguments:
    #   - serverAddress : ByteBlower server ip address or fqdn
    #   - publicPhysicalPort : physical port, e.g. trunk-1-1, to be used as source port
    #   - privatePhysicalPort : physical port, e.g. trunk-1-2, to be used as destination port and which is behind a NAT device.
    #   - publicMacAddress : mac address for the public port
    #   - privateMacAddress : mac address for the NATed port
    #   - publicIpParam, privateIpParam : list of ip parameters for public/private port.
    #       If you want to use dhcp, this list only needs to contain the value 'dhcpv4'
    #       If you want to use a fixed address, this list needs to contain:
    #            *<ipAddress> <gateway ip address> <netmask>
    #       Examples: to use dhcp : [ list dhcpv4]
    #                 to use fixed : [list 10.1.1.2 10.1.1.1 255.255.255.0 ]
    #  - publicUdpPort, destUdpPort : UDP port number for source/destination port
    #  - natPublicUdpPort: UDP port on the NAT device which will forward to destUdpPort
    #  - ethernetLength : ethernet length of frames
    #  - flowParam : list of :
    #        * interframegap
    #        * number of framesl
    #       Examples : [ list 10ms 10000 ]
    # Returns : list of  <serverObject publicByteBlowerPortObject privateByteBlowerPortObject flowList>

    #- Parse flow parameters

    set interFrameGap [lindex $flowParam 0 ]
    set numberOfFrames [lindex $flowParam 1 ]

    set bb [ ByteBlower Instance.Get ]
    set server [ $bb Server.Add $serverAddress ]
    set publicByteBlowerPort [ $server Port.Create $publicPhysicalPort ]
    set privateByteBlowerPort [ $server Port.Create $privatePhysicalPort ]

    [ $publicByteBlowerPort Layer2.EthII.Set ] Mac.Set  $publicMacAddress
    [ $privateByteBlowerPort Layer2.EthII.Set ] Mac.Set  $privateMacAddress

    eval excentis::ByteBlower::Examples::Setup.Port.Layer3 $publicByteBlowerPort $publicIpConfig
    eval excentis::ByteBlower::Examples::Setup.Port.Layer3 $privateByteBlowerPort $privateIpConfig

    puts "Source port:"
    puts [$publicByteBlowerPort Description.Get]
    puts "Destination port:"
    puts [$privateByteBlowerPort Description.Get]
    #- Resolve NAT device public IP address and UDP ports
    #  Note that when the destination ports are behind the SAME NAT device,
    # the publicIpAddress will be the same for both resolved NAT information!
    set natPublicInfo [ ::excentis::ByteBlower::NatDevice.IP.Get $publicByteBlowerPort $privateByteBlowerPort $publicUdpPort $privateUdpPort ]
    set natPublicIpAddress [ lindex $natPublicInfo 0 ]
    #set natPublicUdpPort [ lindex $natPublicInfo 1 ]
    
    puts "Natted Port private IP `[[$privateByteBlowerPort Layer3.IPv4.Get] Ip.Get]' on UDP port `$privateUdpPort' is mapped to NAT device public IP `$natPublicIpAddress' on UDP port `$natPublicUdpPort'"
    puts "Creating flow Public -> NAT -> Private"
    #Setup.Flow.IPv4.UDP.NAT srcPort dstPort ethernetLength publicSrcIP publicDstIP publicSrcUdpPort publicDstUdpPort privateSrcUdpPort privateDstUdpPort numberOfFrames interFrameGap 
    set flows [list [ excentis::ByteBlower::Examples::Setup.Flow.IPv4.UDP.NAT $publicByteBlowerPort $privateByteBlowerPort $ethernetLength  [ [ $publicByteBlowerPort Layer3.IPv4.Get ] Ip.Get ] $natPublicIpAddress $publicUdpPort $natPublicUdpPort  $publicUdpPort $privateUdpPort $numberOfFrames $interFrameGap] ]
   
    return [ list $server $publicByteBlowerPort $privateByteBlowerPort $flows ]
}

