new;
library pgraph;
graphset;
start=hsec;
#include procs/density.pro;
#include procs/distrib.pro;
@#include procs/regrek.pro;@
@------------------Program options--------------------------------------@

output file=gfunc.out on;


sec=1;

smbig=2;       @0=small;1=big;2=all;3=smtmeans;4=bgtmeans@

tests=1;       @1=perform tests@
graphs=1;      @1=draw graphs@

sf=3;          @kernel "smoothing" factor@


@-----------------------------------------------------------------------@
sectors=ftos(sec,"%*.*lf",1,0);
sname="Industry "$+sectors;
cmda="-CF=graphs\\den"$+sectors$+".ps -C=1 -W=4";
cmdb="-CF=graphs\\dis"$+sectors$+".ps -C=1 -W=4";


fname="function\\g"$+sectors;

open k1=^fname;

w=readr(k1,rowsf(k1));


if smbig==0;
  r=selif(w[.,3],w[.,4].==0);
  g=selif(w[.,1],w[.,4].==0);
  h=selif(w[.,2],w[.,4].==0);
elseif smbig==1;
  r=selif(w[.,3],w[.,4].==1);
  g=selif(w[.,1],w[.,4].==1);
  h=selif(w[.,2],w[.,4].==1);
elseif smbig==2;
  r=(selif(w[.,3],w[.,4].==0).*.ones(14,1))|selif(w[.,3],w[.,4].==1);
  g=(selif(w[.,1],w[.,4].==0).*.ones(14,1))|selif(w[.,1],w[.,4].==1);
  h=(selif(w[.,2],w[.,4].==0).*.ones(14,1))|selif(w[.,2],w[.,4].==1);
elseif smbig==3;
  r=selif(w[.,7],(w[.,4].==0) .and (w[.,5]./=0));
  g=selif(w[.,5],(w[.,4].==0) .and (w[.,5]./=0));
  h=selif(w[.,6],(w[.,4].==0) .and (w[.,5]./=0));
elseif smbig==4;
  r=selif(w[.,7],(w[.,4].==1) .and (w[.,5]./=0));
  g=selif(w[.,5],(w[.,4].==1) .and (w[.,5]./=0));
  h=selif(w[.,6],(w[.,4].==1) .and (w[.,5]./=0));
endif;

format /rd 8,0;

if tests==1;

print$ sname;
print;
print "Option:";;smbig;
print;

if smbig==0;
print "Small firms, tests based on";;rows(g);;" observations";
elseif smbig==1;
print "Big firms, tests based on";;rows(g);;" observations";
elseif smbig==2;
print "All firms, tests based on";;rows(g);;" observations";
elseif smbig==3;
print "Small firms, tests based on";;rows(g);;"time means";
elseif smbig==4;
print "Big firms, tests based on";;rows(g);;"time means";
endif;
print;

endif;

gm=meanc(g);
gs=stdc(g);
g1=selif(g,r.==0)-gm;
g2=selif(g,r./=0)-gm;



g1s=sortc(g1,1);
g2s=sortc(g2,1);
cfg1=seqa(1,1,rows(g1s))/rows(g1s);
cfg2=seqa(1,1,rows(g2s))/rows(g2s);

print "Without R&D:";;rows(g1);;"    With R&D:";;rows(g2);
print;
format /rd 12,3;
print "Means and se without and with R&D";
print;
print (meanc(g1))~(meanc(g2));
print;
print (stdc(g1))~(stdc(g2));
wait;

sprt=sortc(union(g1s,g2s,1),1);
fsp1=zeros(rows(sprt),1);
fsp2=zeros(rows(sprt),1);
fsp1[indnv(g1s,sprt)]=cfg1;
fsp2[indnv(g2s,sprt)]=cfg2;
i=2;
do while i<=rows(sprt);
   if fsp1[i]==0;
      fsp1[i]=fsp1[i-1];
   endif;
   if fsp2[i]==0;
      fsp2[i]=fsp2[i-1];
   endif;
i=i+1;
endo;

if tests==1;

dm=(meanc(g1s)-meanc(g2s))
   /((((stdc(g1s)^2)/(rows(g1s)-1))+((stdc(g2s)^2)/(rows(g2s)-1)))^0.5);
print;
print "Mean with R&D is greater";
print;
print dm;;cdftc(dm,minc(rows(g1s)|rows(g2s))-1);
print;
ff=(stdc(g1s)^2)/(stdc(g2s)^2);
print;
print "Var. with R&D is greater";
print;
print ff;;cdffc(ff,rows(g1s)-1,rows(g2s)-1);
print;
ks2=sqrt((rows(g1s)*rows(g2s))/(rows(g1s)+rows(g2s)))*maxc(abs(fsp1-fsp2));
print;
ks1=sqrt((rows(g1s)*rows(g2s))/(rows(g1s)+rows(g2s)))*maxc(fsp2-fsp1);
print;
print "Kolgomorov-Smirnov tests";
print;
sgn={};i=1;do while i<=1000;sgn=sgn|((-1)^i);i=i+1;endo;
print;
print "Equal distributions (two sided):";;ks2;;
-2*sumc(sgn.*exp(-2*((seqa(1,1,1000))^2)*(ks2^2)));
print;
print "Distrib. with R&D dominates (one sided):";;ks1;;exp(-2*(ks1^2));
print;
wait;

endif;

if graphs==1;

mat=zeros(100,4);
{m1,m2}=density(g1s,sf,-0.3,0.3,gs);
{m3,m4}=density(g2s,sf,-0.3,0.3,gs);


mat[.,1 2]=m1~m2;
mat[.,3 4]=m3~m4;


cfg=zeros(100,4);
{w1,w2}=distrib(g1s,sf,-0.3,0.3,gs);
{w3,w4}=distrib(g2s,sf,-0.3,0.3,gs);

cfg[.,1 2]=w1~w2;
cfg[.,3 4]=w3~w4;

_pdate="";
_plctrl=0;
_plwidth={6 6 16};
_pltype={1  6  2};
_pcolor={13 15 14};
_plegctl={2 3 1 5};
_plegstr=
"Controlled process: no R&D\000Controlled process: R&D\000Exogenous process";

call xtics(-0.3,0.3,0.1,0);
call ytics(0,0.7,0.05,0);
xlabel("Difference from average expected productivity");
ylabel("Density of expected productivity");
title(sname);

xy(mat[.,1 3],mat[.,2 4]);
wait;

call xtics(-0.3,0.3,0.1,0);
call ytics(0,1,0.1,0);
ylabel("Distribution of expected productivity");
title(sname);

xy(cfg[.,1 3],cfg[.,2 4]);

endif;

str=etstr(hsec-start);
print;
"Execution time is  ";;print $str;
end;

