#!/usr/bin/perl -s

# take a list of files and aggregate them based on instance number (rank order)

@alldat = ();
foreach $fil (@ARGV){
    print STDERR "$0 working on $fil\n";

    @parts = split(/\//, $fil);
    $base = $parts[$#parts];
    $data = $parts[$#parts - 1];

    ($input, $rest) = split(/\_/, $base);
    # data_trace_bd_0.75_neutral_10
    ($jnk, $jnk2, $jnk3, $noise, $prime, $condition, $run) = split(/\_/, $data);

    $noise =~ s/n//g;
    $prime =~ s/p//g;
    $input =~ s/Q//g;
    $input =~ s/x/\^/g;
    $input =~ s/h/S/g;
    $run *= 1;

    open(F, "$fil");
    while(<F>){
	chomp;
	next if($_ eq "");
	$alldat .=  "$condition\t$noise\t$prime\t$run\t$input\t$_\n";
    }
    close F;
}

print $alldat;

    

    

