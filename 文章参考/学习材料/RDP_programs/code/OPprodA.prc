@ PROCEDURE PROD: prod(a,b,c,e,f,g,h,i,k,l,m,tr,tp)
Drops observations when status change, computes means and weighted means, for soubgroups 
if required, for the specified years.  

INPUTS:

a=w big
b= w small
c= weights
e=indicator for splitting
f=counting
g=initial year
h=final year
i:0=no split;1=split according to e=1;2=split according to e=0;
k,l=discard if status change
m=adding up contributions
tr=trimming
tp=type to use in trimming
 
OUTPUT: 

@
 

declare subperiod;
library pgraph;

graphset;


proc prod(a,b,c,e,f,g,h,i,k,l,m,tr,tp);
local prod,j,wb,wbmiss,ws,wsmiss,wg,el,splt,w,wbv,wsv,nb,nnb,ns,nns,n,nn,wbmin,wsmin,wbmax,wsmax,outef,wbt,wst,swg,wgb,
      swgb,wgs,swgs,t,dwt,wt,dwbt,dwst,iyear,fyear,yrs,spl,swb,sws,sw,drop1,drop2,counting,countbg,countsm,q,nrepl,twb,tws,tw,contb,conts,cont,contrib,swgb0,swgs0,
	  wr,yaej,ytdj,yae,ytd,y,x,z,weights,values, wbmiss1,wbv1,nb1,wb1,wbmin1,wbmax1,wbmiss2,wbv2,nb2,wb2,wbmin2,wbmax2,wbmiss3,wbv3,nb3,wb3,wbmin3,wbmax3,
	  wsmiss1,wsv1,ns1,ws1,wsmin1,wsmax1,wsmiss2,wsv2,ns2,ws2,wsmin2,wsmax2,wsmiss3,wsv3,ns3,ws3,wsmin3,wsmax3,freq,freqi,freqf,mm,bb,bbi,bbf,num;

contrib=m;	
	
counting=f;
if counting==0;
prod=zeros(2,4);
else;
prod=zeros(4,4);
endif;

j=1;
do while j<=2;
wb=a;ws=b;wg=c;splt=e;
iyear=g;fyear=h;spl=i;drop1=k;drop2=l;

wb=wb';
ws=ws';
wg=wg';
splt=splt';
drop1=drop1';
drop2=drop2';

@dropping and, maybe, trimming@

countbg=sumc(sumc(@(wb[.,iyear-1:fyear-1]./=0) .and@ (wb[.,iyear:fyear]./=0)));
	
	
wbmiss=missex(wb,wb.==0);

wbmiss=zeros(rows(wb),1)~missex(wbmiss[.,2:17],((drop1[.,1:16].==0) .and (drop1[.,2:17].>0)) .or ((drop1[.,1:16].>0) .and (drop1[.,2:17].==0)));
wbmiss=zeros(rows(wb),1)~missex(wbmiss[.,2:17],((drop2[.,1:16].==0) .and (drop2[.,2:17].>0)) .or ((drop2[.,1:16].>0) .and (drop2[.,2:17].==0)));

if tr>0;
	
wbmiss1=(splt.==1).*wbmiss;	
wbv1=sortc(packr(vecr(wbmiss1[.,2:cols(wbmiss1)])),1);
nb1=rows(wbv1);
wbmin1=wbv1[round(tr*nb1)];
wbmax1=wbv1[round((1-tr)*nb1)];
wb1=missrv(wbmiss1,0);
	
if subperiod==3;
else;	
wb1=substute(wb1,(wb1.<wbmin1) .or (wb1.>wbmax1),0);
endif;

	
wbmiss2=(splt.==2).*wbmiss;	
wbv2=sortc(packr(vecr(wbmiss2[.,2:cols(wbmiss2)])),1);
nb2=rows(wbv2);
wbmin2=wbv2[round(tr*nb2)];
wbmax2=wbv2[round((1-tr)*nb2)];
wb2=missrv(wbmiss2,0);


wb2=substute(wb2,(wb2.<wbmin2) .or (wb2.>wbmax2),0);
	
	
wbmiss3=(splt.==3).*wbmiss;	
wbv3=sortc(packr(vecr(wbmiss3[.,2:cols(wbmiss3)])),1);
nb3=rows(wbv3);
wbmin3=wbv3[round(tr*nb3)];
wbmax3=wbv3[round((1-tr)*nb3)];
wb3=missrv(wbmiss3,0);
wb3=substute(wb3,(wb3.<wbmin3) .or (wb3.>wbmax3),0);

wb=wb1+wb2+wb3;
	
else;
wb=missrv(wbmiss,0);	
endif;	


countsm=sumc(sumc(@(ws[.,iyear-1:fyear-1]./=0) .and@ (ws[.,iyear:fyear]./=0)));


wsmiss=missex(ws,ws.==0);

wsmiss=zeros(rows(ws),1)~missex(wsmiss[.,2:17],((drop1[.,1:16].==0) .and (drop1[.,2:17].>0)) .or ((drop1[.,1:16].>0) .and (drop1[.,2:17].==0)));
wsmiss=zeros(rows(ws),1)~missex(wsmiss[.,2:17],((drop2[.,1:16].==0) .and (drop2[.,2:17].>0)) .or ((drop2[.,1:16].>0) .and (drop2[.,2:17].==0)));

