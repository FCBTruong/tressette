extends Node
class_name EmoticonMgr
const EMOTICONS_FOLDER = "user://emoticons/"
const URLS = {
	# Smile teeth
	"1": "https://fonts.gstatic.com/s/e/notoemoji/latest/1f601/512.gif",
	
	# Heart eyes
	"2": "https://fonts.gstatic.com/s/e/notoemoji/latest/1f60d/512.gif",
	
	# Loady crying
	"3": "https://fonts.gstatic.com/s/e/notoemoji/latest/1f62d/512.gif",
	
	# Joy
	"4": "https://fonts.gstatic.com/s/e/notoemoji/latest/1f602/512.gif",
	
	# angry
	"5": "https://fonts.gstatic.com/s/e/notoemoji/latest/1f621/512.gif",
	
	# Cold face
	"6": 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f976/512.gif',
	
	# Thinking face
	"7": 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f914/512.gif',
	
	# Happy cry
	"8": 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f972/512.gif',
	
	# Screaming
	"9": 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f631/512.gif',
	
	# Clapping
	'10': 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f44f/512.gif',
	
	# Hug face
	'11': 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f917/512.gif',
	
	# Flushed
	'12': 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f633/512.gif',
	
	# Sleepy
	'13': 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f634/512.gif',
	
	# Sun glass face
	'14': 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f60e/512.gif',
	
	'15': 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f92e/512.gif'
	
}

var keys_to_download = []  # List of keys needing downloads
var current_key = null  # Track current download
@onready var http_request = HTTPRequest.new()
func _ready():
	# Ensure the emoticons folder exists
	var dir = DirAccess.open("user://")
	add_child(http_request)
	if not dir.dir_exists(EMOTICONS_FOLDER):
		dir.make_dir(EMOTICONS_FOLDER)
	
	# Check which files are missing
	for key in URLS.keys():
		var save_path = EMOTICONS_FOLDER + key + ".gif"
		if not FileAccess.file_exists(save_path):
			keys_to_download.append(key)
	
	# Start downloading missing files
	if keys_to_download:
		download_next()
		#
	for i in range(15):  
		load_gif_async(i) 

func download_next():
	if keys_to_download.is_empty():
		return  # No more files to download
	
	current_key = keys_to_download.pop_front()
	http_request.request(URLS[current_key])
	http_request.connect("request_completed", Callable(self, "_on_http_request_request_completed"))

func _on_http_request_request_completed(_result, _response_code, _headers, body):
	if current_key:
		var save_path = EMOTICONS_FOLDER + current_key + ".gif"
		var file = FileAccess.open(save_path, FileAccess.WRITE)
		file.store_buffer(body)
		file.close()
		print("Downloaded:", current_key, "->", save_path)
	
	download_next()  # Proceed to next download

var texture_cache = {}
func get_texture_emoticon(emo_id):
	if not texture_cache.has(emo_id):
		var texture_path = "user://emoticons/" + str(emo_id) + '.gif'
		texture_cache[emo_id] = GifManager.animated_texture_from_file(texture_path)
	return texture_cache[emo_id]


var thread_pool = {}

func load_gif_async(emo_id):
	if texture_cache.has(emo_id):  
		return  

	var texture_path = "user://emoticons/" + str(emo_id) + ".gif"
	var thread = Thread.new()
	thread_pool[emo_id] = thread  # Store thread reference

	# Use Callable instead of string
	var callable = Callable(self, "_load_gif").bind(emo_id, texture_path)
	thread.start(callable)

func _load_gif(emo_id, texture_path):
	texture_cache[emo_id] = GifManager.animated_texture_from_file(texture_path)

	# Free the thread after loading is done
	thread_pool[emo_id].wait_to_finish()
	thread_pool.erase(emo_id)
