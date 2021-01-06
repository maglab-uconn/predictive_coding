
#include "defs.h"
#include <time.h>
/* mostly routines concerned with feature input stuff -- reading,
   writing, compiling, etc included.  also routines concerned
   with changing defs of features and stuff.  these seem useless */

// apparent change log:
//   inputcomp    : removes automatic insertion of silence before and after words?
//                : 'gaussSD' allows adding gaussian noise to inputs
//   fillinput    : 'shifter' allows shifting inputs to the right (with true silence before)
//                   to allow competition with longer words
//   simOneWord   : appears to be completely new function
//   makein       : revised back to 'original' version that prepends and appends sil phone to words
//   makeinNoSil  : revised version of makein that doesn't add silence phonemes; have to figure out how to trigger this
//                : working on getting global variable 'nosilence' to trigger this

inputcomp()
{
  register int i,j,f,k, inp, c, fet;
  int _ninputs;
  char *p;
  /* it appears that all defs from here down were added by Magnuson */
  int atg;
  float fmin = 0.0; // -0.3;
  float fmax = 1.0;
  double jitter;

  for (_ninputs = 0; _ninputs < MAXITEMS-1 ; ) {
    printf("%s \t",inspec[_ninputs]);
    _ninputs++;
  }
  for (i = 0; i < FSLICES; i++) {
    for (j = 0; j < NCONTINS; j++)  {
      for (f = 0; f < NFVALS; f++) {
	infet[i][j][f] = 0;
      }
    }
  }
  for (i = 0; i < ninputs; i++) {
    for (j = 0; j < NCONTINS; j++)  {
      for (f = 0; f < NFVALS; f++) {
	infet[i][j][f] = 0;
      }
    }
    if ( (k = tindex(classchar,inspec[i])) >= 0) {
      // if you leave this in, it adds a weird final phoneme like trace in each word
      // 2016.10.22 -- that comment above probably from me, not sure what this is -- was it adding silence at end? -jmagnuson

      /* a class specification */
      //      for (j = 0; j < NCONTINS; j++) {
      //	for (f = 0; f < NFVALS; f++) {
      //	  infet[i][j][f] = classval[k][j][f];
      //	}
      //      }
      //      indur[i] = PWIDTH;
      //      insus[i] = 1.0;
    } else {			   /*simply a phoneme */
      if ( (k = tindex(phonchar,inspec[i])) < 0 ) {
	continue;
      }
      inphone[i] = phonptr[phonchar[k]];
      indur[i] = phonptr[phonchar[k]]->fdur;
      insus[i] = phonrsus[k];
      
      for (j = 0; j < NCONTINS; j++) {
	for (f = 0; f < NFVALS; f++) {
	  infet[i][j][f] = fetval[k][j][f];
	}
      }
    }
  }
  fillinput();
  // Added by Magnuson: ability to add noise to inputs
  if(gaussSD){
    for(inp = 0; inp < FSLICES; inp++){
      for (c = 0; c < NCONTINS; c++) {
	for (fet = 0; fet < NFVALS; fet++) {
	  jitter = (gaussDist[rand() % GDISTSIZE]*gaussSD);
	  //fprintf(stderr,"################ FETORIG inp %d c %d fet %d input[in][c][fet] %f + jitter %f = ",
	  // inp, c, fet, input[inp][c][fet],jitter);
	  input[inp][c][fet] += (float) jitter;
	  if(input[inp][c][fet] < fmin){ input[inp][c][fet] = fmin; }
	  if(input[inp][c][fet] > fmax){ input[inp][c][fet] = fmax; }
	  //	  fprintf(stderr,"  RESULT input[in][c][fet] = %f\n", input[inp][c][fet],jitter);
	  //fprintf(stderr,"%f\n",input[inp][c][fet]);
	} // for fet
      } // for c
    } // for inp
  }

}

