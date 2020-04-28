
DROP VIEW IF EXISTS ${hivevar:DEP_ENV}_im_calc_engine.vw_flt_agg_oflnsel_hybridmod321;

CREATE VIEW IF NOT EXISTS ${hivevar:DEP_ENV}_im_calc_engine.vw_flt_agg_oflnsel_hybridmod321 COMMENT 'oflnsel' AS SELECT  agg_oflnsel_mod321.abe12 , 
agg_oflnsel_mod321.avgpw , 
agg_oflnsel_mod321.constantvalueinfo.Auto_Ship AS Auto_Ship , 
agg_oflnsel_mod321.constantvalueinfo.Deeper_Main_X AS Deeper_Main_X , 
agg_oflnsel_mod321.constantvalueinfo.Mag_Total AS Mag_Total , 
agg_oflnsel_mod321.constantvalueinfo.Merch_General AS Merch_General , 
agg_oflnsel_mod321.constantvalueinfo.paradigm AS paradigm , 
agg_oflnsel_mod321.constantvalueinfo.Top_Coincident_X AS Top_Coincident_X , 
agg_oflnsel_mod321.constantvalueinfo.Top_Main_X AS Top_Main_X , 
agg_oflnsel_mod321.constantvalueinfo.Total_Mag_Merch AS Total_Mag_Merch , 
agg_oflnsel_mod321.constantvalueinfo.valid_mail_count AS valid_mail_count , 
agg_oflnsel_mod321.cust_id , 
agg_oflnsel_mod321.doleff1y , 
agg_oflnsel_mod321.doleff2y , 
agg_oflnsel_mod321.eff_ctr , 
agg_oflnsel_mod321.geo_loc , 
agg_oflnsel_mod321.hspay3mo , 
agg_oflnsel_mod321.int4 , 
agg_oflnsel_mod321.mag24 , 
agg_oflnsel_mod321.navint , 
agg_oflnsel_mod321.neff24 , 
agg_oflnsel_mod321.nefft6m , 
agg_oflnsel_mod321.nent24 , 
agg_oflnsel_mod321.nmis1y , 
agg_oflnsel_mod321.nmis2y , 
agg_oflnsel_mod321.npavgeff , 
agg_oflnsel_mod321.npcumcch , 
agg_oflnsel_mod321.npdoleft , 
agg_oflnsel_mod321.npefslnn , 
agg_oflnsel_mod321.npnnyr2p , 
agg_oflnsel_mod321.npordys4 , 
agg_oflnsel_mod321.npordys7 , 
agg_oflnsel_mod321.nppdord , 
agg_oflnsel_mod321.nppdy1sq , 
agg_oflnsel_mod321.nret12ms , 
agg_oflnsel_mod321.nret7mo , 
agg_oflnsel_mod321.off_ord_dys , 
agg_oflnsel_mod321.ord24 , 
agg_oflnsel_mod321.ord3 , 
agg_oflnsel_mod321.ord6 , 
agg_oflnsel_mod321.ordda3 , 
agg_oflnsel_mod321.ordda4 , 
agg_oflnsel_mod321.pdo3 , 
agg_oflnsel_mod321.pnoltv1 , 
agg_oflnsel_mod321.poltv1 , 
agg_oflnsel_mod321.poltv12 , 
agg_oflnsel_mod321.poltv3 , 
agg_oflnsel_mod321.rgm6 , 
agg_oflnsel_mod321.scqqord , 
agg_oflnsel_mod321.sefrat4 , 
agg_oflnsel_mod321.selection_dt , 
agg_oflnsel_mod321.sord2y , 
agg_oflnsel_mod321.spppn2y , 
agg_oflnsel_mod321.tdays1 , 
agg_oflnsel_mod321.tdays2 , 
agg_oflnsel_mod321.tdys1 , 
agg_oflnsel_mod321.topdor6 , 
agg_oflnsel_mod321.totnnon1 , 
agg_oflnsel_mod321.tprd1 , 
agg_oflnsel_mod321.tprfudys , 
agg_oflnsel_mod321.trdys5 , 
agg_oflnsel_mod321.vars601  FROM ${hivevar:DEP_ENV}_IM_CALC_ENGINE.agg_oflnsel_hybridmod321;