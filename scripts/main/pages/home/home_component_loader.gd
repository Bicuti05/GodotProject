class_name HomeComponentLoader
extends PageComponentLoader


const GROUP_SCENES: Dictionary = {
	"chapter": {
		"Root/HexBoard": "res://scripts/gameplay/outer_loop/view/hex_board.tscn", 
		"Root/HexBackdrop": "res://scripts/gameplay/outer_loop/view/outer_loop_backdrop.tscn", 
	}, 
	"rank": {
		"AvatarPool": "res://scripts/gameplay/rank/view/rank_avatar_pool.tscn", 
		"Root/RankEntryLayout/RankEntry": "res://scripts/gameplay/rank/view/rank_home_entry.tscn", 
		"Root/HomeNav/AvatarButton": "res://scripts/gameplay/rank/view/rank_avatar_cell.tscn", 
	}, 
	"fx": {"Root/PlayButton/HomeButtonFx": "res://scripts/main/pages/home/home_button_fx.tscn"}, 
}


func _init(page: Node) -> void :
	super (page, GROUP_SCENES)
