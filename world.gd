extends Node3D

var pixelSize = 4
var pixelOffset = Vector2(0.01, 0.01)


# Called when the node enters the scene tree for the first time.
func _ready():
	var material : ShaderMaterial = get_node("CanvasLayer/PixelScreen").get_material()
	material.set_shader_parameter("pixelSize", pixelSize);
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ui_page_up"):
		pixelSize += 2
		var material : ShaderMaterial = get_node("CanvasLayer/PixelScreen").get_material()
		material.set_shader_parameter("pixelSize", pixelSize);
	if Input.is_action_just_pressed("ui_page_down"):
		pixelSize = max(pixelSize - 2, 2);
		var material : ShaderMaterial = get_node("CanvasLayer/PixelScreen").get_material()
		material.set_shader_parameter("pixelSize", pixelSize);

	# Moving Camera
	# Calculating the amount of movement necessary to move by 1 pixel on screen:
	var camera_obj = get_node("CamBase/CameraObject")
	var camera_speed = 2
	var camera_speed_x = camera_obj.size * camera_speed / camera_obj.get_window().size.y
	var camera_speed_z = camera_obj.size * camera_speed / (camera_obj.get_window().size.y * sin(camera_obj.rotation[0]))

	
	if Input.is_action_pressed("ui_right"):
		get_node("CamBase/CameraObject").position.x -= camera_speed_x
		pixelOffset[0] -= camera_speed
		get_node("CanvasLayer/PixelScreen").get_material().set_shader_parameter("pixelOffset", pixelOffset);
		
	if Input.is_action_pressed("ui_left"):
		get_node("CamBase/CameraObject").position.x += camera_speed_x
		pixelOffset[0] += camera_speed
		get_node("CanvasLayer/PixelScreen").get_material().set_shader_parameter("pixelOffset", pixelOffset);
		
	if Input.is_action_pressed("ui_down"):
		get_node("CamBase/CameraObject").position.z += camera_speed_z
		pixelOffset[1] += camera_speed
		get_node("CanvasLayer/PixelScreen").get_material().set_shader_parameter("pixelOffset", pixelOffset);
		
	if Input.is_action_pressed("ui_up"):
		get_node("CamBase/CameraObject").position.z -= camera_speed_z
		pixelOffset[1] -= camera_speed
		get_node("CanvasLayer/PixelScreen").get_material().set_shader_parameter("pixelOffset", pixelOffset);
		
	pass
