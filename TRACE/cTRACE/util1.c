#include "defs.h"
#include <stdlib.h>
#include <math.h>
#define M_PI 3.14159265358979323846

/* parameter load and dump, read lexicon, and display routines */

/***************************************************************************/
load(infile)
char *infile;
{
	FILE *iop;
	register int i;
	if ( (iop = fopen(infile,"r")) == NULL)
		{
		printf("Can't open %s.\n",infile);
		BACKTOTTY
		return(0);
		}
	fscanf(iop,"%f %f %f %f %f %f %f %f",&max,&min,&imax,&fscale,
		&wbase,&wchange,&wgain,&wramp);
	for(i=0; i<NCONTINS; i++)
		fscanf(iop,"%f ",&fweight[i]);
	fscanf(iop,"%f %f %f",&rest[F],&rest[P],&rest[W]);
	fscanf(iop,"%f %f %f",&decay[F],&decay[P],&decay[W]);
	fscanf(iop,"%f %f %f",&pthresh[F],&pthresh[P],&pthresh[W]);
	for (i=0; i<NPARAMS; i++) {
		fscanf(iop,"%f ",&alpha[i]);
	}
	for (i=0; i<NLEVS; i++) {
		fscanf(iop,"%f ",&ga[i]);
	}
	// this is what it adds: reads gaussSD
	fscanf(iop,"%lf",&gaussSD);
	fprintf(stderr,"GAUSSSD IS NOW %f\n",gaussSD);
	fclose(iop);
	return(1);
}

/***************************************************************************/
dump(iop)
FILE *iop;
{
	register int i;

	fprintf(iop,"%f %f %f %f %f %f %f %f\n",max,min,imax,fscale,
		wbase,wchange,wgain,wramp);
	for(i=0; i<NCONTINS; i++)
		fprintf(iop,"%f ",fweight[i]);
	fprintf(iop,"\n");
	fprintf(iop,"%f %f %f\n",rest[F],rest[P],rest[W]);
	fprintf(iop,"%f %f %f\n",decay[F],decay[P],decay[W]);
	fprintf(iop,"%f %f %f\n",pthresh[F],pthresh[P],pthresh[W]);
	for (i=0; i<NPARAMS; i++) {
	    fprintf(iop, "%f ",alpha[i]);
	}
	fprintf(iop,"\n");
	for (i=0; i<NLEVS; i++) {
	    fprintf(iop, "%f ",ga[i]);
	}
	fprintf(iop, "\n");
}

/***************************************************************************/
lexicon(filename)
char *filename;
{
	FILE *iop;
	char sp[40];
	if ( (iop = fopen(filename,"r")) == NULL)
		{
		printf("Can't open %s.\n",filename);
		BACKTOTTY
		return(0);
		}
	nwords = 0;
	while (fgets(in,BUFSIZ,iop) != NULL)
		{
		sscanf(in,"%s %d %s",wordsound[nwords],&wordfreq[nwords],sp);
		nwords++;
		}
	fclose(iop);
	return(1);
}

/***************************************************************************/
printphonemes(pmin,pmax,pstep,iop)
int pmin,pmax,pstep; FILE *iop; 
{
	PHONEME *pp;
	register int cy;
	if (pmax ==0) pmax = PSLICES*FPP-1;
	if (pstep == 2) pstep = FPP*2;
	else pstep = FPP;
	fprintf(iop,"%s\tat\t%d\tPHON ACTIVATIONS BY START POSITION\n", sfeaturefile,cycleno);
	//	fprintf(iop,"\tTRACE ACTIVATIONS at the PHONEME LEVEL (INPUT at %d)\n",
	//		cycleno);
	fprintf(iop,"Slice->\t");
	for (cy = pmin; cy <= pmax; cy += pstep) {
		fprintf(iop," %2d",cy);
	}
	fprintf(iop,"\n");
	for ALLPHONEMES {
	    for (cy = pmin; cy <= pmax; cy += pstep) {
		if (pp->ex[cy/FPP] > pthresh[P]) {
			break;
		}
	    }
	    if (cy > pmax) continue;
	    fprintf(iop,"%c:\t",pp->sound);
	    for (cy = pmin; cy <= pmax; cy += pstep) {
		if (pp->ex[cy/FPP] > pthresh[P]) {
			fprintf(iop,"%3d",(int) (pp->ex[cy/FPP]*100) );
		}
		else fprintf(iop,"   ");
		if (sigflag) {sigflag = 0; return;}
	    }
	    fprintf(iop,"\n");
	}
}

