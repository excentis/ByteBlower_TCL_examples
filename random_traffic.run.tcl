# This script will run the back-to-back IPv4 example, by sourcing all necessary files.
source [ file join [ file dirname [ info script ]] random_traffic.conf.tcl ]
source [ file join [ file dirname [ info script ]] random_traffic.example.tcl ]
