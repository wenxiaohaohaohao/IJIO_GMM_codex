
new;
cls;
library optmum;
optset;

output file=function_our_exogenous/GMM23_east_middle_core_ccity_entrant_ind9.out on;

@----------------Program options----------------------------------------@

instru=4;       @instru=0-11,instruments@

itait=1;        @itait=0, ita is the same over time for a firm; itait=1, using PAVCM to estimate markdown ij @

deltacancel=0;  @deltacancel=0,delta cancelled, do not control ta1, ta2, and ta3; deltacancel=1,delta don't cancelled, control ta1, ta2, and ta3@

requation=0;    @requation=0, direct revunue equation; requation=1, revunue equation using marginal cost@

avgid=1;    @1,not control labor adjustment cost in the first step; 2, control in first but no in the other; 3, control in both case@

onlyfirst=0;      @ =0, run both the first and second step of GMM, onlyfirst=1, only run the first step of GMM@

keep=0;           @1=keeps coeffs. and vars.@
keepg=1;          @1=keeps markdown and productivity@

flag=8;
do until flag>8;

if (flag==44) or (flag==45) or (flag==46) or (flag==76) or (flag==77) or (flag==78) or (flag==82) or (flag==83) or (flag==84) or (flag==87);
   flag=flag+1;
   continue;
endif; 

closeall;
start=hsec;
industry=flag;
print;
print "Sector:";;industry;

industry=flag;       @0=all industries@
ind=ftos(industry,"%*.*lf",1,0);
inst=ftos(instru,"%*.*lf",1,0);

@------Reading inputs here------@
input="data\\sdata"$+ind;
@input="data\\sdatapart"$+ind;@
open f=^input;

@------Selecting industry with enough samples------@
whole=readr(f,rowsf(f));
if rows(whole)<=301;
   flag=flag+1;
   continue;
endif;    

print "instrument:";;instru;
@print "optimal=:";;optimal;
print para1;@
print "_opgtol=0.001";
print "pavcm_Pmit_selc2_rate";
print "control selection,pol2_2(omiga1,pros1)";    
print "Take firm-level material price Pmit into account";    
print "use c0, remove mean from omiga";    
print "effective labor";  
print "amount devided by 1000";
@print "entrant:younger than 5 years old";@
print "demand shifter control: scost,east,middle,core,ccity,entrant";

@------save outputs of second step weights zeez here------@
mtx="function_our_exogenous\\zeez_instru4_"$+ind;

@------save outputs here------@
cffs="function_our_exogenous\\parameter_instru4_"$+ind;
omi="function_our_exogenous\\g_instru4_"$+ind;

declare d,zw,ze,a,zeez,nu; 

@------Naming nonlinear and concentrated out parameters------@
if deltacancel==0;
   nlpms="bk"~"bkk"~"b[3]"~"bsc"~"east"~"middle"~"core"~"ccity"~"entrant"~"bs";
   @bsc1, coeffcients of sales effort@
   @a0,a1, constant lag omiga@
   @a1-a9, coeffcients of demand shfters: east(a1),middle(a2),export(a3),core(a4),ccity(a5),entrant(a6),exiter(a7),subsidy(a8) and soe(a9)@
   @ta-ta3, coeffcients in the series approximation of unknown function of vertical differentiation@
else;
   nlpms="bk"~"bkk"~"b[3]"~"bsc"~"east"~"middle"~"core"~"ccity"~"entrant"~"a0"~"bs"~"ta1"~"ta2"~"ta3";
endif;


copms="c0"~"gama1"~"gama2"~"gama3"~"gama4"~"gama5"~"gama6"~"gama7"~"gama8"@~"gama9"~"gama10"~"gama11"~"gama12"~"gama13"~"gama14"@~"thida1"~"thida2"~"thida3"@~"thida4"~"thida5"~"thida6"~"thida7"~"thida8"~"thida9"@;
   @c0,c1, constant in revenue equation@
   @gama1-gama14, time dummies@
   @thida1-thida9, 9 coeffcients of last period productivity in the series approximation of unknown function@
   @b1-b3, 3 coeffcients of quality 'delta' as the unknown function of ita, b1 also absorbs constant in unknown function of omiga and  base year (1999)@
namex=nlpms~copms;

@------Selecting complete sequences------@
uu=whole[.,cols(whole)];
vv=selif(whole,uu);

@------u is the 0-1 vector that tells the samples we can use in estimating parameters, =0 for the first year observation of each firm------@
data=vv;
u=ones(rows(data),1);
u[1]=0;
i=2;
do while i<=rows(data);
  if data[i,1]/=data[i-1,1];
     u[i]=0;
  elseif data[i,2]/=data[i-1,2]+1;
     u[i]=0;
  endif;
i=i+1;
endo;

@------Cauculating firms of parameter estimation------@
vvu=selif(vv,u);
ju=1;index1=2;
do until  index1>=rows(vvu);
  if vvu[index1,1]/=vvu[index1-1,1];
      ju=ju+1;
  endif;
  index1=index1+1;
endo;
clear whole,data,vvu;

format /rd 6,0;
print "No. of firms in parameter estimation:";;ju;
obsu=selif(u,u);
print "No. of observations in parameter estimation:";;rows(obsu);

@------define variables for parameter estimation--------------------------------------------------------------------------@

sratio=vv[.,18];
sratio1=0|sratio[1:rows(sratio)-1];

ct=ones(rows(vv),1);
td=vv[.,56:63];

east=vv[.,13];
east1=0|east[1:rows(east)-1];

middle=vv[.,14];
middle1=0|middle[1:rows(middle)-1];

ccity=vv[.,15];
ccity1=0|ccity[1:rows(ccity)-1];

core=vv[.,16];
core1=0|core[1:rows(core)-1];

export1step=vv[.,11]./vv[.,66];
export=vv[.,11].>0;
export1=0|export[1:rows(export)-1];

exiter=vv[.,32];
exiter1=0|exiter[1:rows(exiter)-1];

entrant=vv[.,31];
entrant1=0|entrant[1:rows(entrant)-1];

age=vv[.,2]-vv[.,9];
age1=0|age[1:rows(age)-1];

@subsidy=vv[.,72].>0;@
subsidy=vv[.,72]./vv[.,28];
subsidy1=0|subsidy[1:rows(subsidy)-1];

@soe=(vv[.,70]+vv[.,71]).>0;
soe=(vv[.,70]+vv[.,71])./vv[.,39];@
soe=(vv[.,30].==110) .or (vv[.,30].==120) .or (vv[.,30].==141) .or (vv[.,30].==142) .or (vv[.,30].==143) .or (vv[.,30].==151);
soe1=0|soe[1:rows(soe)-1]; 
 
r=ln(vv[.,66]/1000);
r1=0|r[1:rows(r)-1];

p=ln(vv[.,45]);
p1=0|p[1:rows(p)-1];

pm=ln(vv[.,46]);
pm1=0|pm[1:rows(pm)-1];

em=ln((vv[.,42]+vv[.,33])/1000);
em1=0|em[1:rows(em)-1];

m=em-pm;
m1=0|m[1:rows(m)-1];

scost1step=vv[.,38]./vv[.,66];
scost=ln(vv[.,38]/1000);
@scost=(vv[.,38]./vv[.,37]);@
scost1=0|scost[1:rows(scost)-1];

k=ln(vv[.,47]/1000);
k1=0|k[1:rows(k)-1];

@l=ln(vv[.,12]);@
l=ln(vv[.,12]);
l1=0|l[1:rows(l)-1];

wage=ln(vv[.,17])-ln(vv[.,12]);
wage1=0|wage[1:rows(l)-1];

@tao=(vv[.,36]+vv[.,73])./(vv[.,66]);@
tao=vv[.,40];
tao1=0|tao[1:rows(tao)-1];

@taow=vv[.,22]./(vv[.,17]);@
taow=vv[.,26];
taow1=0|taow[1:rows(taow)-1];

@taom=vv[.,33]./(vv[.,42]+vv[.,33]);@
taom=vv[.,41];
taom1=0|taom[1:rows(taom)-1];

rml=vv[.,42]./vv[.,43];
rml1=0|rml[1:rows(rml)-1];
scost1step1=0|scost1step[1:rows(scost1step)-1];
pavcm=ln(vv[.,28]./vv[.,42]); 

@-------------------------------------------------------------------------------@
@---estimating the probability of continuing operation--------------------------@
@-------------------------------------------------------------------------------@
as=(vv[.,32]./=1); @as=1, the firm will stay in the sample next year p(t+1|t)=1@
xs=ones(rows(k),1)~pol4(k,l,m,scost);

bs=invpd(xs'xs)*(xs'as);
pros=xs*bs;
pros1=0|pros[1:rows(pros)-1];

@---------------------------------------------------------------------------------------------@
@---following calculate avga, choise is about itai or itait ----------------------------------@
@---------------------------------------------------------------------------------------------@

if itait==0;
  avga=vv[.,49];
  avga1=0|avga[1:rows(avga)-1];

else;
@---using PAVCM to estimate markdown ij---------------------------------------------------------@
goto below;

vardef:

