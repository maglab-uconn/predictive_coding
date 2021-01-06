
# include <stdio.h>
#include <math.h>
#include <string.h>

extern void dumpMatrix();
extern void dumpParam();
extern void fullSimulation();
extern void simulateLexicon();
extern void diagnostic();
extern double gaussrand();
extern void testGauss();
extern void randseeder();
extern double gaussSD;
extern int nosilence; // 1 = nosilence (makeinNoSilence in util2.c), 0=pad words with silence (original makein)
extern double global_phone_comp; // added jsm 2018.06.09
extern double global_lex_comp; // added jsm 2018.06.09
extern double global_pw_sum;  // added jsm 2018.06.10
extern double global_wp_sum;  // added jsm 2018.06.10
/*      Tuneables, set low for now       */
#define NWORDS		1650		/* maximum words nodes */
#define NPHONS		15		/* number of phonemes : changed from 15, adding /?/ and continuum  */
#define MAXLEN		11		/* max word length */
#define PWIDTH		6		/* base phoneme width in FSLICES */
#define POVERLAP	6		/* base phoneme overlap in FSLICES */
					/* defined as length of p1's skirt
					   past p2's peak */
#define MAXITEMS  	20
#define PSLICES		33		/* changed from 33/22 /number of plevel slices in the trace (a phoneme is about 3 wide) */
#define FPP		3		/* fet slices per plevel slice */

/*      End of tuneables 		*/

#define FSLICES		PSLICES*FPP
#define MAXDUR		6		/* maximum duration of a phoneme in PSLICES */
#define MAXSPREAD	30		/* maximum duration of a feature in FSLICES */
#define NCONTINS	7		/* number of different continua */
#define NFVALS	 	9		/* number of features per continuum */
#define NLEVS	 	3		/* number of different proc levels */
#define NCLASSES  	8		/* number of feature sets giving common features of all phonemes in the class */
#define NPARAMS		9		/* number of weighting parameters */
#define STD		1
#define NONSTD 		0
#define F	 	0 		/* Feature */
#define P	 	1 		/* Phoneme */
#define W	 	2		/* Word */


/* for Gaussian stuff */
#define GDISTSIZE       100000


/* KEY TO INDICES BELOW:
 *	scheme goes from bottom->up, then top->down with any lateral 
 *	  interactions as we get to any given level; unused indices in parens.
 * 
 *
 * a: IF  FF  FP  PP   PW  WW   WP   PF  PFC
 *
 * g: IF  FF  FP  PP   PW  WW   WP   PF  PFC
 *
 */

#define IF	0	/* Input -> Feature weighting */
#define FF	1	/* feature to feature interactions within a trace */
#define FP	2	/* Feature to Phoneme */
#define PP	3	/* Phoneme to Phoneme */
#define PW	4	/* Phoneme to Word */
#define WW 	5	/* Word to Word */
#define WP	6	/* Token to Phoneme */
#define PF	7	/* Phoneme to Feature */
#define PFC	8	/* Phoneme to Feature coarticulatory effect */

#define EX 	0	/* excitatory */
#define IN 	1	/* inhibitory */


#define WORD register struct word
#define PHONEME register struct phoneme
#define FEATURE register struct feature
#define TOK_CHAR register char
#define TOK_FLOAT register float

#define ttyprint if (infp == stdin) printf
#define BACKTOTTY if (infp != stdin) {fileinput(STD); return;}
#define nonneg(ex) (ex < 0 ? 0 : ex)
#define inrange(i,ex) (i < ex && i < PSLICES)
#define ALLWORDS (i = 0 ; i < nwords; i++)
#define ALLWORDPTRS (wptr = wordptr; *wptr; wptr++)
#define ALLPHONEMES (pp = phoneme; pp < phoneme + NPHONS; pp++)

#define allitems(x) (x = 0; x < MAXITEMS; x++)

struct word {
	char 	*sound;		/* pointer to phoneme chars in word */
	int 	*offset;	/* pointer to list of phoneme offsets
				   the first of which is 0 */
	int	start;		/* - 1/2 the width of the first phoneme,
				   defines the edge of the skirt of
				   the word for the competition */
	int	end;		/* offset of last phoneme + 1/2
				   the width of the last phoneme,
				   defines the edge of the skirt of
				   the word for the competition */
	float 	ex[PSLICES],	/* pointer to list of nodes, one per time */
				/* slice in which the word occurs, for */
				/* each possible start position of the word */
		wex[PSLICES],	/* ditto, for excitation squared
						used in w-w inhib */
		nex[PSLICES],	/* new excitation */
		pex[PSLICES],	/* excitation passed to phoneme level */
		pextot,		/* total ""  for all PSLICES */
		prime, 		/* settable top-down priming */
		base, 		/* resting level + effect of frequency */
		rest,		/* working resting level: base+prime */
		scale,		/* length of word over # of phonemes in it.
				   used in scaling excitation of phonemes to
				   word*/
		max;		/* used in printwt, the act of
				   most active token */
	int	mloc;		/* index of most active token */
	};

