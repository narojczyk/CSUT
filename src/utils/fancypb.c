#include <stdio.h>
#include <stdlib.h>
#include <math.h>



int main(int argc, char *argv[])
{
  double ratio=(double) 0;
  int markers = 0, empty = 0, i;
  char mark = (char) 24;

  if( argc != 4 ){
    fprintf(stderr, "[%s] err: worng number of parameters.\n", argv[0]);
    return 1;
  }

  double value_i = atof(argv[1]);
  double value_max = atof(argv[2]);
  int range_max = atoi(argv[3]);

  ratio = value_i/value_max;

  markers = (int) (range_max * ratio);
  empty = range_max - markers;

  fprintf(stdout, "[ ");
  for(i=0; i< markers; i++){
      printf("%c",mark);
  }
  for(i=0; i< empty; i++){
      printf("%s",".");
  }
  fprintf(stdout, " ] %6.2lf%%", ratio * 1e2);


  return 0;
}
