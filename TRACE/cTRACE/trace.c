#include "defs.h"
#include <time.h>
#include <assert.h>
//#include <stdlib.h>
#include <math.h>

/* 2015: in addition to new feature values, this now has defaults set correctly. 
   That said, ALWAYS USE A PARAMETER FILE. */

/* latest updates:
2015.09.25: 
1. changed num to 111 instead of 200 
2. modified dumpmatrix to only do _word.txt files (see dumpmatrixsave)
*/


FILE *altiop = NULL;
FILE *infp ;
FILE *outfile = NULL;
char outname[30];
//char *re_comp(); //
int ecomp();

double gaussDist[GDISTSIZE];


struct word *wordptr[NWORDS + 1];
struct word *wtord[NWORDS + 1];
float *exptr[PSLICES];
int nwptrs;
int printmin, printmax;
float windowcent = 66 + 12;		/* make float for getval routine */

char wordsound[NWORDS][MAXLEN];
int wordfreq[NWORDS];
struct phoneme phoneme[NPHONS];
struct phoneme *phonptr[128]; /* pointers to phoneme structures indexed 
			   by the character corresponding to the phoneme */

struct feature feature[NCONTINS][NFVALS];

int contlen[NCONTINS] = 
	{NFVALS,NFVALS,NFVALS,NFVALS,NFVALS,NFVALS,NFVALS};

char *phonchar =
	{"pbtdkgsSrlaiu^-"};

char *classchar =
	{"VCLNDGBT"}; /*vocalic, consonantal,liquid,noncompact,dental stop,
			velar stop, bilabial stop, bil/alv  */


char *contname[NCONTINS] = 
{"POW","VOC","DIF","ACU","GRD","VOI","BUR"};

float fweight[NCONTINS] = 
  {1., 1., 1., 1., 1., 1., 1. };

int nwords = 0;

char in[BUFSIZ];
char sfeaturefile[BUFSIZ];

double global_phone_comp = 0.0;// added jsm 2018.06.10
double global_lex_comp = 0.0;// added jsm 2018.06.10
double global_pw_sum = 0.0;  // added jsm 2018.06.10
double global_wp_sum = 0.0;  // added jsm 2018.06.10


double gaussSD = 0.0;
int nosilence = 0;

float max = { 1.};
float min = {-.3};
float wbase = {.3};
float wchange = {.1};
float wgain = {1.};
float wramp = {1.};
float rate = {.5};

float ymax = .6;
float ydec = .01;
/*float pthresh[NLEVS]    = {.00,.00,.05};*/
float pthresh[NLEVS]    = {-.03,-.03,-.03};
float linthresh = .2; 
float linthrsq = .04;
float decay[NLEVS]      = {.01,.03,.05}; 
float alpha[NPARAMS] = 
/*   IF   FF    FP  PP  PW  WW  WP  PF  PFC  */
    {1.0,.00,.020,.00,.05,.00,.03,.00,.00};

float ga[NLEVS] = 
/*   FF    PP     WW */
/* no idea why they were set to these values!   {.100, .100, .100}; */
   {.04, .04, .03};

float rest[NLEVS]   = {-.1, -.1, -.01};

float fscale = {.00};
float imax = {3.};

float psum[PSLICES];
float pisum[PSLICES];
int pcount[PSLICES];

float fsum[NCONTINS][FSLICES];
int fcount[NCONTINS][FSLICES];

float wisum[PSLICES];
float wsum[PSLICES];
int wcount[PSLICES];

float ppi[PSLICES];
float wwi[PSLICES];
float ffi[NCONTINS][FSLICES];
int cycleno;

int nreps = 1;
int sigflag;
int echeck;
int outflag;
int sumflag = 1;
int echoflag = 1;
int grace = 0;
int coartflag = 1;
int printfreq = 3;

int stop();

struct phoneme 	*inphone[MAXITEMS];
char 	inspec[MAXITEMS][60];
float 	infet[MAXITEMS][NCONTINS][NFVALS];

float 	instrength[MAXITEMS];
int 	inpeak[MAXITEMS];
int  	indur[MAXITEMS];
float	inrate[MAXITEMS];
float	insus[MAXITEMS];

struct word 	*outword[MAXITEMS];
struct phoneme 	*outphoneme[MAXITEMS];

int ninputs, nwouts, npouts;

float input[FSLICES][NCONTINS][NFVALS];

/***************************************************************************/
main(argc,argv)
int argc; char **argv;
{
	int specflag = 0;
	int aaa,bbb;

	randseeder();
	//	for(bbb=0;bbb<3;bbb++){
	genGauss(); // fills gaussDist with GDISTSIZE values
	// shuffle(gaussDist);
	//fprintf(stderr,"here\n");
	//for(aaa=0; aaa<10;aaa++){
	//fprintf(stderr, "gd %d %lf\n", aaa, gaussDist[aaa]);
	//}
	//}
	infp = stdin;

	while (--argc > 0 && (*++argv) [0] == '-') {
		switch (argv[0][1]) {
			case 'p':
				load(*++argv);
				argc--;
				break;
			case 'l':
				lexicon(*++argv);
				argc--;
				break;
			case 'i':
				inspecs(*++argv);
				specflag = 1;
				argc--;
				break;
			case 'f':
				infeats(*++argv);
				argc--;
				break;
			case 'a':	/* to make it easy for sdb */
				abort();
				break;
			case 'n':
			        togglenosilence();
				argc--;
				break;
		}
	}
	initialize();
	if (specflag) inputcomp();
	if (signal(2,stop) & 01) signal(2,stop);
	command();
}

