class_name ApplePayment
var _appstore = null

func check_events():
	pass

var packs = [
	'pack10',
	'com.clareentertainment.tressette.pack_01',
	'pack_01',
	'pack_02'
]
#
#func _on_Restore_button_down(): # such button is required by Apple for non-consumable products
	#var result = _appstore.restore_purchases()
	
func init_connection():
	print('debug ios appp2')
	if Engine.has_singleton("InAppStore"):
		print('has app store....')
		_appstore = Engine.get_singleton('InAppStore')
		
		var result = _appstore.request_product_info( { "product_ids": packs } )
	else:
		print('not inapp store ios')
		
	
func _on_billing_resume():
	if not _appstore:
		return
	print("Apple: resume billing")
	while _appstore.get_pending_event_count() > 0:
		var event = _appstore.pop_pending_event()
		if event.type == "purchase":
			_process_purchase(event)
	
func get_price_pack(pack_id):
	return ""
	
func purchase_pack(pack_id):
	var result = _appstore.purchase({'product_id': pack_id})
	print('resulttt', result)
	_process_purchase(result)
	
func request_product_info():
	var result = _appstore.request_product_info({ "product_ids": ["pack_01"] })
	print('request_product_info', result)
	
func _process_purchase(purchase):
	print('apple payment: _process_purchase', purchase)
	var pack_id = ""
	var receipt_data = ""
	
	var pkg = GameConstants.PROTOBUF.PACKETS.PaymentAppleConsume.new()
	pkg.set_pack_id(pack_id)
	pkg.set_receipt_data(receipt_data)
	GameClient.send_packet(GameConstants.CMDs.PAYMENT_GOOGLE_CONSUME, pkg.to_bytes())
	
	# SEND TO SERVER TO VERIFY

func test():
	if not _appstore:
		return
	var result = _appstore.request_product_info( { "product_ids": packs } )
