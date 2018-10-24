source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

# This example demonstrates the usage of ByteBlower::Results.Refresh
# The advantage of calling Results.Refresh instead of calling Refresh on every
# result object is that if supported by the ByteBlower server (since 2.2), the
# API will combine these Refresh calls into a single call. 
# This has the advantange that the new approach is usually much faster than 
# calling Refresh on every result seperately.

proc RunScoutingFlow { dstPort srcPort dstUdpPort srcUdpPort { numberOfFrames 1 } { interFrameGap 10000000 } { leadOutTime 100000000 } } {
    return [ excentis::ByteBlower::Examples::RunScoutingFlowV4 $dstPort $srcPort $dstUdpPort $srcUdpPort $numberOfFrames $interFrameGap $leadOutTime ]
}

proc CreateStream { dstPort srcPort dstUdpPort srcUdpPort frameSize interFrameGap numberOfFrames } {

    set srcIp [ [ $srcPort Layer3.IPv4.Get ] Ip.Get ]
    set dstIp [ [ $dstPort Layer3.IPv4.Get ] Ip.Get ]
    puts "Creating stream $srcIp : $srcUdpPort --> $dstUdpPort : $dstIp"

    set srcMac [ [ $srcPort Layer2.EthII.Get ] Mac.Get ]
    set dstMac [ [ $srcPort Layer3.IPv4.Get ] Resolve $dstIp ]
    
    set srcFrame1 [ ::excentis::basic::Frame.Udp.Set $dstMac $srcMac $dstIp $srcIp $dstUdpPort $srcUdpPort [ list -Length [ expr $frameSize - 42 ] ] ]
    set stream [ $srcPort Tx.Stream.Add ]
    [ $stream Frame.Add ] Bytes.Set $srcFrame1
    $stream InterFrameGap.Set $interFrameGap
    $stream NumberOfFrames.Set $numberOfFrames
    
    return $stream

}

proc CreateTrigger { dstPort srcPort dstUdpPort srcUdpPort } {
    set trigger [ $dstPort Rx.Trigger.Basic.Add ]
    set dstMac [ [ $dstPort Layer2.EthII.Get ] Mac.Get ]
    set dstIp [ [ $dstPort Layer3.IPv4.Get ] Ip.Get ]
    $trigger Filter.Set "ip dst $dstIp and udp dst port $dstUdpPort"
    return $trigger
}

set byteBlower [ ByteBlower Instance.Get ]
set server [ $byteBlower Server.Add $serverAddress ]

puts "Creating NSI side port"
# initialize NSI port
set nsiPort [ $server Port.Create $physicalPort1 ]
set nsiL2 [ $nsiPort Layer2.EthII.Set ]
$nsiL2 Mac.Set $nsiMacAddress1

set nsiL3 [ $nsiPort Layer3.IPv4.Set ]
if { $nsiPerformDhcp1 == 1 } {
    # --- Using DHCP
    [ $nsiL3 Protocol.Dhcp.Get ] Perform
} else {
    # --- Using static IP
    $nsiL3 Ip.Set $nsiIpAddress1
    $nsiL3 Netmask.Set $nsiNetmask1
    $nsiL3 Gateway.Set $nsiIpGW1
}
# Send a Gratuitous ARP, so the network knows at L2 we're here
$nsiL3 Protocol.GratuitousArp.Reply

# initialize CPE port
puts "Creating CPE side port"
set cpePort [ $server Port.Create $physicalPort2 ]
set cpeL2 [ $cpePort Layer2.EthII.Set ]
$cpeL2 Mac.Set $cpeMacAddress1

set cpeL3 [ $cpePort Layer3.IPv4.Set ]
if { $cpePerformDhcp1 == 1 } {
    # --- Using DHCP
    [ $cpeL3 Protocol.Dhcp.Get ] Perform
} else {
    # --- Using static IP
    $cpeL3 Ip.Set $cpeIpAddress1
    $cpeL3 Netmask.Set $cpeNetmask1
    $cpeL3 Gateway.Set $cpeIpGW1
}
# Send a Gratuitous ARP, so the network knows at L2 we're here
$cpeL3 Protocol.GratuitousArp.Reply

