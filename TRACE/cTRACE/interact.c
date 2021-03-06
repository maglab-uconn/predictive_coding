#include "defs.h"
/*
 *act_features():
 *	handles input-to-feature excitation
 */	
act_features() 
{
    register float *iptr,*smptr,*fexptr,*nexptr;
    int c;
    FEATURE *fp;
	//ffi[] represents activation, t, from the prev incr. 
    for (c = 0; c < NCONTINS; c++) {
      for (iptr = ffi[c], smptr = fsum[c]; iptr < ffi[c] + FSLICES;) {
	*iptr++ = (*smptr++)*ga[F];
    } }
    
	//i think this block is handling activation coming from the input values while...
    if (cycleno < FSLICES) {
	for (c = 0; c < NCONTINS; c++) {
          for (fp = &feature[c][0],
	       iptr = &input[cycleno][c][0];
	       fp < &feature[c][0] + NFVALS; fp++,iptr++) {
		if ( *iptr ) {
		   fp->nex[cycleno] += fweight[c]*(*iptr); //this is a key update that will be used in fupdate(), fweight is all 1.0
    }  }  }  }

	//...this block is handling the inhibition?
    for (c = 0; c < NCONTINS; c++) {
       for (fp = &feature[c][0]; fp < &feature[c][0] + NFVALS; fp++) {
	    for (fexptr = fp->fex, nexptr = fp->nex, iptr = ffi[c];
	         fexptr < fp->fex + FSLICES; ) {
		 if (*iptr)
		    *nexptr++ -= (*iptr++ - *fexptr++);  //inhibition applied here: fp->nex -= t*ga[F]-fp->fex (last value filters self-inhibition)
		else
		    nexptr++,iptr++,fexptr++;
    }   }   }
}


ppinteract()
{
	register float *iptr, *ppexptr, *pnexptr, *sumptr;
	register int ppeak;
	PHONEME *pp;
	int pmax, pmin, halfdur;
	float *pmaxptr;
	//	char filename[100] = {'\0'}, otherfile[100] = {'\0'};

	for (iptr = ppi, sumptr = pisum; iptr < ppi + PSLICES; ) {
		*iptr++ = ga[P]*(*sumptr++);
	}
	/**/
	//for ALLPHONEMES {
	global_phone_comp = 0; // added jsm 2018.06.09
	for (pp = phoneme; pp < phoneme + 15; pp++) {
		halfdur = pp->pdur/2;
	    for (ppeak=0, pnexptr=pp->nex, ppexptr=pp->pex;
	         ppeak < PSLICES;
		 ppeak++, pnexptr++, ppexptr++) {
		pmax = ppeak+halfdur;
		if (pmax >= PSLICES) {
		    pmax = PSLICES-1;
		    pmin = ppeak - halfdur;
		}
		else if ( (pmin = ppeak - halfdur) < 0) {
			pmin = 0;
		}
		pmaxptr = &ppi[pmax];
		for (iptr = (&ppi[pmin]); iptr < pmaxptr;) {
		  global_phone_comp += *iptr; // added jsm 2018.06.09
		    *pnexptr -= *iptr++;
		    //printf("*pnexptr %.3f   ",*pnexptr);
		    //printf("from subtracting *iptr++ %.3f   ",*iptr);
		    //printf(", ? *ppexptr %.3f  ?",*ppexptr);	
		}
		if (*ppexptr) {
			*pnexptr += (pmax-pmin)*(*ppexptr);  // added jsm 2018.06.09 //filters self inhibition (?)
			global_phone_comp  -= (pmax-pmin)*(*ppexptr);  //filters self inhibition (?)
			//printf("\nRRR  *pnexptr %.3f   ",*pnexptr);
			//printf("*ppexptr %.3f   \n",*ppexptr);
		}
		//else{
		//	printf("***\n ");
		//}
	    }   }

	/*	sprintf(filename,"data/%s_global_phon_comp.txt", modelInput);	
	if(sfeaturefile[0] != '\0') {
	  sprintf(filename,"data/%s_phon.txt", sfeaturefile);
	}
	if(cycleno == 1) {file = fopen(filename,"w");} // create new file
	else{file = fopen(filename,"a");} // append
	fprintf(file,"%d\t%.6f\n", cycleno, global_phone_comp);*/


  /// sprintf(filename,"data/%s/phon_%.3d.xml",modelInput,(cycleno-1));
  //sprintf(filename,"data/phon_%.3d.xml",(cycleno-1));
  // file = fopen(filename,"w");
///  if(cycleno == 1) {file = fopen(filename,"w");} // create new file
//  else{file = fopen(filename,"a");} // append
//fprintf(stderr, "Global phone comp: %.6f\n", global_phone_comp);
}

