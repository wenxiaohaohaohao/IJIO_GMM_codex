new;
start=hsec;


@-----------------------Program options-----------------------------------------@

output file=ols.out on;

industry=1;

namex="c"~"trend"~"sigma"; 

@------------------------------------------------------------------------------@
@Grouping industries@

secs={12 13 13, 11 11 11, 9 10 10, 14 14 14, 15 16 16, 17 18 18,
     1 2 3, 4 5 5, 6 19 19, 7 8 8};
s1=secs[industry,1];s2=secs[industry,2];s3=secs[industry,3];

@Reading input@

input="data\\data";
open f=^input;
  
@Regression@

clear xx,xy;
call seekr(f,1);
tobs=0;i=0;obs=0;
call seekr(f,1);    
do until eof(f);
call seekr(f,tobs+1);
v=readr(f,1);    
  t=v[1,2];
  iob=v[1,1]-1990+1;
  v=v|readr(f,t-1);

  sec=v[1,4:23]*seqa(1,1,20);
  if (sec==s1) or (sec==s2) or (sec==s3);
     i=i+1;
     obs=obs+t-1;    
  else;
     tobs=tobs+t;
     continue;
  endif;
  
  goto below;
  model:
  
  ct=ones(t-1,1);
  tme=0|seqa(1,1,16);
  tme=tme[iob+1:iob+t-1];
  
  pm=lev(74,0);
  wg=lev(72,0);
  lab=lev(61,0);
  mat=lev(62,0)-pm;
    
  y=(mat-lab);
  x=ct~tme~(pm-wg);

  return;
  below:
  gosub model;

  xx=xx+x'x;
  xy=xy+x'y;

tobs=tobs+t;
endo;

b=invpd(xx)*xy;

@Computing robust standard covariances@
clear xeex;
call seekr(f,1);
tobs=0;i=0;obs=0;
call seekr(f,1);    
do until eof(f);
call seekr(f,tobs+1);
v=readr(f,1);    
  t=v[1,2];
  iob=v[1,1]-1990+1;
  v=v|readr(f,t-1);
    
  sec=v[1,4:23]*seqa(1,1,20);
  if (sec==s1) or (sec==s2) or (sec==s3);
     i=i+1;
     obs=obs+t-1;    
  else;
     tobs=tobs+t;
     continue;
  endif;
  
  gosub model;
  e=y-x*b;  
  xeex=xeex+x'e*e'x;
  
tobs=tobs+t;
endo;

vcov=invpd(xx)*xeex*invpd(xx);

@Printing results@

printing:
format /rd 12,0;
print "Industry:";;industry;
print;
print "No. of firms:";;i;
print;
print "No. of observations:";;obs;
print;

let fmt1="*.*lf" 8 8;
let fmt2="*.*lf" 8 3;
res=b~sqrt(diag(vcov));

mask=0~ones(1,2);
fmt=fmt1'|(fmt2'.*.ones(2,1));
call printfm(namex'~res, mask, fmt);
print;

fn lev(c,lag)=v[2-lag:t-lag,c];
end;
