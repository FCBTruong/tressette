extends Node


var google_payment: GooglePayment
var apple_payment: ApplePayment
var paypal_payment: PaypalPayment
var shop_packs = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print('Payment Mgr ready')
	_init_payment_goggle()
	_init_payment_apple()
	_init_payment_paypal()

func _process(delta: float) -> void:
	if apple_payment:
		apple_payment.update(delta)

# Payment should init after login success
func _init_payment_goggle():
	if Config.get_platform() == Config.PLATFORMS.ANDROID or \
		Config.CURRENT_MODE == Config.MODES.LOCAL:
			google_payment = GooglePayment.new()
			google_payment.init_connection()
			
func _init_payment_apple():
	if Config.get_platform() == Config.PLATFORMS.IOS or \
		Config.CURRENT_MODE == Config.MODES.LOCAL:
			apple_payment = ApplePayment.new()
			apple_payment.init_connection()
			
func _init_payment_paypal():
	if Config.get_platform() == Config.PLATFORMS.WEB:
			paypal_payment = PaypalPayment.new()

func on_receive(cmd_id: int, payload: PackedByteArray) -> void:
	match cmd_id:
		GameConstants.CMDs.PAYMENT_SUCCESS:
			_handle_payment_success(payload)
		GameConstants.CMDs.SHOP_CONFIG:
			_handle_shop_config(payload)
		GameConstants.CMDs.PAYMENT_APPLE_FINISHED_TRANSACTION:
			_handle_finished_apple_transaction(payload)
		GameConstants.CMDs.PAYMENT_PAYPAL_REQUEST_ORDER:
			paypal_payment._received_order_url(payload)

func _handle_finished_apple_transaction(payload):
	var pkg = GameConstants.PROTOBUF.PACKETS.PaymentFinishedAppleTransaction.new()
	var result_code = pkg.from_bytes(payload)
	var pack_id = pkg.get_pack_id()
	print('_handle_finished_apple_transaction: ', pack_id)
	apple_payment.finsish_transaction(pack_id)
	
func _handle_payment_success(payload):
	var pkg = GameConstants.PROTOBUF.PACKETS.PaymentSuccess.new()
	var result_code = pkg.from_bytes(payload)
	var gold = pkg.get_gold()
	
	SceneManager.show_dialog(tr("YOU_RECEIVED") + ' ' + StringUtils.point_number(gold) \
		+ " " + tr("LIRA"), 
		func():
			print('click ok'),
		func():
			print('click close')
	)
	return
	
# Resume billing that not proccessed yet
# Should call after login
func _on_billing_resume():
	if Config.get_platform() == Config.PLATFORMS.ANDROID:
		google_payment._on_billing_resume()
	elif Config.get_platform() == Config.PLATFORMS.IOS:
		apple_payment._on_billing_resume()
		
			
func test_google_pay():
	var purchase_data = {
		"purchase_token": "nkkijakeekhblnpgfilaepgl.AO-J1OzWw9RKAnR2XeFNfTYBfmGFLMMW8qNGiSI6gnm1nVkNk_rNfiIc8khpWQdWxncMWlA29lRx8LmoFW4cnRRVjuZm6HmdW2kr1EypeK7hIEkl1_YKTBY",
		"is_acknowledged": false,
		"quantity": 1,
		"skus": ["pack_02"],
		"signature": "g01RIc5AEwDrXDeeiVfoLdK8AhdRPJzTYlaDa7eab1P3MV6KGtFQhuDNR01f+aO4y69VjHqUHjOKvT1eFbrFs198xG8MnMUeW2oF3+ANJaqqDT0YfUcsZ6LEgYGSxmQVu1GntPNsgI9ECDFBFhmPT9qA67CZRc6EHyHxb/oWWNd/TAWU9ljH1lkAKm0udWLf2ZWuKHvtlEPe7vgg3FOv7ZpY/PQNcd2qGhMFuKRU0PhpPF7DdBXsfVT4O/cAH8t7P5uTqS6PoWeIARMYpu0w5k7BAqcOxMksJbjOLMPDnSpewEs25J4Xj31QVV3u9wJo+cpk9i+qbTmv81gK1YIzSQ==",
		"package_name": "com.clareentertainment.tressette",
		"original_json": "{\"orderId\":\"GPA.3394-3459-3955-10526\",\"packageName\":\"com.clareentertainment.tressette\",\"productId\":\"pack_02\",\"purchaseTime\":1737387870183,\"purchaseState\":0,\"purchaseToken\":\"nkkijakeekhblnpgfilaepgl.AO-J1OzWw9RKAnR2XeFNfTYBfmGFLMMW8qNGiSI6gnm1nVkNk_rNfiIc8khpWQdWxncMWlA29lRx8LmoFW4cnRRVjuZm6HmdW2kr1EypeK7hIEkl1_YKTBY\",\"quantity\":1,\"acknowledged\":false}",
		"purchase_time": 1737387870183,
		"sku": "pack_02",
		"order_id": "GPA.3394-3459-3955-10526",
		"purchase_state": 1,
		"is_auto_renewing": false
	}
	google_payment._process_purchase(purchase_data)
func on_user_login():
	if Config.get_platform() == Config.PLATFORMS.ANDROID:
		if not google_payment.payment:
			# init again
			_init_payment_goggle()
			
	if Config.get_platform() == Config.PLATFORMS.IOS:
		apple_payment.request_product_info()
		
		# continue resume
	_on_billing_resume()

func get_price_pack(pack_id):
	var price_str = ''
	if Config.get_platform() == Config.PLATFORMS.ANDROID:
		var price_gg = google_payment.get_price_pack(pack_id)
		if price_gg:
			price_str = price_gg
			
	if Config.get_platform() == Config.PLATFORMS.IOS:
		var price_apple = apple_payment.get_price_pack(pack_id)
		if price_apple:
			price_str = price_apple
	
	if price_str == '':
		for p in shop_packs:
			if p['pack_id'] == pack_id:
				price_str = str(p['price']) + ' ' + p['currency']
				break
	return price_str

func buy_pack(pack_id):
	if not pack_id:
		print('Pack ID must not null')
		return
	print('process buy_pack', pack_id)
		
	if Config.get_platform() == Config.PLATFORMS.ANDROID:
		google_payment.purchase_pack(pack_id)
	elif Config.get_platform() == Config.PLATFORMS.IOS:
		apple_payment.purchase_pack(pack_id)
	elif Config.get_platform() == Config.PLATFORMS.WEB:
		paypal_payment.purchase_pack(pack_id)

func _handle_shop_config(payload):
	print('_handle_shop_config')
	var pkg = GameConstants.PROTOBUF.PACKETS.ShopConfig.new()
	var result_code = pkg.from_bytes(payload)
	var pack_ids = pkg.get_pack_ids()
	var golds = pkg.get_golds()
	var prices = pkg.get_prices()
	var currencies = pkg.get_currencies()
	
	shop_packs = []
	for i in range(len(pack_ids)):
		shop_packs.append({
			'pack_id': pack_ids[i],
			'gold': golds[i],
			'price': prices[i],
			'currency': currencies[i]
		})
	
	
