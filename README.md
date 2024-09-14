# utl-sql-partitioning-increase-in-investment-when-interest-rates-change-over-time-compound-interest
Increase in investment when interest rates change over time compounding interest   
    %let pgm=utl-sql-partitioning-increase-in-investment-when-interest-rates-change-over-time-compound-interest;

      Increase in investment when interest rates change over time compounding interest

      Obviously this can be done easier in many other ways.
      But I want to demonstrate sql partitioning

      For a intial investment of 1 unit (could be $100, $1,000,000)

           SOLUTIONS
              1 sql sas
              2 sql r
              3 sql python
              4 related repos


    github
    https://tinyurl.com/2s44x4s3
    https://github.com/rogerjdeangelis/utl-sql-partitioning-increase-in-investment-when-interest-rates-change-over-time-compound-interest

    Related to
    https://stackoverflow.com/questions/78946168/total-percent-change-in-a-column-in-r

    /*               _     _
     _ __  _ __ ___ | |__ | | ___ _ __ ___
    | `_ \| `__/ _ \| `_ \| |/ _ \ `_ ` _ \
    | |_) | | | (_) | |_) | |  __/ | | | | |
    | .__/|_|  \___/|_.__/|_|\___|_| |_| |_|
    |_|
    */

    /**************************************************************************************************************************/
    /*                                                                                                                        */
    /* For a intial investment of 1 unit (could be $100, $1,000,000)                                                          */
    /*                                                                                                                        */
    /*        INPUT              PROCESS & OUTPUT                                                                             */
    /*                                                                                                                        */
    /*                                                                                                                        */
    /*   CD     RATE     YEAR                                                                                                 */
    /*                                                                                                                        */
    /*   BNY     0.1     1980                                                                                                 */
    /*   BNY     0.2     1981  (1+.1)*(1.2) = 1.32 Increase                                                                   */
    /*                                                                                                                        */
    /*   FDU     0.5     1980                                                                                                 */
    /*   FDU     0.3     1981  (1+.5)*(1.3) = 1.95 Increase                                                                   */
    /*                                                                                                                        */
    /**************************************************************************************************************************/

    options validvarname=upcase;
    libname sd1 "d:/sd1";
    data sd1.have;
     input CD $4. RATE YEAR;
    cards4;
    BNY 0.1 1980
    BNY 0.2 1981
    FDU 0.5 1980
    FDU 0.3 1981
    ;;;;
    run;quit;

    /*             _
    / |  ___  __ _| |  ___  __ _ ___
    | | / __|/ _` | | / __|/ _` / __|
    | | \__ \ (_| | | \__ \ (_| \__ \
    |_| |___/\__, |_| |___/\__,_|___/
                |_|
    */

    proc sql;
     create
       table want  as
     select
          r.cd
         ,r.year                    as current_year
         ,(1 + l.rate)*(1 + r.rate) as return
     from
         (
         select
           *
         from
           %sqlPartition(sd1.have,by=cd)
         ) as l
     inner join
         (
         select
           *
         from
           %sqlPartition(sd1.have,by=cd)
         ) as r
      on
            l.partition = 1
        and r.partition = 2
        and l.cd        = r.cd

    ;quit;

    /**************************************************************************************************************************/
    /*                                                                                                                        */
    /* WORK.WANT total obs=2                                                                                                  */
    /*                                                                                                                        */
    /*               CURRENT_                                                                                                 */
    /* Obs    CD       YEAR      RETURN                                                                                       */
    /*                                                                                                                        */
    /*  1     BNY      1981       1.32                                                                                        */
    /*  2     FDU      1981       1.95                                                                                        */
    /*                                                                                                                        */
    /**************************************************************************************************************************/

    /*___                     _
    |___ \   _ __   ___  __ _| |
      __) | | `__| / __|/ _` | |
     / __/  | |    \__ \ (_| | |
    |_____| |_|    |___/\__, |_|
                           |_|
    */

    %utl_rbeginx;
    parmcards4;
    library(haven)
    library(sqldf)
    source("c:/oto/fn_tosas9x.R")
    have<-read_sas("d:/sd1/have.sas7bdat")
    print(have)
    want<- sqldf('
     select
          r.cd
         ,r.year                    as current_year
         ,(1 + l.rate)*(1 + r.rate) as return
     from
         (
         select
           *
         from
           (select *, row_number() OVER (PARTITION BY cd) as partition from have )
         ) as l
     inner join
         (
         select
           *
         from
           (select *, row_number() OVER (PARTITION BY cd) as partition from have )
         ) as r
      on
            l.partition = 1
        and r.partition = 2
        and l.cd        = r.cd
    ')
    want
    fn_tosas9x(
          inp    = want
         ,outlib ="d:/sd1/"
         ,outdsn ="rwant"
         )
    ;;;;
    %utl_rendx;

    libname sd1 "d:/sd1";
    proc print data=sd1.rwant;
    run;quit;

    /**************************************************************************************************************************/
    /*                                                                                                                        */
    /*                     CURRENT_                                                                                           */
    /*  ROWNAMES    CD       YEAR      RETURN                                                                                 */
    /*                                                                                                                        */
    /*      1       BNY      1981       1.32                                                                                  */
    /*      2       FDU      1981       1.95                                                                                  */
    /*                                                                                                                        */
    /**************************************************************************************************************************/

    /*____               _   _                             _
    |___ /   _ __  _   _| |_| |__   ___  _ __    ___  __ _| |
      |_ \  | `_ \| | | | __| `_ \ / _ \| `_ \  / __|/ _` | |
     ___) | | |_) | |_| | |_| | | | (_) | | | | \__ \ (_| | |
    |____/  | .__/ \__, |\__|_| |_|\___/|_| |_| |___/\__, |_|
            |_|    |___/                                |_|
    */


    %utl_pybeginx;
    parmcards4;
    import pyarrow.feather as feather
    import tempfile
    import pyperclip
    import os
    import sys
    import subprocess
    import time
    import pandas as pd
    import pyreadstat as ps
    import numpy as np
    from pandasql import sqldf
    mysql = lambda q: sqldf(q, globals())
    from pandasql import PandaSQL
    pdsql = PandaSQL(persist=True)
    sqlite3conn = next(pdsql.conn.gen).connection.connection
    sqlite3conn.enable_load_extension(True)
    sqlite3conn.load_extension('c:/temp/libsqlitefunctions.dll')
    mysql = lambda q: sqldf(q, globals())
    exec(open('c:/oto/fn_tosas9x.py').read())
    have, meta = ps.read_sas7bdat("d:/sd1/have.sas7bdat")
    want=pdsql("""
     select
          r.cd
         ,r.year                    as current_year
         ,(1 + l.rate)*(1 + r.rate) as return
     from
         (
         select
           *
         from
           (select *, row_number() OVER (PARTITION BY cd) as partition from have )
         ) as l
     inner join
         (
         select
           *
         from
           (select *, row_number() OVER (PARTITION BY cd) as partition from have )
         ) as r
      on
            l.partition = 1
        and r.partition = 2
        and l.cd        = r.cd
       """)
    print(want)
    fn_tosas9x(want,outlib="d:/sd1/",outdsn="rwant",timeest=3)
    ;;;;
    %utl_pyendx;

    libname sd1 "d:/sd1";
    proc print data=sd1.rwant;
    run;quit;


    /**************************************************************************************************************************/
    /*                                                                                                                        */
    /* PYTHON                                                                                                                 */
    /*                                                                                                                        */
    /*     CD  current_year  return                                                                                           */
    /* 0  BNY        1981.0    1.32                                                                                           */
    /* 1  FDU        1981.0    1.95                                                                                           */
    /*                                                                                                                        */
    /* SAS                                                                                                                    */
    /*                                                                                                                        */
    /*         CURRENT_                                                                                                       */
    /*  CD       YEAR      RETURN                                                                                             */
    /*                                                                                                                        */
    /*  BNY      1981       1.32                                                                                              */
    /*  FDU      1981       1.95                                                                                              */
    /*                                                                                                                        */
    /**************************************************************************************************************************/

    REPO
    ----------------------------------------------------------------------------------------------------------------------------------
    https://github.com/rogerjdeangelis/utl-adding-sequence-numbers-and-partitions-in-SAS-sql-without-using-monotonic
    https://github.com/rogerjdeangelis/utl-create-equally-spaced-values-using-partitioning-in-sql-wps-r-python
    https://github.com/rogerjdeangelis/utl-find-first-n-observations-per-category-using-proc-sql-partitioning
    https://github.com/rogerjdeangelis/utl-macro-to-enable-sql-partitioning-by-groups-montonic-first-and-last-dot
    https://github.com/rogerjdeangelis/utl-pivot-long-pivot-wide-transpose-partitioning-sql-arrays-wps-r-python
    https://github.com/rogerjdeangelis/utl-pivot-transpose-by-id-using-wps-r-python-sql-using-partitioning
    https://github.com/rogerjdeangelis/utl-top-four-seasonal-precipitation-totals--european-cities-sql-partitions-in-wps-r-python
    https://github.com/rogerjdeangelis/utl-transpose-pivot-wide-using-sql-partitioning-in-wps-r-python
    https://github.com/rogerjdeangelis/utl-transposing-rows-to-columns-using-proc-sql-partitioning
    https://github.com/rogerjdeangelis/utl-transposing-words-into-sentences-using-sql-partitioning-in-r-and-python
    https://github.com/rogerjdeangelis/utl-using-DOW-loops-to-identify-different-groups-and-partition-data
    https://github.com/rogerjdeangelis/utl-using-sql-in-wps-r-python-select-the-four-youngest-male-and-female-students-partitioning
    https://github.com/rogerjdeangelis/utl_partition_a_list_of_numbers_into_3_groups_that_have_the_similar_sums_python
    https://github.com/rogerjdeangelis/utl_partition_a_list_of_numbers_into_k_groups_that_have_the_similar_sums


    /*              _
      ___ _ __   __| |
     / _ \ `_ \ / _` |
    |  __/ | | | (_| |
     \___|_| |_|\__,_|

    */