if tr>0;
	
wsmiss1=(splt.==1).*wsmiss;	
wsv1=sortc(packr(vecr(wsmiss1[.,2:cols(wsmiss1)])),1);
ns1=rows(wsv1);
wsmin1=wsv1[round(tr*ns1)];
wsmax1=wsv1[round((1-tr)*ns1)];
ws1=missrv(wsmiss1,0);
ws1=substute(ws1,(ws1.<wsmin1) .or (ws1.>wsmax1),0);
	
wsmiss2=(splt.==2).*wsmiss;	
wsv2=sortc(packr(vecr(wsmiss2[.,2:cols(wsmiss2)])),1);
ns2=rows(wsv2);
wsmin2=wsv2[round(tr*ns2)];
wsmax2=wsv2[round((1-tr)*ns2)];
ws2=missrv(wsmiss2,0);
ws2=substute(ws2,(ws2.<wsmin2) .or (ws2.>wsmax2),0);	
	
wsmiss3=(splt.==3).*wsmiss;	
wsv3=sortc(packr(vecr(wsmiss3[.,2:cols(wsmiss3)])),1);
ns3=rows(wsv3);
wsmin3=wsv3[round(tr*ns3)];
wsmax3=wsv3[round((1-tr)*ns3)];
ws3=missrv(wsmiss3,0);
ws3=substute(ws3,(ws3.<wsmin3) .or (ws3.>wsmax3),0);	
	
ws=ws1+ws2+ws3;	
	
else;
ws=missrv(wsmiss,0);	
endif;

@totals@
twb=sumc(substute(wg,wb.==0,0));
tws=sumc(substute(wg,ws.==0,0));

@splitting@
if spl==1;
   wb=(splt.==tp).*wb;
   ws=(splt.==tp).*ws;
elseif spl==2;
   wb=(1-(splt.==tp)).*wb;
   ws=(1-(splt.==tp)).*ws;
endif;

w=wb+14*ws;


@weights@
wgb=substute(wg,wb.==0,0);
swgb0=sumc(wgb);
swgb=substute(sumc(wgb),sumc(wgb).==0,1);
wgs=substute(wg,ws.==0,0);
swgs0=sumc(wgs);
swgs=substute(sumc(wgs),sumc(wgs).==0,1);


wgb=wgb./(1~swgb[2:rows(swgb)]');
wgs=wgs./(1~swgs[2:rows(swgs)]');

weights=(swgb0+14*swgs0)';

contb=(1~swgb[2:rows(swgb)]')./(1~twb[2:rows(swgb)]');
conts=(1~swgs[2:rows(swgs)]')./(1~tws[2:rows(swgs)]');
cont=(1~(swgb0[2:rows(swgb0)]'+14*swgs0[2:rows(swgs0)]'))./(1~(twb[2:rows(swgb)]'+14*tws[2:rows(swgs)]'));

if j==2;
wb=wgb.*wb;
ws=wgs.*ws;
w=(swgb0./(swgb0+14*swgs0))'.*wb+((swgs0*14)./(swgb0+14*swgs0))'.*ws;
if contrib==1;	
wb=contb.*wb;
ws=conts.*ws;
w=cont.*w;	
endif;	
endif;

wb=missex(wb,wb.==0);
ws=missex(ws,ws.==0);
w=missex(w,w.==0);


nb=0;ns=0;n=0;
t=iyear;dwbt={};dwst={};dwt={};num={};
do while t<=fyear;
   
   wbt=wb[.,t];
   wst=ws[.,t];
   wt=w[.,t];

   if scalmiss(packr(wbt));nnb=0;else;nnb=rows(packr(wbt));endif;
   if scalmiss(packr(wst));nns=0;else;nns=rows(packr(wst));endif;
   if scalmiss(packr(wt));nn=0;else;nn=rows(packr(wt));endif;
   nrepl=nnb+14*nns; 
	   
	   
	@print nn;@   
	   
   nb=nb+nnb;
   ns=ns+nns;
   n=n+nn;  
   
   if j==1;
   dwbt=dwbt|meanc(packr(wbt));
   dwst=dwst|meanc(packr(wst));
   dwt=dwt|(sumc(packr(wt))/nrepl);
   num=num|nrepl;	   
   else;
   dwbt=dwbt|sumc(packr(wbt));
   dwst=dwst|sumc(packr(wst));
   dwt=dwt|sumc(packr(wt));
   endif;

t=t+1;
endo;

dwbt=packr(dwbt);
dwst=packr(dwst);
dwt=packr(dwt);
if j==1;
num=packr(num);
endif;	


weights=weights[iyear fyear];

if j==1;
prod[1,1 2 4]=weights[1]~dwt[1]~num[1];
prod[2,1 2 4]=weights[cols(weights)]~dwt[rows(dwt)]~num[rows(dwt)];
else;
prod[1,3]=dwt[1];
prod[2,3]=dwt[rows(dwt)];
endif;

j=j+1;
endo;

if counting==1;
prod[3 4,.]=(nb~ns~n)|(countbg~countsm~(countbg+countsm));
endif;

retp(prod);
endp;
