#!/usr/bin/perl -s

while(<>){
    chomp;
    ($file, $label, $input, $target, $instim, $wrd, $train, $stim, $act) = split;
    next if($label ne "POST" || $input ne "NON");
    if($target eq "Original"){
	$orig{$wrd."#".$train} = $act;
    }
    if($target eq "Trained"){
	$train{$wrd."#".$train} = $act;
    }
}


foreach $w (sort(keys %orig)){
    printf("$w\t%f\t%f\t%.8f\n",
	   $orig{$w}, $train{$w}, ($orig{$w} - $train{$w}) );
}
