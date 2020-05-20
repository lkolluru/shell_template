# Workflow Information

Workflow responsible for creation and execution of onboarding model aggregations.

## Process Shell Modules

* **CAONWC10.sh**: BQ and HDP based aggregations on match code. 
* **CAONWE20.sh**: Historical Models aggregations on pto, ptp, pte.

### Workflow Clean up Information:
* **Usage Details**: Execute the procedue in the event of any manual exeuciton to reset the logging and being the workflow to execute from the begining.
```sql
EXEC appinfo.dbp_clenuplogginginfo @variablefunctionalgroupcode = N'onb' -- nvarchar(100)
```
### Workflow Execution sneak peek:
* **Usage Details**: Execute the view to determine current run state of the application.
```sql
SELECT * FROM metadatainfo.variablefucntionalgroupinfo

SELECT * FROM appinfo.vw_get_latestunitofworkitems_info
WHERE variablefunctionalgroupcode='onb'
```