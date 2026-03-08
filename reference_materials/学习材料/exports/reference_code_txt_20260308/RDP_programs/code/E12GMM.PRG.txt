new;
library optmum;
optset;
start=hsec;


@-----------------------Program options-----------------------------------------@

output file=e12gmm.out on;

industry=1;

optimal=0;        @0=first stage; 1=second stage@   


@------------------------------------------------------------------------------@
declare t,v,d,zw,ze,a,zeez,i,obs,zec;

@Names of nonlinear and concentrated out parameters, starting values@

nlpms="sigma"~"tw"~"tw2"~"tw3"~"sb"~"sb2"~"sb3";

copms="ct"~"d92"~"d93"~"d94"~"d95"~"d96"~"d97"~"d98"~"d99"
          ~"d00"~"d01"~"d02"~"d03"~"d04"~"d05"~"d06"
          ~"rho1"~"rho2"~"rho3"
          ~"R>0"~"rho1"~"rho2"~"rho3"~"rho4"~"rho5"~"rho6"
          ~"rho7"~"rho8"~"rho9";

namex=nlpms~copms;
gosub stvalues;
startv=startv[.,industry];

@Grouping industries@

secs={12 13 13, 11 11 11, 9 10 10, 14 14 14, 15 16 16, 17 18 18,
     1 2 3, 4 5 5, 6 19 19, 7 8 8};
s1=secs[industry,1];s2=secs[industry,2];s3=secs[industry,3];

@Reading inputs/defining outputs@

input="data\\data";
open f=^input;

industries=ftos(industry,"%*.*lf",1,0);
mtx="matrices12\\zeez"$+industries;

if optimal==1;
open h=^mtx;
aopt=inv(readr(h,rowsf(h)));
endif;

cffs="cvars12\\c"$+industries;
cvars="cvars12\\v"$+industries;
zes="sdcorr\\ze1"$+industries;
gm="sdcorr\\g1"$+industries;

@Optimization routine@

__output=2;
_opalgr=2;
if optimal==0;
_opgtol=0.0001;
else;
_opgtol=0.001;
endif;    
_opmiter=200;
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
lk=rows(aopt)-rows(vb);
endif;

sb=sqrt(diag(vb));

@Printing results@

printing:
format /rd 12,0;
print "Industry:";;industry;
print;
format /rd 12,3;
print "Function value:";;fc;
format /rd 6,0;
print;
"Retcode:";;retcode;
"No. of iterations:";;_opitdta[1];
print;
if optimal==1;
format /rd 6,0;
print "(second step) df:";;lk;
print;
format /rd 6,3;
pv=cdfchic(fc,rows(a)-rows(b|d));
print "Prob. value:";;pv;
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

output file=e17gmm.out off;

@Saving outputs: coeffients, variances, moments, gradient@

call saved(b|d,cffs,0);
call saved(vb,cvars,0);
call saved(zec,zes,0);
call saved(g,gm,0);

@Procedure specifying equations and moments and computing the objective@

proc(6)= compute(b);
local iob,y,ct,hh,z,e,ze,zz,zy,w,ww,zeez,fc,sigma,
pm,pm1,p,p1,out,out1,lab,lab1,cap,cap1,mat,mat1,wg,wg1,sb,sb1,
dums,md,md1,rind,r1,ninc,smat,smat1,gam,tw,tw1,tobs,sec;

sigma=b[1];
gam=b[2:7];

@First loop: preparing computation of the concentrated out params.@
    
clear zw,zz,zy,ww;
call seekr(f,1);
tobs=0;i=0;obs=0;
call seekr(f,1);    
do until eof(f);
call seekr(f,tobs+1);
v=readr(f,1);    
  t=v[1,2];
  iob=v[1,1]-1990+1;
  v=v|readr(f,t-1);

@Selecting the firms that belong to the industry@    
    
  sec=v[1,4:23]*seqa(1,1,20);
  if (sec==s1) or (sec==s2) or (sec==s3);
     i=i+1;
  else;
     tobs=tobs+t;
     continue;
  endif;
  
  
  goto below;
  model:

