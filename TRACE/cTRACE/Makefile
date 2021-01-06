DEBUG = -g -p  -Wno-return-type -v 
OPTIMIZE = -O
#CFLAGS = ${OPTIMIZE}
CFLAGS = ${DEBUG}
LFLAGS = -lm
TOBJS = trace.o initialize.o interact.o command.o pwt.o util1.o util2.o util3.o fetvals.o
TSRCS = trace.c initialize.c interact.c command.c pwt.c util1.c util2.c util3.c fetvals.c
VGRIND = csh /usr/ucb/vgrind

trace:	$(TOBJS)
	cc $(CFLAGS) $(TOBJS) $(LFLAGS) -o trace

trace.o:	defs.h trace.c
	cc $(CFLAGS) -c trace.c

initialize.o:	defs.h initialize.c
	cc $(CFLAGS) -c initialize.c

interact.o:	defs.h interact.c
	cc $(CFLAGS) -c interact.c

command.o:	defs.h command.c
	cc $(CFLAGS) -c command.c

fetvals.o:	defs.h fetvals.c
	cc $(CFLAGS) -c fetvals.c

pwt.o:	defs.h pwt.c
	cc $(CFLAGS) -c pwt.c

util1.o:	defs.h util1.c
	cc $(CFLAGS) -c util1.c

util2.o:	defs.h util2.c
	cc $(CFLAGS) -c util2.c

util3.o:	defs.h util3.c
	cc $(CFLAGS) -c util3.c

print:	$(TSRCS)
	pr $(TSRCS)

clean:
	rm *.o trace

vgrind:
	${VGRIND}  ${TSRCS}

tags:
	ctags ${TSRCS} defs.h

