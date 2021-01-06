# include "defs.h"

wordorder(p1, p2) struct word **p1, **p2; {
	register int i;
	float diff;
	WORD *wp1, *wp2;
	wp1 = *p1;
	wp2 = *p2;
	wp1->mloc = 0;
	wp2->mloc = 0;
	wp1->max = 0;
	wp2->max = 0;

	for (i = 0; i < PSLICES; i++) {
		if (wp1->ex[i] > wp1->max) {
			wp1->mloc = i;
			wp1->max = wp1->ex[i];
		}
		if (wp2->ex[i] > wp2->max) {
			wp2->mloc = i;
			wp2->max = wp2->ex[i];
		}
	}
	diff = wp1->max - wp2->max;
	if (diff > 0) return (-1);
	if (diff < 0) return (1);
	else return (0);
}

printwt(pmin,pmax,pstep,iop)
int pmin,pmax,pstep; 
FILE * iop;
{
    WORD **wptr,*wp;
    register int cy;
    int i, tc, len,npr;
    float thr, ot,yval;
    if (pmax == 0) pmax = (PSLICES*FPP);
    pstep = FPP;
    pmin = 0;
    fprintf(iop,"ACTIVATIONS of WORD TOKENS ");
    fprintf(iop,"(INPUT at %d)\n", cycleno);
    fprintf(iop,"\t");
    for (cy = pmin; cy <= pmax; cy += pstep) {
	    fprintf(iop," %2d",cy);
    }
    fprintf(iop,"\n");
    npr = 0;
    qsort(wtord,nwords,sizeof(struct word *),wordorder);
    yval = ymax;
    for (wptr = wtord; wptr < wtord + nwords; wptr++) {
	    wp = *wptr;
	    if (wp->sound[0] == '-') continue;
	    if (wp->max < pthresh[W]) break;
	    while (yval > wp->max) {
		fprintf(iop,"\n");
		if ( (iop == stdout) && ((++npr % 20) == 0) ) {
			getstring("q to quit/else continue: ");
			if (in[0] == 'q') return;
		}
		yval -= ydec;
	    }
	    fprintf(iop,"%6.4f\t  ",wp->max );
	    for (tc = pmin; tc < (wp->mloc + wp->start)*FPP; tc ++ )  {
		    fprintf(iop," ");
	    }
	    fprintf(iop,"|");
	    tc ++ ;
	    len = strlen(wp->sound);
	    for (i = 0; i < len; i++) {
		for (; tc < (wp->mloc + wp->offset[i])*FPP; tc ++ ) {
		    fprintf(iop," ");
		}
		fprintf(iop,"%c",wp->sound[i]);
		tc ++ ;
	    }
	    for (; tc < (wp->mloc + wp->end)*FPP; tc ++) {
		    fprintf(iop," ");
	    }
	    fprintf(iop,"|\n");
	    yval -= .02;
	    if ( (iop == stdout) && ((++npr % 20) == 0) ) {
		    getstring("q to quit/else continue: ");
		    if (in[0] == 'q') return;
	    }
	if (sigflag) {sigflag = 0; return;}
    }
}

excomp(ex1,ex2) float *ex1, *ex2;  {
	if (*ex1 > *ex2) return (1);
	else if (*ex2 > *ex1) return(-1);
	return(0);
}

printonewt(wrd,pmin,pmax,pstep,iop)
char *wrd;
int pmin,pmax,pstep; 
FILE * iop;
{
    WORD **wptr,*wp;
    register int cy;
    int i, tc, len,npr,exind;
    float thr, ot,yval;
    float **eptr, *ep;
    if (pmax == 0) pmax = (PSLICES*FPP);
    pstep = FPP;
    pmin = 0;
    fprintf(iop,"ACTIVATIONS of TOKENS of WORD %s",wrd);
    fprintf(iop,"(INPUT at %d)\n", cycleno);
    fprintf(iop,"\t");
    for (cy = pmin; cy <= pmax; cy += pstep) {
	    fprintf(iop," %2d",cy);
    }
    fprintf(iop,"\n");
    npr = 0;
    yval = ymax;
    for ALLWORDPTRS {
	    wp = *wptr;
	    if (strcmp(wp->sound,wrd) == 0) break;
    }
    if (!wptr) return;
    for (i = 0; i < PSLICES; i++) {
	exptr[i] = &wp->ex[i];
    }
    qsort(exptr,PSLICES,sizeof(float *),excomp);
    for (eptr = exptr; eptr < exptr + PSLICES; eptr++ ) {
	    ep = *eptr;
	    if (*ep < pthresh[W]) continue;
	    while (yval > *ep) {
		fprintf(iop,"\n");
		if ( (iop == stdout) && ((++npr % 20) == 0) ) {
			getstring("q to quit/else continue: ");
			if (in[0] == 'q') return;
		}
		yval -= ydec;
	    }
	    fprintf(iop,"%6.4f\t  ",*ep );
	    for (i = 0; i < PSLICES; i++) {
		if (&wp->ex[i] == ep) break;
	    }
	    exind = i;
	    for (tc = pmin; tc < (exind + wp->start)*FPP; tc ++ )  {
		    fprintf(iop," ");
	    }
	    fprintf(iop,"|");
	    tc ++ ;
	    len = strlen(wp->sound);
	    for (i = 0; i < len; i++) {
		for (; tc < (exind + wp->offset[i])*FPP; tc ++ ) {
		    fprintf(iop," ");
		}
		fprintf(iop,"%c",wp->sound[i]);
		tc ++ ;
	    }
	    for (; tc < (exind + wp->end)*FPP; tc ++) {
		    fprintf(iop," ");
	    }
	    fprintf(iop,"|\n");
	    yval -= .02;
	    if ( (iop == stdout) && ((++npr % 20) == 0) ) {
		    getstring("q to quit/else continue: ");
		    if (in[0] == 'q') return;
	    }
	if (sigflag) {sigflag = 0; return;}
    }
}
