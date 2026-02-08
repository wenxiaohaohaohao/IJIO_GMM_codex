new;
declare industry;
#include procs/prodd.prc;
closeall;
output file=ratedescrip.out on;

@--------------------------------------------------------------------------------------------------------------------------------------------@

pdt=1;                     @1=labor-augmenting productivity growth; 2=output effect of 1; 3=Hicksian productivity growth; 4=total prod growth@
dec=1;                     @1=split according to rd/no rd firms; 2=contributions of surv., entry and exit@

@--------------------------------------------------------------------------------------------------------------------------------------------@

prod1={};prod2={};prod3={};prod4={};
industry=1;
do while industry<=10;

industries=ftos(industry,"%*.*lf",1,0);
input="dprod/g"$+industries;
open f=^input;

@year, obs, output, size,  rd,  sub, tmw, entry, exit elas, elas2, domgL, domgH@
@ 1     2     3      4     5     6    7    8       9   10    11     12      13@

wb={};ws={};wh={};
sp1={};sp2={};sp3={};sp4={};sp5={};sp6={};
dis1={};dis2={};
j=0;tobs=0;
do until eof(f);
       call seekr(f,tobs+1);
       v=readr(f,1);
       t=v[.,2];
       v=v|(readr(f,t-1));
	
if pdt==1;    
w=v[.,12];                                                   @labor-augmenting productivity growth@
elseif pdt==2;
w=v[.,11].*v[.,12];                                          @output effect of labor-augmenting prod. growth@  	
elseif pdt==3;
w=v[.,13];                                                   @Hicksian productivity growth@
else;       
w=v[.,11].*v[.,12]+v[.,13];                                  @total productivity grwoth@                                                  
endif;  

sz=v[.,4];
rd=v[.,5];
sb=v[.,6];	
	
wbj=zeros(17,1);wsj=zeros(17,1);whj=zeros(17,1);
sp1j=zeros(17,1);sp2j=zeros(17,1);sp3j=zeros(17,1);sp4j=zeros(17,1);sp5j=zeros(17,1);sp6j=zeros(17,1);
dis1j=zeros(17,1);dis2j=zeros(17,1);

ind=indcv(v[.,1],seqa(1990,1,17));	
wbj[ind]=w.*sz;
wsj[ind]=w.*(1-sz);
sales=v[.,3];
whj[ind]=0|0|exp(sales[1:t-2]);

sp1j[ind]=(0|(rd[1:t-1]./=0));
sp2j[ind]=(0|((sb[1:t-1].>0) .or (sb[2:t].>0)));
sp3j[ind]=(v[.,8].>0);
sp4j[ind]=(v[.,9].>0)-((v[.,8].>0).*(v[.,9].>0));
sp5j[ind]=(v[.,8].>0) .or (v[.,9].>0);
sp6j[ind]=v[.,7].>0.1;

dis1j[ind]=(v[.,5]./=0);
dis2j[ind]=(v[.,6].>0);
	
wb=wb~wbj;
ws=ws~wsj;
wh=wh~whj;	
sp1=sp1~sp1j;
sp2=sp2~sp2j;
sp3=sp3~sp3j;
sp4=sp4~sp4j;
sp5=sp5~sp5j;
sp6=sp6~sp6j;
dis1=dis1~dis1j;
dis2=dis2~dis2j;

tobs=tobs+t;
j=j+1;
endo;

if dec==1;
prod1=prod1|prod(wb,ws,wh,sp1,0,3,17,0,dis1,dis2,0);                             
prod2=prod2|prod(wb,ws,wh,sp1,0,3,17,1,dis1,dis2,0);
prod3=prod3|prod(wb,ws,wh,sp1,0,3,17,2,dis1,dis2,0);
else;
prod1=prod1|prod(wb,ws,wh,sp5,0,3,17,0,dis1,dis2,0);
prod2=prod2|prod(wb,ws,wh,sp5,0,3,17,2,dis1,dis2,1);
prod3=prod3|prod(wb,ws,wh,sp3,0,3,17,1,dis1,dis2,1);
prod4=prod4|prod(wb,ws,wh,sp4,0,3,17,1,dis1,dis2,1);
endif;    

industry=industry+1;
closeall;
endo;

if pdt==1;
pdty="Labor-augmenting";
elseif pdt==2;    
pdty="Output effect of labor-augmenting";
elseif pdt==3;    
pdty="Hicksian";
else;
pdty="Total";
endif;    

format /rd 10,3;

if dec==1;
print pdty;;" productivity growth by industries"; 
print "Cols.: mean big, mean small, mean all, weighted mean big, weighted mean small, weighted mean all.";
print prod1;
print;
print "R&D firms";    
print prod2;
print;
print "no R&D firms";    
print prod3;
print;
else;
print pdty;;" productivity growth  by industries";
print "Cols.: mean big, mean small, mean all, weighted mean big, weighted mean small, weighted mean all; percentage of contributions in last column";    
print prod1;
print;
print "Contrib. of survivors";    
print prod2~(prod2[.,6]./(prod2[.,6]+prod3[.,6]+prod4[.,6]));
print;
print "Contrib. of entrants";     
print prod3~(prod3[.,6]./(prod2[.,6]+prod3[.,6]+prod4[.,6]));
print;
print "Contrib. of exitors";    
print prod4~(prod4[.,6]./(prod2[.,6]+prod3[.,6]+prod4[.,6]));
print;
endif;    

end;

