# This tcl script contains procedures to execute a back-to-back test.
# It is intended to be used in conjunction with the following scripts:
#  * general.proc.tcl

source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

proc  BackToBackSetup { serverAddress meetingPointAddress publicPhysicalPort wirelessEndpointUUID publicMacAddress publicIpConfig publicUdpPort privateUdpPort ethernetLength flowParam } {
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
    #  - ethernetLength : ethernet length of frames
    #  - flowParam : list of :
    #        * bidir : boolean indicating unidirectional (0) or bidirectional (1) traffic
    #        * interframegap
    #        * number of framesl
    #       Examples : unidirectional : [ list 0 10ms 10000 ]
    #                  bidirectional : [ list 1 10ms 10000 ]
    # Returns : list of  <serverObject publicByteBlowerPortObject privateByteBlowerPortObject flowList>

    #- Parse flow parameters
    set bidir [lindex $flowParam 0 ]
    set interFrameGap [lindex $flowParam 1 ]
    set numberOfFrames [lindex $flowParam 2 ]

    set bb [ ByteBlower Instance.Get ]
    set server [ $bb Server.Add $serverAddress ]
    set publicByteBlowerPort [ $server Port.Create $publicPhysicalPort ]
    
    set meetingpoint [ $bb MeetingPoint.Add $meetingPointAddress ]
    set wirelessEndpoint [ $meetingpoint Device.Get $wirelessEndpointUUID]

    [ $publicByteBlowerPort Layer2.EthII.Set ] Mac.Set  $publicMacAddress

    eval excentis::ByteBlower::Examples::Setup.Port.Layer3 $publicByteBlowerPort $publicIpConfig

    puts "Source port:"
    puts [$publicByteBlowerPort Description.Get]
    puts "Destination port:"
    puts [$wirelessEndpoint Description.Get]

    if { [ catch {
        #- Resolve NAT device public IP address and UDP ports
        #  Note that when the destination ports are behind the SAME NAT device,
        # the publicIpAddress will be the same for both resolved NAT information!
        set natPublicInfo [ ::excentis::ByteBlower::NatDevice.IP.Get $publicByteBlowerPort $wirelessEndpoint $publicUdpPort $privateUdpPort ]
        
        set natPublicIpAddress [ lindex $natPublicInfo 0 ]
        set natPublicUdpPort [ lindex $natPublicInfo 1 ]
        
        set wirelessEndpointIp [ [ [ $wirelessEndpoint Device.Info.Get ] Network.Info.Get ] IPv4.Get ]
    

        puts "Natted Port private IP '$wirelessEndpointIp' on UDP port `$privateUdpPort' is mapped to NAT device public IP `$natPublicIpAddress' on UDP port `$natPublicUdpPort'"
        puts "Creating flow Public -> NAT -> Private"
        set flows [list [ excentis::ByteBlower::Examples::Setup.Flow.IPv4.UDP.NAT $publicByteBlowerPort $wirelessEndpoint $ethernetLength  [ [ $publicByteBlowerPort Layer3.IPv4.Get ] Ip.Get ] $natPublicIpAddress $publicUdpPort $natPublicUdpPort  $publicUdpPort $privateUdpPort $numberOfFrames $interFrameGap] ]
        if { $bidir == 1 } {
            puts "Creating flow Public <- NAT <- Private"
            lappend flows [ excentis::ByteBlower::Examples::Setup.Flow.IPv4.UDP.NAT $wirelessEndpoint $publicByteBlowerPort $ethernetLength  $natPublicIpAddress [ [ $publicByteBlowerPort Layer3.IPv4.Get ] Ip.Get ] $natPublicUdpPort $publicUdpPort $privateUdpPort $publicUdpPort $numberOfFrames $interFrameGap]
        }
    } err ] } {
        catch { $wirelessEndpoint Lock 0 }
        error $err
    }
    
    return [ list $server $meetingpoint $publicByteBlowerPort $wirelessEndpoint $flows ]
}

