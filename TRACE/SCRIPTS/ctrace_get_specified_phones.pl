#!/usr/bin/perl -s
if($slice eq ""){ $slice = 12; }
if($phone eq ""){ $phone = "aiuxpbtdkgshrl"; } 
if($expect eq ""){ $expect = "a"; } 
if($actual eq ""){ $actual = $expect; }
if($cat eq ""){ $cat = "WORD"; } 
if($lab eq ""){ $lab = "LAB"; } 
print STDERR "$0 checking PHONEMES at tslice $slice for expected /$expect/ and actual /$actual/\n";
foreach $f (@ARGV){
    if($cat eq "WORD" && $actual ne $expect){ warn "\n\t***** $0: for $f, expect $expect ne actual $actual.\n";}
    if(open(F, "$f")){
	open(OF, "> $f".".slice$slice".".$cat".".txt");
	while(<F>){
	    chomp;
	    s/S/h/g;
	    s/\^/x/g;
	    ($tim, $phon, @dat) = split;
#	    next unless $phone =~ $phon;
	    next unless ($phon eq $expect || $phon eq $actual);
	    if($phon eq $expect){ $label = "EXPECT"; } else { $label = "ACTUAL";}
	    print OF "$tim\t$lab\t$cat\t$label\t$f\t$phon\t$dat[$slice]\n";
	}
	close F;
	close OF;
    } else { 
	warn "# $0: could not open file \"$f\", skipping.";
    }
}