/***************************************************************************/
double cycle() 
{
	int tick,pmin,pmax;
	for (tick = 0; tick < nreps; tick++) {
	    act_features();
	    fpinteract();
	    ppinteract();
	    pfinteract();
	    pwinteract();
	    wpinteract();
	    wwinteract();
	    fupdate();
	    pupdate();
	    wupdate();
	    cycleno++;
	    if ( !(cycleno%printfreq) ) {
			if (sumflag) {
				if (cycleno>windowcent) {
					printmin  = 6;
					printmax += 66+6;
				}
				summarypr(printmin,printmax,FPP,stdout);
				//if (outfile) {
				//summarypr(printmin,printmax,FPP,outfile);
				//}
			}
	    }
	    if (sigflag) {sigflag = 0;break;}
	}
}

/***************************************************************************/
zarrays() 
{
  WORD *wp, **wptr;
  PHONEME *pp;
  register int i,f,c;
  
  cycleno = 0;
  printmin = 0;
  printmax = 66;
  
  //extern float infet[MAXITEMS][NCONTINS][NFVALS];
  //extern float input[FSLICES][NCONTINS][NFVALS];
  
  for (i = 0; i < MAXITEMS; i++) {
    for (c = 0; c < NCONTINS; c++) {
      for(f = 0; f < NFVALS; f++){
	infet[i][c][f] = 0;
      }
    }   
  }
  
  for (i = 0; i < PSLICES; i++) {
    wwi[i] =0; wsum[i] =0; wisum[i] =0; wcount[i] = 0;
    ppi[i] =0; psum[i] =0; pisum[i] = 0; pcount[i] = 0;
  }
  
  for (i = 0; i < FSLICES; i++) {
    for (c = 0; c < NCONTINS; c++) {
      ffi[c][i] =0; fsum[c][i] =0; fcount[c][i] = 0;
      for(f = 0; f < NFVALS; f++){
	input[i][c][f] = rest[F];
      }
    }
  }

  for ALLWORDPTRS {
      wp = *wptr;
      wp->pextot = 0;
      wp->rest = wp->prime + wp->base;

      for (i = 0; i < PSLICES; i++) {
	wp->ex[i] = wp->rest;
	wp->nex[i] =0;
	wp->pex[i] = 0;
	wp->wex[i] = 0;
      }   
    }

  for ALLPHONEMES {
      pp->fextot = 0;
      pp->wextot= 0;
      for (i = 0; i < PSLICES; i++) {
	pp->ex[i] = rest[P];
	pp->wex[i] = 0; pp->fex[i] = 0; pp->nex[i] = 0;
	pp->pex[i] = 0;
      }
    }

  for (c = 0; c < NCONTINS; c++) {
    for (f=0; f < NFVALS; f++) {
      feature[c][f].pextot = 0;
      for (i = 0; i < FSLICES; i++) {
	feature[c][f].ex[i] = rest[F];
	feature[c][f].pex[i] = 0;
	feature[c][f].fex[i] = 0;
	feature[c][f].nex[i] = 0;
      }   
    }   
  }
}

/***************************************************************************/
void fullSimulation()
{
  int i,num;
  FILE *file;
  char filename[100], otherfile[100];
  char modInput[20] = {'\0'};
  clock_t ttime;
  
  //initialize();
  
  ttime = clock();
  num=111;
  nreps=1;
  for(i=0;i<num;i++){
    cycle();
    dumpMatrix();			
  }
  //dumpParam();	
  
  for(i = 0; i < MAXITEMS-1; i++){
    if(inspec[i][0]=='.') break;
    else{ 
      modInput[i]=inspec[i][0];
      if(modInput[i] == '-'){ modInput[i] = 'Q'; }
      if(modInput[i] == '^'){ modInput[i] = 'x'; }
      if(modInput[i] == 'S'){ modInput[i] = 'h'; }
      //	    fprintf(stderr,"\t\t-- modInput: %s ; inspec: %s\n",modInput, inspec[i][0]);
      //      fprintf(stderr,"\t\t-- modInput: %s ; inspec: \n",modInput); //, inspec[i][0]);
    }
  }
  
  ttime = clock() - ttime;
  double time_taken = ((double)ttime)/CLOCKS_PER_SEC; 
  if(sfeaturefile[0] != '\0') {
    fprintf(stderr, "\t# THE fullSimulation of %s took %f secs\n", sfeaturefile, time_taken);
  } else 	  {
    fprintf(stderr, "\t# THE fullSimulation of %s took %f secs\n", modInput, time_taken);
  }
}