@---generate time dummy------------------@
dyear=zeros(rows(vv),9);
dyear[.,1]=(vv[.,2].==2008);
dyear[.,2]=(vv[.,2].==2009);
dyear[.,3]=(vv[.,2].==2010);
dyear[.,4]=(vv[.,2].==2011);
dyear[.,5]=(vv[.,2].==2012);
dyear[.,6]=(vv[.,2].==2013);
dyear[.,7]=(vv[.,2].==2014);
dyear[.,8]=(vv[.,2].==2015);
dyear[.,9]=(vv[.,2].==2016);

@---generate 4digital industry dummy--------@
if industry==1;
  dind=zeros(rows(vv),49);  @dind[.,1]=(vv[.,7].==190):base group@
  dind[.,1]=(vv[.,7].==111);
  dind[.,2]=(vv[.,7].==112);
  dind[.,3]=(vv[.,7].==113);
  dind[.,4]=(vv[.,7].==119);
  dind[.,5]=(vv[.,7].==170);
  dind[.,6]=(vv[.,7].==122);
  dind[.,7]=(vv[.,7].==123);
  dind[.,8]=(vv[.,7].==131);
  dind[.,9]=(vv[.,7].==132);
  dind[.,10]=(vv[.,7].==133);
  dind[.,11]=(vv[.,7].==134);
  dind[.,12]=(vv[.,7].==141);
  dind[.,13]=(vv[.,7].==142);
  dind[.,14]=(vv[.,7].==143);
  dind[.,15]=(vv[.,7].==149);
  dind[.,16]=(vv[.,7].==151);
  dind[.,17]=(vv[.,7].==152);
  dind[.,18]=(vv[.,7].==153);
  dind[.,19]=(vv[.,7].==159);
  dind[.,20]=(vv[.,7].==161);
  dind[.,21]=(vv[.,7].==162);
  dind[.,22]=(vv[.,7].==169);
  dind[.,23]=(vv[.,7].==252);
  dind[.,24]=(vv[.,7].==211);
  dind[.,25]=(vv[.,7].==212);
  dind[.,26]=(vv[.,7].==220);
  dind[.,27]=(vv[.,7].==230);
  dind[.,28]=(vv[.,7].==241);
  dind[.,29]=(vv[.,7].==242);
  dind[.,30]=(vv[.,7].==251);
  dind[.,31]=(vv[.,7].==390);
  dind[.,32]=(vv[.,7].==311);
  dind[.,33]=(vv[.,7].==530);
  dind[.,34]=(vv[.,7].==313);
  dind[.,35]=(vv[.,7].==314);
  dind[.,36]=(vv[.,7].==529);
  dind[.,37]=(vv[.,7].==319);
  dind[.,38]=(vv[.,7].==321);
  dind[.,39]=(vv[.,7].==322);
  dind[.,40]=(vv[.,7].==521);
  dind[.,41]=(vv[.,7].==329);
  dind[.,42]=(vv[.,7].==519);
  dind[.,43]=(vv[.,7].==411);
  dind[.,44]=(vv[.,7].==412);
  dind[.,45]=(vv[.,7].==421);
  dind[.,46]=(vv[.,7].==513);
  dind[.,47]=(vv[.,7].==540);
  dind[.,48]=(vv[.,7].==511);
  dind[.,49]=(vv[.,7].==512);
  @dind[.,5]=(vv[.,7].==121);
  dind[.,5]=(vv[.,7].==163);
  dind[.,6]=(vv[.,7].==522);
  dind[.,7]=(vv[.,7].==523);
  dind[.,33]=(vv[.,7].==312);
  dind[.,36]=(vv[.,7].==215);
  dind[.,40]=(vv[.,7].==323);
  dind[.,42]=(vv[.,7].==330);
  dind[.,46]=(vv[.,7].==422);@

elseif industry==2;
  dind=zeros(rows(vv),33);  @dind[.,1]=(vv[.,7].==690):base group@
  dind[.,1]=(vv[.,7].==610);
  dind[.,2]=(vv[.,7].==620);
  dind[.,3]=(vv[.,7].==710);
  dind[.,4]=(vv[.,7].==720);
  dind[.,5]=(vv[.,7].==810);
  dind[.,6]=(vv[.,7].==820);
  dind[.,7]=(vv[.,7].==890);
  dind[.,8]=(vv[.,7].==939);
  dind[.,9]=(vv[.,7].==911);
  dind[.,10]=(vv[.,7].==912);
  dind[.,11]=(vv[.,7].==913);
  dind[.,12]=(vv[.,7].==914);
  dind[.,13]=(vv[.,7].==915);
  dind[.,14]=(vv[.,7].==919);
  dind[.,15]=(vv[.,7].==921);
  dind[.,16]=(vv[.,7].==922);
  dind[.,17]=(vv[.,7].==929);
  dind[.,18]=(vv[.,7].==931);
  dind[.,19]=(vv[.,7].==932);
  dind[.,20]=(vv[.,7].==1099);
  dind[.,21]=(vv[.,7].==1011);
  dind[.,22]=(vv[.,7].==1012);
  dind[.,23]=(vv[.,7].==1013);
  dind[.,24]=(vv[.,7].==1019);
  dind[.,25]=(vv[.,7].==1020);
  dind[.,26]=(vv[.,7].==1030);
  dind[.,27]=(vv[.,7].==1091);
  dind[.,28]=(vv[.,7].==1092);
  dind[.,29]=(vv[.,7].==1093);
  dind[.,30]=(vv[.,7].==1190);
  dind[.,31]=(vv[.,7].==1110);
  dind[.,32]=(vv[.,7].==1120);
  dind[.,33]=(vv[.,7].==1200);
  @dind[.,20]=(vv[.,7].==933);@

elseif industry==3;
  dind=zeros(rows(vv),55);  @dind[.,1]=(vv[.,7].==1310):base group@
  dind[.,1]=(vv[.,7].==1320);
  dind[.,2]=(vv[.,7].==1331);
  dind[.,3]=(vv[.,7].==1332);
  dind[.,4]=(vv[.,7].==1340);
  dind[.,5]=(vv[.,7].==1351);
  dind[.,6]=(vv[.,7].==1352);
  dind[.,7]=(vv[.,7].==1353);
  dind[.,8]=(vv[.,7].==1361);
  dind[.,9]=(vv[.,7].==1362);
  dind[.,10]=(vv[.,7].==1363);
  dind[.,11]=(vv[.,7].==1364);
  dind[.,12]=(vv[.,7].==1369);
  dind[.,13]=(vv[.,7].==1371);
  dind[.,14]=(vv[.,7].==1372);
  dind[.,15]=(vv[.,7].==1391);
  dind[.,16]=(vv[.,7].==1392);
  dind[.,17]=(vv[.,7].==1393);
  dind[.,18]=(vv[.,7].==1399);
  dind[.,19]=(vv[.,7].==1411);
  dind[.,20]=(vv[.,7].==1419);
  dind[.,21]=(vv[.,7].==1421);
  dind[.,22]=(vv[.,7].==1422);
  dind[.,23]=(vv[.,7].==1431);
  dind[.,24]=(vv[.,7].==1432);
  dind[.,25]=(vv[.,7].==1439);
  dind[.,26]=(vv[.,7].==1440);
  dind[.,27]=(vv[.,7].==1451);
  dind[.,28]=(vv[.,7].==1452);
  dind[.,29]=(vv[.,7].==1453);
  dind[.,30]=(vv[.,7].==1459);
  dind[.,31]=(vv[.,7].==1461);
  dind[.,32]=(vv[.,7].==1462);
  dind[.,33]=(vv[.,7].==1469);
  dind[.,34]=(vv[.,7].==1491);
  dind[.,35]=(vv[.,7].==1492);
  dind[.,36]=(vv[.,7].==1493);
  dind[.,37]=(vv[.,7].==1494);
  dind[.,38]=(vv[.,7].==1495);
  dind[.,39]=(vv[.,7].==1499);
  dind[.,40]=(vv[.,7].==1511);
  dind[.,41]=(vv[.,7].==1512);
  dind[.,42]=(vv[.,7].==1513);
  dind[.,43]=(vv[.,7].==1514);
  dind[.,44]=(vv[.,7].==1515);
  dind[.,45]=(vv[.,7].==1519);
  dind[.,46]=(vv[.,7].==1521);
  dind[.,47]=(vv[.,7].==1522);
  dind[.,48]=(vv[.,7].==1523);
  dind[.,49]=(vv[.,7].==1524);
  dind[.,50]=(vv[.,7].==1525);
  dind[.,51]=(vv[.,7].==1529);
  dind[.,52]=(vv[.,7].==1530);
  dind[.,53]=(vv[.,7].==1610);
  dind[.,54]=(vv[.,7].==1620);
  dind[.,55]=(vv[.,7].==1690);