@Construction of variables@  
  
  ct=ones(t-1,1);
  dums=lev(28,0)~lev(29,0)~lev(30,0)~lev(31,0)~lev(32,0)~lev(33,0)~lev(34,0)
       ~lev(35,0)~lev(36,0)~lev(37,0)~lev(38,0)~lev(39,0)~lev(40,0)~lev(41,0)
       ~lev(42,0);
  
  p=lev(69,0);
  p1=lev(69,1); 
  pm=lev(74,0);
  pm1=lev(74,1);
  wg=lev(72,0);
  wg1=lev(72,1);

  out=lev(3,0)-p;
  out1=lev(3,1)-p1;
  cap=lev(46,0);
  cap1=lev(46,1);
  lab=lev(61,0);
  lab1=lev(61,1);
  mat=lev(62,0)-pm;
  mat1=lev(62,1)-pm1;
  
  md=lev(81,0);
  md1=lev(81,1);

  if (industry==2) or (industry==3) or (industry==10);
  tw=ln((lev(88,0).==0)+(lev(88,0).>0).*lev(88,0));
  tw1=ln((lev(88,1).==0)+(lev(88,1).>0).*lev(88,1));    
  else;    
  tw=(lev(88,0).<=0.95).*lev(88,0)+(lev(88,0).>0.95)*0.95;
  tw1=(lev(88,1).<=0.95).*lev(88,1)+(lev(88,1).>0.95)*0.95;
  tw=ln((tw.==0)+(tw.>0).*(tw./(1-tw)));
  tw1=ln((tw1.==0)+(tw1.>0).*(tw1./(1-tw1)));
  endif; 
        
  sb=(lev(64,0).<=0.95).*lev(64,0)+(lev(64,0).>0.95)*0.95;
  sb1=(lev(64,1).<=0.95).*lev(64,1)+(lev(64,1).>0.95)*0.95;

  smat=ln((sb.==0)+((sb./=0).*exp(mat)));
  smat1=ln((sb1.==0)+((sb1./=0).*exp(mat1)));

  rind=lev(50,1)./=0;
  r1=lev(50,1);  
  
  @Equation 12 and instruments@

  hh=(mat1-lab1)+sigma*(pm1-wg1)-(pol1(tw1)~pol1(sb1))*gam;

  y=(mat-lab)+sigma*(pm-wg)-(pol1(tw)~pol1(sb))*gam;
 
  w=ct~dums~((1-rind).*pol1(hh))~rind~(rind.*pol2(hh,r1));

  
  z=ct~dums~((1-rind).*pol3(mat1,lab1,(pm1-wg1)))
    ~rind~(rind.*pol4(mat1,lab1,(pm1-wg1),r1))~md~pol1(smat1);

  if (industry==5) or (industry==8);
  z=ct~dums~((1-rind).*pol3(mat1,lab1,pm1))
    ~rind~(rind.*pol4(mat1,lab1,(pm1-wg1),r1))~md~pol1(smat1);
  endif;
  
  return;
  below:
  gosub model;

@Dropping the observations without temporary workers@
  
  ninc=(lev(88,0).==0) .or (lev(88,1).==0);
  y=delif(y,ninc.==1);
  z=delif(z,ninc.==1);
  w=delif(w,ninc.==1);
  if scalmiss(y);
     i=i-1;
     tobs=tobs+t;
     continue;
  endif;
  obs=obs+rows(y); 

  ww=ww+w'w;
  zw=zw+z'w;
  zz=zz+z'z;
  zy=zy+z'y;

tobs=tobs+t;
endo;

