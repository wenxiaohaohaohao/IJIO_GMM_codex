
new;
library pgraph;
start=hsec;

input="data\\data";


mt=17;

{tints,iobs}=countt(input);
n=rows(tints);
open f=^input;

t=mt;
v=zeros(t,colsf(f));

@-----------------------------------------------------@

output file=descrip.out on;

sector=1;

mtype=0;     @0=unconditional avg.; 1=conditional avg.@

plotting=0;  @1=plotting variables@
let vp=1 2;  @position of variables to plot@

dist=0;      @1=depicts distrib. selected var@
selvar=1;    

@-----------------------------------------------------@

goto below;

vars:
@-----------------------------------------------------@

q=dif(3,0)-dif(69,0);
k=dif(46,0);
l=dif(61,0);
m=dif(62,0)-dif(74,0);
p=dif(69,0);
pm=dif(74,0);
w=dif(72,0);

pinv=exp(lev(67,0));pinv1=exp(lev(67,1));
r=lev(71,0);r1=lev(71,1);
d=lev(49,0);
infr=dif(66,0);infr1=infr[1]|infr[1:t-2];
pk=pinv.*(r+d-infr);pk1=pinv1.*(r1+d-infr1);
pk=ln(pk)-ln(pk1);

x=q~k~l~m~p~(m-l)~(pm-w)~(m-k)~(pm-pk);
namex="out"~"k"~"l"~"m"~"p"~"m-l"~"pm-w"~"m-k"~"pm-pk";

@x=lev(81,0);
namex="md";@

@x=w~pm~pk;
namex="w"~"pm"~"pk";@

@x=(lev(88,0).>0)~(lev(64,0).>0)~(lev(50,0)./=0);
namex="ST>0"~"SO>0"~"RD>0";@

@x=(lev(50,1)./=0);
namex="RD1>0";@

@x=lev(88,0)~lev(64,0)~((exp(lev(50,1))./exp(lev(3,1))).*(lev(50,1)./=0));
namex="ST"~"SO"~"RD1/R1";@

@-----------------------------------------------------@

return;
below:
gosub vars;

sec={12 13 13, 11 11 11, 9 10 10, 14 14 14, 15 16 16, 17 18 18,
     1 2 3, 4 5 5, 6 19 19, 7 8 8};
s1=sec[sector,1];s2=sec[sector,2];s3=sec[sector,3];

nv=cols(namex);

ns=zeros(nv,1);      @number of stable@
no=zeros(nv,1);      @number of occasional@

sx=zeros(nv,mt);
sx2=zeros(nv,mt);

nobs=zeros(nv,mt);
nstb=zeros(nv,mt);   @obs. of stable@
nocc=zeros(nv,mt);   @obs. of occasional@

svar={};
i=1;j=0;obs=0;    @i=firm read; j=firms processed; obs=observ. processed@
do while i<=rows(tints);
  iob=iobs[i];
  t=tints[i];
  v=readr(f,t);
  

  sec=v[1,4:23]*seqa(1,1,20);
  if sector>0;
  if (sec==s1) or (sec==s2) or (sec==s3);
  else;
       i=i+1;
       continue;
  endif;
  endif;

 gosub vars;

 ind=(x./=0);
 stb=sumc(ind).==rows(ind);
 occ=(sumc(ind).>0).*(sumc(ind).<rows(ind));

 
 ns=ns+stb;
 no=no+occ;

 sx[.,iob+1:iob+t-1]=sx[.,iob+1:iob+t-1]+x';
 sx2[.,iob+1:iob+t-1]=sx2[.,iob+1:iob+t-1]+(x^2)';
 if mtype==0;
 nobs[.,iob+1:iob+t-1]=nobs[.,iob+1:iob+t-1]+ones(nv,t-1);
 else;
 nobs[.,iob+1:iob+t-1]=nobs[.,iob+1:iob+t-1]+ind';
 endif;
 nstb[.,iob+1:iob+t-1]=nstb[.,iob+1:iob+t-1]+ind'.*stb; 
 nocc[.,iob+1:iob+t-1]=nocc[.,iob+1:iob+t-1]+ind'.*occ;

 svar=svar|x[.,selvar]; 

 if j==0;
     minx=minc(x);
     maxx=maxc(x);
 else;
     emin=(minc(x).<minx);
     minx=substute(minx,emin,minc(x));
     emax=(maxc(x).>maxx);
     maxx=substute(maxx,emax,maxc(x));
 endif;
 