/***************************************************************************/
void testGauss_notactive()
{
  double agauss[1000000] = {0};
  double meangauss = 0, sumgauss = 0, sdgauss =0 , sd=0, se=0, mg=0;
  int ag=0, cg=0;
  

  cg = 1000000;
  fprintf(stderr,"# at start, meangaus: %f sdgaus: %f\n", meangauss, sd);
  for(ag = 0; ag < cg; ag++){
    agauss[ag] = gaussrand(gaussSD);
    sumgauss += agauss[ag];
    //    fprintf(stdout,"%d\t%lf\n",ag,agauss[ag]);
  }
  meangauss = sumgauss / (double) cg;
  for(ag = 0; ag < cg; ag++){
    se+= pow((agauss[ag]-meangauss),2);
  }
  sd = sqrt(se / (cg-1)); 

  fprintf(stderr,"in %d reps, mean gauss is %.6lf, sd is %.6lf\n",
	  cg, meangauss, sd);
}

/***************************************************************************/
void simulateLexicon(){
  WORD *wp, **wptr;
  int ag=0;

  for ALLWORDPTRS{
      ag ++;
      fprintf(stderr, "ITEM %d\t", ag);
      initialize();
      wp = *wptr;
      test(wp->sound);
      fullSimulation();
    }
}

