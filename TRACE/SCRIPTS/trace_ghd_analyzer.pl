#!/usr/bin/perl -s


# user can specify alternative paths with appropriate command line switches
# e.g., trace_ghd_analyzer.pl -path_scripts=SCRIPTS/NEWSCRIPTS/
if($path_scripts eq ""){ $path_scripts = "SCRIPTS/" ; } 
if($phonscript eq ""){ $phonscript = $path_scripts."ctrace_get_specified_phones.pl"; } 
if($combscript eq ""){ $combscript = $path_scripts."ctrace_combine_activities.pl"; } 
if($lexscript eq ""){ $lexscript = $path_scripts."ctrace_get_specified_words.pl"; } 
if($path eq ""){ $path = ".";}
$path .= "/";

foreach $itemfile(@ARGV){
    print STDERR "#### #### $0 STARTING $itemfile #### ####\n\n";

    ($fbase, $set, $extension) = split(/\./, $itemfile);
    $fbase =~ s/_items//; # remove string '_items' from filebase
    $path_pre  = $path."data_$it"."_$set".".orig/";
    $path_post = $path."data_$it"."_$set".".train/";

    @commands = (); # put series of commands into this list
    open(IT, "$itemfile") || die("Could not open items file \"$itemfile\"; $0 exiting");
    while(<IT>){
	chomp; # remove trailing newline
	next if(substr($_,0,1) eq "#"); # skip lines that begin with # -- headers, comments
	($orig, $non1, $non2, $po, $p1, $p2) = split; # read the 6 columns of current line into these 6 variables

	##################################################################
	# PRETRAINING -- 'original' lexicon 
	##################################################################
	# phone commands for pretraining
	push @commands, "$phonscript -lab=PRE  -cat=TRAIN -expect=$po -actual=$p1 $path_pre"."Q$non1"."Q_phon.txt";
	push @commands, "$phonscript -lab=PRE  -cat=NON   -expect=$po -actual=$p2 $path_pre"."Q$non2"."Q_phon.txt";
	push @commands, "$phonscript -lab=PRE  -cat=WORD  -expect=$po -actual=$po $path_pre"."Q$orig"."Q_phon.txt";

	# combined activity commands for pretraining
	push @commands, "$combscript   -lab=PRE  -cat=TRAIN $path_pre"."Q$non1"."Q_comp.txt";
	push @commands, "$combscript   -lab=PRE  -cat=NON   $path_pre"."Q$non2"."Q_comp.txt";
	push @commands, "$combscript   -lab=PRE  -cat=WORD  $path_pre"."Q$orig"."Q_comp.txt";

	# lexical commands for pretraining
	push @commands, "$lexscript  -lab=PRE -input=TRAIN -word=$orig -train=NA -stim=$non1 $path_pre"."Q$non1"."Q_word.txt";
	push @commands, "$lexscript  -lab=PRE -input=NON   -word=$orig -train=NA -stim=$non2 $path_pre"."Q$non2"."Q_word.txt";
	push @commands, "$lexscript  -lab=PRE -input=WORD  -word=$orig -train=NA -stim=$orig $path_pre"."Q$orig"."Q_word.txt";

	##################################################################
	# POSTTRAINING -- 'train' lexicon with nonword 1 added
	##################################################################
	# phone commands for post1
	push @commands, "$phonscript -lab=POST -cat=TRAIN -expect=$po -actual=$p1 $path_post"."Q$non1"."Q_phon.txt";
	push @commands, "$phonscript -lab=POST -cat=NON   -expect=$po -actual=$p2 $path_post"."Q$non2"."Q_phon.txt";
	push @commands, "$phonscript -lab=POST -cat=WORD  -expect=$po -actual=$po $path_post"."Q$orig"."Q_phon.txt";

	# combined competitor commands for post1
	push @commands, "$combscript   -lab=POST -cat=TRAIN $path_post"."Q$non1"."Q_comp.txt";
	push @commands, "$combscript   -lab=POST -cat=NON   $path_post"."Q$non2"."Q_comp.txt";
	push @commands, "$combscript   -lab=POST -cat=WORD  $path_post"."Q$orig"."Q_comp.txt";
	
	# lexical commands for post1
	push @commands, "$lexscript  -lab=POST -input=TRAIN -word=$orig -train=$non1 -stim=$non1 $path_post"."Q$non1"."Q_word.txt";
	push @commands, "$lexscript  -lab=POST -input=NON   -word=$orig -train=$non1 -stim=$non2 $path_post"."Q$non2"."Q_word.txt";
	push @commands, "$lexscript  -lab=POST -input=WORD  -word=$orig -train=$non1 -stim=$orig $path_post"."Q$orig"."Q_word.txt";

    }
    close IT; # close items file

    if($debug){
	print  "---------------------------------------------\n";
	print "Running commands from: \n";
	print  "---------------------------------------------\n";
	system "pwd";
	print  "---------------------------------------------\n";
	
        for($i = 0; $i < 2; $i++){
	    $ac = pop @commands;
	    push @somecommands, $ac;
	}
	@commands = @somecommands;
    }
    
    # now run the commands while printing them to stdout for user to see/capture
    foreach $syscmd (@commands){
	print $syscmd . "\n";
	system($syscmd);
    }

    print STDERR "====    ====  $0 COMPLETED $itemfile  ====    ====\n\n";
}