/***************************************************************************/
printwords(pmin,pmax,pstep,iop)
int pmin,pmax,pstep; 
FILE * iop;
{
	WORD **wptr,*wp;
	register int cy;
	if (pmax ==0) pmax = PSLICES*FPP-1;
	if (pstep == 2) pstep = 2*FPP;
	else pstep = FPP;
	fprintf(iop,"%s\tat\t%d\tWORD ACTIVATIONS BY START POSITION\n", sfeaturefile,cycleno);
	//	fprintf(iop,"BY STARTING POSITION\n", cycleno);
	fprintf(iop,"Slice->\t");
	for (cy = pmin; cy <= pmax; cy += pstep) {
		fprintf(iop," %2d",cy);
	}
	fprintf(iop,"\n");
	for ALLWORDPTRS {
	    wp = *wptr;
	    for (cy = pmin; cy <= pmax; cy += pstep) {
		if (wp->ex[cy/FPP] > pthresh[W]) {
			break;
		}
	    }
	    if (cy > pmax) continue;
	    if (strlen(wp->sound) < 8) {
	        fprintf(iop,"%s\t",wp->sound);
	    }
	    else if (strlen(wp->sound) == 8) {
	        fprintf(iop,"%s",wp->sound);
	    }
	    else {
		fprintf(iop,"%s\n\t",wp->sound);
	    }
	    for (cy = pmin; cy <= pmax; cy += pstep) {
		if (wp->ex[cy/FPP] > pthresh[W]) {
			fprintf(iop,"%3d",(int) (wp->ex[cy/FPP]*100) );
		}
		else fprintf(iop,"   ");
		if (sigflag) {sigflag = 0; return;}
	    }
	    fprintf(iop,"\n");
	}
}

/***************************************************************************/
printfeatures(pmin,pmax,pstep,iop)
  int pmin, pmax,pstep; 
FILE *iop;
{
	register int i,j,f,cy;
	if (pmax == 0) pmax = cycleno;
	if (pstep == 0) pstep = 1;
	fprintf(iop,"THE TRACE AT THE FEATURE LEVEL (INPUT AT %d)\n",cycleno);
	fprintf(iop,"Slice->\t");
	for (cy = pmin; cy <= pmax; cy += pstep) {
		fprintf(iop,"%3d",cy);
	}
	fprintf(iop,"\n");
	for (j = 0; j < NCONTINS; j++) {
	    for (f = 0; f < NFVALS; f++) {
		for (cy = pmin; cy <= pmax; cy += pstep) {
		    if (feature[j][f].ex[cy] > pthresh[F]) {
			break;
		    }
		}
		if (cy == pmax+pstep) continue;
		fprintf (iop,"%s.%d\t",contname[j],f);
		for (cy = pmin; cy <= pmax; cy += pstep) {
		    if (feature[j][f].ex[cy] <= pthresh[F]) 
			fprintf(iop,"   ");
		    else
			fprintf (iop,"%3d",(int) (feature[j][f].ex[cy]*100));
		}
		fprintf(iop,"\n");
	    }
	    if (sigflag) {sigflag = 0; return;}
	}
}

help() 	
{
	char **op;
	int i;
	for (op = optname, i = 1; *op; op++,i++) {
	//for (op = optname, i = 1; *(*op); op++,i++) {
		printf("%-12s",*op);
		if (!(i % 6)) printf("\n");
	}
	printf("\n");
}

