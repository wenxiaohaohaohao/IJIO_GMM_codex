new;
library optmum;
optset;
start=hsec;

@----------------Program options----------------------------------------@

output file=gmmest.out on;

sector=1;

optimal=0;        @0=first stage; 1=second stage@

keep=0;           @1=keeps coeffs. and vars.@
keepg=1;          @1=keeps function@

@-----------------------------------------------------------------------@
sec={1 4 4, 2 2 2, 3 17 17, 5 5 5, 5 5 5, 8 9 9,
     10 11 12, 13 14 14, 15 15 15, 16 16 16};
s1=sec[sector,1];s2=sec[sector,2];s3=sec[sector,3];
declare t,v,d,zw,zy,ze,a,zeez,izeez,i,obs,ft;

@Defining outputs@

sectors=ftos(sector,"%*.*lf",1,0);
mtx="matrices\\zeez"$+sectors;
cffs="c"$+sectors;
cvars="v"$+sectors;
func="function\\g"$+sectors;

@Naming nonlinear and concentrated out parameters@

   nlpms="k"~"l"~"m"
      ~"p"~"p2"~"p3"~"z"~"z2"~"z3"~"p*z"~"p2*z"~"p*z2";
   copms="ct"~"h0"~"h02"~"h03"
      ~"R>0"~"h11"~"h12"~"h13"~"r"~"r2"~"r3"~"h1*r"~"h12*r"~"h1*r2";
   namex=nlpms~copms;
if (sector==2) or (sector==3) or (sector==6) or (sector==8) or (sector==10);
   namex=nlpms~"bt"~copms;
elseif (sector==1) or (sector==7);
   namex=nlpms~"bt2"~"bt3"~"bt4"~"bt5"~"bt6"~"bt7"~"bt8"~"bt9"~copms;
endif;

@Setting starting values@

gosub stvalues;
   startv=startv[.,sector];
   startvt=startvt[sector];
   startvd=startvd[.,sector];
if (sector==2) or (sector==3) or (sector==6) or (sector==8) or (sector==10);
   startv=startv|startvt;
elseif (sector==1) or (sector==7);
   startv=startv|startvd;
endif;

@Reading inputs@

input="data/data";
{tints,iobs}=countt(input);
n=rows(tints);
open f=^input;
if optimal==1;
   open h=^mtx;
   aopt=inv(readr(h,rowsf(h)));
endif;

@Calling the optimization routine@

_oprteps=0;
__output=1;
_opalgr=2;
_opgtol=0.001;
_opmiter=1000;
__output=2;
{b,fc,g,retcode}=optmum(&fv,startv);
proc fv(x);
   {d,fc,zw,ze,a,zeez}=compute(x);
retp(fc);
endp;

@Computing standard errors@

print "Computing standard errors...";
print;
g=gradp(&mm,b);
jd=gradp(&md,b);
proc mm(x);
   {d,fc,zw,ze,a,zeez}=compute(x);
retp(ze);
endp;
proc md(x);
   {d,fc,zw,ze,a,zeez}=compute(x);
