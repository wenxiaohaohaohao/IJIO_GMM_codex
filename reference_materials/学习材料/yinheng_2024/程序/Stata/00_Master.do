/*
******************************************************************************
*   Identification of Labor market monopsony with Non-neutral Productivity   *
*                                                                            *
*                                  Master                                    * 
******************************************************************************
 File Name: MASTER.do
 Created By:  Hui Li
 Created on:  July 2023
*/

****************************
* Path settings 
****************************
clear all
set more off, permanent

/* This sets the file paths used throughout this project. */
cd "set your path here"
global workdir    "set your path here"
global pathA      "$workdir\数据\analysis"  /*Working Data Folder*/
global pathB      "$workdir\程序\Stata"   /*Program Folder*/
global pathC      "$workdir\table"     /*Table Folder*/
global pathD      "$workdir\figure"    /*Figure Folder*/

***************************
* Step two:Data analysis 
***************************
do "$pathB\01_Tab1&2_Fig1&2.do"
do "$pathB\02_Fig3_Tab3.do"
do "$pathB\03_Fig4_Tab4&5"