@computing the concentrated out params.@

  a=invpd(zz);
  
  if optimal==0;
     d=inv(zw'a*zw)*zw'a*zy;
  else;
     d=inv(zw'aopt*zw)*zw'aopt*zy;
  endif;
  
@Second loop: preparing computation of the objective func.@  
  
clear ze,zw,zeez;
zec={};
tobs=0;i=0;obs=0;
call seekr(f,1);    
do until eof(f);
call seekr(f,tobs+1);
v=readr(f,1);    
  t=v[1,2];
  iob=v[1,1]-1990+1;
  v=v|readr(f,t-1);

@Selecting the firms that belong to the industry@ 
    
  sec=v[1,4:23]*seqa(1,1,20);
  if (sec==s1) or (sec==s2) or (sec==s3);
     i=i+1;    
  else;
     tobs=tobs+t;
     continue;
  endif;
   
  gosub model;

@Dropping the observations without temporary workers@  
  
  ninc=(lev(88,0).==0) .or (lev(88,1).==0);
  y=delif(y,ninc.==1);
  z=delif(z,ninc.==1);
  w=delif(w,ninc.==1);
  if scalmiss(y);
     i=i-1;
     tobs=tobs+t;
     continue;
  endif; 
  obs=obs+rows(y);
  
     e=y-w*d;
     ze=ze+z'e;
     zw=zw+z'w;
     zeez=zeez+z'e*e'*z;
     
     zec=zec|z'e; 

tobs=tobs+t;
endo;

@Computing the objective function@

  if optimal==0;
     fc=ze'a*ze;
  else;
     fc=ze'aopt*ze;
  endif;
  
  
  if optimal==0;
     call saved(zeez,mtx,0);
  endif;

retp(d,fc,zw,ze,a,zeez);
endp;

@Other procedures@

proc(1)=pol1(v);
local pol;
pol=v~(v^2)~(v^3);
retp(pol);
endp;

proc(1)=pol2(v1,v2);
local pol;
pol=v1~(v1^2)~(v1^3)~v2~(v2^2)~(v2^3)~(v1.*v2)~((v1^2).*v2)~(v1.*(v2^2));
retp(pol);
endp;

proc(1)=pol3(v1,v2,v3);
local pol;
pol=v1~v2~v3
    ~(v1^2)~(v2^2)~(v3^2)
    ~(v1.*v2)
    ~(v1.*v3)
    ~(v2.*v3)
    ~(v1^3)~(v2^3)~(v3^3)
    ~((v1^2).*v2)
    ~((v1^2).*v3)
    ~(v1.*(v2^2))
    ~((v2^2).*v3)
    ~(v1.*(v3^2))
    ~(v2.*(v3^2))
    ~(v1.*v2.*v3);
retp(pol);
endp;
    
proc(1)=pol4(v1,v2,v3,v4);
local pol;
pol=v1~v2~v3~v4
    ~(v1^2)~(v2^2)~(v3^2)~(v4^2)
    ~(v1.*v2)
    ~(v1.*v3)
    ~(v1.*v4)
    ~(v2.*v3)
    ~(v2.*v4)
    ~(v3.*v4)
    ~(v1^3)~(v2^3)~(v3^3)~(v4^3)
    ~((v1^2).*v2)
    ~((v1^2).*v3)
    ~((v1^2).*v4)
    ~(v1.*(v2^2))
    ~((v2^2).*v3)
    ~((v2^2).*v4)
    ~(v1.*(v3^2))
    ~(v2.*(v3^2))
    ~((v3^2).*v4)
    ~(v1.*(v4^2))
    ~(v2.*(v4^2))
    ~(v3.*(v4^2))
    ~(v1.*v2.*v3)
    ~(v1.*v2.*v4)
    ~(v1.*v3.*v4)
    ~(v2.*v3.*v4);
retp(pol);
endp;

fn lev(c,lag)=v[2-lag:t-lag,c];

str=etstr(hsec-start);

print;
print "Execution time is  ";;print $str;
end;

stvalues:
if optimal==0;
startv1=0.686|0.174|-0.015|-0.006|-3.636|17.415|-15.707;
startv2=0.611|-0.152|-0.096|-0.011|-2.602|7.925|-4.872;
startv3=0.701|-1.000|-0.468|-0.052|0.907|-1.835|1.793;
startv4=0.601|0.138|-0.028|-0.001|5.155|-20.024|15.789;
startv5=0.609|0.063|-0.057|-0.003|-0.294|-2.365|3.282;
startv6=0.746|0.132|0.034|0.005|-1.155|2.985|-1.867;
startv7=0.604|-0.045|-0.024|-0.007|1.391|-10.177|9.088;
startv8=0.425|0.014|-0.020|-0.003|2.689|-14.328|17.705;
startv9=0.372|0.080|0.002|-0.002|1.424|-5.076|3.612;
startv10=0.282|1.063|0.459|0.056|-0.853|4.410|-4.692;
startv=startv1~startv2~startv3~startv4~startv5~startv6~startv7~startv8~startv9~startv10;    
else;
startv1=0.535|0.176|-0.027|-0.008|-2.455|12.907|-12.299;
startv2=0.730|-0.193|-0.144|-0.019|-2.082|5.588|-2.570;
startv3=0.696|-0.307|-0.204|-0.025|-0.099|2.211|-2.055;
startv4=0.606|0.216|-0.031|-0.004|4.071|-15.487|12.055;
startv5=0.592|-0.001|-0.043|0.002|-0.189|-4.037|5.396;
startv6=0.798|0.145|0.039|0.006|-0.719|2.023|-1.400;
startv7=0.616|-0.076|-0.001|-0.002|2.703|-16.570|14.584;
startv8=0.439|0.055|-0.056|-0.010|-0.038|-1.961|2.463;
startv9=0.438|0.039|-0.010|-0.004|1.173|-5.274|4.300;
startv10=0.530|1.247|0.463|0.051|0.069|-0.803|0.675;
startv=startv1~startv2~startv3~startv4~startv5~startv6~startv7~startv8~startv9~startv10;
endif;
return;



