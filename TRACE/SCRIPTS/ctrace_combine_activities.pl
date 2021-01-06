#!/usr/bin/perl -s
$| = 1; 
if($cat eq ""){ $cat = "WORD"; } 
if($lab eq ""){ $lab = "LAB"; } 
foreach $f (@ARGV){
    $thisset = "ERR";
    if($f =~ "set1"){ $thisset = "A"; }
    if($f =~ "set2"){ $thisset = "B"; }
    @fileparts = split(/\//, $f);
    $awrd = pop @fileparts;
    ($wrd,$fluff) = split(/\_/, $awrd);
    print STDERR "\n\n$0 working on $f\n";
    print STDERR "\tfrom $f, wrd is $wrd, from $awrd (@fileparts)\n";
    $wrd =~ s/Q//g;
    $wrd =~ s/x/\^/g;
    $wrd =~ s/h/S/g;
    $crit = substr($wrd,4,1);
    
    print STDERR "$0 combining comp files at $f \n";
    if(open(F, "$f")){
	open(OF, "> $f".".tocombine.$cat".".txt");
	while(<F>){
	    chomp;
	    print OF "$_\t$cat\t$lab\t$wrd\t$crit\t$thisset\n";
	}
	close F;
	close OF;
    } else { 
	warn "# $0: could not open file \"$f\", skipping.";
    }
}
