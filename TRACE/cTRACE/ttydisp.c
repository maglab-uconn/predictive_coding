# include "curses.h"
# include "stdio.h"
# define NWORDS 200
# define PSLICES 23

# define CLINE 23
# define STREAMLINE CLINE-1
# define NUMLINE CLINE-2
struct word {
	char sound[20];
	int act [PSLICES];
	int mloc, max;
} word [NWORDS];

struct word *wpord[NWORDS];

char line[BUFSIZ];

struct trial {
	char words[30];
	char stream[30];
	int cycle;
	int min, max;
} trial;

FILE *input;

int nwords;

int index;
char num[5];
int thresh = 10;

main(argc,argv) int argc; char **argv; {
	int c; char dword[30];

	if ((input = fopen(argv[1],"r") ) == NULL)  {
		exit();
	}
	initscr();
	raw();
	clear();
	mvprintw(CLINE,0,": ");
	refresh();
	while (c = getchar()) {
	    switch(c) {
		case 'w':
			getstring(dword);
			find(dword);
			getdata();
			break;
		case 'n':
			nextword();
			getdata();
			break;
		case 'r':
			rewind();
			getdata();
			break;
		case 'd':
		case '.':
			display();
			break;
		case 'q':
			endwin();
			noraw();
			exit();
		case '0':
		case '1':
		case '2':
		case '3':
		case '4':
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			num[index++] = c;
			break;
		case 't':
			value(&thresh);
			break;
	    }
	    mvprintw(CLINE,0,": ");
	    clrtoeol();
	    refresh();
	}
}

rewind() {
    fseek(0,0,input);
    nextword();
}

find(wrd) char *wrd; {
    char junk[15], tword[30];
    while (nextword() != EOF) {
	sscanf(line,"%s %s",junk,tword);
	if (strcmp(wrd,tword)  == 0) {
	    return(1);
	}
    }
    return(EOF);
}

nextword() {
    char tword[15];
    while (fgets(line,BUFSIZ,input) != NULL) {
	sscanf(line,"%s",tword) ;
	if (strcmp(tword,"words:") == 0){
	    return(1);
	}
    }
    return(EOF);
}
		
getstring(str) char *str; {
    char c;
    putchar(' ');
    while ( ( c = getchar()) != ' ' && c != '\n') {
	*str++ = c;
    }
    *str = '\0';
}	

value(var) int *var; {
    char vstr[20];
    int i;
    if (num[0] != '?')  {
	sscanf(num,"%d",&var);
    }
    sprintf(vstr,"= %d.",*var);
    for (; i < index; i++) {
	num[i] = '\0';
    }
    index = 0;
}



wordorder(p1, p2) struct word **p1, **p2; {
	register int i;
	int diff;
	struct word *wp1, *wp2;
	wp1 = *p1;
	wp2 = *p2;
	diff = wp2->max - wp1->max;
	if (diff > 0) return (1);
	if (diff < 0) return (-1);
	else return (0);
}

display()
{
    struct word **wptr,*wp;
    clear();
    qsort(wpord,nwords,sizeof(struct word *),wordorder);
    mvprintw(NUMLINE,0,
"    12    18    24    30    36    42    48    54    60    66    72    78    84"
	);
    for (wptr = wpord; wptr < wpord + nwords; wptr++) {
	    wp = *wptr;
	    if (wp->max < thresh) break;
	    showword(wp);
    }
    showlabel();
    refresh();
}

mkdstr (wp,dstr) char *wp; char *dstr; {
    char *dsp, *sp;

    sp = wp;
    dsp = dstr;
    *dsp++ = '<';
    *dsp++ = ' ';
    while(*sp) {
	if (*sp == '.') {
		dsp -= 3;
		*dsp++ = '>'; *dsp++ = '<'; *dsp++ = ' ';
		*sp++;
		continue;
	}
	*dsp++ = *sp++;
	*dsp++ = ' '; *dsp++ = ' ';
	*dsp++ = ' '; *dsp++ = ' ';*dsp++ = ' ';
    }
    dsp -= 3;
    *dsp++ = '>';
    *dsp = '\0';
}

showword(wp) struct word *wp; {
    int x,y,overflow,dlen;
    char dstr[100];
    mkdstr(wp->sound,dstr);
    dlen = strlen(dstr);

    y = sety(wp->max);
    x = 3*wp->mloc;
    if ( (overflow = (x + dlen -80)) > 0) {
	dstr[dlen-overflow] = '\0';
    }
    mvprintw(y,x,"%s",dstr);
}

showlabel() {
	int dlen, overflow;
	char *sp;
	char dstr[100];
	mkdstr(trial.stream,dstr);
	dlen = strlen(dstr);
	if ( (overflow = (3 + dlen -80)) > 0) {
	    dstr[dlen-overflow] = '\0';
	}
	mvprintw(STREAMLINE,3,"%s",dstr);
}


sety(val) int val;  {
    float vmin;
    int y;
    vmin = 60.0;
    for (y = 0; y <= 20; y++) {
	if (val >= vmin)  return(y);
	vmin -= 2.5;
    }
    return(20);
}

	

getdata() {
    int i,cy,j,val;
    char junk[30]; char tnum[5];
    char *np;

    sscanf(line,"%s %s %s %s %s %s",junk,trial.words,junk,junk,junk,
	trial.stream);
    fgets(line,BUFSIZ,input);
    sscanf(line,"%s %d",junk,&i);
    trial.cycle = i;
    fgets(line,BUFSIZ,input);
    trial.min = atoi(line);
    trial.max = trial.min + (3*(PSLICES-1));
    nwords = 0;
    while (fgets(line,BUFSIZ,input) != NULL) {
	if (line[0] == '-') return(1);
	sscanf(line,"%s",word[nwords].sound);
	word[nwords].max = word[nwords].mloc = 0;
	for (cy = 0; cy < PSLICES; cy++) {
	    for (j = 0; j < 3; j++) {
		tnum[j] = line[10+(3*cy)+j];
	    }
	    tnum[3] = '\0';
	    val = 0;
	    sscanf(tnum,"%d",&val);
	    word[nwords].act[cy] = val;
	    if (word[nwords].act[cy] > word[nwords].max) {
		word[nwords].max = word[nwords].act[cy];
		word[nwords].mloc = cy;
	    }
	}
	wpord[nwords++] = &word[nwords];
    }
    return(EOF);
}

