xsim {tb_top_sim} -testplusarg TEST=overwrite -wdb {overwrite_apb_wave.wdb} -cov_db_name overwrite -autoloadwcfg -tclbatch {overwrite_cov.tcl} -onfinish stop