fpinteract()
{
	register float *fpexptr, *wtptr, *pnexptr, *pfetptr, *pendptr;
	register int ftick;
	FEATURE *fp;
	PHONEME *pp, **plptr;
	int pstart, pend;
	int winstart, pfetind;
	int fspr, fmax;
	int c;
	float fpextot, fpexsum;
	float t;
	//printf("cycleno %.3d",cycleno);
	for (pfetind = 0, fp = &feature[0][0];
	     pfetind < NCONTINS*NFVALS; fp++,pfetind++ ) {
	    fpextot = fp->pextot;
	    for (fpexsum = 0, ftick = 0, fpexptr = &fp->pex[0];
		 fpexsum < fpextot; ftick++, fpexsum += *fpexptr++){
		if (*fpexptr) {
		    for (plptr = fp->phonlist; *plptr; ) {
			pp = *plptr++;
			fspr = fp->spread*pp->wscale;
			fmax = FSLICES - fspr;
			if (ftick < fspr) {
			    pstart = 0;
			    pend = (ftick + fspr - 1)/FPP;
			    /* the divide truncates downward to the
			       preceeding peak except in the case where
			       we are actually right on a point divisible
			       by FPP. subtracting 1 insures that we
			       will always be at the last tick that counts*/
			}
			else {
			    if (ftick > fmax) pend = PSLICES - 1; 
			    else pend = (ftick + fspr -1)/FPP;
			    pstart = (ftick - fspr)/FPP + 1;
			    /* the divide truncates downward to the preceeding
			       tick, or if no remainder to the tick at the 
			       disappearing edge of the window -- adding 1
			       makes certain that we are inside the window */
			}
			winstart = fspr - (ftick - FPP*pstart);
			pendptr = &pp->nex[pend];
			//printf("%.3f <= feature[%.2d], phon %c\n",pp->feature[pfetind],pfetind,pp->sound);
			t = pp->feature[pfetind]*(*fpexptr);
			c = pfetind/NFVALS;
			for (pnexptr = &pp->nex[pstart],
			     wtptr = &pp->fpw[c][winstart];
				 pnexptr <= pendptr;
			     wtptr += 3 ) {
				 //printf("fpw[%.2d]",c);
			     //printf("[%.2d]",winstart);
			     //printf("=%.3f ,",*wtptr);
				 //printf(",  fet=%.2d,  fslice=%.2d,  pslice=%.2d,  t=%.4f\n",pfetind,ftick,pnexptr,t);
			    //printf("%.7f | phoneme[%c][%.2d] <= feature[%.2d][%.2d] = %.7f, fpw[%.2d][%.2d]\n",(*wtptr*t),pp->sound,(pstart++),pfetind,ftick,*fpexptr,c,winstart);
				*pnexptr++ += *wtptr*t;
				winstart+=3; //ted added this for the print out
			}
	}   }   }   }
}

pfinteract() 
{
	register float *fnexptr, *wtptr;
	register float *pfexptr, *pfetptr;
	register float *fendptr;
	register int ppeak, fpeak;
	FEATURE *fp;
	PHONEME *pp;
	int fspr,fend,fbegin,c;
	int winstart;
	float pfextot, pfexsum;
	float t;


	for (pp = phoneme; pp < phoneme + 15; pp++) {
	    pfextot = pp->fextot;
	    for (pfexsum = 0, ppeak=0, pfexptr=pp->fex; pfexsum < pfextot;
		 ppeak++, pfexsum += *pfexptr++) {
		fpeak = ppeak*FPP;
		if (*pfexptr) {
		  for (c = 0; c < NCONTINS; c++) {
		    for (pfetptr = &pp->feature[c*NFVALS], fp = &feature[c][0];
		         fp < &feature[c][0] + NFVALS; fp++,pfetptr++ ) {
		    if (*pfetptr) {
			fspr = fp->spread*pp->wscale;
			fbegin = 1+fpeak-fspr;
			if (fbegin < 0) {
			    winstart = 1 - fbegin;
			    fbegin = 0;
			    fend = fpeak+fspr;
			}
			else {
			    if ( (fend = fpeak + fspr) > FSLICES-1) {
				fend = FSLICES-1;
			    }
			    winstart = 1;
			}
			fendptr = &fp->nex[fend];
			t = (*pfexptr)*(*pfetptr);
			for (wtptr = &pp->pfw[c][winstart],
			     fnexptr= &fp->nex[fbegin];
			     fnexptr < fendptr;) {
			       *fnexptr++ += (*wtptr++)*t;
			}
	} } } } }   }
}

