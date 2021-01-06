#!/usr/bin/perl -s

# use $0 -skipcol="x,y,z" to specify columns to skip, replace with text from the first file
# use $0 -skiprow="x,y,z" to specify rows to skip, replace with text from first file

if($out eq ""){ $out = "avgout.txt"; } 

if($skipcol ne ""){
    @colskip = split(/\,/, $skip);
}
if($skiprow ne ""){
    @rowskip = split(/\,/, $skip);
}

$maxrow = 0;
$maxcol = 0;
$atfile = 0;
foreach $fil (@ARGV){
    open(F, "$fil");
    $atfile ++;
    $atrow = 0;
    while(<F>){
	chomp;
	@line = split;
	if($#line > $maxcol) { $maxcol = $#line; } 
	for($i = 0; $i <= $#line; $i++){
	    if ( grep( /^$i$/, @colskip ) || grep ( /^$atrow$/, @rowskip ) ) {
		if($atfile == 1) {
		    $data[$atrow][$i] = $line[$i];
		}
	    } else {
		$data[$atrow][$i] += $line[$i];
		$count[$atrow][$i] ++;
	    }
	}
	$atrow++;
	if($atrow > $maxrow){ $maxrow = $atrow; } 
    }
    close F;
    print STDERR "$0 read $atrow rows from $fil\n";
}

open(OF, "> $out");
for($row = 0; $row < $maxrow; $row++){
    for($col = 0; $col <= $maxcol; $col++){
	$d = $data[$row][$col];
	$c = $count[$row][$col];
	$v = $d;
	if($d > 0 && $c > 0){
	    $v = sprintf("%.8f", $d / $c);
	}
	if($col){ print OF "\t"; }
	print OF "$v";
    }
    print OF "\n";
}
