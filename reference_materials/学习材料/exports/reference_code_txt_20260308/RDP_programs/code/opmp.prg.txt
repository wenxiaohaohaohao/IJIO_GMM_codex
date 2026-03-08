new;
declare industry;
#include procs/OPprodA.prc;
closeall;
output file=OPMP.out on;

@--------------------------------------------------------------------------------------------------------------------------@

pdt=1;                     @1=output effect of labor-augmenting productivity; 2=Hicksian productivity; 3=total productivity@
subperiod=0;               @0=1992-2006;1=1992-1996;2=1997-2001;3=2002-2006@ 
trm=0.01;

@--------------------------------------------------------------------------------------------------------------------------@

wb={};ws={};wh={};
sp={};
dis1={};dis2={};

industry=1;
do while industry<=10;

industries=ftos(industry,"%*.*lf",1,0);
input="lprod/g"$+industries;
open f=^input;
    
@year, obs, out,  size,  rd, sub, ptw, entry, exit, elas, elas2, omgL, omgH, momgL, momgH@
@ 1     2     3     4     5   6    7    8      9     10     11    12    13    14     15 @    

if subperiod==0;
iy=3;fy=17;	
elseif subperiod==1;
iy=3;fy=7;
elseif subperiod==2;	
iy=8;fy=12;
elseif subperiod==3;	
iy=13;fy=17;
endif;

j=0;tobs=0;
do until eof(f);
       call seekr(f,tobs+1);
       v=readr(f,1);
       t=v[.,2];
       v=v|(readr(f,t-1));
	
cond=(v[.,10]./=0) .and (v[.,12]./=0) .and (v[.,13]./=0);

if pdt==1;
w=(v[.,10].*(v[.,12]-v[.,14])).*cond;
elseif pdt==2;	
w=(v[.,13]-v[.,15]).*cond;
else;	
w=(v[.,10].*(v[.,12]-v[.,14])+(v[.,13]-v[.,15])).*cond;
endif;    
    
	
z=v[.,7];
z=0|((z[2:rows(z)].==0) .or (z[1:rows(z)-1].==0));
	
sz=v[1,4]*ones(t,1);
rd=v[.,5];
sb=v[.,6];	
	
wbj=zeros(17,1);wsj=zeros(17,1);whj=zeros(17,1);
sp3j=zeros(17,1);sp4j=zeros(17,1);sp5j=zeros(17,1);
spj=zeros(17,1);dis1j=zeros(17,1);dis2j=zeros(17,1);

ind=indcv(v[.,1],seqa(1990,1,17));	
wbj[ind]=w.*sz.*(1-z);
wsj[ind]=w.*(1-sz).*(1-z);
sales=v[.,3];
whj[ind]=sales;

sp3j[ind]=(v[.,8].>0)*(ind[1]>iy)-((v[.,8].>0)*(ind[1]>iy)).*((v[.,9].>0)*(ind[t]<fy));
sp4j[ind]=(v[.,9].>0)*(ind[t]<fy);
sp5j[ind]=ones(t,1)-(((v[.,8].>0)*(ind[1]>iy)) .or ((v[.,9].>0)*(ind[t]<fy)));

spj=sp3j+2*sp4j+3*sp5j;

dis1j[ind]=(v[.,5]./=0);
dis2j[ind]=(v[.,6].>0);
	
wb=wb~wbj;
ws=ws~wsj;
wh=wh~whj;	
sp=sp~spj;
dis1=dis1~dis1j;
dis2=dis2~dis2j;

tobs=tobs+t;
j=j+1;
endo;

industry=industry+1;
closeall;
endo;

if pdt==1;
pdty="Output effect of labor-augmenting productivity";
elseif pdt==2;    
pdty="Hicksian productivity";
else;
pdty="Total productivity";
endif;

if subperiod==0;
sbp=" 1992-2006";
elseif subperiod==1;
sbp=" 1992-96";
elseif subperiod==2;
sbp=" 1997-2001";
else;
sbp=" 2002-2006";
endif;    


format /rd 10,3;
y1=prod(wb,ws,wh,sp,0,iy,fy,0,dis1,dis2,0,trm,3);
y2=prod(wb,ws,wh,sp,0,iy,fy,1,dis1,dis2,0,trm,3);
y3=prod(wb,ws,wh,sp,0,iy,fy,1,dis1,dis2,0,trm,1);
y4=prod(wb,ws,wh,sp,0,iy,fy,1,dis1,dis2,0,trm,2);

tot=y1[2,3]-y1[1,3];
shift=y2[2,2]-y2[1,2];
shent=(y3[2,1]/y1[2,1]);
pent=y3[2,3];psur1=y2[2,3];
entry=shent*(pent-psur1);
shext=(y4[1,1]/y1[1,1]);
pext=y4[1,3];psur0=y2[1,3];
exit=shext*(psur0-pext);
cov=tot-shift-entry-exit;

print;
print pdty;;sbp;
print;
print "      tot       shift        shE         pE        pS1       shX        pS0         pX"; 
print tot shift shent pent psur1 shext psur0 pext;
print;
print "      tot       shift        cov         ent       ext"; 
print tot~shift~cov~entry~exit;

surv=y2[2,3]-y2[1,3];
sshift=y2[2,2]-y2[1,2];
scov=surv-sshift;
print "      surv      shift        cov"; 
print surv~sshift~scov;
print;




print;
end;