wwinteract()
{
	register float *iptr, *sumptr, *wnexptr, *wwexptr;
	register int wstart; 
	WORD *wp, **wptr;
	int wmin, wmax;
	float *wmaxptr;
	
	//wisum= sum of t^2 for all , from prev cycle, 
	//wex=t^2*Ga[w] from prev cycle
	for (iptr = wwi, sumptr = wisum; iptr < wwi + PSLICES; ) {
	    if (*sumptr > imax) *sumptr = imax; //imax=3.
	    *iptr++ = ga[W]*(*sumptr++);
	}

	global_lex_comp = 0; // added jsm 2018.06.09
	for ALLWORDPTRS {
	    wp = *wptr;
	    for (wstart = 0, wnexptr = wp->nex, wwexptr = wp->wex;
	         wstart < PSLICES; 
		 wstart++, wnexptr++, wwexptr++) {
	        wmin = wstart + wp->start;
	        if (wmin < 0) wmin = 0;
	        wmax = wstart + wp->end;
	        if (wmax > PSLICES-1) wmax = PSLICES-1;
	        wmaxptr = &wwi[wmax];
	        for (iptr = &wwi[wmin]; iptr < wmaxptr; ) {
		  global_lex_comp += *iptr;
		    *wnexptr -= *iptr++;  //nex 
	        }
	        if (*wwexptr) {
		    *wnexptr += (wmax - wmin)*(*wwexptr); //filters self inhibition
		    global_lex_comp  -= (wmax-wmin)*(*wwexptr);  //filters self inhibition (?)
	        }
	    }
	}
}

pwinteract() 
{
	register float *pwexptr, *wnexptr, *wtptr;
	WORD *wp, **wptr;
	PHONEME *pp;
	register int wpeak,pslice;
	int pdur,winstart,wmin, wmax;
	int *ofstptr;
	float *wmaxptr;
	float pwextot, pwexsum;
	float t;
	global_pw_sum = 0;
	for (pp = phoneme; pp < phoneme + 15; pp++) {
	    pwextot = pp->wextot;
	    pdur = pp->pdur;
	    for (pwexsum = 0, pslice = 0, pwexptr = pp->wex;
		 pwexsum < pwextot; pwexsum += *pwexptr++, pslice++) {
		if (*pwexptr) {
		  for (wptr = pp->wordlist, ofstptr = pp->ofstlist; *wptr; ) {
		    wp = *wptr++;
		    wpeak = pslice - *ofstptr++;
		    if (wpeak < -pdur) continue;
		    if ( (wmin = 1 + wpeak - pdur) < 0) {
			winstart = 1 - wmin;
			wmin = 0;
			wmax = wpeak + pdur;
		    }	
		    else {
			if ( (wmax = wpeak + pdur) > PSLICES-1) {
			    wmax = PSLICES-1;
			}
			winstart = 1;
		    }
			//printf("%.1d  ", winstart);
		    wmaxptr = &wp->nex[wmax];
		    t = wp->scale*(*pwexptr); //scale=2, pwexptr=ex*Alpha[PW]
		    for ( wnexptr = &wp->nex[wmin],
			  wtptr = &pp->pww[winstart];
			  wnexptr < wmaxptr;) {
		      global_pw_sum += *wtptr * t; 
			    *wnexptr++ += *wtptr++*t; //key p->w update									
	} } } } }
}