/***************************************************************************/
void dumpMatrixXML()
{
  int c,f,slice, phon, wd, i;
  FILE *file = NULL;
  char modelInput[20] = {'\0'};
  char filename[100] = {'\0'}, otherfile[100] = {'\0'};
  //printf("Filename:");
  //scanf("%s",filename);
  //sprintf(otherfile, "%s.phon",filename);
  fflush(stdin);
  fflush(stdout);
  for(i = 0; i < MAXITEMS-1; i++){
    if(inspec[i][0]=='.') break;
    else
      { modelInput[i]=inspec[i][0];
	//       sprintf(stderr,"\t\t-- modelInput: %s\n",modelInput);
      }
  }
  sprintf(filename,"data/%s/input_%.3d.xml", modelInput,(cycleno-1));	
  //sprintf(filename,"data/input_%.3d.xml", (cycleno-1));	
  file = fopen(filename,"w");
  if(file == NULL)
    {
      printf("Could not open file (%s)! \n",filename);
      return;
    }
  fprintf(file, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\n<inputData slice=\"%.3d\" \n\txmlns=\'http://xml.netbeans.org/examples/targetNS\'\n\t\txmlns:xsi=\'http://www.w3.org/2001/XMLSchema-instance\'\n\txsi:schemaLocation=\'http://xml.netbeans.org/examples/targetNS http://maglab.psy.uconn.edu/jtraceschema.xsd\'>\n", (cycleno-1));
  for ( c = 0; c < NCONTINS; c++){	        
    for (f=0; f < NFVALS; f++){	
      if(c == 0) fprintf(file, "\n\t\t<row><feat>POW</feat>");	
      if(c == 1) fprintf(file, "\n\t\t<row><feat>VOC</feat>");	
      if(c == 2) fprintf(file, "\n\t\t<row><feat>DIF</feat>");	
      if(c == 3) fprintf(file, "\n\t\t<row><feat>ACU</feat>");	
      if(c == 4) fprintf(file, "\n\t\t<row><feat>GRA</feat>");	
      if(c == 5) fprintf(file, "\n\t\t<row><feat>VOI</feat>");	
      if(c == 6) fprintf(file, "\n\t\t<row><feat>BUR</feat>");		    
      fprintf(file, "<cont>%d</cont>",f);		
      for(slice = 0 ; slice < FSLICES; slice++){
	if(input[slice][c][f]==0){ fprintf(file, "<a>%.1f</a>", input[slice][c][f]); }
	else{ fprintf(file, "<a>%.6f</a>", input[slice][c][f]);}
      }
      fprintf(file,"</row>");		
    }
  }
  fprintf(file, "\n\t</inputData>\n");
  fclose(file);
  
  sprintf(filename,"data/%s/feature_%.3d.xml", modelInput,(cycleno-1));	
  //sprintf(filename,"data/feature_%.3d.xml", (cycleno-1));	
  file = fopen(filename,"w");	
  
  fprintf(file, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\n<featureData slice=\"%.3d\" \n\txmlns=\'http://xml.netbeans.org/examples/targetNS\'\n\t\txmlns:xsi=\'http://www.w3.org/2001/XMLSchema-instance\'\n\txsi:schemaLocation=\'http://xml.netbeans.org/examples/targetNS http://maglab.psy.uconn.edu/jtraceschema.xsd\'>\n", (cycleno-1));
  
  for ( c = 0; c < NCONTINS; c++){	        
    for (f=0; f < NFVALS; f++){	
      if(c == 0) fprintf(file, "\n\t\t<row><feat>POW</feat>");	
      if(c == 1) fprintf(file, "\n\t\t<row><feat>VOC</feat>");	
      if(c == 2) fprintf(file, "\n\t\t<row><feat>DIF</feat>");	
      if(c == 3) fprintf(file, "\n\t\t<row><feat>ACU</feat>");	
      if(c == 4) fprintf(file, "\n\t\t<row><feat>GRA</feat>");	
      if(c == 5) fprintf(file, "\n\t\t<row><feat>VOI</feat>");	
      if(c == 6) fprintf(file, "\n\t\t<row><feat>BUR</feat>");		    
      fprintf(file, "<cont>%d</cont>",f);		
      for(slice = 0 ; slice < FSLICES; slice++){
	//fprintf(file, "<act slice=\"%f\"> ", slice);
	//fprintf(file, "<a>%.17f</a>", feature[c][f].ex[slice]);
	if(feature[c][f].ex[slice]==0){ fprintf(file, "<a>%.1f</a>", feature[c][f].ex[slice]); }
	else{ fprintf(file, "<a>%.8f</a>", feature[c][f].ex[slice]);}				
      }
      fprintf(file,"</row>");		
    }
  }
  fprintf(file, "\n\t</featureData>\n");
  fclose(file);
  
  sprintf(filename,"data/%s/phon_%.3d.xml",modelInput,(cycleno-1));
  //sprintf(filename,"data/phon_%.3d.xml",(cycleno-1));
  file = fopen(filename,"w");
  
  fprintf(file, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\n<phonemeData slice=\"%.3d\" \n\txmlns=\'http://xml.netbeans.org/examples/targetNS\'\n\t\txmlns:xsi=\'http://www.w3.org/2001/XMLSchema-instance\'\n\txsi:schemaLocation=\'http://xml.netbeans.org/examples/targetNS http://maglab.psy.uconn.edu/jtraceschema.xsd\'>\n", (cycleno-1));
  for(phon = 0; phon < NPHONS; phon++){
    fprintf(file, "\n\t\t<row><phon>%c</phon> ",phonchar[phon]);			
    for(slice = 0 ; slice < PSLICES; slice++){
      //fprintf(file, "<act slice\"%f\"> ",slice);
      //fprintf(file, "<a>%.3f</a> ",phoneme[phon].ex[slice]);
      if(phoneme[phon].ex[slice]==0){ fprintf(file, "<a>%.1f</a>", phoneme[phon].ex[slice]); }
      else{ fprintf(file, "<a>%.8f</a>", phoneme[phon].ex[slice]);}
    }
    fprintf(file,"</row>");				
  }
  fprintf(file,"\n\t</phonemeData>\n");
  fclose(file);
  
  sprintf(filename,"data/%s/word_%.3d.xml",modelInput,(cycleno-1));
  //sprintf(filename,"data/word_%.3d.xml",(cycleno-1));
  file = fopen(filename,"w");
  fprintf(file, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\n<wordData slice=\"%.3d\" \n\txmlns=\'http://xml.netbeans.org/examples/targetNS\'\n\t\txmlns:xsi=\'http://www.w3.org/2001/XMLSchema-instance\'\n\txsi:schemaLocation=\'http://xml.netbeans.org/examples/targetNS http://maglab.psy.uconn.edu/jtraceschema.xsd\'>\n", (cycleno-1));
  for(wd = 0; wd < nwords; wd++){
    fprintf(file, "\n\t\t<row><word>%s</word> ",wordptr[wd]->sound);			
    for(slice = 0 ; slice < PSLICES; slice++){
      //fprintf(file, "<act slice=\"%f\"> ",slice);
      //fprintf(file, "<a>%.3f</a> ",wordptr[wd]->ex[slice]);
      if(wordptr[wd]->ex[slice]==0){ fprintf(file, "<a>%.1f</a>", wordptr[wd]->ex[slice]); }
      else{ fprintf(file, "<a>%.8f</a>", wordptr[wd]->ex[slice]);}
    }
    fprintf(file, "</row>");		
  }
  fprintf(file,"\n\t</wordData>\n");
  fclose(file);	
  //printf("nwords %d \n",nwords);
  printf("ok\n");	
}

