# include "defs.h"

/* low-level subroutines -- plan is that they should not need to be
   changed too often  */

stop()
{
	if (signal(2,stop) & 01) signal(2,stop);
	sigflag = 1;
}

getfloat(fptr,nvals,args)
register float *fptr;
int nvals;
char *args;
{
	register int i,n;
	register char **label;
	label = &args;
	n = ( (nvals > 10) ? 10 : nvals);
	for (i = 0; i < n; i++) ttyprint("%7s",label[i]);
	ttyprint("\n");
	for (i = 0; i < n; i++) {
		ttyprint("%7.4f",*(fptr + i));
	}
	ttyprint("\n");
	if (nvals > 10) {
		for (i = 10; i < nvals; i++) ttyprint("%7s",label[i]);
		ttyprint("\n");
		for (i = 10; i < nvals; i++) {
			ttyprint("%7.4f",*(fptr + i));
		}
		ttyprint("\n");
	}
	ttyprint("changes? ");
getfloatloop:
	fscanf(infp,"%s",in);
	if (in[0] == 'n' || in[0] == 'q') return;
	for (i = 0; i < nvals; i++)
		if (strcmp(in,label[i]) == 0)  break;
	if (i == nvals) 
		{
		printf ("Unrecognized label.\n");
		BACKTOTTY
		return;
		}
	fscanf(infp,"%f",(fptr + i));
	goto getfloatloop;
}

quit()
{
	register int i;
	FILE *iop;

	getstring("w to save params and quit, q to quit without saving: ");
	if (in[0] == 'q') exit(0);
	if (in[0] == 'w')
		{
		getstring ("File name: ");
		if ( (iop = fopen(in,"w")) == NULL)
			{
			printf ("Can't open %s.\n",in);
			BACKTOTTY
			return;
			}
		dump(iop);
		exit(0);
		}
}

getval(fp)
float *fp;
{
	ttyprint("%7.4f -- change? ",*fp);
	fscanf(infp,"%s",in);
	if (in[0] == 'n') return;
	sscanf(in,"%f",fp);
}

getstring(string)
char *string;
	{
infp=stdin;
	ttyprint (string);
	return(fscanf(infp,"%s",in));
	}

tindex(s,t)
char s[], t[];
{
	register int i,j,k;
	for (i = 0; s[i] != '\0'; i++)
		{
		for (j = i, k = 0; t[k] != '\0' && s[j] == t[k]; j++,k++);
		if (t[k] == '\0')
			return(i);
		}
	return(-1);
}
startsame(s1,s2) /* does s1 start the same as s2? s2 is the full version, s1
				 its possible beginning */
char *s1, *s2; 
{
	while (*s1) {
		if (*s1++ != *s2++)
		return(0);
	}
	return(1);
}


setex() 
{
	char *error;
getreloop:
	getstring("Regular expression: ");
	if (in[0] == '-' || in[0] == 'Q')  {
		echeck = 0;
		return;
	}
	//if ( (error = re_comp(in)) != NULL) {
	//	printf("%s\n",error);
	//	BACKTOTTY
	//	goto getreloop;
	//}
	echeck = 1;
}


fileinput(type)
int type; {
	if (type == STD) {
		if (altiop)  {
			fclose(altiop);
			altiop = NULL;
		}
		infp = stdin;
		return;
	}
	else {
		if (altiop)  {
			fclose(altiop);
			altiop = NULL;
		}
		getstring ("Take input from file: ");
		if ( (altiop = fopen(in,"r") ) == NULL) {
			printf ("Can't open %s.\n",in);
			BACKTOTTY
			return;
		}
		infp = altiop;
	}
}

ecomp(wp1,wp2)
WORD **wp1, **wp2; {
	float t;

	t = (*wp2)->ex - (*wp1)->ex;
	if (t > 0) return (1);
	if (t < 0) return (-1);
	return (0);
}


setoutfile(fname) char *fname;
{
	if (fname[0] == '-') {
		outfile = NULL;
		outflag = 0;
	}
	else {
		strcpy(outname,fname);
		if (outfile != NULL) fclose(outfile);
		if ( (outfile = fopen(outname,"a") ) == NULL) {
			printf("cannot open %s.\n",outname);
			BACKTOTTY
			return;
		}
		outflag = 1;
	}
}

getlex()
{
    getstring("lexicon file name: ");
    if (lexicon(in))	{
	    initialize();
    }
    //    fprintf(stderr,"Opened lexicon %s\n",in);
}

getpars() 
{
    WORD *wp;
    register int i;

    getstring("parameter file name: ");
    if (load(in))	{
	    i = 0;
	    for ALLWORDS {
		    wp->base = rest[W] + fscale*log(1. + wordfreq[i]);
	    }
    }
}

