new;
declare industry;
closeall;
output file=ratecorrel.out on;

rcorr={};

industry=1;
do while industry<=10;

industries=ftos(industry,"%*.*lf",1,0);
input="dprod/g"$+industries;
open f=^input;
 
@year, obs, output, size,  rd,  sub, tmw, entry, exit elas, elas2, domgL, domgH@
@ 1     2     3      4     5     6    7    8       9   10    11     12      13@    
 

domgl={};domgh={};

j=0;tobs=0;
do until eof(f);
       call seekr(f,tobs+1);
       v=readr(f,1);
       t=v[.,2];
       v=v|(readr(f,t-1));
	
wl=v[.,11].*v[.,12];	
wh=v[.,13];
	
rd=v[.,5];rd1=0|rd[1:t-1];
sub=v[.,6];sub1=0|sub[1:t-1];

drop1=((rd1.==0) .and (rd./=0)) .or ((rd1./=0) .and (rd.==0));
drop2=((sub1.==0) .and (sub./=0)) .or ((sub1./=0) .and (sub.==0));
keep=(1-drop1).*(1-drop2);	
wl=wl.*keep;
wh=wh.*keep;

domgl=domgl|wl;	
domgh=domgh|wh;	

tobs=tobs+t;
j=j+1;
endo;

format /rd 6,3;
omglsel=domgl;
domgl=delif(domgl,omglsel.==0);domgh=delif(domgh,omglsel.==0);
rcorr=rcorr|meanc((domgl-meanc(domgl)).*(domgh-meanc(domgh)))/(stdc(domgl)*stdc(domgh));

industry=industry+1;
closeall;
endo;

print;
print "Correlation between the growth of the output-effect of labor-augmenting productivity
                   and the growth of Hicksian productivity";
print rcorr;
print;

end;

