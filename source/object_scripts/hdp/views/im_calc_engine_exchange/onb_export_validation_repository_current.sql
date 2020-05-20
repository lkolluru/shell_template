drop view if exists ${hivevar:DEP_ENV}_im_calc_engine_exchange.onb_export_validation_repository_current;
CREATE VIEW ${hivevar:DEP_ENV}_im_calc_engine_exchange.onb_export_validation_repository_current as
select *
from ${hivevar:DEP_ENV}_im_calc_engine_exchange.onb_export_validation_repository
where load_time = `current_date`();