wpinteract()
{
	register float *pnexptr, *wpexptr, *wtptr;
	WORD *wp, **wptr;
	PHONEME *pp;
	register int wstart, wslot; 
	register char *t_c_p;
	register int *t_o_p;
	int pdur,pwin,pmin, pmax;
	float *pmaxptr;
	float wpextot, wpexsum;

	global_wp_sum = 0;
	for ALLWORDPTRS {
	    wp = *wptr;
	    wpextot = wp->pextot;
	    for (wpexsum = 0, wstart = 0, wpexptr = wp->pex;
		 wpexsum < wpextot; wstart++, wpexsum += *wpexptr++) {
	      if (*wpexptr) {
		for (t_c_p = wp->sound, t_o_p = wp->offset; *t_c_p;) {
		    wslot = wstart+*t_o_p++;
		    pp = phonptr[*t_c_p++];
		    pdur = pp->pdur;
		    pmin = 1 + wslot - pdur;
		    if (pmin >= PSLICES) break;
		    if (pmin < 0) {
			pwin = 1 - pmin;
			pmin = 0;
			pmax = wslot + pdur;
			pmaxptr = &pp->nex[pmax];
		    }
		    else {
			if ( (pmax = wslot + pdur) > PSLICES-1) {
			    pmax = PSLICES-1;
			}
			pwin = 1;
			pmaxptr = &pp->nex[pmax];
		    }
		    for ( pnexptr = &pp->nex[pmin],
			  wtptr = &pp->wpw[pwin];
			  pnexptr < pmaxptr;) {
		      global_wp_sum += *wtptr * *wpexptr; 
			    *pnexptr++ += (*wtptr++)*(*wpexptr);
		    }
    }   }    }  }
}

fupdate()
{
	register float *exptr, *nexptr, *pexptr, *fexptr;
	register float *sumptr;
	register int *cntptr;
	FEATURE *fp;
	int c,f, tick;
	double grcheck, grtrans;
	float t, tt, ttrans;
	float *fpextotptr;

	//clear these values.
	for (sumptr = fsum[0], cntptr = fcount[0];
	     sumptr < fsum[0] + NCONTINS*FSLICES;) {
		*sumptr++ = *cntptr++ = 0;
	}

	for (c = 0; c < NCONTINS; c++)
	    for (f = 0; f < NFVALS; f++) {
		fp = &feature[c][f]; //iterate over all feature values
		fpextotptr = &fp->pextot; //total phone activation potential
		*fpextotptr = 0;
		for (sumptr = fsum[c], cntptr = fcount[c], exptr = fp->ex,
		     nexptr = fp->nex, pexptr = fp->pex, fexptr = fp->fex, tick = 0; 
		     sumptr < fsum[c] + FSLICES; tick++) {
		    t = *exptr;
		    if ( *nexptr > 0) {
		        t += (max - t)*(*nexptr);
		    }
		    else if (*nexptr < 0) {
		        t += (t - min)*(*nexptr);
		    }
			if ( (tt = *exptr - rest[F]) ) {
			t -= decay[F]*tt;
		    }
			//if t>0, then ...
		    if (t > 0) { 
			    if (t > max) t = max;
			    //printf("fsum[%.2d][%.2d] <- %f (%.2d, %.2d)\n ", c, tick, t, c, f);			
			    *sumptr++ += t; //relates to inhibition 
				*cntptr++ += 1; //this value does not seem to be used
			    *fpextotptr += *pexptr++ = t*alpha[FP]; //phoneme excitation potential
			    *fexptr++ = t*ga[F]; //inhibition potential
		    }
		    else { //(t<=0)
			    if (t < min) t = min;
			    *pexptr++ = 0; //no phoneme activation
			    *fexptr++ = 0; //no inhibition
			    cntptr++; sumptr++;
		    }
		    /* --- ORIGINAL */
		     *exptr++ = t; //here is the actual value update
		     /* --- END ORIGINAL     */
		    //grtrans = 
		    //ttrans = t + (float) gaussrand(gaussSD);
		    //*exptr++ = ttrans; //here is the actual value update
		    *nexptr++ = 0; //reset the next value field 
	    }
	}
}