/***************************************************************************/
//void dumpMatrixSAVE() // modifying version below on 2015.09.25
void dumpMatrix() // modifying version below on 2015.09.25
{
  int c,f,slice, phon, wd, i;
  FILE *file = NULL;
  char modelInput[20] = {'\0'};
  // char modelInputForFileName[20] = {'\0'};
  char filename[100] = {'\0'}, otherfile[100] = {'\0'};

  double global_phon_sum_all = 0.0;
  double global_phon_sum_pos = 0.0;
  double global_lex_sum_all = 0.0;
  double global_lex_sum_pos = 0.0;
  int    global_lex_count_pos = 0; 
  int    global_lex_count_all = 0;

  //printf("Filename:");
  //scanf("%s",filename);
  //sprintf(otherfile, "%s.phon",filename);
  fflush(stdin);
  fflush(stdout);
  //  fprintf(stderr,"GPI: %.6f\n", global_phone_comp);

  for(i = 0; i < MAXITEMS-1; i++){
    if(inspec[i][0]=='.') break;
    else{ 
      modelInput[i]=inspec[i][0];
      if(modelInput[i] == '-'){ modelInput[i] = 'Q'; }
      if(modelInput[i] == '^'){ modelInput[i] = 'x'; }
      if(modelInput[i] == 'S'){ modelInput[i] = 'h'; }
      //     fprintf(stderr,"\t\t-- modelInput: %s\n",modelInput);
    }
  }
  sprintf(filename,"data/%s_input.txt", modelInput);
  if(sfeaturefile[0] != '\0') {
    // if(strcmp(sfeaturefile,"")){ 
    sprintf(filename,"data/%s_input.txt", sfeaturefile);
  }
  
  //   fprintf(stderr,"******* input file is %s\n", filename);
  
  
  // else { 
  //   fprtinf(stderr,"sfeaturefile %s does not match empty string\n", sfeaturefile);
  // }
  // sprintf(filename,"data/%s_input_%.3d.txt", modelInput,(cycleno-1));	
  //sprintf(filename,"data/input_%.3d.xml", (cycleno-1));	
  
   if(cycleno == 1) {
     file = fopen(filename,"w");
     // 11/27/13 changing to only write first cycleno -- it's the same every time!
     //   } // create new file
     //   else{file = fopen(filename,"a");} // append
     if(file == NULL)
       {
	 printf("Could not open file (%s)! \n",filename);
	 return;
       }
     // fprintf(file, "#slice\t\"%.3d\" \n", (cycleno-1));
     for ( c = 0; c < NCONTINS; c++){	        
       for (f=0; f < NFVALS; f++){	
	 fprintf(file, "%d\t", (cycleno-1));
	 if(c == 0) fprintf(file, "POW");	
	 if(c == 1) fprintf(file, "VOC");
	 if(c == 2) fprintf(file, "DIF");
	 if(c == 3) fprintf(file, "ACU");
	 if(c == 4) fprintf(file, "GRA");
	 if(c == 5) fprintf(file, "VOI");
	 if(c == 6) fprintf(file, "BUR");
	 fprintf(file, "\t%d",f);		
	 for(slice = 0 ; slice < FSLICES; slice++){
	   if(input[slice][c][f]==0){ fprintf(file, "\t%.1f", input[slice][c][f]); }
	   else{ fprintf(file, "\t%.17f", input[slice][c][f]);}
	 }
	 fprintf(file,"\n");		
       }
     }
     // fprintf(file, "\n\t</inputData>\n");
     fclose(file);
   }

  
  /* 
  // sprintf(filename,"data/%s_feature_%.3d.txt", modelInput,(cycleno-1));	
  sprintf(filename,"data/%s_feature.txt", modelInput);	
  // if(strcmp(sfeaturefile,"")){ 
  if(sfeaturefile[0] != '\0') {
  sprintf(filename,"data/%s_feature.txt", sfeaturefile);
  }
  // sprintf(filename,"data/%s/feature_%.3d.xml", modelInput,(cycleno-1));	
  //sprintf(filename,"data/feature_%.3d.xml", (cycleno-1));	
  if(cycleno == 1) {file = fopen(filename,"w");} // create new file
  else{file = fopen(filename,"a");} // append
  
  
  fprintf(file, "#slice\t%.3d\n", (cycleno-1));
  
  for ( c = 0; c < NCONTINS; c++){	        
  for (f=0; f < NFVALS; f++){	
  fprintf(file, "%d\t", (cycleno-1));
  /*     if(c == 0) fprintf(file, "\n\t\t<row><feat>POW</feat>");	
  if(c == 1) fprintf(file, "\n\t\t<row><feat>VOC</feat>");	
  if(c == 2) fprintf(file, "\n\t\t<row><feat>DIF</feat>");	
  if(c == 3) fprintf(file, "\n\t\t<row><feat>ACU</feat>");	
  if(c == 4) fprintf(file, "\n\t\t<row><feat>GRA</feat>");	
  if(c == 5) fprintf(file, "\n\t\t<row><feat>VOI</feat>");	
  if(c == 6) fprintf(file, "\n\t\t<row><feat>BUR</feat>");		    
  fprintf(file, "<cont>%d</cont>",f);		*/
  /*     if(c == 0) fprintf(file, "POW");	
	 if(c == 1) fprintf(file, "VOC");
	 if(c == 2) fprintf(file, "DIF");
	 if(c == 3) fprintf(file, "ACU");
	 if(c == 4) fprintf(file, "GRA");
	 if(c == 5) fprintf(file, "VOI");
	 if(c == 6) fprintf(file, "BUR");
	 fprintf(file, "\t%d",f);		
	 for(slice = 0 ; slice < FSLICES; slice++){
	 //fprintf(file, "<act slice=\"%f\"> ", slice);
	 //fprintf(file, "<a>%.17f</a>", feature[c][f].ex[slice]);
	 if(feature[c][f].ex[slice]==0){ fprintf(file, "\t%.1f", feature[c][f].ex[slice]); }
	 else{ fprintf(file, "\t%.17f", feature[c][f].ex[slice]);}				
	 }
	 fprintf(file,"\n");		
	 }
	 }
	 // fprintf(file, "\n\t</featureData>\n");
	 fclose(file);
  */
  
   // sprintf(filename,"data/%s_phon_%.3d.txt", modelInput,(cycleno-1));	
  sprintf(filename,"data/%s_phon.txt", modelInput);	
  if(sfeaturefile[0] != '\0') {
    //if(strcmp(sfeaturefile,"")){ 
    sprintf(filename,"data/%s_phon.txt", sfeaturefile);
  }
  /// sprintf(filename,"data/%s/phon_%.3d.xml",modelInput,(cycleno-1));
  //sprintf(filename,"data/phon_%.3d.xml",(cycleno-1));
  // file = fopen(filename,"w");
  if(cycleno == 1) {file = fopen(filename,"w");} // create new file
  else{file = fopen(filename,"a");} // append
  
  // fprintf(file, "#slice\t\"%.3d\" \n", (cycleno-1));
  global_phon_sum_all = 0.0;
  global_phon_sum_pos = 0.0;
  for(phon = 0; phon < NPHONS; phon++){
    fprintf(file, "%d\t%c",(cycleno-1),phonchar[phon]);			
    //    fprintf(file, "%d\t%c\t%.6f",(cycleno-1),phonchar[phon],global_phone_comp);			
    for(slice = 0 ; slice < PSLICES; slice++){
      //fprintf(file, "<act slice\"%f\"> ",slice);
      //fprintf(file, "<a>%.3f</a> ",phoneme[phon].ex[slice]);
      if(phoneme[phon].ex[slice]==0){ fprintf(file, "\t%.1f", phoneme[phon].ex[slice]); }
      else{ fprintf(file, "\t%.8f", phoneme[phon].ex[slice]);}
      global_phon_sum_all += phoneme[phon].ex[slice];
      if(phoneme[phon].ex[slice] > 0){
	global_phon_sum_pos += phoneme[phon].ex[slice];
      }
    }
    fprintf(file,"\n");				
  }
  // fprintf(file,"\n\t</phonemeData>\n");
  fclose(file);
  
  // sprintf(filename,"data/%s_word_%.3d.txt", modelInput,(cycleno-1));	
  sprintf(filename,"data/%s_word.txt", modelInput);	
  if(sfeaturefile[0] != '\0') {
    // if(strcmp(sfeaturefile,"")){ 
    sprintf(filename,"data/%s_word.txt", sfeaturefile);
  }
  // sprintf(filename,"data/%s/word_%.3d.xml",modelInput,(cycleno-1));
  //sprintf(filename,"data/word_%.3d.xml",(cycleno-1));
  // file = fopen(filename,"w");
  if(cycleno == 1) {file = fopen(filename,"w");} // create new file
  else{file = fopen(filename,"a");} // append
  
  // fprintf(file, "#slice\t\"%.3d\" \n", (cycleno-1));
  // fprintf(stderr,"There are %d words\n", nwords);

  global_lex_sum_all = 0.0;
  global_lex_sum_pos = 0.0;
  global_lex_count_pos = 0; 
  global_lex_count_all = 0;
  for(wd = 0; wd < nwords; wd++){
    fprintf(file, "%d\t%s",(cycleno-1),wordptr[wd]->sound);			
    for(slice = 0 ; slice < PSLICES; slice++){
      //fprintf(file, "<act slice=\"%f\"> ",slice);
      //fprintf(file, "<a>%.3f</a> ",wordptr[wd]->ex[slice]);
      if(wordptr[wd]->ex[slice]==0){ fprintf(file, "\t%.1f", wordptr[wd]->ex[slice]); }
      else{ fprintf(file, "\t%.8f", wordptr[wd]->ex[slice]);}
      global_lex_sum_all += wordptr[wd]->ex[slice];
      global_lex_count_all ++;
      if(wordptr[wd]->ex[slice] > 0){
	global_lex_sum_pos += wordptr[wd]->ex[slice];
	global_lex_count_pos ++;
      }
    }
    fprintf(file, "\n");		
  }
  // fprintf(file,"\n\t</wordData>\n");
  fclose(file);	
  //printf("nwords %d \n",nwords);


  sprintf(filename,"data/%s_comp.txt", modelInput);	
  if(sfeaturefile[0] != '\0') {
    //if(strcmp(sfeaturefile,"")){ 
    sprintf(filename,"data/%s_comp.txt", sfeaturefile);
  }
  /// sprintf(filename,"data/%s/phon_%.3d.xml",modelInput,(cycleno-1));
  //sprintf(filename,"data/phon_%.3d.xml",(cycleno-1));
  // file = fopen(filename,"w");
  if(cycleno == 1) {file = fopen(filename,"w");} // create new file
  else{file = fopen(filename,"a");} // append
  fprintf(file, "%d\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\n", cycleno,
	  global_phone_comp, global_phon_sum_all, global_phon_sum_pos,
	  global_lex_comp, global_lex_sum_all, global_lex_sum_pos, global_pw_sum, global_wp_sum);
	  //	  global_lex_comp, global_lex_sum_all / global_lex_count_all, global_lex_sum_pos / global_lex_count_pos);

  fclose(file);

  //  "PhoneInhib", "PhoneSum", "PhoneSumPos", "LexInhib", "LexSum", "LexSumPos", "PWsum", "WPsum", "Item", "Phase"


  printf("ok\n");	
}

