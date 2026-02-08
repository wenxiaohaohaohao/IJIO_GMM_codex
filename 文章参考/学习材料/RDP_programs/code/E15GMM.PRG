new;
library optmum;
optset;
start=hsec;


@----------------------Program options-----------------------------------------@

output file=e15gmm.out on;

industry=1;

optimal=0;        @0=first stage; 1=second stage@

sdcorr=1;         @0=no correction of the standard errors; 1=correction@  

@------------------------------------------------------------------------------@
declare t,v,d,zw,ze,a,zeez,i,obs,ftd,ftl,prods1,prods2,prods3,prods4,ratecorr,corrlev,quantsol,quantsh;
final=0;

@Nonlinear and concentrated out parameters, starting values@

nlpms="bk"~"nu"~"eta1"~"eta2"~"eta3"~"eta4"~"eta5"~"eta6"~"tw1"~"tw2"~"tw3";

copms="ct"~"d92"~"d93"~"d94"~"d95"~"d96"~"d97"~"d98"~"d99"
          ~"d00"~"d01"~"d02"~"d03"~"d04"~"d05"~"d06"~"rho1"~"rho2"~"rho3"
          ~"R>0"~"rho1"~"rho2"~"rho3"~"rho4"~"rho5"~"rho6"~"rho7"~"rho8"~"rho9";

namex=nlpms~copms;
gosub stvalues;
startv=startv[.,industry];

@Grouping industries@

secs={12 13 13, 11 11 11, 9 10 10, 14 14 14, 15 16 16, 17 18 18,
     1 2 3, 4 5 5, 6 19 19, 7 8 8};
s1=secs[industry,1];s2=secs[industry,2];s3=secs[industry,3];

@Reading inputs/defining output@

input="data\\data";
open f=^input;

industries=ftos(industry,"%*.*lf",1,0);
mtx="matrices15\\zeez"$+industries;

if optimal==1;
open h=^mtx;
aopt=inv(readr(h,rowsf(h)));
endif;

cffs="cvars12\\c"$+industries;
cvars="cvars12\\v"$+industries;
funcd="dprod\\g"$+industries;
funcl="lprod\\g"$+industries;
corrs1="sdcorr\\g1"$+industries;
corrs2="matrices12\\zeez"$+industries;

open cfs=^cffs;
slg=readr(cfs,7);

input2="sdcorr\\ze1"$+industries;
open f2=^input2;

open crr1=^corrs1;
g1=readr(crr1,rowsf(crr1));
open crr2=^corrs2;
w1=inv(readr(crr2,rowsf(crr2)));

@Optimization routine@

__output=2;
_opalgr=2;
if (industry==6) or (industry==7) or (industry==8); 
_opgtol=0.01;
else;
_opgtol=0.0001;
endif;
if optimal==0;
_opmiter=40;
else;
_opmiter=60;
endif;    
{b,fc,g,retcode}=optmum(&fv,startv);
proc fv(x);
{d,fc,zw,ze,a,zeez}=compute(x);
retp(fc);
endp;

@Computing standard errors@

final=1;
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

@Saving productivity@
	
if optimal==0;
call saved(ftd,funcd,0);
denom=sumc(ftl[.,12:13]./=0);
ftl=ftl~(sumc(ftl[.,12:13])./denom)'.*ones(rows(ftl),2);	
call saved(ftl,funcl,0);
endif;

@Procedure specifying equations and moments and computing the objective@
proc(6)= compute(b);
local iob,y,ct,hh,z,e,ze,zy,zz,zeez,w,ww,sz,sz1,sigma,
pm,pm1,p,p1,out,out1,lab,lab1,cap,cap1,mat,mat1,wg,wg1,ms,ms1,msc,tw,tw1,sb1,sub,sub1,
dums,md,md1,rind,r,r1,ninc,lan,gam,bk,scale,btw,ze1,dlxds,dlx1ds,dhds,dpol0,dpol1,dzeds,dsubdg,dsub1dg,dlxdg,dlx1dg,dhdg,dzedg,ggam,zee,
etab,u1,u2,etav,etav1,eta,eta1,x,x1,mr,mr1,eps,lx,lx1,lmr,lmr1,trend,trend1,tobs,sec,tau,
wb1,ws1,wb2,ws2,wb3,ws3,wb4,ws4,wh,el,dis1,dis2,splt,wbi1,wsi1,wbi2,wsi2,wbi3,wsi3,wbi4,wsi4,whi,eli,dis1i,dis2i,split,mso,mso1,sbt,subt,fx,fgd,fgl,fg,
rd,rd1,drop1,drop2,keep,cdwl,cdwh,cdwsel,    
elas,elas2,omgl,domgl,oeomgl,omgh,domgh,domg,idsb,idr,dlmr,twt,idrd,
nfg,nfgi,newfg,it,nt,wl,wo,wi,ol,e2,e21,e2j,oel,oel1,oelmm,oel1mm,ohh,oh,oh1,ohm,cto,cth,ctoh,oelm;

