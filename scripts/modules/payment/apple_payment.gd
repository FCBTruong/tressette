class_name ApplePayment
var _appstore = null

var packs = [
	'pack_01',
	'pack_02',
	'pack_03',
	'pack_04',
	'pack_05'
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
		

var last_time = 0.0
const INTERVAL = 0.5  # Time interval in seconds

func update(delta):
	last_time += delta  # Accumulate the elapsed time
	if last_time >= INTERVAL:
		check_events()
		last_time = 0.0  # Reset the timer
	
func _on_billing_resume():
	print("Apple: resume billing")
	pass

func check_events():
	if not _appstore:
		return
	print("Check event apple pay")
	while _appstore.get_pending_event_count() > 0:
		print("Pending event count", _appstore.get_pending_event_count())
		var event = _appstore.pop_pending_event()
		print("eventt", event.type)
		if event.type == "purchase":
			_handle_purchase_result(event)
		elif event.type == "restore":
			pass
		elif event.type == "product_info":
			if event.result == "ok":
				var titles = event.titles
				var descriptions = event.descriptions
				var prices = event.prices
				var ids = event.ids
				var localized_prices = event.localized_prices
				var currency_codes = event.currency_codes
			else:
				print("get product info failed")

	
func get_price_pack(pack_id):
	return ""
	
func purchase_pack(pack_id):
	var result = _appstore.purchase({'product_id': pack_id})
	print('resulttt apple pay', result)
	
	if result != pack_id:
		SceneManager.show_dialog(tr("ERROR_PAY_APPLE") + ', Error: ' + result)
	
func request_product_info():
	var result = _appstore.request_product_info({ "product_ids": packs })
	print('request_product_info', result)
	
func _process_purchase(pack_id, receipt):
	print('apple payment: _process_purchase', pack_id)
	LogsMgr.log_dev("packkk: " + pack_id)
	LogsMgr.log_dev("Receipt apple" + receipt)

	
	var pkg = GameConstants.PROTOBUF.PACKETS.PaymentAppleConsume.new()
	pkg.set_pack_id(pack_id)
	pkg.set_receipt_data(receipt)
	GameClient.send_packet(GameConstants.CMDs.PAYMENT_APPLE_CONSUME, pkg.to_bytes())
	
	# SEND TO SERVER TO VERIFY

func test():
	if not _appstore:
		return
	var result = _appstore.request_product_info( { "product_ids": packs } )

func _handle_purchase_result(event):
	if event.result == "ok":
		# handle buy success
		var receipt = event.receipt
		var pack_id = event.product_id
		_process_purchase(pack_id, receipt)
		pass
	elif event.result == "unhandled":
		SceneManager.show_dialog(tr("TRANSACTION_IS_UNHANDLED") + ', Error: ' + event.result)
		pass
	elif event.result == "progress":
		print("pay on progress")
		
