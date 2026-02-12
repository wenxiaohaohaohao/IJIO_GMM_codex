This is the readme file of Matlab code for the empirical estimation using GLZ (2016) 
for CES specification.  This code serves two purposes. First, it does empirical estimation of the CES production function
using GLZ (2016) method (implemented via a minimal distance-based approach). 
Second, it implements OP-KG method with material quantities replaced by their values (expenditures)
to check the performance of GLZ's method against the traditional value-based approach. We briefly 
explain the files in this folder as follows.

1. The data used in the estiamtion is drawn from the database used in 
   "Colombia, 1977-1985: Producer Turnover, Margins, and Trade Exposure",
   Chapter 10 in Industrial Evolution in Developing Countries: 
   Micro Patterns of Turnover, Productivity, and Market Structure, 
   Mark J. Roberts and James R. Tybout, Oxford University Press, 1996.

   Anyone who reads this code should cite the book as well as the reference. 

   Four industries domenstrated in the paper includes:
    data_3117 -- Bakery Products
    data_3220 -- Clothing
    data_3420 -- Printing & Publishing
    data_3813 -- Metal Furniture

2. To run the estimation with our method, use main_data_US.m;
    To run the estimation with OP-KG method, use main_data_OP.m.
    Different data files can be called in the beginning of each script above.

3. Obj_US.m: the objective function used in our method (it is minimal distance-based);
    Obj_GMM_OP.m: the GMM objective function used in OP-KG;
    OmegaAR.m: objective function used in our method to estimate AR(1) process of productivity.

4. The main output (parameter estimates of the production function) from the estimation is printed on the screen.   

