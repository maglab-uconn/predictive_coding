# include "defs.h"

initialize() 
{
	WORD *wp, **wptr, **wlp, **wlptr;
	PHONEME *pp, **plptr;
	FEATURE *fp;
	register int f, c, phnm, len, t, fslice, pslice, i;
	int *ofstlptr;
	char *sp;
	float ft, denom;
	int ntoks, index;
	int ispr;
	float tdur, spr, ss;
	char pchar;
	static int reset = 0;

	printmin = 0;
	printmax = 66;

	for (c = 0 ; c < NCONTINS; c++ ) {
	    for (f = 0; f < NFVALS; f++) {
		fp = &feature[c][f];
		fp->spread = fetspread[c];
		plptr = fp->phonlist;
		for (i = 0; i < NPHONS; i++) {
		    if (fetval[i][c][f]) *plptr++ = &phoneme[i];
		}
	    }
	}
	/* feature spread is the number of feature slices over which
	   the feature spreads, in one direction, or alternatively
	   the 1/2 bandwidth of the spacial range over which the
	   feature spreads.  We assume triangular distributions */

	i = 0;
	for ALLPHONEMES {
	    pp->sound = phonchar[i];
	    pp->wscale = wscale[i];
	    pp->fdur = (PWIDTH)*pp->wscale;
	    pp->pdur = pp->fdur/FPP;
	    tdur = (float) (PWIDTH+POVERLAP)*pp->wscale/FPP;
	/*  pp->pdur is the number of PHONEME slices over which the 
	    phoneme spreads, in one direction from its center, or 
	    alternatively the 1/2 bandwidth of the spacial range
	    over which the phoneme spreads.  We assume triangluar
	    distributions.  pp->fdur is just the same thing in FEATURE
	    slices */
	    pp->rsus = phonrsus[i];
	    pp->feature = &fetval[i][0][0];
	    phonptr[pp->sound] = pp;
	    pp->feature = &fetval[i++][0][0];
	    /* determine weights for feature to phoneme interactions
	       based on the spread of the values on the continuum in
	       this particular phoneme. */
	    for (c = 0; c < NCONTINS; c++) {
		spr = (fetspread[c]*pp->wscale);
		ispr = spr;
		denom = 0;
		for (fslice = 0; fslice <= 2*(ispr); fslice++) {
		    ft = ((spr - abs(ispr - fslice))/spr);
		    denom += ft*ft;
		}
		for (fslice = 0; fslice < 2*(ispr); fslice++) {
		    pp->pfw[c][fslice] = ((spr - abs(ispr - fslice))/spr);
		    pp->fpw[c][fslice] = pp->pfw[c][fslice]*pp->wscale/denom;
			//printf("%.3f | ", ((spr - abs(ispr - fslice))/spr));
			//printf("%.3f , ", pp->pfw[c][fslice]*pp->wscale/denom);
		}
		//printf("\n");
		/* Note that fpw is weighted by the length of the phoneme
	       (wscale).  The intention here is to implement the notion
	       that a particular unit's total excitability has to be 
	       proportional to its length. This is because its inhibitability
	       is also proportional to its length. */

	    }
	    /* now determine the weights for phoneme->word excitation 
	       based on the spread of the phoneme.   */
	    denom = 0;
	    for (pslice = 0; pslice <= 2*(pp->pdur); pslice++) {
		    ft = ((tdur - abs(pp->pdur - pslice))/tdur);
		    denom += ft*ft;
	    }
	    for (pslice = 0; pslice < 2*(pp->pdur); pslice++) {
		    ft = ((tdur - abs(pp->pdur - pslice))/tdur);
		    pp->pww[pslice] = ft/denom;
		    pp->wpw[pslice] = pp->wscale*ft/denom;
			//printf("%.3f | ", (ft/denom));
			//printf("%.3f , ", (pp->wscale*ft/denom));			
	    }
		//printf("\n");
	    /* the above assumes that the phoneme in question
	       spreads over a distance equal to +- spread from
	       its peak.  The word detector looks for it 
	       accordingly in a window that wide.  The weighting
	       rule for how importantly it weights the activation
	       at distance i from the left edge of its window is
	       stored in pp->nw.  nw's values are assigned such that
	       if the phoneme is exactly present as specified,
	       the weights times the activation values will add
	       to 1.0 */
	}


	wptr = wordptr;
	for ALLWORDS {
	    if (*wptr) free(*wptr);
	    *wptr = (struct word *) calloc(1,sizeof(struct word));
	    wp = *wptr++;
	    wp->base = rest[W] + fscale*log(1. + wordfreq[i]);
	    wp->sound = wordsound[i];
	    len = strlen(wp->sound);
	    wp->offset = (int *) calloc(len,sizeof(int));
	    wp->offset[0] = t = 0;
	    for (phnm = 1; phnm < len; phnm++) {
		t += (phonptr[wp->sound[phnm]]->pdur)/2 +
			(phonptr[wp->sound[phnm-1]]->pdur)/2;
		wp->offset[phnm] = t;
	    }
	    wp->start = 0 - (phonptr[wp->sound[0]]->pdur)/2;
	    wp->end = wp->offset[phnm-1] + (phonptr[wp->sound[phnm-1]]->pdur)/2;
	    wp->scale = (wp->end - wp->start)/len;	
		//printf("scale %.2d\n",((wp->end - wp->start)/len));
	}
	/* wp->scale gives the length of the word in PSLICES per phoneme.
	   it is used in determining the excitability of the word  by
	   phonemes.  */

	*wptr = NULL;
	wlp = wtord;
	for ALLWORDPTRS {
		*wlp++ = *wptr;
	}
		

	for ALLPHONEMES {

	    ntoks = 0;
	    pchar = pp->sound;
	    for ALLWORDPTRS {
		wp = *wptr;
		for (sp = wp->sound; *sp; ) {
		    if (*sp++ == pchar) ntoks++;
		}
	    }
	    pp->wordlist = 
		 (struct word **) calloc(ntoks+1,sizeof(struct word *));
	    pp->ofstlist = (int *) calloc(ntoks,sizeof(int));
	    wlptr = pp->wordlist;
	    ofstlptr = pp->ofstlist;
	    for ALLWORDPTRS {
		wp = *wptr;
		for (sp = wp->sound, index = 0; *sp; index++ ) {
		    if (*sp++ == pchar) {
			*wlptr++ = wp;
			*ofstlptr++ = wp->offset[index];
		    }
		}
	    }
	}

	reset = 1;
	zarrays();
}