topdown() 
{
	WORD **wptr;
	int wd; 

	ttyprint("Topdown input: Give words, prime strengths, end with q.\n");
	while(1) {
getprime:
		getstring("next: ");
		if (in[0] == 'q'){
		  for(wd = 0; wd < nwords; wd++){
		    fprintf(stderr, "%s\tREST:%.3f\tPRIME:%.3f\tBASE:%.3f\n",
			    wordptr[wd]->sound,
			    wordptr[wd]->rest,
			    wordptr[wd]->prime,
			    wordptr[wd]->base);
		  }
		  return;
		}
		for ALLWORDPTRS {
			if (strcmp((*wptr)->sound,in) == 0)  break;
		}
		if (!*wptr) {
			printf("%s not in lexicon.\n",in);
			BACKTOTTY
			goto getprime;
		}
getpval:
		if (fscanf(infp,"%f",&((*wptr)->prime)) == 0) {
			printf("Illegal prime value for %s.\n",in);
			BACKTOTTY
			ttyprint ("Try again: ");
			goto getpval;
		}
	}
}

setout() 
{
	WORD **wptr;
	PHONEME *pp;

	ttyprint("Output: ");
	ttyprint("Give phonemes, end with q.\n");
	for allitems(npouts) {
		outphoneme[npouts] = NULL;
getphoneme:
		getstring("next: ");
		if (in[0] == 'q') break;
		for ALLPHONEMES {
			if (pp->sound == in[0]) {
			outphoneme[npouts] = pp;
			break;
			}
		}
		if (!outphoneme[npouts]) {
			printf("%s not a phoneme.\n",in);
			BACKTOTTY
			goto getphoneme;
		}
	}
	ttyprint("Give words, end with q.\n");
	for allitems(nwouts) {
		outword[nwouts] = NULL;
getword:
		getstring("next: ");
		if (in[0] == 'q') break;
		for ALLWORDPTRS {
			if (strcmp((*wptr)->sound,in) == 0) {
				outword[nwouts] = *wptr;
				break;
			}
		}
		if (outword[nwouts] == NULL) {
			printf("%s not in lexicon .\n",in);
			BACKTOTTY
			goto getword;
		}
	}
}

/***************************************************************************/
summarypr(min,max,step,iop) 
int min,max,step;
FILE *iop;
{
	int cy,c;
	PHONEME *pp;
	WORD *wp, **wptr;
	int last;

	if (min < 0) min = 0;
	max += 1; 
	if (max > FSLICES) max = FSLICES;
	if (step == 0) step = 1;
	if (step != 1) step = 3;
	fprintf(iop,"\t\t\t\tCYCLE %2d\n",cycleno);
	fprintf(iop,"          ");
	for (cy = min; cy < max; cy+=step) {
		fprintf(iop,"%3d",cy);
	}
	fprintf(iop,"\n");
	for ALLWORDPTRS {
	    wp = *wptr;
	    for (cy = min; cy < max; cy += step) {
		if (wp->ex[cy/FPP] > pthresh[W]) {
			break;
		}
	    }
	    if (cy >= max) continue;
	    if (strcmp(wp->sound,"-") == 0) {
		fprintf(iop,"--        ");
	    }
	    else {
	        fprintf(iop,"%-10s",wp->sound);
	    }
	    for (cy = min; cy < max; cy += step) {
		if (wp->ex[cy/FPP] > pthresh[W]) {
			fprintf(iop,"%3d",(int) (wp->ex[cy/FPP]*100) );
		}
		else fprintf(iop,"   ");
	    }
	    fprintf(iop,"\n");
	}
	for ALLPHONEMES {
	    last = 0;
	    for (cy = min; cy < max; cy += step) {
		if (pp->ex[cy/FPP] > pthresh[P]) {
			last = cy;
		}
	    }
	    if (!last) continue;
	    fprintf(iop,"%c         ",pp->sound);
	    for (cy = min; cy <= last; cy += step) {
		if (pp->ex[cy/FPP] > pthresh[P]) {
			fprintf(iop,"%3d",(int) (pp->ex[cy/FPP]*100) );
		}
		else fprintf(iop,"   ");
	    }
	    fprintf(iop,"\n");
	}

	/* DON'T PRINT FEATURE JUNK - JLE 1/15/83
	for (c = 0; c < NCONTINS; c++) {
	  last = 0;
	  for (cy = min; cy < max; cy+=step) {
	    if (fcount[c][cy]) last = cy;
	  }
	  if (last) {
	    fprintf(iop,"%s ct:\t",contname[c]);
	    for (cy = min; cy <= last; cy+=step) {
		    if (!fcount[c][cy]) fprintf(iop,"   ");
		    else fprintf(iop,"%3d",fcount[c][cy]);
	    }
	    fprintf(iop,"\n");
	    fprintf(iop,"%s sm:\t",contname[c]);
	    for (cy = min; cy <= last; cy+=step) {
		    if (!fsum[c][cy]) fprintf(iop,"   ");
		    else fprintf(iop,"%3d",(int) (fsum[c][cy]*100) );
	    }
	    fprintf(iop,"\n");
	  }
	}
	END OF COMMENTED OUT CODE*/
}