elseif industry==4;
  dind=zeros(rows(vv),43); @dind[.,1]=(vv[.,7].==1711);base group@ 
  dind[.,1]=(vv[.,7].==1712);
  dind[.,2]=(vv[.,7].==1713);
  dind[.,3]=(vv[.,7].==1721);
  dind[.,4]=(vv[.,7].==1722);
  dind[.,5]=(vv[.,7].==1723);
  dind[.,6]=(vv[.,7].==1731);
  dind[.,7]=(vv[.,7].==1732);
  dind[.,8]=(vv[.,7].==1733);
  dind[.,9]=(vv[.,7].==1741);
  dind[.,10]=(vv[.,7].==1742);
  dind[.,11]=(vv[.,7].==1743);
  dind[.,12]=(vv[.,7].==1751);
  dind[.,13]=(vv[.,7].==1752);
  dind[.,14]=(vv[.,7].==1761);
  dind[.,15]=(vv[.,7].==1762);
  dind[.,16]=(vv[.,7].==1763);
  dind[.,17]=(vv[.,7].==1771);
  dind[.,18]=(vv[.,7].==1772);
  dind[.,19]=(vv[.,7].==1773);
  dind[.,20]=(vv[.,7].==1779);
  dind[.,21]=(vv[.,7].==1781);
  dind[.,22]=(vv[.,7].==1782);
  dind[.,23]=(vv[.,7].==1783);
  dind[.,24]=(vv[.,7].==1784);
  dind[.,25]=(vv[.,7].==1789);
  dind[.,26]=(vv[.,7].==1810);
  dind[.,27]=(vv[.,7].==1820);
  dind[.,28]=(vv[.,7].==1830);
  dind[.,29]=(vv[.,7].==1910);
  dind[.,30]=(vv[.,7].==1921);
  dind[.,31]=(vv[.,7].==1922);
  dind[.,32]=(vv[.,7].==1923);
  dind[.,33]=(vv[.,7].==1929);
  dind[.,34]=(vv[.,7].==1931);
  dind[.,35]=(vv[.,7].==1932);
  dind[.,36]=(vv[.,7].==1939);
  dind[.,37]=(vv[.,7].==1941);
  dind[.,38]=(vv[.,7].==1942);
  dind[.,39]=(vv[.,7].==1951);
  dind[.,40]=(vv[.,7].==1952);
  dind[.,41]=(vv[.,7].==1953);
  dind[.,42]=(vv[.,7].==1954);
  dind[.,43]=(vv[.,7].==1959);

elseif industry==5;
  dind=zeros(rows(vv),18);  @ 2029 as base group@
  dind[.,1]=(vv[.,7].==2012);
  dind[.,2]=(vv[.,7].==2013);
  dind[.,3]=(vv[.,7].==2019);
  dind[.,4]=(vv[.,7].==2021);
  dind[.,5]=(vv[.,7].==2031);
  dind[.,6]=(vv[.,7].==2032);
  dind[.,7]=(vv[.,7].==2033);
  dind[.,8]=(vv[.,7].==2034);
  dind[.,9]=(vv[.,7].==2039);
  dind[.,10]=(vv[.,7].==2041);
  dind[.,11]=(vv[.,7].==2042);
  dind[.,12]=(vv[.,7].==2043);
  dind[.,13]=(vv[.,7].==2049);
  dind[.,14]=(vv[.,7].==2110);
  dind[.,15]=(vv[.,7].==2120);
  dind[.,16]=(vv[.,7].==2130);
  dind[.,17]=(vv[.,7].==2140);
  dind[.,18]=(vv[.,7].==2190);
  @dind[.,19]=(vv[.,7].==2011);
  dind[.,20]=(vv[.,7].==2022);
  dind[.,5]=(vv[.,7].==2023);@

elseif industry==6;
  dind=zeros(rows(vv),11);  @ dind[.,1]=(vv[.,7].==2211):base group@
  dind[.,1]=(vv[.,7].==2212);
  dind[.,2]=(vv[.,7].==2221);
  dind[.,3]=(vv[.,7].==2222);
  dind[.,4]=(vv[.,7].==2223);
  dind[.,5]=(vv[.,7].==2231);
  dind[.,6]=(vv[.,7].==2239);
  dind[.,7]=(vv[.,7].==2311);
  dind[.,8]=(vv[.,7].==2312);
  dind[.,9]=(vv[.,7].==2319);
  dind[.,10]=(vv[.,7].==2320);
  dind[.,11]=(vv[.,7].==2330);

elseif industry==7;
  dind=zeros(rows(vv),66);  @ dind[.,1]=(vv[.,7].==2611);:base group@
  dind[.,1]=(vv[.,7].==2612);
  dind[.,2]=(vv[.,7].==2613);
  dind[.,3]=(vv[.,7].==2614);
  dind[.,4]=(vv[.,7].==2619);
  dind[.,5]=(vv[.,7].==2621);
  dind[.,6]=(vv[.,7].==2622);
  dind[.,7]=(vv[.,7].==2623);
  dind[.,8]=(vv[.,7].==2624);
  dind[.,9]=(vv[.,7].==2625);
  dind[.,10]=(vv[.,7].==2629);
  dind[.,11]=(vv[.,7].==2631);
  dind[.,12]=(vv[.,7].==2632);
  dind[.,13]=(vv[.,7].==2641);
  dind[.,14]=(vv[.,7].==2642);
  dind[.,15]=(vv[.,7].==2643);
  dind[.,16]=(vv[.,7].==2644);
  dind[.,17]=(vv[.,7].==2645);
  dind[.,18]=(vv[.,7].==2651);
  dind[.,19]=(vv[.,7].==2652);
  dind[.,20]=(vv[.,7].==2653);
  dind[.,21]=(vv[.,7].==2659);
  dind[.,22]=(vv[.,7].==2661);
  dind[.,23]=(vv[.,7].==2662);
  dind[.,24]=(vv[.,7].==2663);
  dind[.,25]=(vv[.,7].==2664);
  dind[.,26]=(vv[.,7].==2665);
  dind[.,27]=(vv[.,7].==2666);
  dind[.,28]=(vv[.,7].==2669);
  dind[.,29]=(vv[.,7].==2671);
  dind[.,30]=(vv[.,7].==2672);
  dind[.,31]=(vv[.,7].==2681);
  dind[.,32]=(vv[.,7].==2682);
  dind[.,33]=(vv[.,7].==2683);
  dind[.,34]=(vv[.,7].==2684);
  dind[.,35]=(vv[.,7].==2689);
  dind[.,36]=(vv[.,7].==2710);
  dind[.,37]=(vv[.,7].==2720);
  dind[.,38]=(vv[.,7].==2730);
  dind[.,39]=(vv[.,7].==2740);
  dind[.,40]=(vv[.,7].==2750);
  dind[.,41]=(vv[.,7].==2760);
  dind[.,42]=(vv[.,7].==2770);
  dind[.,43]=(vv[.,7].==2811);
  dind[.,44]=(vv[.,7].==2812);
  dind[.,45]=(vv[.,7].==2821);
  dind[.,46]=(vv[.,7].==2822);
  dind[.,47]=(vv[.,7].==2823);
  dind[.,48]=(vv[.,7].==2824);
  dind[.,49]=(vv[.,7].==2825);
  dind[.,50]=(vv[.,7].==2826);
  dind[.,51]=(vv[.,7].==2829);
  dind[.,52]=(vv[.,7].==2911);
  dind[.,53]=(vv[.,7].==2912);
  dind[.,54]=(vv[.,7].==2913);
  dind[.,55]=(vv[.,7].==2914);
  dind[.,56]=(vv[.,7].==2915);
  dind[.,57]=(vv[.,7].==2919);
  dind[.,58]=(vv[.,7].==2921);
  dind[.,59]=(vv[.,7].==2922);
  dind[.,60]=(vv[.,7].==2923);
  dind[.,61]=(vv[.,7].==2924);
  dind[.,62]=(vv[.,7].==2925);
  dind[.,63]=(vv[.,7].==2926);
  dind[.,64]=(vv[.,7].==2927);
  dind[.,65]=(vv[.,7].==2928);
  dind[.,66]=(vv[.,7].==2929);

elseif industry==8;
  dind=zeros(rows(vv),51);  @ dind[.,1]=(vv[.,7].==3110);:base group@
  dind[.,1]=(vv[.,7].==3120);
  dind[.,2]=(vv[.,7].==3130);
  dind[.,3]=(vv[.,7].==3140);
  dind[.,4]=(vv[.,7].==3150);
  dind[.,5]=(vv[.,7].==3211);
  dind[.,6]=(vv[.,7].==3212);
  dind[.,7]=(vv[.,7].==3213);
  dind[.,8]=(vv[.,7].==3214);
  dind[.,9]=(vv[.,7].==3215);
  dind[.,10]=(vv[.,7].==3216);
  dind[.,11]=(vv[.,7].==3217);
  dind[.,12]=(vv[.,7].==3219);
  dind[.,13]=(vv[.,7].==3221);
  dind[.,14]=(vv[.,7].==3222);
  dind[.,15]=(vv[.,7].==3229);
  dind[.,16]=(vv[.,7].==3231);
  dind[.,17]=(vv[.,7].==3232);
  dind[.,18]=(vv[.,7].==3239);
  dind[.,19]=(vv[.,7].==3240);
  dind[.,20]=(vv[.,7].==3250);
  dind[.,21]=(vv[.,7].==3261);
  dind[.,22]=(vv[.,7].==3262);
  dind[.,23]=(vv[.,7].==3263);
  dind[.,24]=(vv[.,7].==3264);
  dind[.,25]=(vv[.,7].==3269);
  dind[.,26]=(vv[.,7].==3311);
  dind[.,27]=(vv[.,7].==3312);
  dind[.,28]=(vv[.,7].==3321);
  dind[.,29]=(vv[.,7].==3322);
  dind[.,30]=(vv[.,7].==3323);
  dind[.,31]=(vv[.,7].==3324);
  dind[.,32]=(vv[.,7].==3329);
  dind[.,33]=(vv[.,7].==3331);
  dind[.,34]=(vv[.,7].==3332);
  dind[.,35]=(vv[.,7].==3333);
  dind[.,36]=(vv[.,7].==3340);
  dind[.,37]=(vv[.,7].==3351);
  dind[.,38]=(vv[.,7].==3352);
  dind[.,39]=(vv[.,7].==3353);
  dind[.,40]=(vv[.,7].==3359);
  dind[.,41]=(vv[.,7].==3360);
  dind[.,42]=(vv[.,7].==3371);
  dind[.,43]=(vv[.,7].==3373);
  dind[.,44]=(vv[.,7].==3379);
  dind[.,45]=(vv[.,7].==3381);
  dind[.,46]=(vv[.,7].==3382);
  dind[.,47]=(vv[.,7].==3383);
  dind[.,48]=(vv[.,7].==3389);
  dind[.,49]=(vv[.,7].==3391);
  dind[.,50]=(vv[.,7].==3392);
  dind[.,51]=(vv[.,7].==3399);
  @dind[.,17]=(vv[.,7].==3372);@