/***************************************************************************/
void dumpMatrix_skip_input_and_phon()
{
  int c,f,slice, phon, wd, i;
  FILE *file = NULL;
  char modelInput[20] = {'\0'};
  char filename[100] = {'\0'}, otherfile[100] = {'\0'};

  fflush(stdin);
  fflush(stdout);

  for(i = 0; i < MAXITEMS-1; i++){
    if(inspec[i][0]=='.') break;
    else{ 
      modelInput[i]=inspec[i][0];
      if(modelInput[i] == '-'){ modelInput[i] = 'Q'; }
      if(modelInput[i] == '^'){ modelInput[i] = 'x'; }
      if(modelInput[i] == 'S'){ modelInput[i] = 'h'; }
    }
  }

  // PRINT THE _INPUT.TXT FILE -- COMMENTING OUT 2015.09.25 
  /*
  sprintf(filename,"data/%s_input.txt", modelInput);
  if(sfeaturefile[0] != '\0') {
    sprintf(filename,"data/%s_input.txt", sfeaturefile);
    }
  
  if(cycleno == 1) {
    file = fopen(filename,"w");
    if(file == NULL)
      {
	printf("Could not open file (%s)! \n",filename);
	return;
      }
    for ( c = 0; c < NCONTINS; c++){	        
      for (f=0; f < NFVALS; f++){	
	fprintf(file, "%d\t", (cycleno-1));
	if(c == 0) fprintf(file, "POW");	
	if(c == 1) fprintf(file, "VOC");
	if(c == 2) fprintf(file, "DIF");
	if(c == 3) fprintf(file, "ACU");
	if(c == 4) fprintf(file, "GRA");
	if(c == 5) fprintf(file, "VOI");
	if(c == 6) fprintf(file, "BUR");
	fprintf(file, "\t%d",f);		
	for(slice = 0 ; slice < FSLICES; slice++){
	  if(input[slice][c][f]==0){ fprintf(file, "\t%.1f", input[slice][c][f]); }
	  else{ fprintf(file, "\t%.17f", input[slice][c][f]);}
	}
	fprintf(file,"\n");		
      }
    }
    
    fclose(file);
  }
  */
  
  // PRINT THE _PHON.TXT FILE -- COMMENTING OUT 2015.09.25 TO SAVE DISKSPACE
  
  sprintf(filename,"data/%s_phon.txt", modelInput);	
  if(sfeaturefile[0] != '\0') {
    sprintf(filename,"data/%s_phon.txt", sfeaturefile);
  }
  
  if(cycleno == 1) {file = fopen(filename,"w");} // create new file
  else{file = fopen(filename,"a");} // append
  
  
  for(phon = 0; phon < NPHONS; phon++){
    fprintf(file, "%d\t%c",(cycleno-1),phonchar[phon]);			
    for(slice = 0 ; slice < PSLICES; slice++){
      if(phoneme[phon].ex[slice]==0){ fprintf(file, "\t%.1f", phoneme[phon].ex[slice]); }
      else{ fprintf(file, "\t%.8f", phoneme[phon].ex[slice]);}
    }
    fprintf(file,"\n");				
  }
  fclose(file);


  // PRINT THE _WORD.TXT FILE -- THIS IS THE CRITICAL ONE; WE'LL LEAVE IT 
  sprintf(filename,"data/%s_word.txt", modelInput);	
  if(sfeaturefile[0] != '\0') {
    sprintf(filename,"data/%s_word.txt", sfeaturefile);
  }
  
  if(cycleno == 1) {file = fopen(filename,"w");} // create new file
  else{file = fopen(filename,"a");} // append
  
  for(wd = 0; wd < nwords; wd++){
    fprintf(file, "%d\t%s",(cycleno-1),wordptr[wd]->sound);			
    for(slice = 0 ; slice < PSLICES; slice++){
      if(wordptr[wd]->ex[slice]==0){ fprintf(file, "\t%.1f", wordptr[wd]->ex[slice]); }
      else{ fprintf(file, "\t%.8f", wordptr[wd]->ex[slice]);}
    }
    fprintf(file, "\n");		
  }
  fclose(file);	
  
  printf("ok\n");	
}

