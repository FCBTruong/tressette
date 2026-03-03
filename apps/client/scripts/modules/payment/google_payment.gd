class_name GooglePayment
var payment

# Matches Purchase.PurchaseState in the Play Billing Library
enum PurchaseState {
	UNSPECIFIED,
	PURCHASED,
	PENDING,
}

# Matches BillingClient.ConnectionState in the Play Billing Library
enum ConnectionState {
	DISCONNECTED, # not yet connected to billing service or was already closed
	CONNECTING, # currently in process of connecting to billing service
	CONNECTED, # currently connected to billing service
	CLOSED, # already closed and shouldn't be used again
}

var packs = [
	'first_buy_offer',
	'pack_01',
	'pack_02',
	'pack_03',
	'pack_04',
	'pack_05'
]

var packages:Array = []

func init_connection():
	print('GooglePayment on ready')
	if Engine.has_singleton("GodotGooglePlayBilling"):
		payment = Engine.get_singleton("GodotGooglePlayBilling")

		# These are all signals supported by the API
		# You can drop some of these based on your needs
		payment.billing_resume.connect(_on_billing_resume) # No params
		payment.connected.connect(_on_connected) # No params
		payment.disconnected.connect(_on_disconnected) # No params
		payment.connect_error.connect(_on_connect_error) # Response ID (int), Debug message (string)
		payment.price_change_acknowledged.connect(_on_price_acknowledged) # Response ID (int)
		payment.purchases_updated.connect(_on_purchases_updated) # Purchases (Dictionary[])
		payment.purchase_error.connect(_on_purchase_error) # Response ID (int), Debug message (string)
		payment.sku_details_query_completed.connect(_on_product_details_query_completed) # Products (Dictionary[])
		payment.sku_details_query_error.connect(_on_product_details_query_error) # Response ID (int), Debug message (string), Queried SKUs (string[])
		payment.purchase_acknowledged.connect(_on_purchase_acknowledged) # Purchase token (string)
		payment.purchase_acknowledgement_error.connect(_on_purchase_acknowledgement_error) # Response ID (int), Debug message (string), Purchase token (string)
		payment.purchase_consumed.connect(_on_purchase_consumed) # Purchase token (string)
		payment.purchase_consumption_error.connect(_on_purchase_consumption_error) # Response ID (int), Debug message (string), Purchase token (string)
		payment.query_purchases_response.connect(_on_query_purchases_response) # Purchases (Dictionary[])

		payment.startConnection()
	else:
		print("Android IAP support is not enabled. Make sure you have enabled 'Gradle Build' and the GodotGooglePlayBilling plugin in your Android export settings! IAP will not work.")
	
func _on_connected():
	print('payment: _on_connected')
	payment.querySkuDetails(packs, "inapp") # "subs" for subscriptions

func _on_disconnected():
	print('payment: _on_disconnected')
	pass
	
func _on_connect_error(response_id: int, message: String):
	print('payment: _on_connect_error', response_id, message)
	pass

enum BillingResponse {SUCCESS = 0, CANCELLED = 1}

func confirm_price_change(product_id):
	print('payment: confirm_price_change')
	payment.confirmPriceChange(product_id)
		
func _on_price_acknowledged(response_id):
	if response_id == BillingResponse.SUCCESS:
		print("price_change_accepted")
	elif response_id == BillingResponse.CANCELLED:
		print("price_change_canceled")
	
func _on_purchases_updated(purchases):
	print('payment: _on_purchases_updated')
	for purchase in purchases:
		_process_purchase(purchase)
		
func _on_purchase_error(response_id, error_message):
	print("purchase_error id:", response_id, " message: ", error_message)
	
func _on_product_details_query_completed(product_details):
	packages.clear()
	print('payment: _on_product_details_query_completed: ', len(product_details))
	for available_product in product_details:
		print(available_product)
		packages.append(available_product)
	
func _on_product_details_query_error(response_id, error_message, products_queried):
	print("on_product_details_query_error id:", response_id, " message: ",
			error_message, " products: ", products_queried)
	
func _on_purchase_acknowledgement_error(response_id, error_message, purchase_token):
	print("_on_purchase_acknowledgement_error id: ", response_id,
			" message: ", error_message)
	_handle_purchase_token(purchase_token, false)

func _on_purchase_consumed(token: String):
	print('payment: _on_purchase_consumed')
	pass
	
func _handle_purchase_token(purchase_token, purchase_successful):
	print('payment: _handle_purchase_token')
	# check/award logic, remove purchase from tracking list
	pass
	
func _on_purchase_acknowledged(purchase_token):
	print('payment: _on_purchase_acknowledged')
	_handle_purchase_token(purchase_token, true)
	
func _on_purchase_consumption_error(response_id, error_message, purchase_token):
	print("_on_purchase_consumption_error id:", response_id,
			" message: ", error_message)
	_handle_purchase_token(purchase_token, false)


func _on_query_purchases_response(query_result):
	print('payment: _on_query_purchases_response')
	if query_result.status == OK:
		for purchase in query_result.purchases:
			_process_purchase(purchase)
	else:
		print("queryPurchases failed, response code: ",
				query_result.response_code,
				" debug message: ", query_result.debug_message)

func _process_purchase(purchase):
	print('payment: _process_purchase')
	if g.v.config.CURRENT_MODE != g.v.config.MODES.LIVE:
		for key in purchase.keys():
			print("%s: %s" % [key, purchase[key]])
	# get all keys and log
	# Send to server to consume
	
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.PaymentGoogleConsume.new()
	pkg.set_purchase_token(purchase['purchase_token'])
	pkg.set_quantity(purchase['quantity'])
	pkg.set_sku(purchase['sku'])
	pkg.set_signature(purchase['signature'])
	g.v.game_client.send_packet(g.v.game_constants.CMDs.PAYMENT_GOOGLE_CONSUME, pkg.to_bytes())
		#payment.consumePurchase(purchase.purchase_token)

	
func get_price_pack(pack_id):
	for p in packages:
		if p['sku'] == pack_id:
			return p['original_price']
	return null
	
func purchase_pack(pack_id):
	payment.purchase(pack_id)
	
	
func _on_billing_resume():
	print('payment: _on_billing_resume')
	if payment.getConnectionState() == ConnectionState.CONNECTED:
		_query_purchases()
		
func _query_purchases():
	print('payment: _query_purchases')
	payment.queryPurchases("inapp") # Or "subs" for subscriptions