/* ROUTINE COMMENTED OUT 10/3/82 -- JLM 
wordsubset() 
{
	WORD *wp, **wptr;
	char *error;
	getstring("subset specification: ");
	if (strcmp(in,"*") == 0) {
		wptr = wordptr;
		for ALLWORDS *wptr++ =  wp;
		*wptr = '\0';
		return;
	}
	//if ( ( error = re_comp(in)) != 0) {
	//	printf("%s\n",error);
	//	BACKTOTTY
	//	return;
	//}
	wptr = wordptr;
	nwptrs = 0;
	for ALLWORDS {
		if (re_exec(wp->sound)) {
			*wptr++ = wp;
			nwptrs++;
		}
	}
	*wptr = '\0';
}
*/
/***************************************************************************/

double gaussrand()
{
  static double V1, V2, S;
  static int phase = 0;
  double X;
  
  if(phase == 0) {
    do {
      double U1 = (double)rand() / RAND_MAX;
      double U2 = (double)rand() / RAND_MAX;
      
      V1 = 2 * U1 - 1;
      V2 = 2 * U2 - 1;
      S = V1 * V1 + V2 * V2;
    } while(S >= 1 || S == 0);
    
    X = V1 * sqrt(-2 * log(S) / S);
  } else
    X = V2 * sqrt(-2 * log(S) / S);
  
  phase = 1 - phase;
  
  // fprintf(stderr,"gaussrand value is %f\n", X);
  
 return X;
}

  /* double gaussrand()  /* normal distribution, centered on 0, std dev 1 */
  /*{
  return sqrt(-2*log(drand())) * cos(2*M_PI*drand());
  }*/

/***************************************************************************/

double gaussrand2_notactive (double mu, double sigma)
{
  double U1, U2, M, mult;
  static double X1, X2;
  static int call = 0;
 
  if (call == 1)
    {
      call = !call;
      return (mu + sigma * (double) X2);
    }
 
  do
    {
      U1 = -1 + ((double) rand () / RAND_MAX) * 2;
      U2 = -1 + ((double) rand () / RAND_MAX) * 2;
      M = pow (U1, 2) + pow (U2, 2);
    }
  while (M >= 1 || M == 0);
 
  mult = sqrt ((-2 * log (M)) / M);
  X1 = U1 * mult;
  X2 = U2 * mult;
 
  call = !call;
 
  return (mu + sigma * (double) X1);
}


/***************************************************************************/
#define NSUM 25

double gaussrand_ver2_notactive(theSD)
     double theSD;
{
  double x = 0;
  int i;

  for(i = 0; i < NSUM; i++)
    x += (double)rand() / RAND_MAX;

  x -= NSUM / 2.0;
  x /= sqrt(NSUM / 12.0);

  return x * theSD;
}


/***************************************************************************/
void randseeder()
{
  //  struct timeval tv;
  //  gettimeofday(&tv, NULL);
  //  int usec = tv.tv_usec;
  //  srand48(usec);
  int seed = time(NULL);
  srand(seed);
}
/***************************************************************************/
void genGauss()
{
  int ag=0, cg=0;

  cg = GDISTSIZE;
  for(ag = 0; ag < cg; ag++){
    gaussDist[ag] = gaussrand();
  }
}
/***************************************************************************/
void shuffle(int *array, size_t n) {    
  struct timeval tv;
  gettimeofday(&tv, NULL);
  int usec = tv.tv_usec;
  srand48(usec);


  if (n > 1) {
    size_t i;
    for (i = n - 1; i > 0; i--) {
      size_t j = (unsigned int) (drand48()*(i+1));
      int t = array[j];
      array[j] = array[i];
      array[i] = t;
    }
  }
}