elseif industry==9;
  dind=zeros(rows(vv),95);  @ dind[.,1]=(vv[.,7].==3411);:base group@
  dind[.,1]=(vv[.,7].==3412);
  dind[.,2]=(vv[.,7].==3413);
  dind[.,3]=(vv[.,7].==3414);
  dind[.,4]=(vv[.,7].==3415);
  dind[.,5]=(vv[.,7].==3419);
  dind[.,6]=(vv[.,7].==3421);
  dind[.,7]=(vv[.,7].==3422);
  dind[.,8]=(vv[.,7].==3423);
  dind[.,9]=(vv[.,7].==3424);
  dind[.,10]=(vv[.,7].==3425);
  dind[.,11]=(vv[.,7].==3429);
  dind[.,12]=(vv[.,7].==3431);
  dind[.,13]=(vv[.,7].==3432);
  dind[.,14]=(vv[.,7].==3433);
  dind[.,15]=(vv[.,7].==3434);
  dind[.,16]=(vv[.,7].==3435);
  dind[.,17]=(vv[.,7].==3439);
  dind[.,18]=(vv[.,7].==3441);
  dind[.,19]=(vv[.,7].==3442);
  dind[.,20]=(vv[.,7].==3443);
  dind[.,21]=(vv[.,7].==3444);
  dind[.,22]=(vv[.,7].==3451);
  dind[.,23]=(vv[.,7].==3452);
  dind[.,24]=(vv[.,7].==3459);
  dind[.,25]=(vv[.,7].==3461);
  dind[.,26]=(vv[.,7].==3462);
  dind[.,27]=(vv[.,7].==3463);
  dind[.,28]=(vv[.,7].==3464);
  dind[.,29]=(vv[.,7].==3465);
  dind[.,30]=(vv[.,7].==3466);
  dind[.,31]=(vv[.,7].==3467);
  dind[.,32]=(vv[.,7].==3468);
  dind[.,33]=(vv[.,7].==3471);
  dind[.,34]=(vv[.,7].==3472);
  dind[.,35]=(vv[.,7].==3473);
  dind[.,36]=(vv[.,7].==3474);
  dind[.,37]=(vv[.,7].==3475);
  dind[.,38]=(vv[.,7].==3479);
  dind[.,39]=(vv[.,7].==3481);
  dind[.,40]=(vv[.,7].==3482);
  dind[.,41]=(vv[.,7].==3483);
  dind[.,42]=(vv[.,7].==3484);
  dind[.,43]=(vv[.,7].==3489);
  dind[.,44]=(vv[.,7].==3490);
  dind[.,45]=(vv[.,7].==3511);
  dind[.,46]=(vv[.,7].==3512);
  dind[.,47]=(vv[.,7].==3513);
  dind[.,48]=(vv[.,7].==3514);
  dind[.,49]=(vv[.,7].==3515);
  dind[.,50]=(vv[.,7].==3516);
  dind[.,51]=(vv[.,7].==3521);
  dind[.,52]=(vv[.,7].==3522);
  dind[.,53]=(vv[.,7].==3523);
  dind[.,54]=(vv[.,7].==3524);
  dind[.,55]=(vv[.,7].==3525);
  dind[.,56]=(vv[.,7].==3529);
  dind[.,57]=(vv[.,7].==3531);
  dind[.,58]=(vv[.,7].==3532);
  dind[.,59]=(vv[.,7].==3533);
  dind[.,60]=(vv[.,7].==3534);
  dind[.,61]=(vv[.,7].==3541);
  dind[.,62]=(vv[.,7].==3542);
  dind[.,63]=(vv[.,7].==3543);
  dind[.,64]=(vv[.,7].==3544);
  dind[.,65]=(vv[.,7].==3545);
  dind[.,66]=(vv[.,7].==3546);
  dind[.,67]=(vv[.,7].==3549);
  dind[.,68]=(vv[.,7].==3551);
  dind[.,69]=(vv[.,7].==3552);
  dind[.,70]=(vv[.,7].==3553);
  dind[.,71]=(vv[.,7].==3554);
  dind[.,72]=(vv[.,7].==3561);
  dind[.,73]=(vv[.,7].==3562);
  dind[.,74]=(vv[.,7].==3571);
  dind[.,75]=(vv[.,7].==3572);
  dind[.,76]=(vv[.,7].==3573);
  dind[.,77]=(vv[.,7].==3574);
  dind[.,78]=(vv[.,7].==3575);
  dind[.,79]=(vv[.,7].==3576);
  dind[.,80]=(vv[.,7].==3577);
  dind[.,81]=(vv[.,7].==3579);
  dind[.,82]=(vv[.,7].==3581);
  dind[.,83]=(vv[.,7].==3582);
  dind[.,84]=(vv[.,7].==3583);
  dind[.,85]=(vv[.,7].==3584);
  dind[.,86]=(vv[.,7].==3585);
  dind[.,87]=(vv[.,7].==3586);
  dind[.,88]=(vv[.,7].==3589);
  dind[.,89]=(vv[.,7].==3591);
  dind[.,90]=(vv[.,7].==3592);
  dind[.,91]=(vv[.,7].==3599);
  dind[.,92]=(vv[.,7].==3594);
  dind[.,93]=(vv[.,7].==3595);
  dind[.,94]=(vv[.,7].==3596);
  dind[.,95]=(vv[.,7].==3597);
  @dind[.,46]=(vv[.,7].==3593);@

elseif industry==10;
  dind=zeros(rows(vv),28);  @ dind[.,1]=(vv[.,7].==3610);:base group@
  dind[.,1]=(vv[.,7].==3620);
  dind[.,2]=(vv[.,7].==3630);
  dind[.,3]=(vv[.,7].==3640);
  dind[.,4]=(vv[.,7].==3650);
  dind[.,5]=(vv[.,7].==3660);
  dind[.,6]=(vv[.,7].==3711);
  dind[.,7]=(vv[.,7].==3712);
  dind[.,8]=(vv[.,7].==3713);
  dind[.,9]=(vv[.,7].==3714);
  dind[.,10]=(vv[.,7].==3719);
  dind[.,11]=(vv[.,7].==3720);
  dind[.,12]=(vv[.,7].==3731);
  dind[.,13]=(vv[.,7].==3732);
  dind[.,14]=(vv[.,7].==3733);
  dind[.,15]=(vv[.,7].==3734);
  dind[.,16]=(vv[.,7].==3735);
  dind[.,17]=(vv[.,7].==3739);
  dind[.,18]=(vv[.,7].==3741);
  dind[.,19]=(vv[.,7].==3742);
  dind[.,20]=(vv[.,7].==3743);
  dind[.,21]=(vv[.,7].==3749);
  dind[.,22]=(vv[.,7].==3751);
  dind[.,23]=(vv[.,7].==3752);
  dind[.,24]=(vv[.,7].==3761);
  dind[.,25]=(vv[.,7].==3762);
  dind[.,26]=(vv[.,7].==3770);
  dind[.,27]=(vv[.,7].==3791);
  dind[.,28]=(vv[.,7].==3799);

