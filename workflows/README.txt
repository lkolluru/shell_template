onb workflows test git gui

Execution instructions for Merklehh, merklezip and allianthh
-------------------------------------------------------------
1. The sql queries to load the data into the above subject area are part of ONBEXPORT functional group.
2. onb_pto_historical, onb_ptp_historical, onb_pte_historical are part of the schedule process and are enable in DB by setting the value to '1' 
    in the column variabletablegrouprebuildflag.
3. All other tables groups under ONBEXPORT functional group are disabled by seeting the the value as '-1' in the coulmn variabletablegrouprebuildflag in the DB.
4. In order to run the ondemand workflow of 
        a. allianthh
        b. merklehh
        c. merklezip
    please enable the table group executing by setting the value of variabletablegrouprebuildflag from '-1' to '1' and disabling the tablegroup by
    setting teh value of variabletablegrouprebuildflag from '1' to '-1' in DB.
5. For production the below tablegroups are only enabled for execution.
        a. ptp_historical_scores
        b. pto_historical_scores
        c. pte_historical_scores