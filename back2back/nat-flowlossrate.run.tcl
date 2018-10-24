# Example of how to run a flowlossrate test on a NATed setup.
# Details in the run and proc scripts.
##
source [ file join [ file dirname [ info script ]]  nat-flowlossrate.conf.tcl ]
source [ file join [ file dirname [ info script ]]  nat-flowlossrate.example.tcl ]