sigma=slg[1];
lan=slg[2:4];
gam=slg[5:7];    

bk=b[1];
scale=b[2];
etab=b[3:8];
btw=b[9:11];
 
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
  
  sz=lev(59,0);
  sz1=lev(59,1);

  ct=ones(t-1,1);
  dums=lev(28,0)~lev(29,0)~lev(30,0)~lev(31,0)~lev(32,0)~lev(33,0)~lev(34,0)
       ~lev(35,0)~lev(36,0)~lev(37,0)~lev(38,0)~lev(39,0)~lev(40,0)~lev(41,0)
       ~lev(42,0);
  trend=seqa(iob+1,1,t-1);
  trend1=trend-1;

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


  if (industry==2) or (industry==3) or (industry==10);
  tw=(lev(88,0).<=0.95).*lev(88,0)+(lev(88,0).>0.95)*0.95;
  tw1=(lev(88,1).<=0.95).*lev(88,1)+(lev(88,1).>0.95)*0.95;
  else;
  tw=(lev(88,0).<=0.95).*lev(88,0)+(lev(88,0).>0.95)*0.95;
  tw1=(lev(88,1).<=0.95).*lev(88,1)+(lev(88,1).>0.95)*0.95;
  tw=ln((tw.==0)+(tw.>0).*(tw./(1-tw)));
  tw1=ln((tw1.==0)+(tw1.>0).*(tw1./(1-tw1)));
  
  endif;  

  md=lev(81,0);
  md1=lev(81,1);

  sb=(lev(64,0).<=0.95).*lev(64,0)+(lev(64,0).>0.95)*0.95;
  sb1=(lev(64,1).<=0.95).*lev(64,1)+(lev(64,1).>0.95)*0.95;

  rind=lev(50,1)./=0;
  r=lev(50,0);
  r1=lev(50,1);

  u1=p1;
  u2=md1;
  etav1=u1~10*(u1^2)~100*(u1^3)~u2@~(u2^2)~(u2^3)@
       ~10*(u1.*u2)~100*((u1^2).*u2)@~(u1.*(u2^2))@;
  eta1=1+exp(etav1*etab);
  mr1=1-(1/eta1);  
  
  ms=exp(pm+mat)./(exp(wg+lab)+exp(pm+mat));
  ms1=exp(pm1+mat1)./(exp(wg1+lab1)+exp(pm1+mat1));

  ms=(1-ms)./ms;
  ms1=(1-ms1)./ms1;
    
  sub=(sb~(sb^2)~(sb^3))*(gam/sigma);
  sub1=(sb1~(sb1^2)~(sb1^3))*(gam/sigma);
    
  x=bk*exp((-(1-sigma)/sigma)*cap)+(1-bk)*(1+ms.*(pol1(tw)*btw)).*exp((-(1-sigma)/sigma)*mat).*exp(sub);
  x1=bk*exp((-(1-sigma)/sigma)*cap1)+(1-bk)*(1+ms1.*(pol1(tw1)*btw)).*exp((-(1-sigma)/sigma)*mat1).*exp(sub1);
  
  eps=(1e-10)*ones(rows(x),1);
  lx=ln(maxc((x~eps)'))+(x.<=eps).*((x./eps)-1);
  lx1=ln(maxc((x1~eps)'))+(x1.<=eps).*((x1./eps)-1);
  lmr1=ln(maxc((mr1~eps)'))+(mr1.<=eps).*((mr1./eps)-1);


  @Equation 15 and instruments@
   
  hh=(1/sigma)*mat1+(pm1-p1-lmr1)+(1+(scale*sigma/(1-sigma)))*lx1-sub1;

  y=out+(scale*sigma/(1-sigma))*lx;
   
  w=ct~dums~((1-rind).*pol1(hh))~rind~(rind.*pol2(hh,r1));
 
 
 z=ct~dums~rind~pol1(pm1-p1)~pol1(p1)
    ~(1-rind).*pol2(exp(mat1).*ms1,exp(cap1))
    ~rind.*pol2(exp(mat1).*ms1,exp(cap1))~pol1(r1);
 
 if (industry==3);
 z=z~cap~pol1(tw1);
 elseif (industry==4) or (industry==8);
 z=z~cap~md~pol1(tw1);
 elseif (industry==5);
 z=z~pol1(cap)~pol1(tw1);
 else;
 z=z~pol1(cap)~md;
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
     d=invswp(zw'aopt*zw)*zw'aopt*zy;
  endif;
  
@Second loop: preparing computation of the objective func.@  

clear ze,zw,zeez;
tobs=0;i=0;obs=0;
call seekr(f,1);
call seekr(f2,1);  
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
  x=delif(x,ninc.==1);
  x1=delif(x1,ninc.==1);
  cap=delif(cap,ninc.==1);
  cap1=delif(cap1,ninc.==1);
  ms=delif(ms,ninc.==1);
  ms1=delif(ms1,ninc.==1);
  tw=delif(tw,ninc.==1);
  tw1=delif(tw1,ninc.==1);
  mat=delif(mat,ninc.==1);
  mat1=delif(mat1,ninc.==1);
  sub=delif(sub,ninc.==1);
  sub1=delif(sub1,ninc.==1);
  lx=delif(lx,ninc.==1);
  lx1=delif(lx1,ninc.==1);
  hh=delif(hh,ninc.==1);
  r1=delif(r1,ninc.==1);
  sb=delif(sb,ninc.==1);
  sb1=delif(sb1,ninc.==1);
  rind=delif(rind,ninc.==1); 
  if scalmiss(y);
      i=i-1;
     tobs=tobs+t;
     continue;
  endif;
  obs=obs+rows(y); 
	 
	e=y-w*d;
    ze=ze+z'e;
    zw=zw+z'w;
  
      
  if sdcorr==1;
	  
	  ze1=readr(f2,74); 
	  
	  dlxds=(1./(x*sigma^2)).*(bk*cap.*exp((-(1-sigma)/sigma)*cap)+(1-bk)*(1+ms.*(pol1(tw)*btw)).*mat.*exp((-(1-sigma)/sigma)*mat).*exp(sub)
	  -(1-bk)*(1+ms.*(pol1(tw)*btw)).*exp((-(1-sigma)/sigma)*mat).*(sigma*sub).*exp(sub));
	  dlx1ds=(1./(x1*sigma^2)).*(bk*cap1.*exp((-(1-sigma)/sigma)*cap1)+(1-bk)*(1+ms1.*(pol1(tw1)*btw)).*mat1.*exp((-(1-sigma)/sigma)*mat1).*exp(sub1)
	  -(1-bk)*(1+ms1.*(pol1(tw1)*btw)).*exp((-(1-sigma)/sigma)*mat1).*(sigma*sub1).*exp(sub1));
	  
	  dhds=-(1/sigma)*mat1+(scale/(1-sigma)^2)*lx1+(1+scale*sigma/(1-sigma))*dlx1ds+(1/sigma^2)*(sigma*sub1);
	  
	  dpol0=d[17]+2*d[18]*hh+3*d[19]*hh^2;
	  dpol1=d[21]+2*d[22]*hh+3*d[23]*hh^2+d[27]*r1+2*d[28]*hh.*r1+d[29]*r1^2;
	   
	  dzeds=z'((scale/(1-sigma)^2)*lx+(scale*sigma/(1-sigma))*dlxds-(1-rind).*dpol0.*dhds-rind.*dpol1.*dhds);
	  
	  dsubdg=(1/sigma)*(sb~(sb^2)~(sb^3));
	  dsub1dg=(1/sigma)*(sb1~(sb1^2)~(sb1^3));
	  dlxdg=dsubdg.*((1-bk)*(1+ms.*(pol1(tw)*btw)).*exp((-(1-sigma)/sigma)*mat).*exp(sub));
	  dlx1dg=dsub1dg.*((1-bk)*(1+ms1.*(pol1(tw1)*btw)).*exp((-(1-sigma)/sigma)*mat1).*exp(sub1));
	  dhdg=(1+scale*sigma/(1-sigma))*dlx1dg-dsub1dg;
	  
	  dzedg=z'((scale*sigma/(1-sigma))*dlxdg-(1-rind).*dpol0.*dhdg-rind.*dpol1.*dhdg);
	  
	  ggam=dzeds~zeros(rows(dzeds),3)~dzedg~zeros(rows(dzeds),29);
	  	  
	  zee=z'e-ggam*inv(g1'w1*g1)*g1'w1*ze1;
	  zeez=zeez+zee*zee';
		    	  
  elseif sdcorr==0;
	  
	  zeez=zeez+z'e*e'*z;
      
  endif;
	   
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

if optimal==0;  
if final==1;

@Third loop: computing productivity@
    
wb1={};ws1={};wb2={};ws2={};wb3={};ws3={};wb4={};ws4={};wh={};el={};dis1={};dis2={};splt={};ftd={};ftl={};
e2={};e21={};ol={};oel={};oel1={};ohh={};oh={};oh1={};
cdwl={};cdwh={};    
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
  
  wbi1=zeros(17,1);
  wsi1=zeros(17,1);
  wbi2=zeros(17,1);
  wsi2=zeros(17,1);     
  wbi3=zeros(17,1);
  wsi3=zeros(17,1);
  wbi4=zeros(17,1);
  wsi4=zeros(17,1);
  whi=zeros(17,1);
  eli=zeros(17,1);
  dis1i=zeros(17,1);
  dis2i=zeros(17,1);
  split=zeros(17,1);
    
     sz=v[1,25];

     dums=v[.,28]~v[.,29]~v[.,30]~v[.,31]~v[.,32]~v[.,33]~v[.,34]
         ~v[.,35]~v[.,36]~v[.,37]~v[.,38]~v[.,39]~v[.,40]~v[.,41]
         ~v[.,42];

     etav=v[.,69]~10*(v[.,69]^2)~100*(v[.,69]^3)~v[.,81]~10*(v[.,69].*v[.,81])~100*((v[.,69]^2).*v[.,81]);
     eta=1+exp(etav*etab);
     lmr=ln(1-(1/eta));
     
     dlmr=lmr[2:t]-lmr[1:t-1];
     dlmr=((dlmr.>-0.15) .and (dlmr.<0.15)).*dlmr+(dlmr.<=-0.15)*(-0.15)+(dlmr.>=0.15)*0.15;
     
     tau=2;                                            @making the level compatibe with the difference@
	 do while tau<=t;
		lmr[tau]=lmr[tau-1]+dlmr[tau-1];
     tau=tau+1;
     endo;    		 

     if (industry==2) or (industry==3) or (industry==10);
     tw=(v[.,88].<=0.95).*v[.,88]+(v[.,88].>0.95)*0.95;
     twt=v[.,88];
     twt=ln((twt.==0)+(twt.>0).*twt);
     else;
     tw=(v[.,88].<=0.95).*v[.,88]+(v[.,88].>0.95)*0.95;
     tw=ln((tw.==0)+(tw.>0).*(tw./(1-tw)));
     twt=(v[.,88].<=0.95).*v[.,88]+(v[.,88].>0.95)*0.95;
     twt=ln((twt.==0)+(twt.>0).*(twt./(1-twt)));
     endif;  
        
     ms=exp(v[.,62])./(exp(v[.,72]+v[.,61])+exp(v[.,62]));
     ms=(1-ms)./ms;
     ms1=ms[1:t-1];

     mso=exp(v[.,62])./(exp(v[.,72]+v[.,61])+exp(v[.,62]));
     mso1=mso[1:t-1];

     sbt=(v[.,64].<=0.95).*v[.,64]+(v[.,64].>0.95)*0.95;        
     subt=sbt;
     subt=(subt~(subt^2)~(subt^3))*(gam/sigma); 
         
     fx=bk*exp((-(1-sigma)/sigma)*v[.,46])+(1-bk)*(1+(ms.*(pol1(tw)*btw))).*exp((-(1-sigma)/sigma)*(v[.,62]-v[.,74])).*exp(subt);
     lx=ln(fx);
            
     @hicksian productivity (up to lmr)@
        
     omgh=(1/sigma)*(v[.,62]-v[.,74])+v[.,74]-v[.,69]-subt+(1+(scale*sigma/(1-sigma)))*lx;                 
     
     @labor-saving productivity@        
    
     omgl=(1/(1-sigma))*(v[.,62]-v[.,74]-v[.,61]+sigma*(v[.,74]-v[.,72])-pol1(twt)*lan-sigma*subt);

     @elas using observed mshare, at t-1 and t-2@
     elas=( scale*(1-mso))./(1+(bk/(1-bk)).*mso.*exp( ((1-sigma)/sigma)*(v[.,62]-v[.,74]-v[.,46]) ).*exp(-subt) );         
     elas2=0|0|elas[1:t-2];                                                                                    
           
     @growth@      
           
     domgl=(0|(omgl[2:t]-omgl[1:t-1]));               @labor saving productivity@
   
     oeomgl=elas2.*(0|(omgl[2:t]-omgl[1:t-1]));       @labor saving output effect@
        
     domgh=(0|omgh[2:t]-omgh[1:t-1])-(0|dlmr);        @hicks neutral productivity@
     
     domg=oeomgl+domgh;                               @total@ 
    
     ninc=(lev(88,0).==0) .or (lev(88,1).==0);
     ninc=0|ninc;
     domgl=substute(domgl,ninc,0);
     oeomgl=substute(oeomgl,ninc,0);
     domgh=substute(domgh,ninc,0);
     domg=substute(domg,ninc,0);
         
     wbi1[iob:iob+t-1]=domgl*sz;
     wsi1[iob:iob+t-1]=domgl*(1-sz);
     wbi2[iob:iob+t-1]=oeomgl*sz;
     wsi2[iob:iob+t-1]=oeomgl*(1-sz);
     wbi3[iob:iob+t-1]=domgh*sz;
     wsi3[iob:iob+t-1]=domgh*(1-sz);
     wbi4[iob:iob+t-1]=domg*sz;
     wsi4[iob:iob+t-1]=domg*(1-sz);
     whi[iob+2:iob+t-1]=trimr(exp(lev(3,1)),0,1);
     eli[iob:iob+t-1]=elas2;
     dis1i[iob:iob+t-1]=v[.,50]./=0;
     dis2i[iob:iob+t-1]=v[.,64].>0;
     
     idsb=(sb1.>0) .or (sb.>0);
     idrd=rind;         
     split[iob+1:iob+t-1]=idrd;       @R&D1>0@
          
     wb1=wb1~wbi1;
     ws1=ws1~wsi1;
     wb2=wb2~wbi2;
     ws2=ws2~wsi2;
     wb3=wb3~wbi3;
     ws3=ws3~wsi3;
     wb4=wb4~wbi4;
     ws4=ws4~wsi4;
     wh=wh~whi;
     el=el~eli;
     dis1=dis1~dis1i;
     dis2=dis2~dis2i;     
     splt=splt~split;
           
     fgd=v[.,1]~v[.,2]~v[.,3]~(sz*ones(t,1))~v[.,50]~v[.,64]~v[.,88]~v[.,100]~v[.,101]~elas~elas2~domgl~domgh;
     ftd=ftd|fgd;
   
     fgl=v[.,1]~v[.,2]~v[.,3]~(sz*ones(t,1))~v[.,50]~v[.,64]~v[.,88]~v[.,100]~v[.,101]~elas~elas2~omgl~(omgh-lmr);
     ftl=ftl|fgl;
   
                     
tobs=tobs+t;
endo;

endif;
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

fn lev(c,lag)=v[2-lag:t-lag,c];

str=etstr(hsec-start);

print;
print "Execution time is  ";;print $str;
end;

stvalues:
startv1=0.232|0.941|-1.247|-0.526|0.029|-0.048|-0.360|0.869|-0.022|0.271|0.028;
startv2=0.225|0.911|13.680|7.351|0.154|2.988|-0.948|-1.062|1.131|-3.817|1.971;
startv3=0.137|0.933|3.727|0.466|-0.304|0.517|-0.778|0.084|1.092|-3.242|2.344;
startv4=0.138|0.806|-15.028|-2.939|-0.539|-0.351|2.797|0.277|-0.043|0.138|0.022;
startv5=0.132|0.848|0.065|-1.491|-0.354|2.230|-0.648|0.706|-0.042|0.004|0.006;
startv6=0.307|0.923|5.228|1.347|-0.491|0.444|-0.591|-0.779|-0.031|-0.052|-0.013;
startv7=0.303|0.931|0.585|0.898|-0.019|0.481|-0.295|-0.248|0.012|-0.003|0.001;
startv8=0.066|0.976|-4.449|-0.003|0.027|0.292|0.080|-0.052|0.010|-0.002|-0.002;
startv9=0.103|0.932|2.041|-2.039|-0.577|-0.448|1.190|0.627|0.009|-0.014|0.002;
startv10=0.233|0.939|7.268|0.707|-0.047|-0.155|-0.792|-0.063|1.053|-1.827|1.039;
startv=startv1~startv2~startv3~startv4~startv5~startv6~startv7~startv8~startv9~startv10;    
return;



