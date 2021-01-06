#!/usr/bin/perl -s

if($path eq ""){ $path = "."; }
$path .= "/";

if($items eq ""){ $items = "trace_ghd_items.txt"; }
if($label eq ""){ $label = "trace_ghd_"; }
if($lexlabel eq ""){ $lexlabel = $path."LEX/slex_base_ghd_"; }


foreach $itemfile (@ARGV) {

    (@fileparts) = split(/\./, $itemfile);
    $set = $fileparts[$#fileparts-1];

    

    $lex_orig  = $lexlabel.$set.".orig";
    $lex_train = $lexlabel.$set.".trained";

    $tracein_orig  = $label.$set.".orig.tracein";
    $tracein_train = $label.$set.".train.tracein";

    print STDERR "\n---------------------------------------------------------------------------\n";
    print STDERR "$0 working on $itemfile,\n\t\t\t\t\tmaking $path"."$tracein_orig and $path"."$tracein_train\n";

    open(TIOR, "> $path"."$tracein_orig");
    open(TITR, "> $path"."$tracein_train");

    # specify default TRACE parameters for both simulations
    $parline = "p PARAM/par_def_wp0.03_gsd0\n"; 
    printf TIOR $parline;
    printf TITR $parline;

    # specify appropriate lexicon for each simulation 
    printf TIOR "l $lex_orig\n";
    printf TITR "l $lex_train\n";

    # now let's get the items
    $itemfile = $itemfile;
    open(IT, "$itemfile") || die("Cannot open trace items file \"$itemfile\". $0 exiting.");

    while(<IT>){
	chomp;
	next if(substr($_,0,1) eq "#"); # skip lines beginning with '#'
	s/x/\^/g; # restore TRACE phoneme x --> ^
	s/h/S/g;  # restore TRACE phoneme h --> S

	# fields are orig = original word, non1 = nonword variant 1 (to be trained),
	# non2 = nonword variant 2, po = critical phoneme in original word,
	# p1 = critical phoneme in non1, p2 = critical phoneme in non2
	($orig, $non1, $non2, $po, $p1, $p2) = split;

	$testline =  "\ntest $orig\nsim\n\ntest $non1\nsim\n\ntest $non2\nsim\n";
	printf TIOR $testline;
	printf TITR $testline;
    }
    close IT;

    # add the 2 qs at end of tracein files to make trace close
    $quitline = "\nq\nq\n";
    printf TIOR $quitline;
    printf TITR $quitline;

    close TIOR;
    close TITR;
}

print STDERR "\n--------------------------------------------------------------------------------\n$0 COMPLETE\n";
print STDERR "--------------------------------------------------------------------------------\n\n";
    