/* *************************************************** */
fillinput()
{
  register int inp, c, fet, cyc;
  int midp;
  int shifter = 0;
  double jitter;
  float t,spread,r_sq,weight;
 

  for (cyc = 0; cyc < FSLICES; cyc++) {
    for (c = 0; c < NCONTINS; c++) {
      for (fet = 0; fet < NFVALS; fet++) {
	input[cyc][c][fet] = 0;
      } 
    } 
  }

  for (inp = 0; inp < ninputs; inp++) {
    if (inp) {
      //inpeak[inp] = inpeak[inp-1] +
	inpeak[inp] = inpeak[inp-1] +
	inrate[inp-1]*insus[inp-1]*indur[inp-1]/2.0
	+ inrate[inp]*insus[inp]*indur[inp]/2.0;
    } else {
      //      inpeak[inp] = shifter + 
	      inpeak[inp] = 
	inrate[inp]*insus[inp]*indur[inp];
    }

    for (c = 0; c < NCONTINS; c++) {
      for (fet = 0; fet < NFVALS; fet++) {
	t = infet[inp][c][fet];
	spread = inrate[inp]*fetspread[c];
	// ORIGINAL
	for (cyc = nonneg( 1 + inpeak[inp] - spread);
	   cyc < (inpeak[inp]+spread) && cyc < FSLICES; cyc++) {

	// modifying to pad at the onset by 'shifter' slices; 
	// the aim in doing this is to allow competition between 
	// long and short words, e.g., if words align at time 0, 
	// ^s won't activate a tr^st node because there isn't one aligned with it
	// (of course, this may be appropriate, but this will generate testable
	// hypotheses: do words show competition from longer words that 'start'
	// 2-3 phonemes 'before' them (e.g., does 'us' get competition from 'trust',
	// 'bust', 'must', 'frustrate', etc.?)
	// jim magnuson 2015.12.09

	  // HOWEVER: 2016.10.22 -- you have to be careful to add multiples of 3; if you don't, word
	  // duplicates don't align properly and accuracy goes to hell -- jmagnuson

	  weight = 1 - (abs(inpeak[inp] - cyc)/spread);
	  input[cyc + shifter][c][fet] += weight*t*instrength[inp];
	} // for cyc   
      } // for fet
    } // for c
  } // for inp

  for(inp = 0; inp < FSLICES; inp++){
    for (c = 0; c < NCONTINS; c++) {
      for (fet = 0; fet < NFVALS; fet++) {
	input[cyc][c][fet] += 0;
      } // for fet
    } // for c
  } // for inp

}



/* *************************************************** */
inspecs(str) char *str; 
{
  PHONEME *pp;
  register int i,j;
  int count;
  FILE *iop;
  char phchar[BUFSIZ];
  
  if (str[0] == '-') iop = infp;
  else if ( (iop = fopen(str,"r")) == NULL) {
    printf("Can't open %s.\n",str);
    BACKTOTTY
      return;
  }
  
  if (iop == infp) {
    ttyprint("Give one phoneme,strength,rate/line (end with ^D):\n");
  }
  
  for (ninputs = 0; ninputs < MAXITEMS; ninputs++) {
  getphoneme:
    count = fscanf(iop,"%s %f %f",
		   phchar,&instrength[ninputs],&inrate[ninputs]);
    if (count == EOF) break;
    strcpy(inspec[ninputs],phchar);
  }
  clearerr(iop);
  if (iop != infp)
    fclose(iop);
  else
    clearerr(infp);
  inputcomp();
}

/* *************************************************** */
sinspec() 
{
  FILE *iop;
  int i;
  getstring("Give filename for spec list: ");
  if ( (iop = fopen(in,"w")) == NULL) {
    printf ("Can't open %s.\n",in);
    BACKTOTTY
      return;
  }
  for (i = 0; i < ninputs; i++) {
    fprintf(iop,"%s %f %f\n",
	    inspec[i],instrength[i],inrate[i]);
  }
  fprintf(iop,"q\n");
  fclose(iop);
}

/* *************************************************** */
dinspec() 
{
    int i;
    for (i = 0; i < ninputs; i++) {
	printf("%s %f %f %d %d\n",
	  inspec[i],instrength[i],inrate[i],inpeak[i],indur[i]);
    }
}

