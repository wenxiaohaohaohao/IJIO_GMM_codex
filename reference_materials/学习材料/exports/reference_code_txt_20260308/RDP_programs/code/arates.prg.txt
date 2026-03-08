new;
declare industry;
#include procs/prodd.prc;
closeall;
output file=arates.out on;


w1b={};w1s={};wh={};
w2b={};w2s={};
w3b={};w3s={};
w4b={};w4s={};
sp1={};sp2={};sp3={};sp4={};sp5={};sp6={};
dis1={};dis2={};
prod1={};prod2={};prod3={};prod4={};
industry=1;
do while industry<=10;

industries=ftos(industry,"%*.*lf",1,0);
input="dprod/g"$+industries;
open f=^input;

@year, obs, output, size,  rd,  sub, tmw, entry, exit elas, elas2, domgL, domgH@
@ 1     2     3      4     5     6    7    8       9   10    11     12      13@

j=0;tobs=0;
do until eof(f);
       call seekr(f,tobs+1);
       v=readr(f,1);
       t=v[.,2];
       v=v|(readr(f,t-1));
	
  
w1=v[.,12];                                                   
w2=v[.,11].*v[.,12];                                          
w3=v[.,13];                                              
w4=v[.,11].*v[.,12]+v[.,13];                                                                                 

sz=v[.,4];
rd=v[.,5];
sb=v[.,6];	
	
w1bj=zeros(17,1);w1sj=zeros(17,1);whj=zeros(17,1);
w2bj=zeros(17,1);w2sj=zeros(17,1);
w3bj=zeros(17,1);w3sj=zeros(17,1);
w4bj=zeros(17,1);w4sj=zeros(17,1);
sp1j=zeros(17,1);sp2j=zeros(17,1);sp3j=zeros(17,1);sp4j=zeros(17,1);sp5j=zeros(17,1);sp6j=zeros(17,1);
dis1j=zeros(17,1);dis2j=zeros(17,1);

ind=indcv(v[.,1],seqa(1990,1,17));	
w1bj[ind]=w1.*sz;
w1sj[ind]=w1.*(1-sz);
w2bj[ind]=w2.*sz;
w2sj[ind]=w2.*(1-sz);
w3bj[ind]=w3.*sz;
w3sj[ind]=w3.*(1-sz);
w4bj[ind]=w4.*sz;
w4sj[ind]=w4.*(1-sz);
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
	
w1b=w1b~w1bj;
w1s=w1s~w1sj;
w2b=w2b~w2bj;
w2s=w2s~w2sj;
w3b=w3b~w3bj;
w3s=w3s~w3sj;
w4b=w4b~w4bj;
w4s=w4s~w4sj;
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

industry=industry+1;
closeall;
endo;

format /rd 8,3;
print;
print "Aggregate productivity growth";
print "Cols.: mean big, mean small, mean all, weighted mean big, weighted mean small, weighted mean all."; 
print "Rows: Labor-augmenting, Output effect of labor-augmenting, Hicksian, Total";

prod1=prod(w1b,w1s,wh,sp1,0,3,17,0,dis1,dis2,0);                             
prod2=prod(w2b,w2s,wh,sp1,0,3,17,0,dis1,dis2,0);
prod3=prod(w3b,w3s,wh,sp1,0,3,17,0,dis1,dis2,0);
prod4=prod(w4b,w4s,wh,sp1,0,3,17,0,dis1,dis2,0);

print prod1|prod2|prod3|prod4;
print;

prod1R=prod(w1b,w1s,wh,sp1,0,3,17,1,dis1,dis2,0);
prod1NR=prod(w1b,w1s,wh,sp1,0,3,17,2,dis1,dis2,0);

prod2R=prod(w2b,w2s,wh,sp1,0,3,17,1,dis1,dis2,0);
prod2NR=prod(w2b,w2s,wh,sp1,0,3,17,2,dis1,dis2,0);

prod3R=prod(w3b,w3s,wh,sp1,0,3,17,1,dis1,dis2,0);
prod3NR=prod(w3b,w3s,wh,sp1,0,3,17,2,dis1,dis2,0);

prod21=prod(w2b,w2s,wh,sp5,0,3,17,2,dis1,dis2,1);
prod22=prod(w2b,w2s,wh,sp3,0,3,17,1,dis1,dis2,1);
prod23=prod(w2b,w2s,wh,sp4,0,3,17,1,dis1,dis2,1);

prod31=prod(w3b,w3s,wh,sp5,0,3,17,2,dis1,dis2,1);
prod32=prod(w3b,w3s,wh,sp3,0,3,17,1,dis1,dis2,1);
prod33=prod(w3b,w3s,wh,sp4,0,3,17,1,dis1,dis2,1);

print "Splitting the labor-aug. growth in R&D and no R&D firms:";
print prod1R|prod1NR;
print;
print "Splitting the output-effect growth in R&D and no R&D firms:";
print prod2R|prod2NR;
print;
print "Splitting Hicksian productivity growth in R&D and no R&D firms:";
print prod3R|prod3NR;
print;
print "Splitting the output-effect growth in the contributions of survivors, entry and exit:";
print (prod21|prod22|prod23)~((prod21[.,6]/(prod21[.,6]+prod22[.,6]+prod23[.,6]))|(prod22[.,6]/(prod21[.,6]+prod22[.,6]+prod23[.,6]))|(prod23[.,6]/(prod21[.,6]+prod22[.,6]+prod23[.,6])));
print;
print "Splitting Hicsian productivity growth in the contributions of survivors, entry and exit:";
print (prod31|prod32|prod33)~((prod31[.,6]/(prod31[.,6]+prod32[.,6]+prod33[.,6]))|(prod32[.,6]/(prod31[.,6]+prod32[.,6]+prod33[.,6]))|(prod33[.,6]/(prod31[.,6]+prod32[.,6]+prod33[.,6])));









end;

