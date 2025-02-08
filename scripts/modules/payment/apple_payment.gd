extends Node
var _appstore = null

func check_events():
	pass
	
func _on_Purchase_button_down():
	var result = _appstore.purchase({'product_id': "product_1"})
	

func _on_Restore_button_down(): # such button is required by Apple for non-consumable products
	var result = _appstore.restore_purchases()
	
func _ready():
	print('debug ios appp')
	if Engine.has_singleton("InAppStore"):
		print('has app store....')
		_appstore = Engine.get_singleton('InAppStore')
	else:
		print('not inapp store ios')
		
	
