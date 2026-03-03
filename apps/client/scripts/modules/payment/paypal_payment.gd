class_name PaypalPayment


func purchase_pack(pack_id):
	# Send request to server to get paypal url
	g.v.scene_manager.add_loading(5)
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.PaymentPaypalRequestOrder.new()
	pkg.set_pack_id(pack_id)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.PAYMENT_PAYPAL_REQUEST_ORDER, pkg.to_bytes())

func _received_order_url(payload):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.PaymentPaypalOrder.new()
	var result_code = pkg.from_bytes(payload)
	var order_url = pkg.get_order_url()
	OS.shell_open(order_url)
