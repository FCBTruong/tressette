extends Node


var google_payment: GooglePayment
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print('Payment Mgr ready')
	_init_payment()

# Payment should init after login success
func _init_payment():
	if Config.get_platform() == Config.PLATFORMS.ANDROID:
		google_payment = GooglePayment.new()
		google_payment.init_connection()

# Resume billing that not proccessed yet
# Should call after login
func _on_billing_resume():
	if Config.get_platform() == Config.PLATFORMS.ANDROID:
		if google_payment.payment.getConnectionState() == google_payment.ConnectionState.CONNECTED:
			google_payment.payment._query_purchases()
			
func on_user_login():
	if Config.get_platform() == Config.PLATFORMS.ANDROID:
		if not google_payment.payment:
			# init again
			_init_payment()
		
		# continue resume
		_on_billing_resume()

func get_price_pack(pack_id):
	var price_str = 'Undefined'
	if Config.get_platform() == Config.PLATFORMS.ANDROID:
		var price_gg = google_payment.get_price_pack(pack_id)
		if price_gg:
			price_str = price_gg
	return price_str
