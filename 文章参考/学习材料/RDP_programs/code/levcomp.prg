new;
declare industry;
#include procs/prodl.prc;
closeall;
output file=levcomp.out on;

@---------------------------------------------------------------------------------------------------------------@

pdt=3;            @1=labor-augmenting productivity; 2=output effect of 1; 3=Hicksian productivity; 4=total prod.@

@---------------------------------------------------------------------------------------------------------------@

iy=3;fy=17;
trm=0;

y={};
industry=1;
do while industry<=10;

industries=ftos(industry,"%*.*lf",1,0);
input="lprod/g"$+industries;
open f=^input;

@year, obs, out,  size,  rd, sub, ptw, entry, exit  elas, elas2, omgL, omgH, momgL, momgH@
@ 1     2     3     4     5   6    7    8      9     10    11     12    13    14     15 @

wb={};ws={};wh={};sp1={};
dis1={};dis2={};

j=0;tobs=0;
call seekr(f,1);	
do until eof(f);
       call seekr(f,tobs+1);
       v=readr(f,1);
       t=v[.,2];
       v=v|(readr(f,t-1));
	
if pdt==1;    
w=v[.,12];
elseif pdt==2;    
w=v[.,11].*(v[.,12]-v[.,14]);
elseif pdt==3;    
w=v[.,13];
else;	
w=v[.,11].*(v[.,12]-v[.,14])+v[.,13];
endif;    
	
z=v[.,7];
z=0|((z[2:rows(z)].==0) .or (z[1:rows(z)-1].==0));
	
sz=v[1,4]*ones(t,1);
rd=v[.,5];
sb=v[.,6];	
	
wbj=zeros(17,1);wsj=zeros(17,1);whj=zeros(17,1);sp1j=zeros(17,1);dis1j=zeros(17,1);dis2j=zeros(17,1);

ind=indcv(v[.,1],seqa(1990,1,17));	
wbj[ind]=w.*sz.*(1-z);
wsj[ind]=w.*(1-sz).*(1-z);

relw=exp(v[.,3])/1000;relw=0|0|relw[1:t-2];
whj[ind]=relw;

sp1j[ind]=(0|(rd[1:t-1]./=0));

dis1j[ind]=(v[.,5]./=0);
dis2j[ind]=(v[.,6].>0);
	
wb=wb~wbj;
ws=ws~wsj;
wh=wh~whj;	
sp1=sp1~sp1j;
dis1=dis1~dis1j;
dis2=dis2~dis2j;

tobs=tobs+t;
j=j+1;
endo;

y1=prod(wb,ws,wh,sp1,0,iy,fy,1,dis1,dis2,0,trm);
y2=prod(wb,ws,wh,sp1,0,iy,fy,2,dis1,dis2,0,trm);

y=y|y1[1,3]-y2[1,3];

industry=industry+1;
closeall;
endo;

if pdt==1;
pdty="Labor-augmenting productivity:";
elseif pdt==2;    
pdty="Output effect of labor-augmenting productivity:";
elseif pdt==3;    
pdty="Hicksian productivity:";
else;
pdty="Total productivity:";
endif;
format /rd 10,3;
print;
print pdty;;" RD-NO RD";
print y;
print;

end;