elseif industry==11;
  dind=zeros(rows(vv),68);  @ dind[.,1]=(vv[.,7].==3811);:base group@
  dind[.,1]=(vv[.,7].==3812);
  dind[.,2]=(vv[.,7].==3819);
  dind[.,3]=(vv[.,7].==3821);
  dind[.,4]=(vv[.,7].==3822);
  dind[.,5]=(vv[.,7].==3823);
  dind[.,6]=(vv[.,7].==3824);
  dind[.,7]=(vv[.,7].==3825);
  dind[.,8]=(vv[.,7].==3829);
  dind[.,9]=(vv[.,7].==3831);
  dind[.,10]=(vv[.,7].==3832);
  dind[.,11]=(vv[.,7].==3833);
  dind[.,12]=(vv[.,7].==3839);
  dind[.,13]=(vv[.,7].==3841);
  dind[.,14]=(vv[.,7].==3842);
  dind[.,15]=(vv[.,7].==3849);
  dind[.,16]=(vv[.,7].==3851);
  dind[.,17]=(vv[.,7].==3852);
  dind[.,18]=(vv[.,7].==3853);
  dind[.,19]=(vv[.,7].==3854);
  dind[.,20]=(vv[.,7].==3855);
  dind[.,21]=(vv[.,7].==3856);
  dind[.,22]=(vv[.,7].==3857);
  dind[.,23]=(vv[.,7].==3859);
  dind[.,24]=(vv[.,7].==3861);
  dind[.,25]=(vv[.,7].==3869);
  dind[.,26]=(vv[.,7].==3871);
  dind[.,27]=(vv[.,7].==3872);
  dind[.,28]=(vv[.,7].==3879);
  dind[.,29]=(vv[.,7].==3891);
  dind[.,30]=(vv[.,7].==3899);
  dind[.,31]=(vv[.,7].==3911);
  dind[.,32]=(vv[.,7].==3912);
  dind[.,33]=(vv[.,7].==3913);
  dind[.,34]=(vv[.,7].==3919);
  dind[.,35]=(vv[.,7].==3921);
  dind[.,36]=(vv[.,7].==3922);
  dind[.,37]=(vv[.,7].==3931);
  dind[.,38]=(vv[.,7].==3932);
  dind[.,39]=(vv[.,7].==3939);
  dind[.,40]=(vv[.,7].==3940);
  dind[.,41]=(vv[.,7].==3951);
  dind[.,42]=(vv[.,7].==3952);
  dind[.,43]=(vv[.,7].==3953);
  dind[.,44]=(vv[.,7].==3961);
  dind[.,45]=(vv[.,7].==3962);
  dind[.,46]=(vv[.,7].==3963);
  dind[.,47]=(vv[.,7].==3969);
  dind[.,48]=(vv[.,7].==3971);
  dind[.,49]=(vv[.,7].==3972);
  dind[.,50]=(vv[.,7].==3990);
  dind[.,51]=(vv[.,7].==4090);
  dind[.,52]=(vv[.,7].==4011);
  dind[.,53]=(vv[.,7].==4012);
  dind[.,54]=(vv[.,7].==4013);
  dind[.,55]=(vv[.,7].==4014);
  dind[.,56]=(vv[.,7].==4015);
  dind[.,57]=(vv[.,7].==4019);
  dind[.,58]=(vv[.,7].==4021);
  dind[.,59]=(vv[.,7].==4022);
  dind[.,60]=(vv[.,7].==4023);
  dind[.,61]=(vv[.,7].==4025);
  dind[.,62]=(vv[.,7].==4026);
  dind[.,63]=(vv[.,7].==4027);
  dind[.,64]=(vv[.,7].==4028);
  dind[.,65]=(vv[.,7].==4029);
  dind[.,66]=(vv[.,7].==4030);
  dind[.,67]=(vv[.,7].==4041);
  dind[.,68]=(vv[.,7].==4042);
  @dind[.,10]=(vv[.,7].==4024);@

elseif industry==12;
  dind=zeros(rows(vv),20);  @ dind[.,1]=(vv[.,7].==4890);:base group@
  dind[.,1]=(vv[.,7].==4811);
  dind[.,2]=(vv[.,7].==4812);
  dind[.,3]=(vv[.,7].==4813);
  dind[.,4]=(vv[.,7].==4819);
  dind[.,5]=(vv[.,7].==4821);
  dind[.,6]=(vv[.,7].==4822);
  dind[.,7]=(vv[.,7].==4823);
  dind[.,8]=(vv[.,7].==4830);
  dind[.,9]=(vv[.,7].==4840);
  dind[.,10]=(vv[.,7].==4851);
  dind[.,11]=(vv[.,7].==4852);
  dind[.,12]=(vv[.,7].==4700);
  dind[.,13]=(vv[.,7].==4990);
  dind[.,14]=(vv[.,7].==4910);
  dind[.,15]=(vv[.,7].==4920);
  dind[.,16]=(vv[.,7].==5090);
  dind[.,17]=(vv[.,7].==5010);
  dind[.,18]=(vv[.,7].==5021);
  dind[.,19]=(vv[.,7].==5029);
  dind[.,20]=(vv[.,7].==5030);

elseif industry==13;
  dind=zeros(rows(vv),37);   @dind[.,1]=(vv[.,7].==5310):base group@
  dind[.,1]=(vv[.,7].==5320);
  dind[.,2]=(vv[.,7].==6020);
  dind[.,3]=(vv[.,7].==6010);
  dind[.,4]=(vv[.,7].==5339);
  dind[.,5]=(vv[.,7].==5449);
  dind[.,6]=(vv[.,7].==5411);
  dind[.,7]=(vv[.,7].==5412);
  dind[.,8]=(vv[.,7].==5413);
  dind[.,9]=(vv[.,7].==5419);
  dind[.,10]=(vv[.,7].==5420);
  dind[.,11]=(vv[.,7].==5430);
  dind[.,12]=(vv[.,7].==5441);
  dind[.,13]=(vv[.,7].==5442);
  dind[.,14]=(vv[.,7].==5539);
  dind[.,15]=(vv[.,7].==5511);
  dind[.,16]=(vv[.,7].==5512);
  dind[.,17]=(vv[.,7].==5513);
  dind[.,18]=(vv[.,7].==5521);
  dind[.,19]=(vv[.,7].==5522);
  dind[.,20]=(vv[.,7].==5523);
  dind[.,21]=(vv[.,7].==5531);
  dind[.,22]=(vv[.,7].==5532);
  dind[.,23]=(vv[.,7].==5611);
  dind[.,24]=(vv[.,7].==5612);
  dind[.,25]=(vv[.,7].==5620);
  dind[.,26]=(vv[.,7].==5631);
  dind[.,27]=(vv[.,7].==5632);
  dind[.,28]=(vv[.,7].==5639);
  dind[.,29]=(vv[.,7].==5700);
  dind[.,30]=(vv[.,7].==5829);
  dind[.,31]=(vv[.,7].==5810);
  dind[.,32]=(vv[.,7].==5821);
  dind[.,33]=(vv[.,7].==5822);
  dind[.,34]=(vv[.,7].==5990);
  dind[.,35]=(vv[.,7].==5911);
  dind[.,36]=(vv[.,7].==5912);
  dind[.,37]=(vv[.,7].==5919);
  @dind[.,2]=(vv[.,7].==5331);
  dind[.,3]=(vv[.,7].==5332);@

elseif industry==14;
  dind=zeros(rows(vv),16);    @dind[.,1]=(vv[.,7].==6311):base group@
  dind[.,1]=(vv[.,7].==6312);
  dind[.,2]=(vv[.,7].==6319);
  dind[.,3]=(vv[.,7].==6321);
  dind[.,4]=(vv[.,7].==6322);
  dind[.,5]=(vv[.,7].==6330);
  dind[.,6]=(vv[.,7].==6410);
  dind[.,7]=(vv[.,7].==6599);
  dind[.,8]=(vv[.,7].==6420);
  dind[.,9]=(vv[.,7].==6490);
  dind[.,10]=(vv[.,7].==6510);
  dind[.,11]=(vv[.,7].==6520);
  dind[.,12]=(vv[.,7].==6530);
  dind[.,13]=(vv[.,7].==6540);
  dind[.,14]=(vv[.,7].==6550);
  dind[.,15]=(vv[.,7].==6591);
  dind[.,16]=(vv[.,7].==6592);
  @dind[.,7]=(vv[.,7].==6410);@  

elseif industry==15;
  dind=zeros(rows(vv),23);  @ dind[.,1]=(vv[.,7].==6610);:base group@
  dind[.,1]=(vv[.,7].==6620);
  dind[.,2]=(vv[.,7].==6631);
  dind[.,3]=(vv[.,7].==6632);
  dind[.,4]=(vv[.,7].==6633);
  dind[.,5]=(vv[.,7].==6639);
  dind[.,6]=(vv[.,7].==6640);
  dind[.,7]=(vv[.,7].==6711);
  dind[.,8]=(vv[.,7].==6712);
  dind[.,9]=(vv[.,7].==6713);
 
  dind[.,11]=(vv[.,7].==6729);
  dind[.,12]=(vv[.,7].==6990);
  dind[.,13]=(vv[.,7].==6740);
  dind[.,14]=(vv[.,7].==6811);
  dind[.,15]=(vv[.,7].==6812);
  dind[.,16]=(vv[.,7].==6820);
  dind[.,17]=(vv[.,7].==6940);
  dind[.,18]=(vv[.,7].==6930);
  dind[.,19]=(vv[.,7].==6850);
  dind[.,20]=(vv[.,7].==6860);
  dind[.,21]=(vv[.,7].==6891);
  dind[.,22]=(vv[.,7].==6899);
  dind[.,23]=(vv[.,7].==6910);
  dind[.,10]=(vv[.,7].==6920);
  @dind[.,12]=(vv[.,7].==6730);
  dind[.,17]=(vv[.,7].==6830);
  dind[.,18]=(vv[.,7].==6840);@

