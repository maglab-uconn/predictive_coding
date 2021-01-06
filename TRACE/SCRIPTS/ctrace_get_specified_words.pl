#!/usr/bin/perl -s
if($slice eq ""){ $slice = 4; }
if($lab   eq ""){ $lab   = "LAB"; } 

print STDERR "$0 checking WORDS at tslice $slice for expected /$word/ and trainer /$train/ given $input $stim\n";

foreach $f (@ARGV){
    if(open(F, "$f")){
	open(OF, "> $f".".wrdslice$slice".".$input".".txt");
	while(<F>){
	    chomp;
	    s/S/h/g;
	    s/\^/x/g;

	    ($tim, $wrd, @dat) = split;
	    if($debug){	print STDERR "-------- ## comparing TRACE item $wrd to $word and $train\n";}
	    next unless ($wrd eq $word || $wrd eq $train);
	    if($wrd eq $word){
		if($debug){print STDERR " \t**** found word ($wrd eq $word)\n";}
		print OF "$tim\t$lab\t$input\tOriginal\t$wrd\t$word\t$train\t$stim\t$dat[$slice]\n";
	    } elsif($wrd eq $train){
		if($debug){print STDERR " \t**** found train ($wrd eq $train)\n";}
		print OF "$tim\t$lab\t$input\tTrained\t$wrd\t$word\t$train\t$stim\t$dat[$slice]\n";
	    }
	}
	close F;
	close OF;
    } else { 
	warn "# $0: could not open file \"$f\", skipping.";
    }
}