/***************************************************************************/
void diagnostic2()
{
	int i, j, k;
	double result;
	result = 1.;
	for(i = 1; i < 10000000;){
		result = result * i;
		i += 2;
		if(i>9998000){
		  printf("%.17f\n",result);
		}
		result = result / i;
		i += 3;
		if(i>9998000){
		  printf("%.17f\n",result);
		}
	}

}


/***************************************************************************/
void diagnostic()
{
	double a, b, c, d , e ;
	double result;
	int i, j, k;
	result = 1.;
	a=1.; b=1.; c=2.; d=c/(a+b);
	for(i = 1; i < 1000;i++){
		a=b;
		b=c;
		c=d;
		d=c/(a+b);
		//if(i%100==0){
		  printf("%.17f\n",d);
		//}
		
	}

}

/***************************************************************************/
void dumpParam()
{	
	int i,wd;
	FILE *file;
	char filename[100], modelInput[20];
	//printf("Filename:");
	//scanf("%s",filename);
	//sprintf(otherfile, "%s.phon",filename);
	for(i = 0; i < MAXITEMS-1; i++){
		if(inspec[i][0]=='.') break;
		modelInput[i]=inspec[i][0];
		if(modelInput[i] == '-'){ modelInput[i] = 'Q'; }
		if(modelInput[i] == '^'){ modelInput[i] = 'x'; }
		if(modelInput[i] == 'H'){ modelInput[i] = 'h'; }
	}

	sprintf(filename,"data/%s_parameters.jt", modelInput,(cycleno-1));	
	//sprintf(filename,"data/parameters.xml");	
	file = fopen(filename,"w");
	if(file == NULL)
	{
     printf("Could not open file (%s)! \n",filename);
		return;
	}
	//	fprintf(file, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<jt xmlns=\'http://xml.netbeans.org/examples/targetNS\' \n\txmlns:xsi=\'http://www.w3.org/2001/XMLSchema-instance\' xsi:schemaLocation=\'http://xml.netbeans.org/examples/targetNS http://maglab.psy.uconn.edu/jtraceschema.xsd\'>\n\t<description>cTRACE simulation parameters</description>\n\t<script>\n\t\t<action>\n\t\t<set-parameters><parameters>");//
	fprintf(file, "#parameters from a cTrace simulation.\n");
	fprintf(file, "alpha\tIF\t%.3f\tFP\t%.3f\tPW\t%.3f\tPF\t%.3f\tWP\t%.3f\n", alpha[IF], alpha[FP], alpha[PW], alpha[PF], alpha[WP]);
	fprintf(file, "decay\tF\t%.3f\tP\t%.3f\tW\t%.3f\n", decay[F], decay[P], decay[W]);
 	fprintf(file, "gamma\tF\t%.3f\tP\t%.3f\tW\t%.3f\n", ga[F], ga[P], ga[W]);
	fprintf(file, "rest\tF\t%.3f\tP\t%.3f\tW\t%.3f\n", rest[0], rest[1], rest[2]);
	fprintf(file, "min\t%.3f\tmax\t%.3f\n", min, max);
	fprintf(file, "FSLICES\t%d\tnwords\t%d\tnreps\t%d\tFPP\t%d\n", FSLICES, nwords, nreps, FPP);
	for(i = 0; i < MAXITEMS-1; i++){
		modelInput[i]=inspec[i][0];
	}
	fprintf(file, "\n\t\t<StringParam><name>modelInput</name><StringValue>%s</StringValue></StringParam>", modelInput);
	fprintf(file, "\n\t\t<StringParam><name>phonContinuum</name><StringValue>pb3</StringValue></StringParam>");
	//fprintf(file, "\n\t\t<IntParam><name>deltaSlices</name><IntValue>%d</IntValue></IntParam>", );
	fprintf(file, "\n\t\t<lexicon>");
	for(wd = 0; wd < nwords;wd++){ 	
		fprintf(file, "\n\t\t\t<lexeme><phonology>%s</phonology></lexeme>", wordptr[wd]->sound);
	}
	fprintf(file, "\n\t\t</lexicon>");
	fprintf(file, "\n\t\t<IntParamRep><name>FETSPREAD</name>");
	for(i = 0;i < NCONTINS; i++){
		fprintf(file, "\n\t\t\t<IntValue>%d</IntValue>", fetspread[i]);
	}
	fprintf(file, "\n\t\t</IntParamRep>");
	
	fprintf(file, "\n\t\t<DecimalParamRep><name>spreadScale</name>");
	for(i = 0;i < NCONTINS; i++){
		fprintf(file, "\n\t\t\t<DecimalValue>1.0</DecimalValue>");
	}
	fprintf(file, "\n\t\t</DecimalParamRep>");
	fprintf(file, "\n\t</parameters>\n\t</set-parameters></action>");	
	fprintf(file, "\n\t<action><set-cycles-per-sim><cycles>80</cycles></set-cycles-per-sim></action>");
	fprintf(file, "\n\t<action><new-window><arg>n/a</arg></new-window></action>");
	fprintf(file, "\n\t</script></jt>");
	fclose(file);	
	printf("ok\n");	
}