elseif industry==16;
  dind=zeros(rows(vv),32);   @dind[.,1]=(vv[.,7].==7111);:base group@
  dind[.,1]=(vv[.,7].==7263);  
  dind[.,2]=(vv[.,7].==7113);
  dind[.,3]=(vv[.,7].==7114);
  dind[.,4]=(vv[.,7].==7119);
  dind[.,5]=(vv[.,7].==7272);
  dind[.,6]=(vv[.,7].==7269);
  dind[.,7]=(vv[.,7].==7262);
  dind[.,8]=(vv[.,7].==7129);
  dind[.,9]=(vv[.,7].==7211);
  dind[.,10]=(vv[.,7].==7281);
  dind[.,11]=(vv[.,7].==7219);
  dind[.,12]=(vv[.,7].==7221);
  dind[.,13]=(vv[.,7].==7222);
  dind[.,14]=(vv[.,7].==7229);
  dind[.,15]=(vv[.,7].==7231);
  dind[.,16]=(vv[.,7].==7232);
  dind[.,17]=(vv[.,7].==7233);
  dind[.,18]=(vv[.,7].==7239);
  dind[.,19]=(vv[.,7].==7240);
  dind[.,20]=(vv[.,7].==7250);
  dind[.,21]=(vv[.,7].==7261);
  dind[.,22]=(vv[.,7].==7271);
  dind[.,23]=(vv[.,7].==7294);
  dind[.,24]=(vv[.,7].==7293);
  dind[.,25]=(vv[.,7].==7292);
  dind[.,26]=(vv[.,7].==7291);
  dind[.,27]=(vv[.,7].==7212);
  dind[.,28]=(vv[.,7].==7299);
  dind[.,29]=(vv[.,7].==7296);
  dind[.,30]=(vv[.,7].==7282);
  dind[.,31]=(vv[.,7].==7213);
  dind[.,32]=(vv[.,7].==7289);
  @dind[.,21]=(vv[.,7].==7295);
  dind[.,1]=(vv[.,7].==7112);
  dind[.,5]=(vv[.,7].==7121);
  dind[.,6]=(vv[.,7].==7122);
  dind[.,7]=(vv[.,7].==7123);
  dind[.,30]=(vv[.,7].==7250);@

elseif industry==17;
  dind=zeros(rows(vv),23);  @ dind[.,1]=(vv[.,7].==7499);:base group@
  dind[.,1]=(vv[.,7].==7410);  
  dind[.,2]=(vv[.,7].==7420);
  dind[.,3]=(vv[.,7].==7430);
  dind[.,4]=(vv[.,7].==7440);
  dind[.,5]=(vv[.,7].==7450);
  dind[.,6]=(vv[.,7].==7461);
  dind[.,7]=(vv[.,7].==7492);
  dind[.,8]=(vv[.,7].==7471);
  dind[.,9]=(vv[.,7].==7472);
  dind[.,10]=(vv[.,7].==7473);
  dind[.,11]=(vv[.,7].==7474);
  dind[.,12]=(vv[.,7].==7475);
  dind[.,13]=(vv[.,7].==7481);
  dind[.,14]=(vv[.,7].==7482);
  dind[.,15]=(vv[.,7].==7483);
  dind[.,16]=(vv[.,7].==7491);
  dind[.,17]=(vv[.,7].==7520);
  dind[.,18]=(vv[.,7].==7590);
  dind[.,19]=(vv[.,7].==7511);  
  dind[.,20]=(vv[.,7].==7512);
  dind[.,21]=(vv[.,7].==7513);
  dind[.,22]=(vv[.,7].==7514);
  dind[.,23]=(vv[.,7].==7519);
  @dind[.,25]=(vv[.,7].==7462);
  dind[.,7]=(vv[.,7].==7493);@

elseif industry==18;
  dind=zeros(rows(vv),18);  @ dind[.,1]=(vv[.,7].==7111);:base group@
  dind[.,1]=(vv[.,7].==7910);  
  dind[.,2]=(vv[.,7].==7990);
  dind[.,3]=(vv[.,7].==7930);
  dind[.,4]=(vv[.,7].==7940);
  dind[.,5]=(vv[.,7].==7950);
  dind[.,6]=(vv[.,7].==7960);
  dind[.,7]=(vv[.,7].==7970);
  dind[.,8]=(vv[.,7].==8099);
  dind[.,9]=(vv[.,7].==8011);  
  dind[.,10]=(vv[.,7].==8012);
  dind[.,11]=(vv[.,7].==8021);
  dind[.,12]=(vv[.,7].==8022);
  dind[.,13]=(vv[.,7].==8029);
  dind[.,14]=(vv[.,7].==8031);
  dind[.,15]=(vv[.,7].==8032);
  dind[.,16]=(vv[.,7].==8190);
  dind[.,17]=(vv[.,7].==8111);  
  dind[.,18]=(vv[.,7].==8119);
  @dind[.,30]=(vv[.,7].==8091);
  dind[.,8]=(vv[.,7].==8093);
  dind[.,8]=(vv[.,7].==8092);
  dind[.,2]=(vv[.,7].==7920);
  dind[.,8]=(vv[.,7].==7980);@

elseif industry==19;
  dind=zeros(rows(vv),21);  @ dind[.,1]=(vv[.,7].==8510);:base group@
  dind[.,1]=(vv[.,7].==8521);  
  dind[.,2]=(vv[.,7].==8522);
  dind[.,3]=(vv[.,7].==8523);  
  dind[.,4]=(vv[.,7].==8524);
  dind[.,5]=(vv[.,7].==8525);  
  dind[.,6]=(vv[.,7].==8529);
  dind[.,7]=(vv[.,7].==8610);
  dind[.,8]=(vv[.,7].==8620);  
  dind[.,9]=(vv[.,7].==8630);
  dind[.,10]=(vv[.,7].==8640);  
  dind[.,11]=(vv[.,7].==8650);
  dind[.,12]=(vv[.,7].==8660);  
  dind[.,13]=(vv[.,7].==8810);
  dind[.,14]=(vv[.,7].==8820);  
  dind[.,15]=(vv[.,7].==8830);
  dind[.,16]=(vv[.,7].==8890);  
  dind[.,17]=(vv[.,7].==8911);
  dind[.,18]=(vv[.,7].==8990);  
  dind[.,19]=(vv[.,7].==8949);
  dind[.,20]=(vv[.,7].==8919);  
  dind[.,21]=(vv[.,7].==8920);
  @dind[.,1]=(vv[.,7].==8912);
  dind[.,2]=(vv[.,7].==8913);
  dind[.,5]=(vv[.,7].==8930); 
  dind[.,5]=(vv[.,7].==8942);
  dind[.,5]=(vv[.,7].==8941);@  

else;
  dind={};
endif;

mshare=vv[.,42]./(vv[.,43]);
ladjust=(mshare./meanc(mshare))-1;
ladjust=ln(1+(vv[.,43]./(vv[.,42]+vv[.,43])).*ladjust);

vv=vv[.,1:5];

xs=ct~dyear~age~east~middle~core~ccity~entrant~k~l~m~wage~rml~scost1step~soe~dind;
return;
below:
gosub vardef;

clear f,as,dind,dyear;
bspara=invpd(xs'xs)*(xs'pavcm);
avga=xs*bspara;
avga1=0|avga[1:rows(avga)-1];

endif;

@------------------------------------------------------------@ 
@---define variables: do not use first year ownig to lag-----@
@------------------------------------------------------------@     
ct=selif(ct,u);
td=selif(td,u);

sratio=selif(sratio,u);
sratio1=selif(sratio1,u);

east=selif(east,u);
east1=selif(east1,u);
middle=selif(middle,u);
middle1=selif(middle1,u);
ccity=selif(ccity,u);
ccity1=selif(ccity1,u);
core=selif(core,u);
core1=selif(core1,u);
export=selif(export,u);
export1=selif(export1,u);
age=selif(age,u);
age1=selif(age1,u);
exiter=selif(exiter,u);
exiter1=selif(exiter1,u);
entrant=selif(entrant,u);
entrant1=selif(entrant1,u);
subsidy=selif(subsidy,u);
subsidy1=selif(subsidy1,u);
soe=selif(soe,u);
soe1=selif(soe1,u);

r=selif(r,u);
r1=selif(r1,u);
p=selif(p,u);
p1=selif(p1,u);

pm=selif(pm,u);
pm1=selif(pm1,u);
em=selif(em,u);
em1=selif(em1,u);
m=selif(m,u);
m1=selif(m1,u);
wage=selif(wage,u);
wage1=selif(wage1,u);

k=selif(k,u);
k1=selif(k1,u);
scost=selif(scost,u);
scost1=selif(scost1,u);
l=selif(l,u);
l1=selif(l1,u);
tao=selif(tao,u);
tao1=selif(tao1,u);
taow=selif(taow,u);
taow1=selif(taow1,u);
taom=selif(taom,u);
taom1=selif(taom1,u);

scost1step1=selif(scost1step1,u);
rml1=selif(rml1,u);

avga=selif(avga,u);
avga1=selif(avga1,u);

pros=selif(pros,u);
pros1=selif(pros1,u);

@---------------------------------------------------------------------------------------@
@------First step of GMM----------------------------------------------------------------@
@---------------------------------------------------------------------------------------@

optimal=0;
@------Starting values------@

startv=0|0|-1.50|0|0|0|0|0|0|0;