struct phoneme {
	char 	sound;		/* the character for this phoneme */
	float 	*feature;	/* pointer f->p weight matrix */
	float 	ex[PSLICES], 	/* phoneme node excitation holder */
		pex[PSLICES],	/* phoneme phoneme inhibitory effect */
		nex[PSLICES],   /* new excitation */
		fex[PSLICES],	/* ability of phoneme to excite features */
		fextot,		/* total above over all PSLICES */
		wex[PSLICES],   /* ability of phoneme to excite words */
		wextot,		/* total above over all PSLICES */
		rsus;		/* susceptibility of this ph to rate effects*/
	float	pww[2*MAXDUR];	/* normalized weight of the effect of the 
				   phoneme on words it is in */
	float	wpw[2*MAXDUR];	/* weight of the effect of a word constaining
				   this phoneme on the phoneme */
	float	wscale;		/* the relative width of this phoneme to
				   other phonemes */
	float	fpw[NCONTINS][2*MAXSPREAD];
				/* weights linking features to phonemes
				   based on the pread of the features
				   in the phoneme */
	float	pfw[NCONTINS][2*MAXSPREAD];
				/* weights linking phoneme to features
				   based on the pread of the features
				   in the phoneme */
	int	pdur, 		/* intrinsic duration of this phoneme
				   measured in phoneme slices */
		fdur; 		/* intrinsic duration of this phoneme 
				   measured in feature slices */
	struct word **wordlist; /* pointer to list of pointers to words 
				   containing this phoneme */
	int *ofstlist;		/* pointer to list of offsets for
				   occurrances of this phoneme in words */
	};

struct feature {
	float 	ex[FSLICES], 	/* feature node excitation holder */
		nex[FSLICES],   /* new excitation */
	 	pex[FSLICES],	/* feature's ability to excite phonemes */
		pextot,		/* total above over all FSLICES */
		fex[FSLICES];	/* features ability to inhibit others */
	float	nw[2*MAXSPREAD];/* normalized weights dependent on spread
				   of feature in FSLICES */
	int	spread;		/* feature's tendency to spread
				   measured in feature slices  */
	struct phoneme *phonlist[NPHONS + 1];
				/* pointers to the phonemes this feature
				   excites */
	};

/* these are defined in trace.c but are used in many of the other routines */

extern int contlen[NCONTINS];
extern char *contname[NCONTINS];
extern FILE *altiop;
extern FILE *infp;
extern FILE *outfile;
extern char outname[30];
extern char *re_comp();
extern int ecomp();

extern struct word *wordptr[NWORDS + 1];
extern struct word *wtord[NWORDS + 1];
extern float *exptr[PSLICES];
extern int nwptrs;

extern struct phoneme phoneme[NPHONS];

extern struct phoneme *phonptr[128];	/* pointers to phoneme structures 
					indexed by the character corresponding 
   					to the phoneme */


extern struct feature feature[NCONTINS][NFVALS];

extern char *phonchar;

extern char *classchar;

extern char *fetname[NCONTINS][NFVALS];

extern char *optname[];

extern float fweight[NCONTINS];

extern int fetspread[NCONTINS];


extern float rate;
extern int nwords;
extern char in[BUFSIZ];
extern char sfeaturefile[BUFSIZ];

extern float max;
extern float min;
extern float wbase;
extern float wchange;
extern float wgain;
extern float wramp;

extern float ymax, ydec;
extern float pthresh[NLEVS];
extern float linthresh, linthrsq;
extern float decay[NLEVS]; 
extern float alpha[NPARAMS];
extern float ga[NLEVS];

extern float rest[NLEVS];

extern float fscale;
extern float imax;

extern float 	psum[PSLICES];
extern float 	pisum[PSLICES];
extern int 	pcount[PSLICES];

extern float 	fsum[NCONTINS][FSLICES];
extern int 	fcount[NCONTINS][FSLICES];

extern int 	wcount[PSLICES];
extern float 	wisum[PSLICES];
extern float 	wsum[PSLICES];

extern float	ppi[PSLICES];
extern float 	ffi[NCONTINS][FSLICES];
extern float	wwi[PSLICES];

extern int cycleno;

extern int shifter;
extern int nreps;
extern int sigflag;
extern int echeck;
extern int coartflag;
extern int outflag;
extern int sumflag;
extern int echoflag;
extern int grace;
extern int printfreq;
extern int printmin;
extern int printmax;
extern float windowcent;

extern int stop();

extern struct phoneme *inphone[MAXITEMS];
extern char inspec[MAXITEMS][60];
extern float infet[MAXITEMS][NCONTINS][NFVALS];

extern float 	instrength[MAXITEMS];
extern int 	inpeak[MAXITEMS];
extern int	indur[MAXITEMS];
extern float 	inrate[MAXITEMS];
extern float	insus[MAXITEMS];

extern struct word *outword[MAXITEMS];
extern struct phoneme *outphoneme[MAXITEMS];

extern int ninputs, nwouts, npouts;

extern float input[FSLICES][NCONTINS][NFVALS];

extern char wordsound[NWORDS][MAXLEN];
extern int wordfreq[NWORDS];
extern float fetval[NPHONS][NCONTINS][NFVALS];
extern float classval[NCLASSES][NCONTINS][NFVALS];
extern float wscale[NPHONS];
extern float phonrsus[NPHONS];


extern double gaussDist[GDISTSIZE];
