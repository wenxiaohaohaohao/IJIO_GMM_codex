proc(2)=distrib(x,c,a,b,s);
local r,sx,z,zs,h,f,i,k;
         r=rows(x);
         sx=s;
         z=seqa(a,(b-a)/99,100);
         x=x/sx;
         zs=z/sx;
         h=c*(r^(-(1/3)));
         f=zeros(100,1);
         i=1;
         do while i<=100;
            k=cdfn((zs[i]-x)/h);
            f[i]=(ones(1,r)*k)/r;
            i=i+1;
         endo;
retp(z,f);
endp;



