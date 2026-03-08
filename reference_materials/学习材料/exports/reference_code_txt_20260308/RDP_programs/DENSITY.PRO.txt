proc(2)=density(x,c,a,b,s);
local r,sx,h,f,z,zs,i,k;
         r=rows(x);
         sx=s;
         z=seqa(a,(b-a)/99,100);
         x=x/sx;
         zs=z/sx;
         h=c*(r^(-0.2));
         f=zeros(100,1);
         i=1;
         do while i<=100;
            k=pdfn((zs[i]-x)/h);
            f[i]=(ones(1,r)*k)/(r*h);
            i=i+1;
         endo;
retp(z,f);
endp;