@------Calling the optimization routine------@
@_oprteps=0;@
__output=1;

_opalgr=2;
_opgtol=0.001;
_opmiter=999;
__output=2;
{b,fc,g,retcode}=optmum(&fv,startv);
proc fv(x);
   {d,fc,zw,ze,a,zeez}=compute(x);
retp(fc);
endp;

@------Computing first step standard errors------@
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
@vb=inv(g'a*g);@
vb=inv(g'a*g)*g'a*zeez*a*g*inv(g'a*g);
df=rows(a)-rows(vb);
sb=sqrt(diag(vb));

para1=(b|d)~sb;
format /rd 12,3;
print "first step Function value:";;fc;

@ for onlyfirst, only run the first step of GMM------@
if onlyfirst==0;

@-----------------------------------------------------------------------------------------@
@----Second step of GMM-------------------------------------------------------------------@
@-----------------------------------------------------------------------------------------@

optimal=1;
startv=b;

@------Reading second step weights zeez------@
open h=^mtx;
aopt=inv(readr(h,rowsf(h)));

@------Calling the optimization routine------@
@_oprteps=0;@
__output=1;
_opalgr=2;
_opgtol=0.001;
_opmiter=999;
__output=2;
{b,fc,g,retcode}=optmum(&fv,startv);
proc fv(x);
   {d,fc,zw,ze,a,zeez}=compute(x);
retp(fc);
endp;

@------Computing second step standard errors------@
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
vb=inv(g'aopt*g);
df=rows(aopt)-rows(vb);
sb=sqrt(diag(vb));

endif;

@------Saving parameter estimation outputs-------------------------------------------------------------@
if keep==1;
  if onlyfirst/=1;
    para=para1~(b|d)~sb;
    call saved(para,cffs,0);
  else;
    call saved(para1,cffs,0);
  endif;
endif;

@------Cauculating outputs: markdown and productivity----------------------------------------------------@
if keepg==1;

@------Selecting complete sequences------@
input="data\\sdata"$+ind;
open f=^input;
whole=readr(f,rowsf(f));
uu=whole[.,cols(whole)];
vv=selif(whole,uu);
clear whole,uu;

@------Cauculating firms of productivity estimation------@
j=1;index1=2;
do until  index1>=rows(vv);
  if vv[index1,1]/=vv[index1-1,1];
      j=j+1;
  endif;
  index1=index1+1;
endo;

format /rd 6,0;
print "No. of firms in productivity estimation:";;j;
print "No. of observations in productivity estimation:";;rows(vv);

   p=ln(vv[.,45]);
   pm=ln(vv[.,46]);
   r=ln(vv[.,66]/1000);

   em=ln((vv[.,42]+vv[.,33])/1000);
   m=em-pm;
   
   export1step=vv[.,11]./vv[.,66];
   scost1step=vv[.,38]./vv[.,66];
   scost=ln(vv[.,38]/1000);

   k=ln(vv[.,47]/1000);
   @l=ln(vv[.,12]);@
   l=ln(vv[.,12]);
   tao=vv[.,40];
   taom=vv[.,41];
   sratio=vv[.,18];
   east=vv[.,13];
   middle=vv[.,14];
   ccity=vv[.,15];
   core=vv[.,16];
   
   entrant=vv[.,31];
   exiter=vv[.,32];
   age=vv[.,2]-vv[.,9];
   @subsidy=vv[.,72].>0;@
   subsidy=vv[.,72]./vv[.,28];
   @soe=(vv[.,70]+vv[.,71]).>0;
   soe=(vv[.,70]+vv[.,71])./vv[.,39];@
   soe=(vv[.,30].==110) .or (vv[.,30].==120) .or (vv[.,30].==141) .or (vv[.,30].==142) .or (vv[.,30].==143) .or (vv[.,30].==151);

   rml=vv[.,42]./vv[.,43];
   wage=ln(vv[.,17])-ln(vv[.,12]);
 
@here clear data for adnormal observations@
@change negative scost to 0@
@   cond=(scost.<0);
   i=1;
   do while i<=rows(vv);
     if cond[i];
       scost[i]=0;
       i=i+1;
     else;
       i=i+1;
     endif;
   endo;@

if itait==0;
   avg=vv[.,49];
else;
   @---using PAVCM to estimate markdown ij-------@
   vva=vv[.,1:2];
   vvb=vv[.,7];
   vvc=vv[.,42:43];
   vv=vva;
   clear f,vva;
   vv=vv~zeros(rows(vv),4)~vvb;
   clear vvb;
   vv=vv~zeros(rows(vv),34)~vvc;
   clear vvc;

   ct=ones(rows(vv),1);
   gosub vardef;
   if avgid==2;
    avg=xs*bspara;
    avg=avg-bspara[17,.]*ladjust;
   else;
    avg=xs*bspara;
   endif;
endif;
     
bk=b[1];bkk=b[2];bm=exp(exp(b[3])-0.5);bsc=b[4];ae=b[5];a2=b[6];a4=b[7];a5=b[8];a6=b[9];bs=b[10];
svl=1-(1/bm)*(1/(exp(avg)));
omiga=ln(1-taom)-(bk*k+bkk*(k^2)+bm*m+bs*(svl^2))+em-ln(1-tao)-(bsc*scost+ae*east+a2*middle+a4*core+a5*ccity+a6*entrant)-ln(1-svl);
   markdown=rml.*(svl./(1-svl));
   lomiga=m-l+(2*bs/bm)*svl;
   lomiga=lomiga-meanc(lomiga);


   @------Cauculating outputs----------------------------------------@
   bk=bk.*ones(rows(vv),1);
   bkk=bkk.*ones(rows(vv),1);
   b3=b[3].*ones(rows(vv),1);
   bs=bs.*ones(rows(vv),1);
   bm=bm.*ones(rows(vv),1);
   bkt=bk/sb[1];
   bkkt=bkk/sb[2];
   b3t=b3/sb[3];
   bst=bs/sb[10];

   dnudb=exp(b[3])*exp(exp(b[3])-0.5); 
   vbm=(dnudb^2)*submat(vb,3,3); 
   bmt=bm./sqrt(vbm);

   functionvalue=fc.*ones(rows(vv),1);

   if onlyfirst==0;
    freedom=df.*ones(rows(vv),1);
    pvalue=cdfchic(fc,rows(aopt)-rows(b|d)).*ones(rows(vv),1);
   else;
    freedom=zeros(rows(vv),1);
    pvalue=zeros(rows(vv),1);
   endif;

   bsc=b[4].*ones(rows(vv),1);
   east=b[5].*ones(rows(vv),1);
   middle=b[6].*ones(rows(vv),1);
   core=b[7].*ones(rows(vv),1);
   ccity=b[8].*ones(rows(vv),1);
   entrant=b[9].*ones(rows(vv),1);
   a0=ones(rows(vv),1);

   bsct=(b[4]/sb[4]).*ones(rows(vv),1);
   eastt=(b[5]/sb[5]).*ones(rows(vv),1);
   middlet=(b[6]/sb[6]).*ones(rows(vv),1);
   coret=(b[7]/sb[7]).*ones(rows(vv),1);
   ccityt=(b[8]/sb[8]).*ones(rows(vv),1);
   entrantt=(b[9]/sb[9]).*ones(rows(vv),1);
   a0t=ones(rows(vv),1);
   
   if deltacancel==0;
      ta1=ones(rows(vv),1);
      ta2=ones(rows(vv),1);
      ta3=ones(rows(vv),1);
      ta1t=ones(rows(vv),1);
      ta2t=ones(rows(vv),1);
      ta3t=ones(rows(vv),1);
   else;
      ta1=b[12].*ones(rows(vv),1);
      ta2=b[13].*ones(rows(vv),1);
      ta3=b[14].*ones(rows(vv),1);
      ta1t=(b[12]/sb[12]).*ones(rows(vv),1);
      ta2t=(b[13]/sb[13]).*ones(rows(vv),1);
      ta3t=(b[14]/sb[14]).*ones(rows(vv),1);
   endif;

   thd1=d[10].*ones(rows(vv),1);
   if deltacancel==0;
      thd1t=thd1/sb[21];
   else;
      thd1t=thd1/sb[24];
   endif;

   numpro=j.*ones(rows(vv),1);
   obspro=rows(vv).*ones(rows(vv),1);
   numpara=ju.*ones(rows(vv),1);
   obspara=rows(obsu).*ones(rows(vv),1);

   export=ones(rows(vv),1);
   exportt=ones(rows(vv),1);   
   soe=ones(rows(vv),1);
   soet=ones(rows(vv),1);

    if (bm>0.2 and bm<2);
     omiga=vv[.,1:2]~omiga;
     if itait==0;
       clear vv;
     else;
       clear vv,xs,dind;
     endif;
     omiga=omiga~markdown~functionvalue~freedom~pvalue~bk~bkk~bm~bsc~ta1~ta2~ta3~east~middle~export~core~ccity~entrant~bkt~bkkt~bmt~bsct~ta1t~ta2t~ta3t~eastt~middlet~exportt~coret~ccityt~entrantt~soet~numpro~obspro~numpara~obspara~b3~b3t~soe~a0~a0t~bs~bst~lomiga~thd1~thd1t~svl;
     @      3       4          5          6       7    8   9  10 11  12  13  14   15    16    17     18    19    20    21   22  23  24    25   26   27   28     29      30      31     32     33     34     35    36     37      38    39 40  41  42 43  44  45   46    47   48@ 
     call saved(omiga,omi,0); 
   endif;
   
endif;

@------Printing---------------------------------------------------------------------------@
format /rd 12,0;
print "code(normal=0):";;retcode;
if optimal==1;
  format /rd 12,3;
  print "Second step function value:";;fc;
  format /rd 6,0;
  print "(second step) df:";;df;
  format /rd 6,3;
  print "Prob. value:";;cdfchic(fc,rows(aopt)-rows(b|d));
  let fmt1="*.*lf" 8 4;
  let fmt2="*.*lf" 8 4;
  let fmt3="*.*lf" 8 4;
  let fmt4="*.*lf" 8 4;
  res=para1~(b|d)~sb;
  mask=0~ones(1,4);
  fmt=fmt1'|fmt2'|fmt3'|(fmt4'.*.ones(2,1));
  call printfm(namex'~res, mask, fmt);
else;
  let fmt1="*.*lf" 8 8;
  let fmt2="*.*lf" 8 3;
  res=para1;
  mask=0~ones(1,2);
  fmt=fmt1'|(fmt2'.*.ones(2,1));
  call printfm(namex'~res, mask, fmt);
endif;
print;

format /rd 6,3;
print "     bM   ";;bm[1];;sqrt(vbm); 
print;

format /rd 6,3;
print "Mean markdown=";;meanc(markdown);
format /rd 6,3;
print "Min markdown=";;minc(markdown);
format /rd 6,3;
print "Quartiles markdown:";
print quantile(markdown,0.25|0.5|0.75);
print;

print "Mean svl=";;meanc(svl);
print "Min svl=";;minc(svl);
format /rd 4,0;
print "No of bot svl (%):";;sumc(svl.<=0.05);;sumc(svl.<=0.05)*100/rows(svl);
print "No of top svl (%):";;sumc(svl.>=0.8);;sumc(svl.>=0.8)*100/rows(svl);
format /rd 6,3;
print "Quartiles svl:";
print quantile(svl,0.25|0.5|0.75);
print;

closeall;

str=etstr(hsec-start);
"Execution time is  ";;print $str;

flag=flag+1;
endo;


@---Procedure specifying equations and moments and computing the objective-----------------------------------------------@
proc(6)= compute(b);

local bk,bkk,bm,bs,bsc,a0,ae,a2,a3,a4,a5,a6,y,omiga1,w0,w,z,e,zy,xx,zz,ww,xy,ta1,ta2,ta3; 
local svl,svl1;
clear d,zw,ze,a,zeez;
bk=b[1];bkk=b[2];bm=exp(exp(b[3])-0.5);bsc=b[4];ae=b[5];a2=b[6];a4=b[7];a5=b[8];a6=b[9];bs=b[10];

@First loop: defining model, computing the concentrated parameters@

clear xx,xy,zw,zz,zy,ww;

@------------------------------------define estimation equation--------------------------------------@
svl=1-(1/bm)*(1/(exp(avga)));
svl1=1-(1/bm)*(1/(exp(avga1)));

y=r-(bk*k+bkk*(k^2)+bm*m+bs*(svl^2))-(bsc*scost+ae*east+a2*middle+a4*core+a5*ccity+a6*entrant);
omiga1=ln(1-taom1)-(bk*k1+bkk*(k1^2)+bm*m1+bs*(svl1^2))+em1-ln(1-tao1)-(bsc*scost1+ae*east1+a2*middle1+a4*core1+a5*ccity1+a6*entrant1)-ln(1-svl1);
w=ct~td~pol1(omiga1);  @here we use the estimation of survival probability to control selection@

@---instrumentsusing PAVCM to estimate markdown ij-------@
     if instru==0;
      z=ct~td~east~middle~core~ccity~entrant1~scost1~pol3(k1,l1,m1)~pol1(rml1)~pol1(avga1);
     elseif instru==1;
      z=ct~td~east~middle~core~ccity~entrant1~scost1~pol3(k1,l1,m1)~pol2(rml1,avga1);
     elseif instru==2;
      z=ct~td~east~middle~core~ccity~entrant1~scost1~pol2(k1,m1)~pol1(l1)~pol2(rml1,avga1);
     elseif instru==3;
      z=ct~td~east~middle~core~ccity~entrant1~pol2(k1,m1)~pol1(l1)~pol3(rml1,scost1step1,avga1);
     elseif instru==4;
      z=ct~td~east~middle~core~ccity~entrant1~pol3(scost1,k1,m1)~pol1(l1)~pol1(rml1)~pol1(avga1);
     elseif instru==5;
      z=ct~td~east~middle~core~ccity~entrant1~pol2(k1,m1)~pol1(l1)~pol3(rml1,scost1step1,avga1);
     
     elseif instru==6;
      z=ct~td~east~middle~core~ccity~entrant1~pol1(scost1)~pol2(k1,l1)~pol1(em1)~pol1(rml1)~pol1(avga1);
     elseif instru==7;
      z=ct~td~east~middle~core~ccity~entrant1~pol1(scost1)~pol1(k1)~pol2(l1,em1)~pol2(rml1,avga1);
     elseif instru==8;
      z=ct~td~east~middle~core~ccity~entrant1~pol1(scost1step1)~pol2(k1,em1)~pol1(l1)~pol2(rml1,avga1);
     elseif instru==9;
      z=ct~td~east~middle~core~ccity~entrant1~pol1(scost1)~pol2(k1,em1)~pol2(rml1,avga1);
     elseif instru==10;
      z=ct~td~east~middle~core~ccity~entrant1~pol2(scost1step1,avga1)~pol2(k1,em1)~pol1(rml1);
     else;     
      z=ct~td~east~middle~core~ccity~entrant1~pol1(k1)~pol1(em1)~pol3(rml1,scost1step1,avga1);
     endif;

ww=w'w;
zw=z'w;
zz=z'z;
zy=z'y;

@------computing the concentrated parameters------@

a=invpd(zz);

if optimal==0;
   d=invpd(zw'a*zw)*zw'a*zy;
else;
   d=invpd(zw'aopt*zw)*zw'aopt*zy;
endif;

@---------Second loop: computing moments and outputs---------@

clear ze,zw;

e=y-w*d;
ze=z'e;
zw=z'w;

@---------calculate second step weights zeez,adding firm by firm------------@
local ma,index,tt,ue,uz;
if optimal==0;
  ma=vv[.,5]-1;
  ma=selif(ma,u);
  ma=ma~e~z;
  index=1;
  do until  index>rows(ma);
    tt=ma[index,1];
    ue=ma[index:index+tt-1,2];
    uz=ma[index:index+tt-1,3:cols(ma)];
    zeez=zeez+uz'ue*ue'*uz;
  index=index+tt;
  endo;
  call saved(zeez,mtx,0);
endif;

@fg=w*d;
ft=ft|fg;@

@Computing the objective@

if optimal==0;
   fc=ze'a*ze;
else;
   fc=ze'aopt*ze;
endif;

retp(d,fc,zw,ze,a,zeez);
endp;

@------Other procedures--------------------------------------------------------------------@
proc(1)=pol2_2(u1,u2);
local pol;
pol=u1~(u1^2)~u2~(u2^2)~(u1.*u2);
retp(pol);
endp;

proc(1)=pol1(u);
local pol;
pol=u~(u^2)~(u^3);
retp(pol);
endp;

proc(1)=pol2(u1,u2);
local pol;
pol=u1~(u1^2)~(u1^3)~u2~(u2^2)~(u2^3)~(u1.*u2)~((u1^2).*u2)~(u1.*(u2^2));
retp(pol);
endp;

proc(1)=pol3(v1,v2,v3);
local pol;
pol=v1~v2~v3~(v1^2)~(v2^2)~(v3^2)
    ~(v1.*v2)~(v1.*v3)~(v2.*v3)
    ~(v1^3)~(v2^3)~(v3^3)
    ~((v1^2).*v2)~((v1^2).*v3)
    ~(v1.*(v2^2))~((v2^2).*v3)
    ~(v1.*(v3^2))~(v2.*(v3^2))
    ~(v1.*v2.*v3);
retp(pol);
endp;

proc(1)=pol4(v1,v2,v3,v4);
local pol;
pol=v1~v2~v3~v4~(v1^2)~(v2^2)~(v3^2)~(v4^2)
    ~(v1.*v2)~(v1.*v3)~(v1.*v4)~(v2.*v3)~(v2.*v4)~(v3.*v4)
    ~(v1^3)~(v2^3)~(v3^3)~(v4^3)
    ~((v1^2).*v2)~((v1^2).*v3)~((v1^2).*v4)~(v1.*(v2^2))~((v2^2).*v3)
    ~((v2^2).*v4)~(v1.*(v3^2))~(v2.*(v3^2))~((v3^2).*v4)~(v1.*(v4^2))
    ~(v2.*(v4^2))~(v3.*(v4^2))~(v1.*v2.*v3)~(v1.*v2.*v4)~(v1.*v3.*v4)
    ~(v2.*v3.*v4);
retp(pol);
endp;

end;


