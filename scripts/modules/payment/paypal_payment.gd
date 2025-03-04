class_name PaypalPayment


func purchase_pack(pack_id):
	# Send request to server to get paypal url
	SceneManager.add_loading(5)
	var pkg = GameConstants.PROTOBUF.PACKETS.PaymentPaypalRequestOrder.new()
	pkg.set_pack_id(pack_id)
	GameClient.send_packet(GameConstants.CMDs.PAYMENT_PAYPAL_REQUEST_ORDER, pkg.to_bytes())

func _received_order_url(payload):
	var pkg = GameConstants.PROTOBUF.PACKETS.PaymentPaypalOrder.new()
	var result_code = pkg.from_bytes(payload)
	var order_url = pkg.get_order_url()
	OS.shell_open(order_url)
