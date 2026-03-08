@ PROCEDURE PROD: prod(a,b,c,e,f,g,h,i,k,l,m,tr)
Drops observations when status change, computes means and weighted means, for soubgroups 
if required, for the specified years. Trims the distributions if tr>0.


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
tr=triming
 
OUTPUT: 

@
 


library pgraph;
graphset;


proc prod(a,b,c,e,f,g,h,i,k,l,m,tr);
local prod,j,wb,wbmiss,wbmiss1,wbmiss2,ws,wsmiss,wsmiss1,wsmiss2,wg,el,splt,w,wbv,wsv,nb,nnb,ns,nns,n,nn,wbmin,wsmin,wbmax,wsmax,outef,wbt,wst,swg,wgb,
      swgb,wgs,swgs,t,dwt,wt,dwbt,dwst,iyear,fyear,yrs,spl,swb,sws,sw,drop1,drop2,counting,countbg,countsm,q,nrepl,twb,tws,tw,contb,conts,cont,contrib,swgb0,swgs0,
	  wr,yaej,ytdj,yae,ytd,y,x,z,weights,values;

contrib=m;	
	
counting=f;
if counting==0;
prod=zeros(2,3);
else;
prod=zeros(4,3);
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
wbv=sortc(packr(vecr(wbmiss[.,2:cols(wbmiss)])),1);
nb=rows(wbv);
wbmin=wbv[round(tr*nb)];
wbmax=wbv[round((1-tr)*nb)];
wb=missrv(wbmiss,0);
wb=substute(wb,(wb.<wbmin) .or (wb.>wbmax),0);
else;
wb=missrv(wbmiss,0);	
endif;	

countsm=sumc(sumc(@(ws[.,iyear-1:fyear-1]./=0) .and@ (ws[.,iyear:fyear]./=0)));
wsmiss=missex(ws,ws.==0);


wsmiss=zeros(rows(ws),1)~missex(wsmiss[.,2:17],((drop1[.,1:16].==0) .and (drop1[.,2:17].>0)) .or ((drop1[.,1:16].>0) .and (drop1[.,2:17].==0)));
wsmiss=zeros(rows(ws),1)~missex(wsmiss[.,2:17],((drop2[.,1:16].==0) .and (drop2[.,2:17].>0)) .or ((drop2[.,1:16].>0) .and (drop2[.,2:17].==0)));

if tr>0;
wsv=sortc(packr(vecr(wsmiss[.,2:cols(wsmiss)])),1);
ns=rows(wsv);
wsmin=wsv[round(tr*ns)];
wsmax=wsv[round((1-tr)*ns)];
ws=missrv(wsmiss,0);
ws=substute(ws,(ws.<wsmin) .or (ws.>wsmax),0);
else;
ws=missrv(wsmiss,0);	
endif;

@totals@
twb=sumc(substute(wg,wb.==0,0));
tws=sumc(substute(wg,ws.==0,0));

@splitting@
if spl==1;
   wb=splt.*wb;
   ws=splt.*ws;
elseif spl==2;
   wb=(1-splt).*wb;
   ws=(1-splt).*ws;
endif;

w=wb+14*ws;

@weights@
wgb=substute(wg,wb.==0,0);
swgb0=sumc(wgb);
swgb=substute(sumc(wgb),sumc(wgb).==0,1);
wgs=substute(wg,ws.==0,0);
swgs0=sumc(wgs);
swgs=substute(sumc(wgs),sumc(wgs).==0,1);


wgb=wgb./(1~1~swgb[3:rows(swgb)]');
wgs=wgs./(1~1~swgs[3:rows(swgs)]');

weights=(swgb0+14*swgs0)';

contb=(1~1~swgb[3:rows(swgb)]')./(1~1~twb[3:rows(swgb)]');
conts=(1~1~swgs[3:rows(swgs)]')./(1~1~tws[3:rows(swgs)]');
cont=(1~1~(swgb0[3:rows(swgb0)]'+14*swgs0[3:rows(swgs0)]'))./(1~1~(twb[3:rows(swgb)]'+14*tws[3:rows(swgs)]'));

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
t=iyear;dwbt={};dwst={};dwt={};
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

weights=weights[iyear fyear];

if j==1;
prod[1,1 2]=meanc(dwt)~meanc(dwt);
prod[2,1 2]=meanc(dwt)~meanc(dwt);
else;
prod[1,3]=meanc(dwt);
prod[2,3]=meanc(dwt);
endif;


j=j+1;
endo;

if counting==1;
prod[3 4,.]=(nb~ns~n)|(countbg~countsm~(countbg+countsm));
endif;

retp(prod);
endp;
