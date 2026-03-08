new;
closeall;
output file=levcorr.out on;

corrlev={};
quantsol={};
quantsh={};

industry=1;
do while industry<=10;

industries=ftos(industry,"%*.*lf",1,0);
input="lprod/g"$+industries;
open f=^input;
   
@year, obs, out,  size,  rd, sub, twp, entry, exit  elas, elas2, omgL, omgH, momgL, momgH@
@ 1     2     3     4     5   6    7    8      9     10    11     12    13    14     15 @    

ol={};e2={};e21={};
oel={};oel1={};
ohh={};oh={};oh1={};	
    
j=0;tobs=0;
do until eof(f);
       call seekr(f,tobs+1);
       v=readr(f,1);
       t=v[.,2];
       v=v|(readr(f,t-1));
           
       fg=v[.,1]~v[.,2]~v[.,12]~(v[.,11].*v[.,12])~v[.,13]~v[.,11];
	 
       twpo=v[.,7];twp=twpo[2:t];twp1=twpo[1:t-1];   
       ninc=(twp.==0) .or (twp1.==0);
       if sumc(ninc)>0;
	   newfg={};	 
	   i=1;
		  nfg={}; 
	      do while i<=t;
			 nfgi=fg[i,.];  
			 if v[i,7]>0;
	            nfg=nfg|nfgi;
                i=i+1;
                continue;
			 else;
                if rows(nfg)>1;
                nfg[.,2]=rows(nfg)*ones(rows(nfg),1);
                newfg=newfg|nfg;
				endif;
				nfg={};
				i=i+1;
		     endif; 	 
	      endo;
		  if rows(nfg)>1;
          nfg[.,2]=rows(nfg)*ones(rows(nfg),1);
          newfg=newfg|nfg;
		  endif;
		  
	   fg=newfg;
       endif;    

	   it=1;
       do while it<=rows(fg);
       nt=fg[it,2];     
       wl=fg[it:it+nt-1,3];
       wo=fg[it:it+nt-1,4];    
       wi=fg[it:it+nt-1,5];
       e2j=fg[it:it+nt-1,6];    
           
       ol=ol|wl;    
       e2=e2|e2j[2:nt];
       e21=e21|e2j[1:nt-1];    
       oel=oel|wo[2:nt];
       oel1=oel1|wo[1:nt-1];    
       ohh=ohh|wi;	
       oh=oh|wi[2:nt];
       oh1=oh1|wi[1:nt-1];               
                    
       it=it+nt;
       endo; 
	
tobs=tobs+t;
j=j+1;
endo;

e2=delif(e2,(oel.==0) .and (oel1.==0));
e21=delif(e21,(oel.==0) .and (oel1.==0));
oelmm=delif(oel,(oel.==0) .and (oel1.==0));
oel1mm=delif(oel1,(oel.==0) .and (oel1.==0));
oelmm=oelmm-e2*meanc(ol);
oel1mm=oel1mm-e21*meanc(ol);
cto=meanc((oelmm-meanc(oelmm)).*oel1mm)/(stdc(oelmm)*stdc(oel1mm));
cth=meanc((oh-meanc(oh)).*oh1)/(stdc(oh)*stdc(oh1));
oelm=delif(oel,oel.==0);
oelm=oelm-e2*meanc(ol);
ohm=delif(oh,oel.==0);
ctoh=meanc((oelm-meanc(oelm)).*ohm)/(stdc(oelm)*stdc(ohm));
quantsolk=quantile(oelm,0.1|0.25|0.5|0.75|0.9)';
ohh=ohh-meanc(ohh);
quantshk=quantile(ohh,0.1|0.25|0.5|0.75|0.9)';

corrlev=corrlev|(cto~cth~ctoh);
quantsol=quantsol|quantsolk~(quantsolk[.,4]-quantsolk[.,2]);
quantsh=quantsh|quantshk~(quantshk[.,4]-quantshk[.,2]);


industry=industry+1;
closeall;
endo;

format /rd 8,3;
print;
print "Autocorrelacions and corr. across firms and time:";
print;
print "      omgL      omgH     omgl-omgH ";
print corrlev;
print;
print;
print "Quantiles (0.1,0.25,0.5,0.75,0.90) and IQR";
print;
print "Output effect of labor augmenting";
print quantsol;
print;
print "Hicks-neutral";
print quantsh;


end;

