class_name WebGoogleSignIn

var my_callback = JavaScriptBridge.create_callback(on_google_login_success)
func init_siginin():
	if OS.has_feature("web"):  
		JavaScriptBridge.eval("""
			var godotBridge = {
				callback: null,
				setCallback: (cb) => this.callback = cb,
				googleLoginSuccess: (data) => this.callback(JSON.stringify(data)),
			};
			""", true)
		var godot_bridge = JavaScriptBridge.get_interface("godotBridge")
		godot_bridge.setCallback(my_callback)
		
func login_google():
	if OS.has_feature("web"):
		JavaScriptBridge.eval("googleLogin();", true)

func on_google_login_success(args):
	var token = str(args[0])
	var sub_type = 1 # google 
	print(typeof(token))  # Should print TYPE_STRING (4)
	token = token.replace('"', "")
	g.v.login_mgr.send_login_firebase(token, sub_type)
	print("Google login successful! Token:", token)
