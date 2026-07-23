/* Increase in investment when interest rates change over time (compound interest) */
/* SQL-partitioning solution from the repo, run against its BNY/FDU sample.         */
/*                                                                                  */
/* The repo's libname sd1 "d:/sd1" is replaced with WORK so the data step is        */
/* self-contained; the PROC SQL join, the (1+l.rate)*(1+r.rate) return computation, */
/* and the row_number() OVER (PARTITION BY cd) partitioning are the author's own —  */
/* the window-function form is the exact SQL used in this repo's R and Python       */
/* solutions, expressed here in PROC SQL.                                           */

data have;
 input CD $4. RATE YEAR;
cards4;
BNY 0.1 1980
BNY 0.2 1981
FDU 0.5 1980
FDU 0.3 1981
;;;;
run;quit;

proc sql;
 create
   table want  as
 select
      r.cd
     ,r.year                    as current_year
     ,(1 + l.rate)*(1 + r.rate) as return
 from
     (
     select *, row_number() OVER (PARTITION BY cd) as partition from have
     ) as l
 inner join
     (
     select *, row_number() OVER (PARTITION BY cd) as partition from have
     ) as r
  on
        l.partition = 1
    and r.partition = 2
    and l.cd        = r.cd
;quit;

proc print data=want; run;quit;
