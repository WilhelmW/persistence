mod_config = {
	money_to_keep_on_death = 0.25,
	research_wand_price_multiplier = 1,
	research_spell_price_multiplier = 10,
	buy_wand_price_multiplier = 1,
	buy_spell_price_multiplier = 1,
	enable_edit_wands_in_lobby = true,
	enable_teleport_back_up = true,
	enable_menu_in_holy_mountain = false,
	reuseable_holy_mountain = false,
	spawn_location_as_lobby_location = false, -- false -> the lobby location will be relative to the mouse controlls stone; true -> the lobby location will be on the spawn location
	always_choose_save_id = -1, -- -1 -> choose manualy; 0 -> choose to not use the mod; 1-5 -> choose saveslot
	default_wands = {
		{
			name = "Handgun",
			file = "data/items_gfx/handgun.png",
			grip_x = 4,
			grip_y = 4,
			tip_x = 12,
			tip_y = 4
		},
		{
			name = "Bomb wand",
			file = "data/items_gfx/bomb_wand.png",
			grip_x = 4,
			grip_y = 4,
			tip_x = 12,
			tip_y = 4
		}
	}
};