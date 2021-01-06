----------------------------------------------------------------------
       TRACE SIMULATIONS OF GAGNEPAIN, HENDERSON, & DAVIS (2012)
                    ( and a few miscellaneous items )
----------------------------------------------------------------------
                        Jim Magnuson, 2021.01.06
----------------------------------------------------------------------

This directory contains a somewhat-modfied version of the original C
implementation of TRACE (cTRACE), obtained from Jay McClelland in the
early 2000s. It currently compiles on Macintosh and Linux computers,
but cannot run on Linux machines -- an undeclared register creates a
segmentation fault. We unfortunately have been unable to solve the
runtime segmentation fault under Linux. If you are able to solve it,
please share the solution! However, the code runs on a Mac. It has not
been tested on Windows (e.g., in a cygwin environment).

The simulations and analyses are automated via a series of simple
shell scripts (really, just "source"-able lists of commands) and some
fairly complex (and unfortunately amateur) perl scripts I wrote.

----------------------------------------------------------------------

COMPILING TRACE

To run the simulations on your local machine, you would need to first
compile the TRACE model. To do this, go to the cTRACE directory and
simply enter the command 'make' at the command line. You will get
various warning messages, but it should compile. To check whether it
did, use the command "ls -l trace" to verify that you have recreated
the trace file (the date and time should be ~now). If it does not
work, we can try to help you debug it, but our ability to do so will
be limited. However, we hope to replace these cTRACE simulations with
jsTRACE simulations in the near future (jsTRACE is an update of
jTRACE, written in javascript rather than java; batch processing and
scripting will be very powerful since jsTRACE simulations can be
written in javascript).

----------------------------------------------------------------------

TRACE SIMULATIONS AND ANALYSES

The workflow is organized around files with names that begin with
numbers, e.g., 01_do_trace_ghd_simulations.src. To run each step, you
simply use the unix 'source' command with the file name. For example,
the first command is the following (it takes about 1 minute to run on
my Macbook Pro):

     source 01_do_trace_ghd_simulations.src

If you examine this file, you'll see it does various things to clear
out existing data (caveat utilitor!), generates simple text files in
the cTRACE directory (six pairs like trace_ghd_set1.orig.tracein and
trace_ghd_set1.train.tracein) and then uses those files to run TRACE
simulations. Each simulation uses a unique lexicon (located in the
cTRACE/LEX directory) with items from cTRACE/trace_ghd_items.txt as
the 'original' word and 'trained' vs. 'untrained' nonwords ('trained'
items are simply added to the lexicon). For each triple, the items
could be fully rotated through each role twice, giving all ordered
permuations. For example, if we label the 3 items A, B, and C, we
have:

   Set     Original     Trained     Untrained
    1         A            B            C
    2         A            C            B
    3         B            A            C
    4         B            C            A
    5         C            A            B
    6         C            C            A

If we don't do this, we wind up with spurious differences between
conditions, due to the difficulty (impossibility) of creating triples
where mutual similarity is equal for all pairs (AB, AC, BC). Rotating
through washes out such details. To make these simulations more
comparable to the predictive cohort and SRN simulations that are part
of this project, however, WE ONLY DO SETS 1 AND 2 ABOVE, which rotates
the nonwords through the trained and untrained roles.

The next step calls a series of perl scripts that analyze the TRACE
data (the key data that we are about winds up in the GHD_TRACE folder;
the raw data is in the cTRACE/data_trace_ghd* directories). This step
takes a little over a minute on my Macbook Pro.

     source 02_analyze_trace_simulations.src

The final step runs R scripts that create plots, with the results
stored in the PLOTS folder. This takes about a minute as well. Note
that the final plot versions from the manuscript are created by an R
script a level up in the directory hierarchy.

     source 03_do_r_plots.src

A final note: several key folders (GHD_TRACE, GHD_SRN, PLOTS,
GHD_PREDICTIVE_COHORT) contain a subdirectory called 'ARC', which has
an archival version of the data. If you have any trouble running the
simulations, you can still explore this data. We do not include the
raw data with the repository because it is massive.


