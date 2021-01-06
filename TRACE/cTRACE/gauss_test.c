#include <stdio.h>


main(argc,argv)
int argc;
char **argv;
{
int c,d,n,a, req, rep;


req = 13;
rep = 10;

fprintf(stderr,"\tnullify replaces unwanted characters\n\t with specified characters.\n\n");
fprintf(stderr,"Uses:  nullify < filename > filename2\n");
fprintf(stderr,"       this is the default.  replaces char(13) (backslash r)\n");
fprintf(stderr,"                             with newline (char(10))\n\n");
fprintf(stderr,"       nullify n < filename > filename2\n");
fprintf(stderr,"       replaces char(n) with newline\n\n");
fprintf(stderr,"       nullify n m < filename > filename2\n");
fprintf(stderr,"       replaces char(n) with char(m)\n\n");
fprintf(stderr,"       nullify n 999 < filename > filename2\n");
fprintf(stderr,"       removes char(n), no replacement\n\n");
fprintf(stderr,"%i arguments...\n",argc);

if (argc > 1)
  req = atoi(argv[1]);
if (argc > 2)
  rep = atoi(argv[2]);
c=getchar();
d=n=0;
/*if (req!=999)
  {
    fprintf(stderr,"\nREPLACING: ");
    fputc(req,stderr);
    fprintf("  WITH: ");
    fputc(rep,stderr);
    fprintf(stderr," \n\n");
  }
else
  {
    fprintf(stderr,"\nREMOVING: ");
    fputc(req,stderr);
    fprintf(stderr," \n\n");
  };
*/

do
{
  if ((c=getchar())==req)
    {
      c=rep;
      if (rep != 999)
	putchar(c);
    }
  else
    putchar(c);
}
  while (!feof(stdin));

}