/* *************************************************** */
sfeatures() 
{
    FILE *iop;
    register int i,f,c;
    if ( (iop = fopen(in,"w")) == NULL) {
	printf ("Can't open %s.\n",in);
	BACKTOTTY
	return;
    }
    for (i = 0; i < FSLICES; i++) {
      for (c = 0; c < NCONTINS; c++) {
	for (f = 0; f < NFVALS; f++) {
	    fprintf(iop,"%8.5f ",input[i][c][f]);
	}
	fprintf(iop,"\n");
      }
    }
    fclose(iop);

}

/* *************************************************** */
infeats(str) char *str;
{
	register int i,c,f;
	FILE *iop;

	if ( (iop = fopen(str,"r")) == NULL) {
		printf("Can't open %s.\n",in);
		fprintf(stderr,"Can't open %s.\n",in);
		BACKTOTTY
		return;
	}

	initialize();

	for (i = 0; i < FSLICES; i++) {
	  for (c = 0; c < NCONTINS; c++) {
	    for (f = 0; f < NFVALS; f++) {
		fscanf(iop,"%f ",&input[i][c][f]);
	    }
	    fscanf(iop,"\n");
	  }
	}
	fclose(iop);
}
		
/* *************************************************** */
acoustinput(pmin,pmax,pstep,iop)
int pmin, pmax,pstep; 
FILE *iop;
{
	register int i,j,f,cy;
	if (pmax == 0) pmax = cycleno;
	if (pstep == 0) pstep = 1;
	fprintf(iop,"\t\t\tACOUSTIC FEATURES\n");
	fprintf(iop,"Slice->\t");
	for (cy = pmin; cy <= pmax; cy += pstep) {
		fprintf(iop,"%3d",cy);
	}
	fprintf(iop,"\n");
	for (j = 0; j < NCONTINS; j++) {
	    for (f = 0; f < NFVALS; f++) {
		for (cy = pmin; cy <= pmax; cy += pstep) {
		    if (input[cy][j][f] > pthresh[F]) {
			break;
		    }
		}
		if (cy == pmax+pstep) continue;
		fprintf (iop,"%s.%d\t",contname[j],f);
		for (cy = pmin; cy <= pmax; cy += pstep) {
		    if (input[cy][j][f] <= pthresh[F]) 
			fprintf(iop,"   ");
		    else
			fprintf (iop,"%3d",(int) (input[cy][j][f]*100));
		}
		fprintf(iop,"\n");
	    }
	    if (sigflag) {sigflag = 0; return;}
	}
}


/* *************************************************** */
/* get new set of feature definitions for the phonemes */
getfeats()
{
    getstring("feature file name: ");
    if (features(in))	{
	initialize();
    }
}	

/* *************************************************** */
features(filename)
char *filename;
{
    FILE *iop;
    register int c,f,p;

    if ( (iop = fopen(filename,"r")) == NULL) {
	printf("Can't open %s.\n",filename);
	fprintf(stderr,"Can't open %s.\n",filename);
	BACKTOTTY
	return(0);
    }
    
    while (fgets(in,BUFSIZ,iop) != NULL) {
	for (p=0; p<NPHONS; p++) {
	  for (c = 0; c < NCONTINS;c++) {
	    for (f=0; f<NFVALS; f++) {
		sscanf(in,"%f",&fetval[p][c][f]);
	    }	
	    sscanf(in,"\n");
	  }
	}
    }
    fclose(iop);
    return(1);
}

/* *************************************************** */
test(str)  char *str; {
	char string[20], word[20];
	// if you initialize here it wipes out primes, etc. 
	//initialize();
	strcpy(string,str);
	//strcpy(string,in);
	//getstring("words: ");
	//strcpy(word,in);
	zarrays();
	if(nosilence){
	  makeinNoSilence(string);
	} else { 
	  makein(string);
	}
	//zarrays();
	//cycle();
}

/* *************************************************** */
simOneWord(str)  char *str; {
	char string[20], word[20];
	int i,num;
	clock_t ttime;

	ttime = clock();
	initialize();
	strcpy(string,str);
	fprintf(stderr, "\t# simulating");
	zarrays();
	if(nosilence){
	  makeinNoSilence(string);
	} else { 
	  makein(string);
	}
	num = 111;
	nreps = 1;
	for(i=0;i<num;i++){
	  cycle();
	  dumpMatrix();
	}

	ttime = clock() - ttime;
	double time_taken = ((double)ttime)/CLOCKS_PER_SEC; 
	fprintf(stderr, "\t# took %f secs\n", time_taken);
}

