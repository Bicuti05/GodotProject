extends RefCounted



static func prepare(page: JuiceGamePage, component_scripts: Dictionary = {}, 
		additional_groups: Array[String] = [], prepare_coins: bool = false, 
		prepare_props: bool = false) -> void :
	if not page.is_node_ready():
		await page.ready
	if page._components == null:
		page._components = PageComponentLoader.new(page, GamePagePreparation.COMPONENT_SCENES)
	for path: String in component_scripts:
		var resource_path: String = GamePagePreparation.COMPONENT_SCENES["core"][path]
		var component: Node = (load(resource_path) as PackedScene).instantiate()
		component.set_script(component_scripts[path])
		var scene: = PackedScene.new()
		assert (scene.pack(component) == OK, "Cannot pack component fixture: " + path)
		component.free()
		page._components._resources[resource_path] = scene
	var active: Callable = func() -> bool: return is_instance_valid(page) and page.is_inside_tree()
	var groups: Array[String] = ["core"]
	groups.append_array(additional_groups)
	assert ( await page._ensure_component_groups(groups, active), "Game component fixture preparation failed")
	if prepare_props:
		for index: int in 3:
			page._build_prop_button(index)
	page._components_ready = true
	if prepare_coins:
		assert ( await page._components.ensure_resources(PackedStringArray([GamePagePreparation.WIN_COIN_PATH]), active), 
			"Game coin fixture preparation failed")