retp(d);
endp;
g=(g+zw*jd)~zw;
if optimal==0;
   vb=inv(g'a*g)*g'a*zeez*a*g*inv(g'a*g);
else;
   vb=inv(g'aopt*g);
   df=rows(aopt)-rows(vb);
endif;
sb=sqrt(diag(vb));

@Printing@

format /rd 12,0;
print "Sector:";;sector;
print;
print "code(normal=0):";;retcode;
format /rd 12,3;
print "Function value:";;fc;
print;
if optimal==1;
format /rd 6,0;
print "(second step) df:";df;
print;
format /rd 6,3;
print "Prob. value:";;cdfchic(fc,rows(a)-rows(b|d));
print;
endif;
format /rd 6,0;
print "No. of firms:";;i;
print;
print "No. of observations:";;obs;
print;
let fmt1="*.*lf" 8 8;
let fmt2="*.*lf" 8 3;
res=(b|d)~sb;
mask=0~ones(1,2);
fmt=fmt1'|(fmt2'.*.ones(2,1));
call printfm(namex'~res, mask, fmt);
print;

@Saving outputs@

if keep==1;
   call saved(b|d,cffs,0);
   call saved(vb,cvars,0);
endif;
   if keepg==1;
call saved(ft,func,0);
endif;

@Procedure specifying equations and moments and computing the objective@
proc(6)= compute(b);
local xx,xy,zw,zz,zy,ww,j,iob,sec,y,ct,k,l,m,k1,l1,m1,w1,p1,pm1,d1,rind,r,
eta,arg,veca,larg,hl,trend,trend1,dtm,dtm1,mt,tm,g0,g1,w,z,ze,zeez,e,fg,sz,mns;

@First loop: defining model, computing the concentrated parameters@

clear xx,xy,zw,zz,zy,ww;
call seekr(f,1);
j=1;i=0;obs=0;
do while j<=rows(tints);
  t=tints[j];
  iob=iobs[j];
  v=readr(f,t);

  @selecting sector@

  sec=v[1,4:21]*seqa(1,1,18);
  if (sec==s1) or (sec==s2) or (sec==s3);
     i=i+1;
  else;
     j=j+1;
     continue;
  endif;
  
  goto below;
  model:

  @variables@

  y=lev(3,0);
  ct=ones(rows(y),1);
  k=lev(40,0);
  l=lev(43,0);
  m=lev(44,0);
  k1=lev(40,1);
  l1=lev(43,1);
  m1=lev(44,1);
  w1=lev(48,1);
  p1=lev(45,1);
  pm1=lev(49,1);
  d1=lev(55,1);
  rind=(lev(36,1)./=0);
  r=lev(36,1)/10;

  @h function@

  eta=1+exp(pol2(p1,d1)*b[4:12]);
  arg=1-(1/eta);
  veca=0.01*ones(rows(arg),1);
  larg=ln(maxc((arg~veca)'))+(arg.<=veca).*((arg./veca)-1);
  hl=(1-b[2]-b[3])*l1-b[1]*k1+(1-b[3])*(w1-p1)+b[3]*(pm1-p1)-larg;

  @time trend and dummies@

  trend=seqa(iobs[j]+1,1,rows(y));
  trend1=trend-1;
  mt=eye(10);mt[1,1]=0;mt[2,2]=0;
  dtm=mt[iob+1:iob+t-1,3:cols(mt)];
  dtm1=mt[iob:iob+t-2,3:cols(mt)];
  tm=trend;
  if (sector==2) or (sector==3)
  or (sector==6) or (sector==8) or (sector==10);
     hl=-b[13]*trend1+hl;
  elseif (sector==1) or (sector==7);
     hl=-dtm1*b[13:20]+hl;
  tm=dtm;
  endif;

  @esimating equation@

  g0=(1-rind).*(hl~(hl^2)~(hl^3));

  g1=rind.*(rind~hl~(hl^2)~(hl^3)~r~(r^2)~(r^3)
     ~(hl.*r)~(hl.*(r^2))~((hl^2).*r));

  y=y-(k~l~m)*b[1:3];
  if (sector==2) or (sector==3)
  or (sector==6) or (sector==8) or (sector==10);
     y=y-b[13]*trend;
  elseif (sector==1) or (sector==7);
     y=y-dtm*b[13:20];
  endif;

  w=ct~g0~g1;

  @instruments@

  z=ct~tm~k~m1~rind~pol2(p1,d1)~pol4(k1,l1,w1-p1,pm1-p1)~pol1(r)
    ~interact(r,k1,l1,w1-p1,pm1-p1,p1,d1);

  if (sector==4);
     z=z~rind.*lev(40,0);
  elseif (sector==2) or (sector==3) or (sector==6);
     z=z~(rind.*(k1~l1~m1~(w1-p1)~(pm1-p1)));
  elseif sector==7;
     z=z~((trend-1).*(k1~l1~(w1-p1)~(pm1-p1)));
  elseif (sector==1) or (sector==8);
     z=z~(rind.*(k1~l1~m1~(w1-p1)~(pm1-p1)))
       ~((trend-1).*(k1~l1~(w1-p1)~(pm1-p1)));
  endif;

  return;
  below:
  gosub model;

  ww=ww+w'w;
  zw=zw+z'w;
  zz=zz+z'z;
  zy=zy+z'y;

j=j+1;
endo;

@computing the concentrated parameters@

  a=invpd(zz);
  if optimal==0;
     d=invpd(zw'a*zw)*zw'a*zy;
  else;
     d=invpd(zw'aopt*zw)*zw'aopt*zy;
  endif;

@Second loop: computing moments and outputs@

clear ze,zw,zeez;
call seekr(f,1);
j=1;i=0;obs=0;ft={};
do while j<=rows(tints);
   t=tints[j];
   iob=iobs[j];
   v=readr(f,t);

   @selecting sector@

   sec=v[1,4:21]*seqa(1,1,18);
   if (sec==s1) or (sec==s2) or (sec==s3);
      i=i+1;
   else;
      j=j+1;
      continue;
   endif;

   gosub model;
   e=y-w*d;
   ze=ze+z'e;
   zw=zw+z'w;
   zeez=zeez+z'e*e'*z;

   fg=w[.,2:cols(w)]*d[2:rows(d)];
   sz=lev(23,1);sz=sz[1]*ones(rows(y),1);
   mns=zeros(rows(y),3);
   if ((sumc(rind)==0) or (sumc(rind)==rows(rind)));
     mns[1,.]=meanc(fg~hl~r)';
   else;
     mns[1,.]=sumc(rind.*(fg~hl~r))'/sumc(rind);
   endif;
   ft=ft|(fg~hl~r~sz~mns);

obs=obs+rows(y);
j=j+1;
endo;

if optimal==0;
   call saved(zeez,mtx,0);
endif;

@Computing the objective@

if optimal==0;
   fc=ze'a*ze;
else;
   fc=ze'aopt*ze;
endif;

retp(d,fc,zw,ze,a,zeez);
endp;
@Other procedures@

proc(1)=pol1(u);
local pol;
pol=u~(u^2)~(u^3);
retp(pol);
endp;

proc(1)=pol2(u1,u2);
local pol;
pol=u1~(u1^2)~(u1^3)~u2~(u2^2)~(u2^3)~(u1.*u2)~((u1^2).*u2)~(u1.*(u2^2));
retp(pol);
endp;

proc(1)=pol4(v1,v2,v3,v4);
local pol;
pol=v1~v2~v3~v4~(v1^2)~(v2^2)~(v3^2)~(v4^2)
    ~(v1.*v2)~(v1.*v3)~(v1.*v4)~(v2.*v3)~(v2.*v4)~(v3.*v4)
    ~(v1^3)~(v2^3)~(v3^3)~(v4^3)
    ~((v1^2).*v2)~((v1^2).*v3)~((v1^2).*v4)~(v1.*(v2^2))~((v2^2).*v3)
    ~((v2^2).*v4)~(v1.*(v3^2))~(v2.*(v3^2))~((v3^2).*v4)~(v1.*(v4^2))
    ~(v2.*(v4^2))~(v3.*(v4^2))~(v1.*v2.*v3)~(v1.*v2.*v4)~(v1.*v3.*v4)
    ~(v2.*v3.*v4);
retp(pol);
endp;

proc(1)=interact(u,v1,v2,v3,v4,v5,v6);
local pol;
pol=(v1.*u)~(v2.*u)~(v3.*u)~(v4.*u)~(v5.*u)~(v6.*u)
    ~(v1.*(u^2))~(v2.*(u^2))~(v3.*(u^2))~(v4.*(u^2))~(v5.*(u^2))~(v6.*(u^2))
    ~((v1^2).*u)~((v2^2).*u)~((v3^2).*u)~((v4^2).*u)~((v5^2).*u)~((v6^2).*u);
retp(pol);
endp;

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

str=etstr(hsec-start);
print;
"Execution time is  ";;print $str;
end;

@Starting values@

stvalues:
if optimal==0;
startv=
(0.115|0.113|0.676|-2.43|-0.31|20.74|0.68|-1.32|0.76|5.59|-8.40|-4.55)~
(0.232|0.136|0.618|-1.91|4.31|-18.52|-1.25|1.51|-0.55|2.84|-12.24|-1.62)~
(0.131|0.137|0.703|-0.31|-1.92|-3.23|0.52|-1.29|0.76|1.04|2.19|-0.70)~
(0.078|0.291|0.637|1.15|-11.82|-53.26|-1.31|3.16|-1.89|-12.11|-9.92|12.47)~
(0.078|0.291|0.637|1.15|-11.82|-53.26|-1.31|3.16|-1.89|-12.11|-9.92|12.47)~
(0.137|0.152|0.652|-2.74|-9.70|1.07|-0.91|1.43|-0.75|10.10|11.00|-7.45)~
(0.100|0.123|0.742|0.05|2.89|1.29|0.18|0.16|-0.23|-0.92|-3.03|1.14)~
(0.047|0.324|0.585|2.10|20.63|51.32|-0.50|-0.82|0.96|1.13|11.65|-3.42)~
(0.122|0.199|0.696|-1.60|-5.94|2.44|-1.12|1.84|-1.01|7.82|7.49|-7.28)~
(0.142|0.237|0.607|-0.70|1.78|4.91|0.49|-2.13|1.50|2.37|2.37|-1.72);
startvt=0|-0.006|0.016|0|0|0.024|0|0.012|0|0.006;
startvd=
(-0.017|-0.049|-0.044|-0.012|-0.014|-0.027|-0.027|-0.013)~zeros(8,5)~
(-0.025|-0.039|-0.079|-0.096|-0.124|-0.139|-0.158|-0.150)~zeros(8,3);
else;
startv=
(0.106|0.111|0.684|-2.27|-0.51|18.42|0.72|-1.37|0.72|3.73|-7.36|-2.76)~
(0.227|0.137|0.633|-1.87|3.55|-16.03|-0.73|0.34|0.15|3.98|-9.98|-2.87)~
(0.132|0.122|0.713|-0.50|-1.91|-0.15|0.47|-1.28|0.77|0.57|1.65|0.03)~
(0.079|0.281|0.642|1.81|-10.62|-77.91|-1.75|4.41|-2.72|-12.37|-14.23|12.81)~
(0.079|0.281|0.642|1.81|-10.62|-77.91|-1.75|4.41|-2.72|-12.37|-14.23|12.81)~
(0.117|0.158|0.675|-3.50|-6.69|4.81|-1.22|2.44|-1.46|11.10|8.97|-7.37)~
(0.068|0.129|0.766|0.02|4.12|2.44|0.49|-0.52|0.13|-0.59|-3.06|0.97)~
(0.057|0.313|0.593|2.54|27.93|73.79|-0.78|0.23|0.18|-3.83|-1.81|1.26)~
(0.131|0.176|0.697|-0.62|-4.87|-4.51|-1.58|2.84|-1.54|3.99|4.63|-3.82)~
(0.121|0.249|0.617|-0.70|1.52|4.06|0.43|-1.87|1.25|3.36|4.56|-2.43);
startvt=0|-0.002|0.014|0|0|0.020|0|0.011|0|0.010;
startvd=
(-0.030|-0.079|-0.071|-0.050|-0.049|-0.059|-0.059|-0.047)~zeros(8,5)~
(-0.018|-0.028|-0.064|-0.086|-0.110|-0.122|-0.136|-0.119)~zeros(8,3);
endif;
return;