set results [ list ]
set streams [ list ]
set triggers [ list ]

puts "Creating streams"
for { set flowIdx 0 } { $flowIdx < $nrOfFlows } { incr flowIdx} {
    set srcUdpPort $baseUdpPort
    set dstUdpPort [ incr baseUdpPort ]
    incr baseUdpPort
    
    RunScoutingFlow $nsiPort $cpePort $dstUdpPort $srcUdpPort 2
    
    set stream [ CreateStream $nsiPort $cpePort $dstUdpPort $srcUdpPort $ethernetLength $interFrameGap $numberOfFrames ]
    lappend streams $stream
    
    set trigger [ CreateTrigger $nsiPort $cpePort $dstUdpPort $srcUdpPort ]
    lappend triggers $trigger
    
    # add the result objects of the stream and for the trigger to the results list!
    lappend results [ $stream Result.Get ] [ $trigger Result.Get ]
    
    if { $bidir == 1 } {
        set srcUdpPort $baseUdpPort
        set dstUdpPort [ incr baseUdpPort ]    
        incr baseUdpPort
                
        RunScoutingFlow $cpePort $nsiPort $dstUdpPort $srcUdpPort 2
        
        set stream [ CreateStream $cpePort $nsiPort $dstUdpPort $srcUdpPort $ethernetLength $interFrameGap $numberOfFrames ]
        lappend streams $stream
        
        set trigger [ CreateTrigger $cpePort $nsiPort $dstUdpPort $srcUdpPort ]
        lappend triggers $trigger
        
        # add the result objects of the stream and for the trigger to the results list!
        lappend results [ $stream Result.Get ] [ $trigger Result.Get ]
        
    }
    
}

puts "Created [ llength $streams ] streams"
puts "Created [ llength $triggers ] triggers"

# calculate duration
# duration in nanoseconds = number of frames * inter frame gap
set duration_ns [ expr $numberOfFrames * double($interFrameGap) ]
set duration_ms [ expr int(ceil($duration_ns / 1000000)) ]

# Start the ports
$byteBlower Ports.Start $nsiPort $cpePort

# Wait for half of the duration before refreshing...
after [ expr $duration_ms / 2 ]

# Why did we need the results list? Well it will be clear in the next line of code
eval { $byteBlower Results.Refresh } $results
# in the 2.1 API the line above would be written like this
#foreach result $results {
#    $result Refresh
#}

for { set i 0 } { $i < [ llength $streams ] } { incr i } {
    set stream [ lindex $streams $i ]
    set streamResult [ $stream Result.Get ]
    set streamFrames [ $streamResult PacketCount.Get ]
    set trigger [ lindex $triggers $i ]
    set triggerResult [ $trigger Result.Get ]
    set triggerFrames [ $triggerResult PacketCount.Get ]
    puts "Stream [ expr $i + 1 ] sent $streamFrames frames, trigger received $triggerFrames frames" 
}

after [ expr $duration_ms / 2 ]

after 1000

$byteBlower Ports.Stop $nsiPort $cpePort

# Wait a little for last frames to be received.
after 1500

# Ports are stopped now, so refresh for the final results
eval { $byteBlower Results.Refresh } $results
# in the 2.1 API the line above would be written like this
#foreach result $results {
#    $result Refresh
#}

set result [ list ]
foreach { streamResult triggerResult } $results {
    set streamFrames [ $streamResult PacketCount.Get ]
    set triggerFrames [ $triggerResult PacketCount.Get ]
    puts "Stream [ expr $i + 1 ] sent $streamFrames frames, trigger received $triggerFrames frames" 
    lappend result [ list $streamFrames $triggerFrames ]
}

# Cleanup
$server Destructor
