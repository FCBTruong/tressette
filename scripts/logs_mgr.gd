extends RefCounted
class_name LogsMgr

func log_dev(str, group = ""):
	if g.v.config.CURRENT_MODE == g.v.config.MODES.LIVE:
		return
	var log = "LOG_DEV: " + group + ": " + str
	print(log)
	
