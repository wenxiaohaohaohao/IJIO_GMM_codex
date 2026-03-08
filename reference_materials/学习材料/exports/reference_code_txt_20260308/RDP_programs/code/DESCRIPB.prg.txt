new;
start=hsec;

input="data\\data";
mt=17;
{tints,iobs}=countt(input);
n=rows(tints);
open f=^input;
output file=descripb.out reset;

entexit=zeros(10,2);
maxdif=zeros(10,3);
vmaxdif=zeros(10,3);
nmd=zeros(10,1);

i=1;j=0;obs=0;
do while i<=rows(tints);
  iob=iobs[i];
  t=tints[i];
  v=readr(f,t);
    
  sec=v[1,4:23]*seqa(1,1,20);
if (sec==12) or (sec==13);
   sector=1;
elseif (sec==11);
   sector=2;
elseif (sec==9) or (sec==10);
   sector=3;
elseif (sec==14);
   sector=4;
elseif (sec==15) or (sec==16);
   sector=5;
elseif (sec==17) or (sec==18);
   sector=6;
elseif (sec==1) or (sec==2) or (sec==3);
   sector=7;
elseif (sec==4) or (sec==5);
   sector=8;
elseif (sec==6) or (sec==19);
   sector=9;
elseif (sec==7) or (sec==8);
   sector=10;
else;
   i=i+1;   
   continue;
endif;

  
if sumc(v[.,100].==1)>0;
   entexit[sector,1]=entexit[sector,1]+1;
endif;
if sumc(v[.,101].==1)>0;
   entexit[sector,2]=entexit[sector,2]+1;
endif;

mdst=maxc(v[.,88])-minc(v[.,88]);
mdth=maxc(v[.,61])-minc(v[.,61]);
mdh=maxc(v[.,60])-minc(v[.,60]);


maxdif[sector,1]=maxdif[sector,1]+mdst;
maxdif[sector,2]=maxdif[sector,2]+mdth;
maxdif[sector,3]=maxdif[sector,3]+mdh;

nmd[sector]=nmd[sector]+1;

i=i+1;
j=j+1;
obs=obs+t-1;

endo;

print;
format /rd 6,0;
print "Entrants Exitors";
print entexit;
print;
format /rd 6,3;
print "Intrafirm max-min (dif of logs)";
print "Share   Hours   H. per worker";
print (maxdif./nmd);
print; 

proc(2)=countt(file);
local f,tints,v,iobs,t;
open f=^file for read;
  tints={};
  v=readr(f,1);
  iobs=v[.,1]-1990+1;
  t=2;
  call seekr(f,2);
  do until eof(f);
     v=readr(f,1);
     if t<=v[.,2];
     t=t+1;
     else;
     tints=tints|(t-1);
     iobs=iobs|v[.,1]-1990+1;
     t=2;
     endif;
  endo;
  tints=tints|(t-1);
  retp(tints,iobs);
closeall;
endp;

str=etstr(hsec-start);
"Execution time is  ";;print $str;
print;
end;

