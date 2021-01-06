#!/usr/bin/perl -s

if($path eq ""){ $path = "."; } # use current dir if none specified
$path .= "/";

foreach $tracein (@ARGV){

    print STDERR "    ####  $0 STARTING $tracein  ####\n";

    # determine data directory name
    $base = substr($tracein,0,-8); # lop off '.tracein' from filename
    $data = "data_$base";
    $tracein = $path . $tracein;
    print STDERR "$0 system call: rm -rf data\n";
    system "rm -rf data";
    print STDERR "$0 system call: mkdir data\n";
    system "mkdir data";
    print STDERR "$0 system call: $path"."trace < $tracein > traceout\n";
    system "$path"."trace < $tracein > traceout";
    print STDERR "$0 system call: rm traceout\n";
    system "rm traceout";
    print STDERR "$0 system call: mv $path"."data $path"."$data\n";
    system "mv data $path"."$data";

    print STDERR "    ----  $0 FINISHED $tracein  ----\n\n";
}
