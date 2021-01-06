#!/usr/bin/perl -s

if($path eq ""){ $path = "."; }
$path .= "/";
if($label eq ""){ $label = "_set";}
if($outit eq ""){ $outit = "trace_ghd_items_";}

# we need to rotate items through all possible roles; if we do not,
# minor interactions with other lexical items over time create imbalances
# that can result in large, if transient, differences between targets
# and trained items

# Need 6 lists.
# TRG  TRN  NON
#  A    B    C
#  A    C    B
#  B    A    C
#  B    C    A
#  C    A    B
#  C    B    A

# OR -- to maintain more direct comparability with the other
# simulations, we could just keep set A (original items) in
# the word role and only do the other two

# **** * SET "-simpler" at command line to reduce to these *****
# TRG  TRN  NON
#  A    B    C
#  A    C    B



# get the base lexicon     
open(LEX, $path."$lex") || die("Could not open lexicon file \"$lex\"; exiting. ");
while(<LEX>){
    chomp;
    push @lexicon, $_;
}
close LEX;


# We get the base items from the items file
open(IT, $path."$items") || die("Could not open items file \"$items\"; exiting");
$at = 1;
while(<IT>){
    chomp; # remove trailing newline
    next if(substr($_,0,1) eq "#"); # skip lines that begin with # -- headers, comments
    print OT "$_";
    ($a, $b, $c) = split; # read the 3 columns of current line into these 3 variables

    $ap = substr($a,4,1);
    $bp = substr($b,4,1);
    $cp = substr($c,4,1);

    $set[1][$at] = "$a\t$b\t$c\t$ap\t$bp\t$cp";
    $set[2][$at] = "$a\t$c\t$b\t$ap\t$cp\t$bp";
    unless($simpler){
	$set[3][$at] = "$b\t$a\t$c\t$bp\t$ap\t$cp";
	$set[4][$at] = "$b\t$c\t$a\t$bp\t$cp\t$ap";
	$set[5][$at] = "$c\t$a\t$b\t$cp\t$ap\t$bp";
	$set[6][$at] = "$c\t$b\t$a\t$cp\t$bp\t$ap";
    }

    # now restore TRACE phonemes for x and h (--> ^ and S)
    $a =~ s/x/\^/g;
    $a =~ s/h/S/g;
    $b =~ s/x/\^/g;
    $b =~ s/h/S/g;
    $c =~ s/x/\^/g;
    $c =~ s/h/S/g;

    # now put them in 2d list for later
    $wrd[1][$at] = "$a";
    $wrd[2][$at] = "$a";
    unless($simpler){
	$wrd[3][$at] = "$b";
	$wrd[4][$at] = "$b";
	$wrd[5][$at] = "$c";
	$wrd[6][$at] = "$c";
    }
    
    $trn[1][$at] = "$b";
    $trn[2][$at] = "$c";
    unless($simpler){
	$trn[3][$at] = "$a";
	$trn[4][$at] = "$c";
	$trn[5][$at] = "$a";
	$trn[6][$at] = "$b";
    }
    
    $at++;
}
close IT;

if(substr($items,-4) eq ".txt"){
    $itbase = substr($items,0,-4);
} else {
    $itbase = $items;
}

$nsets = 6;
if($simpler){ $nsets = 2; } 

for($s = 1; $s <= $nsets; $s++){
    $setx = $lex.$label.$s;
    open(LEXA, "> $path"."$setx".".orig");
    open(LEXB, "> $path"."$setx".".trained");

    # add all base words to each lexicon
    foreach $alex(@lexicon){
	print LEXA "$alex\n";
	print LEXB "$alex\n";
    }
    # open the items files
    open(SF, "> $path"."$itbase".".set$s".".txt");
    #
    for($row = 1; $row < $at; $row++) {
	# add all details to items file
	print SF "$set[$s][$row]\n";
	# add all original target words to each lexicon
	print LEXA "$wrd[$s][$row] 1\n";
	print LEXB "$wrd[$s][$row] 1\n";
    }
    for($row = 1; $row < $at; $row++) {
	# add all 'trained' words to trained lexicon
	print LEXB "$trn[$s][$row] 1\n";
    }
    close SF;
    close SET;
}


    