i=i+1;
j=j+1;
obs=obs+t-1;

endo;




mx=sx./nobs;
sdx=sqrt((sx2./nobs)-mx^2);
mm=minx'|maxx';
tmx=sumc(sx')./sumc(nobs');
tsdx=sqrt(sumc(sx2')./sumc(nobs')-tmx^2);

res=mx'~sdx';
tres=tmx'~tsdx';


let year=1990 1991 1992 1993 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006;


format /rd 6,0;
print "Sector:";;sector;;
print "   No of firms:";;j;;
print "   No of obs. (t-1 per firm):";;obs;
print;
print "No (and prop.) of stable, occasional (rest is zero):";
print ns'|no';
format /rd 6,3;
print (ns'/j)|(no'/j);
print;
format /rd 6,0;
print "Obs. (and prop.) of stable, occasional (rest is zero):";
print sumc(nstb')'|sumc(nocc')';
format /rd 6,3;
print (sumc(nstb')'/obs)|(sumc(nocc')'/obs);
print;  
let fmt0="*.*lf" 7 0;
let fmt1="*.*lf" 7 7;
let fmt2="*.*lf" 7 3;
print "Year and total averages, min and max";
if mtype==0;
print "(unconditional averages)";
else;
print "(conditional averages)";
endif;
print;
mask=zeros(1,1+rows(mx));
fmt=fmt1'.*.ones(1+rows(mx),1);
call printfm("year"~namex, mask, fmt);
print;
print;
mask=ones(1,1+rows(mx));
fmt=fmt0'|fmt2'.*.ones(rows(mx),1);
call printfm(year~mx', mask, fmt);
print;
mask=0~ones(1,rows(mx));
fmt=fmt1'|fmt2'.*.ones(rows(mx),1);
call printfm("total"~tmx', mask, fmt);
print;
print;
mask=0~ones(1,rows(mx));
fmt=fmt1'|fmt2'.*.ones(rows(mx),1);
call printfm(("min"|"max")~mm, mask, fmt);
print;
print "Year and total standard deviations";
print;
mask=zeros(1,1+rows(mx));
fmt=fmt1'.*.ones(1+rows(mx),1);
call printfm("year"~namex, mask, fmt);
print;
mask=ones(1,1+rows(mx));
fmt=fmt0'|fmt2'.*.ones(rows(mx),1);
call printfm(year~sdx', mask, fmt);
print;
mask=0~ones(1,rows(mx));
fmt=fmt1'|fmt2'.*.ones(rows(mx),1);
call printfm("total"~tsdx', mask, fmt);
print;
print;

if plotting==1;
   sectors=ftos(sector,"%*.*lf",1,0);
   plt="graphs\\s"$+sectors$+".eps";
   cmda=" -po=l"$+" -c=1"$+" -cf="$+plt;
   graphprt(cmda);
   call makewind(8,6,0.5,0.5,1);
   _pltype={6, 1, 3, 4};
   mxs=mx[vp,.]';
   year=year.*.ones(1,cols(mxs));
   xy(year, mxs);
endif;

if dist==1;
   format /rd 8,0;
   print "Variable distribution:";;selvar;
   print;
   format /rd 8,3;
   print "Obs.and mean before ad after trimming 1% at each tail";
   print; 
   print rows(svar)~meanc(svar);
   svar=sortc(svar,1);
   low=svar[round(rows(svar)*0.01)];
   up=svar[round(rows(svar)*0.99)];
   svar=delif(svar, (svar.<low) .or (svar.>up));
   print rows(svar)~meanc(svar);
   print;
   {bk,m,freq}=hist(svar,100);
   print "Breaking points and frequency";
   print;
   print bk~freq;
endif;

proc(2)=countt(file);
local f,tints,v,iobs,t;
open f=^file for read;
  tints={};
  v=readr(f,1);
  iobs=v[.,1]-1990+1;
  t=2;
  call seekr(f,2);
  do until eof(f);
     v=readr(f,1);
     if t<=v[.,2];
     t=t+1;
     else;
     tints=tints|(t-1);
     iobs=iobs|v[.,1]-1990+1;
     t=2;
     endif;
  endo;
  tints=tints|(t-1);
  retp(tints,iobs);
closeall;
endp;


fn lev(c,lag)=v[2-lag:t-lag,c];
fn dif(c,lag)=v[2-lag:t-lag,c]-v[1-lag:t-1-lag,c];

str=etstr(hsec-start);
"Execution time is  ";;print $str;
print;

end;

