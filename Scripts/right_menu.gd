extends CanvasLayer

var full_heart: Texture = load("res://Textures/UI/heart.png")
var empty_heart: Texture = load("res://Textures/UI/heart_empty.png")

@onready var budget_label: Label = $side_panel/MarginContainer/Control/budget_label
@onready var grid_container: GridContainer = $side_panel/MarginContainer/Control/shop_panel/ScrollContainer/GridContainer
@onready var hearts_group: Control = $side_panel/MarginContainer/Control/hearts

var shop_button_scene = load("res://UI/shop_button.tscn")

func _on_budget_changed():
	budget_label.text = "Tax Dollars: " + str(Globals.budget)


func _on_health_changed(health: int):
	for i in range(10, health, -1):
		var heart = hearts_group.get_node(str(i - 1)).get_node("TextureRect")
		heart.texture = empty_heart


func _on_shop_button_pressed(tower_id: String):
	print(tower_id)
	TowerHandler.create_tower(tower_id, Vector2(400, 400))


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Globals.budget_changed.connect(_on_budget_changed)
	Globals.health_changed.connect(_on_health_changed)
	
	for tower_information in Globals.tower_information:
		var this = shop_button_scene.instantiate()
		
		var name_label: Label = this.get_node("Button").get_node("Background").get_node("Name")
		var price_label: Label = this.get_node("Button").get_node("Background").get_node("Price")
		var preview_image: TextureRect = this.get_node("Button").get_node("Background").get_node("Preview")
		
		name_label.text = str(tower_information.name)
		price_label.text = str(tower_information.price)
		preview_image.texture = tower_information.texture
		
		this.get_node("Button").connect("pressed", _on_shop_button_pressed.bind(tower_information.id))
		
		grid_container.add_child(this)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