pupdate() 
{
	register float *exptr, *nexptr, *fexptr, *pexptr, *wexptr;
	register float *sumptr, *isumptr;
	register int *countptr;
	register int ppeak;
	PHONEME *pp;
	int halfdur;
	int pmin, pmax;
	float *pmaxptr;
	float *pfextotptr;
	float *pwextotptr;
	float t,tt,ttrans;

	for (sumptr = psum, isumptr = pisum, countptr = pcount;
		sumptr < psum + PSLICES;) {
	    *sumptr++ = *isumptr++ = *countptr = 0;
	}

	for (pp = phoneme; pp < phoneme + 15; pp++) {
		halfdur = (pp->pdur)/2;
		pfextotptr = &pp->fextot;
		pwextotptr = &pp->wextot;
		*pfextotptr = 0;
		*pwextotptr = 0;
		for (ppeak = 0,
		     exptr = pp->ex, nexptr = pp->nex, fexptr = pp->fex,
		     pexptr = pp->pex, wexptr = pp->wex, sumptr = psum,
		     countptr = pcount;
		     ppeak < PSLICES; ppeak++) {
			t = *exptr;
			if (*nexptr > 0) {
			    t += (max - t)*(*nexptr);
			}
			else if (*nexptr < 0) {
			    t += (t - min)*(*nexptr);
			}
			if ( (tt = *exptr - rest[P]) ) {
			    t -= decay[P]*tt;
			}
			if (t > 0) {
			    if (t > max) t = max;
			    *pwextotptr += *wexptr++ = alpha[PW]*(t);
			    *pexptr++ = ga[P]*(t);
			    *pfextotptr += *fexptr++ = alpha[PF]*(t);
			    *sumptr++ += t;
			    *countptr++ += 1;
			    if (ppeak < halfdur) pmin = 0;
			    else pmin = ppeak - halfdur;
			    pmax = ppeak+halfdur;
			    if (pmax > PSLICES-1) pmax = PSLICES-1;
			    pmaxptr = &pisum[pmax];
			    for (isumptr = &pisum[pmin]; isumptr<pmaxptr;) {
				*isumptr++ += t;
			    }
			}
			else {
				if (t < min) t = min;
				*wexptr++ = *pexptr++ = *fexptr++ = 0;
				sumptr++; countptr++;
			}
			//		    ttrans = t + (float) gaussrand(gaussSD);
			//		    *exptr++ = ttrans; //here is the actual value update
			//			*exptr++ = t + gaussrand() * gaussSD; //here is the actual value update
			*exptr++ = t;
			*nexptr++ = 0;
		}
	}
}

wupdate() 
{
	register float *exptr, *nexptr, *pexptr, *wexptr;
	register float *sumptr, *isumptr;
	register int *countptr;
	register int wstart;
	WORD *wp, **wptr;
	int wmin, wmax;
	float *wpextotptr;
	float *wmaxptr;
	float t, tt, ttrans;

	for (sumptr = wsum, isumptr = wisum, countptr = wcount;
		sumptr < wsum + PSLICES; ) {
	    *sumptr++ = *isumptr++ = *countptr++ = 0;
	}

	for ALLWORDPTRS {
	    wp = *wptr;
	    wpextotptr = &wp->pextot;
	    *wpextotptr = 0;
	    for (wstart = 0,
		 exptr = wp->ex, nexptr = wp->nex, pexptr = wp->pex,
		 wexptr = wp->wex, sumptr = wsum, countptr = wcount; 
		 wstart < PSLICES; wstart++) {
		t = *exptr;
		if ( *nexptr > 0) {
		    t +=  (max - t)*(*nexptr);
		}
		else if (*nexptr < 0) {
		    t +=  (t - min)*(*nexptr);
		}
		if ( (tt = *exptr - wp->rest) ) {
		    t -= decay[W]*tt;
		}
		if (t > 0) {
		    if (t > max) t = max;
		    *wpextotptr += *pexptr++ = t*alpha[WP];
		    tt = t * t;
		    *wexptr++ = tt*ga[W];
		    *countptr++ += 1;
		    *sumptr++ += t;
		    wmin = nonneg(wstart + wp->start);
		    wmax = wp->end + wstart;
		    if (wmax > PSLICES-1) wmax = PSLICES-1;
		    wmaxptr = &wisum[wmax];
		    for (isumptr = &wisum[wmin]; isumptr < wmaxptr;) {
			*isumptr++ += tt;
		    }
		}
		else {
		    if (t < min) t = min;
		    *wexptr++ = *pexptr++ = 0;
		    countptr++;  sumptr++;
		}
		//ttrans = t + (float) gaussrand(gaussSD);
		//*exptr++ = ttrans; //here is the actual value update
		//		*exptr++ = t + gaussrand() * gaussSD; //here is the actual value update
		*exptr++ = t;
		*nexptr++ = 0;
	}
    }
}