//##########################################//
makein(word) char *word; {
  //char _inspec[20];
  //strcpy(_inspec,*word);
  /* * * * * * * * * * * * * * * * * * * * */
  instrength[0] = inrate[0] = 1.;
  for (ninputs = 1; ninputs < MAXITEMS-1 ; ) {
    inspec[ninputs][0] = '\0';
    inspec[ninputs][1] = '\0';
    ninputs++;
  }
  // have not tested, but I think this has to come after the clearing
  // step (that is, copying silence to beginning).

  /* putting next line back in for SILENCE */
  strcpy(inspec[0],"-"); // pad silence phoneme at word onset
  for (ninputs = 1; ninputs < MAXITEMS && *word; ) {
    if (*word == '.') {
      *word++;
      continue;
    }
    inspec[ninputs][0] = *word++;
    inspec[ninputs][1] = '\0';
    instrength[ninputs] = inrate[ninputs] = 1.0;
    ninputs++;
  }
  strcpy(inspec[ninputs],"-"); // pad silence phoneme at word offset
  instrength[ninputs] = inrate[ninputs] = 1.;
  ninputs++;
  int _ninputs;
  for (_ninputs = ninputs; _ninputs < MAXITEMS; ) {		
    strcpy(inspec[_ninputs],".");	
    inspec[_ninputs][0] = '\0';
    inspec[_ninputs][1] = '\0';
    _ninputs++;		
  }
  inputcomp();
}

//##########################################//
makeinNoSilence(word) char *word; {
  //char _inspec[20];
  //strcpy(_inspec,*word);
  /* * * * * * * * * * * * * * * * * * * * */
  instrength[0] = inrate[0] = 1.;
  for (ninputs = 1; ninputs < MAXITEMS-1 ; ) {
    inspec[ninputs][0] = '\0';
    inspec[ninputs][1] = '\0';
    ninputs++;
  }
  // have not tested, but I think this has to come after the clearing
  // step (that is, copying silence to beginning).

  /* putting next line back in for SILENCE */
  //  //  strcpy(inspec[0],"-");
  // LINE BELOW IS FOR WORKING WITH SILENCE
  //for (ninputs = 1; ninputs < MAXITEMS && *word; ) {
  for (ninputs = 0; ninputs < MAXITEMS && *word; ) {
    if (*word == '.') {
      *word++;
      continue;
    }
    inspec[ninputs][0] = *word++;
    inspec[ninputs][1] = '\0';
    instrength[ninputs] = inrate[ninputs] = 1.0;
    ninputs++;
  }
  /* putting next line back in for SILENCE */
  //  //  strcpy(inspec[ninputs],"-");
  /* * * * * * * * * * * * * * * * * * * * */
  //	instrength[ninputs] = inrate[ninputs] = 1.;
  ninputs++;
  int _ninputs;
  for (_ninputs = ninputs; _ninputs < MAXITEMS; ) {		
    strcpy(inspec[_ninputs],".");	
    inspec[_ninputs][0] = '\0';
    inspec[_ninputs][1] = '\0';
    _ninputs++;		
  }
  inputcomp();
}

/*******************************/
togglenosilence()
{
	  if(nosilence == 1){
	    nosilence = 0;
	  } else if(nosilence == 0){
	    nosilence = 1;
	  }
	  fprintf(stderr, "nosilence now %i\n", nosilence);
}

/*
makein(word) char *word; {
	//strcpy(inspec[0],"-");
	//instrength[0] = inrate[0] = 1.;
	for (ninputs = 0; ninputs < MAXITEMS-1 && *word; ) {
		if (*word == '.') {
			*word++;
			continue;
		}
		inspec[ninputs][0] = *word++;
		inspec[ninputs][1] = '\0';
		instrength[ninputs] = inrate[ninputs] = 1.0;
		ninputs++;
	}
	//strcpy(inspec[ninputs],"-");
	//instrength[ninputs] = inrate[ninputs] = 1.;
	ninputs++;	

	inputcomp();
}
*/
