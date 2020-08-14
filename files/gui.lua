dofile_once("mods/persistence/config.lua");
dofile_once("mods/persistence/files/data_store.lua");
dofile_once("mods/persistence/files/helper.lua");
dofile_once("data/scripts/gun/procedural/wands.lua");
dofile_once("mods/persistence/files/wand_spell_helper.lua");

local gui = GuiCreate();
local active_windows = {};

local function gui_sprite(x, y, file_path)
	local cx, cy = GameGetCameraPos();
	local size_x, size_y = get_screen_size();
	GameCreateSpriteForXFrames(file_path, cx - size_x / 2 + size_x * (x / 100), cy - size_y / 2 + size_y * (y / 100), false);
end

function show_save_selector_gui()
	local delete_save_confirmation = 0;
	active_windows["save_selector"] = { true, function (get_next_id)
		GuiLayoutBeginVertical(gui, 1, 20);
		for i = 1, get_save_count() do
			GuiText(gui, 0, 0, "Save slot " .. pad_number(i, #tostring(get_save_count())) .. ":");
			if get_save_ids()[i] == nil then
				if GuiButton(gui, 20, 0, "Create new save", get_next_id()) then
					set_selected_save_id(i);
					create_new_save(i);
					hide_save_selector_gui();
					OnSaveAvailable(i);
					enable_controlls();
				end
			else
				if GuiButton(gui, 20, 0, "Load save", get_next_id()) then
					set_selected_save_id(i);
					load(i);
					hide_save_selector_gui();
					OnSaveAvailable(i);
					enable_controlls();
				end
				if delete_save_confirmation == i then
					if GuiButton(gui, 20, 0, "Press again to delete", get_next_id()) then
						delete_save_confirmation = 0;
						delete_save(i);
					end
				else
					if GuiButton(gui, 20, 0, "Delete save", get_next_id()) then
						delete_save_confirmation = i;
					end
				end
			end
		end
		if GuiButton(gui, 0, 20, "Play without this mod", get_next_id()) then
			set_selected_save_id(0);
			hide_save_selector_gui();
			enable_controlls();
		end
		GuiLayoutEnd(gui);
	end };
end

function hide_save_selector_gui()
	active_windows["save_selector"] = nil;
end

function show_money_gui()
	active_windows["money"] = { false, function(get_next_id)
		local save_id = get_selected_save_id();
		local safe_money = get_safe_money(save_id);
		local player_money = get_player_money();

		GuiLayoutBeginHorizontal(gui, 85, 15);
		GuiLayoutBeginVertical(gui, 0, 0);
		if safe_money < 1 then
			GuiText(gui, 0, 0, "^ 1$");
		else
			if GuiButton(gui, 0, 0, "^ 1$", get_next_id()) then
				transfer_money_to_player(save_id, 1);
			end
		end
		if safe_money < 10 then
			GuiText(gui, 0, 0, "^ 10$");
		else
			if GuiButton(gui, 0, 0, "^ 10$", get_next_id()) then
				transfer_money_to_player(save_id, 10);
			end
		end
		if safe_money < 100 then
			GuiText(gui, 0, 0, "^ 100$");
		else
			if GuiButton(gui, 0, 0, "^ 100$", get_next_id()) then
				transfer_money_to_player(save_id, 100);
			end
		end
		if safe_money < 1000 then
			GuiText(gui, 0, 0, "^ 1000$");
		else
			if GuiButton(gui, 0, 0, "^ 1000$", get_next_id()) then
				transfer_money_to_player(save_id, 1000);
			end
		end
		if GuiButton(gui, 0, 0, "^ ALL", get_next_id()) then
			transfer_money_to_player(save_id, safe_money);
		end
		GuiLayoutEnd(gui);
		GuiLayoutAddHorizontalSpacing(gui);
		GuiLayoutAddHorizontalSpacing(gui);
		GuiLayoutAddHorizontalSpacing(gui);
		GuiLayoutAddHorizontalSpacing(gui);
		GuiLayoutAddHorizontalSpacing(gui);
		GuiLayoutBeginVertical(gui, 0, 0);
		if GuiButton(gui, 0, 0, "v ALL", get_next_id()) then
			transfer_money_to_safe(save_id, player_money);
		end
		if player_money < 1000 then
			GuiText(gui, 0, 0, "v 1000$");
		else
			if GuiButton(gui, 0, 0, "v 1000$", get_next_id()) then
				transfer_money_to_safe(save_id, 1000);
			end
		end
		if player_money < 100 then
			GuiText(gui, 0, 0, "v 100$");
		else
			if GuiButton(gui, 0, 0, "v 100$", get_next_id()) then
				transfer_money_to_safe(save_id, 100);
			end
		end
		if player_money < 10 then
			GuiText(gui, 0, 0, "v 10$");
		else
			if GuiButton(gui, 0, 0, "v 10$", get_next_id()) then
				transfer_money_to_safe(save_id, 10);
			end
		end
		if player_money < 1 then
			GuiText(gui, 0, 0, "v 1$");
		else
			if GuiButton(gui, 0, 0, "v 1$", get_next_id()) then
				transfer_money_to_safe(save_id, 1);
			end
		end
		GuiLayoutEnd(gui);
		GuiLayoutEnd(gui);
		GuiLayoutBeginHorizontal(gui, 86, 31);
		GuiText(gui, 0, 0, " $" .. tostring(safe_money));
		GuiLayoutEnd(gui);
	end };
end

function hide_money_gui()
	active_windows["money"] = nil;
end

function show_teleport_gui()
	local teleport_confirmation = false;
	active_windows["teleport"] = { false, function(get_next_id)
		GuiLayoutBeginHorizontal(gui, 45, 1);
		if teleport_confirmation then
			if GuiButton(gui, 0, 0, "Press again to teleport", get_next_id()) then
				teleport_back_to_lobby();
			end
		else
			if GuiButton(gui, 0, 0, "Teleport back up", get_next_id()) then
				teleport_confirmation = true;
			end
		end
		GuiLayoutEnd(gui);
	end };
end

function hide_teleport_gui()
	active_windows["teleport"] = nil;
end

local research_wands_open = false;
function show_research_wands_gui()
	research_wands_open = true;
	local wand_entity_ids = get_all_wands();
	local wands = {};

	for pos, entity_id in pairs(wand_entity_ids) do
		wands[pos] = {
			["entity_id"] = entity_id,
			["wand_data"] = read_wand(entity_id)
		};
	end

	active_windows["research_wands"] = { true, function(get_next_id)
		local player_money = get_player_money();
		GuiLayoutBeginHorizontal(gui, 30, 30);
		GuiLayoutBeginVertical(gui, 0, 0);
		for i = 1, 4 do
			GuiText(gui, 0, 0, "Inventory Slot " .. tostring(i) .. ":");
		end
		GuiLayoutEnd(gui);
		GuiLayoutAddHorizontalSpacing(gui);
		GuiLayoutAddHorizontalSpacing(gui);
		GuiLayoutAddHorizontalSpacing(gui);
		GuiLayoutBeginVertical(gui, 0, 0);
		for i = 0, 3 do
			if wands[i] ~= nil then
				local price = research_wand_price(get_selected_save_id(), wands[i].entity_id);
				local is_new = research_wand_is_new(get_selected_save_id(), wands[i].entity_id);
				if is_new then
					if price > player_money then
						GuiText(gui, 0, 0, tostring(price) .. "$");
					else
						if #wands[i].wand_data.spells > 0 then
							if GuiButton(gui, 0, 0, tostring(price) .. "$", get_next_id()) then
								research_wand(get_selected_save_id(), wands[i].entity_id);
								wands[i] = nil;
							end
						else
							if GuiButton(gui, 0, 0, tostring(price) .. "$", get_next_id()) then
								research_wand(get_selected_save_id(), wands[i].entity_id);
								wands[i] = nil;
							end
						end
					end
				else
					GuiText(gui, 0, 0, "0$");
				end
			else
				GuiText(gui, 0, 0, " ");
			end
		end
		GuiLayoutEnd(gui);
		GuiLayoutAddHorizontalSpacing(gui);
		GuiLayoutAddHorizontalSpacing(gui);
		GuiLayoutAddHorizontalSpacing(gui);
		GuiLayoutAddHorizontalSpacing(gui);
		GuiLayoutAddHorizontalSpacing(gui);
		GuiLayoutBeginVertical(gui, 0, 0);
		for i = 0, 3 do
			if wands[i] ~= nil then
				local price = research_wand_price(get_selected_save_id(), wands[i].entity_id);
				local is_new = research_wand_is_new(get_selected_save_id(), wands[i].entity_id);
				if is_new then
					if price > player_money then
						GuiText(gui, 0, 0, "You can't afford that");
					else
						if #wands[i].wand_data.spells > 0 then
							GuiText(gui, 0, 0, "WARNING: The spells on this wand will be lost");
						else
							GuiText(gui, 0, 0, " ");
						end
					end
				else
					GuiText(gui, 0, 0, "This wand does not have anything new to research");
				end
			else
				GuiText(gui, 0, 0, " ");
			end
		end
		GuiLayoutEnd(gui);
		GuiLayoutEnd(gui);
	end };
end

function hide_research_wands_gui()
	research_wands_open = false;
	active_windows["research_wands"] = nil;
end

local research_spells_open = false;
function show_research_spells_gui()
	research_spells_open = true;
	local spell_entity_ids = get_all_spells();
	local researched_spells = get_spells(get_selected_save_id());
	local spell_data_temp = {};
	local spell_data = {};

	for i = 1, #spell_entity_ids do
		local action_id = read_spell(spell_entity_ids[i]);
		if action_id ~= nil then
			if researched_spells[action_id] == nil then
				spell_data_temp[action_id] = spell_entity_ids[i];
			end
		end
	end
	for i = 1, #actions do
		local entity_id = spell_data_temp[actions[i].id];
		if entity_id ~= nil then
			table.insert(spell_data, {
				["entity_id"] = entity_id,
				["id"] = actions[i].id,
				["name"] = GameTextGetTranslatedOrNot(actions[i].name),
				["price"] = research_spell_price(entity_id)
			});
		end
	end
	table.sort(spell_data, function(a, b) return a.name < b.name end);

	active_windows["research_spells"] = { true, function(get_next_id)
		if #spell_data > 0 then
			local player_money = get_player_money();
			GuiLayoutBeginHorizontal(gui, 40, 15);
			GuiLayoutBeginVertical(gui, 0, 0);
			for _, value in ipairs(spell_data) do
				if player_money < value.price then
					GuiText(gui, 0, 0, tostring(value.price) .. "$");
				else
					if GuiButton(gui, 0, 0, tostring(value.price) .. "$", get_next_id()) then
						research_spell(get_selected_save_id(), value.entity_id);
						hide_research_spells_gui();
						show_research_spells_gui();
					end
				end
			end
			GuiLayoutEnd(gui);
			GuiLayoutAddHorizontalSpacing(gui);
			GuiLayoutAddHorizontalSpacing(gui);
			GuiLayoutAddHorizontalSpacing(gui);
			GuiLayoutBeginVertical(gui, 0, 0);
			for _, value in ipairs(spell_data) do
				GuiText(gui, 0, 0, value.name);
			end
			GuiLayoutEnd(gui);
			GuiLayoutEnd(gui);
		else
			GuiLayoutBeginHorizontal(gui, 40, 30);
			GuiText(gui, 0, 0, "No new spells to research");
			GuiLayoutEnd(gui);
		end
	end };
end

function hide_research_spells_gui()
	research_spells_open = false;
	active_windows["research_spells"] = nil;
end

local buy_wands_open = false;
function show_buy_wands_gui()
	buy_wands_open = true;
	local save_id = get_selected_save_id();
	if can_create_wand(save_id) then
		local window_nr = 0;
		local spells_per_cast = get_spells_per_cast(save_id);
		local cast_delay_min = get_cast_delay_min(save_id);
		local cast_delay_max = get_cast_delay_max(save_id);
		local recharge_time_min = get_recharge_time_min(save_id);
		local recharge_time_max = get_recharge_time_max(save_id);
		local mana_max = get_mana_max(save_id);
		local mana_charge_speed = get_mana_charge_speed(save_id);
		local capacity = get_capacity(save_id);
		local spread_min = get_spread_min(save_id);
		local spread_max = get_spread_max(save_id);
		local wand_types = get_wand_types(save_id);
		local always_cast_spells = get_always_cast_spells(save_id);
		local wand_data_selected = {
			["shuffle"] = true,
			["spells_per_cast"] = spells_per_cast_min,
			["cast_delay"] = math.floor((cast_delay_min + cast_delay_max)/2),
			["recharge_time"] = math.floor((recharge_time_min + recharge_time_max)/2),
			["mana_max"] = mana_max_min,
			["mana_charge_speed"] = mana_charge_speed_min,
			["capacity"] = capacity_min,
			["spread"] = spread_min,
			["always_cast_spells"] = {},
			["wand_type"] = "default_1";
		};
		local delete_template_confirmation = 0;

		local spells_page_number = 1;
		local spell_data = {};

		for i = 1, #actions do
			if always_cast_spells[actions[i].id] ~= nil then
				table.insert(spell_data, {
					["id"] = actions[i].id,
					["name"] = GameTextGetTranslatedOrNot(actions[i].name),
					["selected"] = false
				});
			end
		end

		local function toggle_select_spell(action_id)
			local selected = false;
			for i = 1, #spell_data do
				if spell_data[i].id == action_id then
					selected = not spell_data[i].selected;
					spell_data[i].selected = selected;
					break;
				end
			end
			for i = 1, #wand_data_selected["always_cast_spells"] do
				if wand_data_selected["always_cast_spells"][i] == action_id then
					table.remove(wand_data_selected["always_cast_spells"], i);
					break;
				end
			end
			if selected then
				table.insert(wand_data_selected["always_cast_spells"], action_id);
			end
		end

		table.sort(spell_data, function(a, b) return a.name < b.name end);
		local spell_columns = split_array(spell_data, 20);

		local wand_types_page_number = 1;
		local wand_type_list = {};

		for wand_type, _ in pairs(wand_types) do
			table.insert(wand_type_list, {
				["wand_type"] = wand_type,
				["sprite_file"] = wand_type_to_sprite_file(wand_type)
			});
		end

		table.sort(wand_type_list, function(a, b) return a.wand_type < b.wand_type end);
		local wand_type_columns = split_array(wand_type_list, 5);

		active_windows["buy_wands"] = { true, function(get_next_id)
			local player_money = get_player_money();
			local price = create_wand_price(wand_data_selected);
			if window_nr == 0 then
				GuiLayoutBeginHorizontal(gui, 20, 15);
				GuiLayoutBeginVertical(gui, 0, 0);
				GuiText(gui, 0, 0, "$inventory_shuffle");
				GuiText(gui, 0, 0, "$inventory_actionspercast");
				GuiText(gui, 0, 0, "$inventory_castdelay");
				GuiText(gui, 0, 0, "$inventory_rechargetime");
				GuiText(gui, 0, 0, "$inventory_manamax");
				GuiText(gui, 0, 0, "$inventory_manachargespeed");
				GuiText(gui, 0, 0, "$inventory_capacity");
				GuiText(gui, 0, 0, "$inventory_spread");
				GuiText(gui, 0, 0, "$inventory_alwayscasts");
				GuiText(gui, 0, 0, "Wand design");
				GuiLayoutEnd(gui);
				GuiLayoutAddHorizontalSpacing(gui);
				GuiLayoutAddHorizontalSpacing(gui);
				GuiLayoutAddHorizontalSpacing(gui);
				GuiLayoutBeginVertical(gui, 0, 0);
				GuiText(gui, 0, 0, " ");
				GuiText(gui, 0, 0, " ");
				if wand_data_selected["cast_delay"] - 60 >= cast_delay_min then
					if GuiButton(gui, 0, 0, "<<<", get_next_id()) then
						wand_data_selected["cast_delay"] = wand_data_selected["cast_delay"] - 60;
					end
				else
					GuiButton(gui, 0, 0, "      ", get_next_id());
				end
				if wand_data_selected["recharge_time"] - 60 >= recharge_time_min then
					if GuiButton(gui, 0, 0, "<<<", get_next_id()) then
						wand_data_selected["recharge_time"] = wand_data_selected["recharge_time"] - 60;
					end
				else
					GuiButton(gui, 0, 0, "      ", get_next_id());
				end
				if wand_data_selected["mana_max"] - 100 >= mana_max_min then
					if GuiButton(gui, 0, 0, "<<<", get_next_id()) then
						wand_data_selected["mana_max"] = wand_data_selected["mana_max"] - 100;
					end
				else
					GuiButton(gui, 0, 0, "      ", get_next_id());
				end
				if wand_data_selected["mana_charge_speed"] - 100 >= mana_charge_speed_min then
					if GuiButton(gui, 0, 0, "<<<", get_next_id()) then
						wand_data_selected["mana_charge_speed"] = wand_data_selected["mana_charge_speed"] - 100;
					end
				else
					GuiButton(gui, 0, 0, "      ", get_next_id());
				end
				GuiText(gui, 0, 0, " ");
				if wand_data_selected["spread"] - 10 >= spread_min then
					if GuiButton(gui, 0, 0, "<<<<", get_next_id()) then
						wand_data_selected["spread"] = wand_data_selected["spread"] - 10;
					end
				else
					GuiButton(gui, 0, 0, "      ", get_next_id());
				end
				GuiText(gui, 0, 0, "      ");
				GuiLayoutEnd(gui);
				GuiLayoutAddHorizontalSpacing(gui);
				GuiLayoutAddHorizontalSpacing(gui);
				GuiLayoutAddHorizontalSpacing(gui);
				GuiLayoutBeginVertical(gui, 0, 0);
				GuiText(gui, 0, 0, " ");
				GuiText(gui, 0, 0, " ");
				if wand_data_selected["cast_delay"] - 6 >= cast_delay_min then
					if GuiButton(gui, 0, 0, "<<", get_next_id()) then
						wand_data_selected["cast_delay"] = wand_data_selected["cast_delay"] - 6;
					end
				else
					GuiButton(gui, 0, 0, "    ", get_next_id());
				end
				if wand_data_selected["recharge_time"] - 6 >= recharge_time_min then
					if GuiButton(gui, 0, 0, "<<", get_next_id()) then
						wand_data_selected["recharge_time"] = wand_data_selected["recharge_time"] - 6;
					end
				else
					GuiButton(gui, 0, 0, "    ", get_next_id());
				end
				if wand_data_selected["mana_max"] - 10 >= mana_max_min then
					if GuiButton(gui, 0, 0, "<<", get_next_id()) then
						wand_data_selected["mana_max"] = wand_data_selected["mana_max"] - 10;
					end
				else
					GuiButton(gui, 0, 0, "    ", get_next_id());
				end
				if wand_data_selected["mana_charge_speed"] - 10 >= mana_charge_speed_min then
					if GuiButton(gui, 0, 0, "<<", get_next_id()) then
						wand_data_selected["mana_charge_speed"] = wand_data_selected["mana_charge_speed"] - 10;
					end
				else
					GuiButton(gui, 0, 0, "    ", get_next_id());
				end
				if wand_data_selected["capacity"] - 10 >= capacity_min then
					if GuiButton(gui, 0, 0, "<<", get_next_id()) then
						wand_data_selected["capacity"] = wand_data_selected["capacity"] - 10;
					end
				else
					GuiButton(gui, 0, 0, "    ", get_next_id());
				end
				if wand_data_selected["spread"] - 1 >= spread_min then
					if GuiButton(gui, 0, 0, "<<", get_next_id()) then
						wand_data_selected["spread"] = wand_data_selected["spread"] - 1;
					end
				else
					GuiButton(gui, 0, 0, "    ", get_next_id());
				end
				GuiText(gui, 0, 0, "    ");
				GuiLayoutEnd(gui);
				GuiLayoutAddHorizontalSpacing(gui);
				GuiLayoutAddHorizontalSpacing(gui);
				GuiLayoutAddHorizontalSpacing(gui);
				GuiLayoutBeginVertical(gui, 0, 0);
				if wand_data_selected["shuffle"] == true then
					if GuiButton(gui, 0, 0, "<", get_next_id()) then
						wand_data_selected["shuffle"] = false;
					end
				else
					GuiButton(gui, 0, 0, "  ", get_next_id());
				end
				if wand_data_selected["spells_per_cast"] > spells_per_cast_min then
					if GuiButton(gui, 0, 0, "<", get_next_id()) then
						wand_data_selected["spells_per_cast"] = wand_data_selected["spells_per_cast"] - 1;
					end
				else
					GuiButton(gui, 0, 0, "  ", get_next_id());
				end
				if wand_data_selected["cast_delay"] > cast_delay_min then
					if GuiButton(gui, 0, 0, "<", get_next_id()) then
						wand_data_selected["cast_delay"] = wand_data_selected["cast_delay"] - 1;
					end
				else
					GuiButton(gui, 0, 0, "  ", get_next_id());
				end
				if wand_data_selected["recharge_time"] > recharge_time_min then
					if GuiButton(gui, 0, 0, "<", get_next_id()) then
						wand_data_selected["recharge_time"] = wand_data_selected["recharge_time"] - 1;
					end
				else
					GuiButton(gui, 0, 0, "  ", get_next_id());
				end
				if wand_data_selected["mana_max"] > mana_max_min then
					if GuiButton(gui, 0, 0, "<", get_next_id()) then
						wand_data_selected["mana_max"] = wand_data_selected["mana_max"] - 1;
					end
				else
					GuiButton(gui, 0, 0, "  ", get_next_id());
				end
				if wand_data_selected["mana_charge_speed"] > mana_charge_speed_min then
					if GuiButton(gui, 0, 0, "<", get_next_id()) then
						wand_data_selected["mana_charge_speed"] = wand_data_selected["mana_charge_speed"] - 1;
					end
				else
					GuiButton(gui, 0, 0, "  ", get_next_id());
				end
				if wand_data_selected["capacity"] > capacity_min then
					if GuiButton(gui, 0, 0, "<", get_next_id()) then
						wand_data_selected["capacity"] = wand_data_selected["capacity"] - 1;
					end
				else
					GuiButton(gui, 0, 0, "  ", get_next_id());
				end
				if wand_data_selected["spread"] - 0.1 >= spread_min then
					if GuiButton(gui, 0, 0, "<", get_next_id()) then
						wand_data_selected["spread"] = wand_data_selected["spread"] - 0.1;
					end
				else
					GuiButton(gui, 0, 0, "  ", get_next_id());
				end
				GuiText(gui, 0, 0, "  ");
				GuiLayoutEnd(gui);
				GuiLayoutAddHorizontalSpacing(gui);
				GuiLayoutAddHorizontalSpacing(gui);
				GuiLayoutAddHorizontalSpacing(gui);
				GuiLayoutBeginVertical(gui, 0, 0);
				GuiText(gui, 0, 0, wand_data_selected["shuffle"] and "$menu_yes" or "$menu_no");
				GuiText(gui, 0, 0, tostring(wand_data_selected["spells_per_cast"]));
				GuiText(gui, 0, 0, tostring(math.floor((wand_data_selected["cast_delay"] / 60) * 100 + 0.5) / 100));
				GuiText(gui, 0, 0, tostring(math.floor((wand_data_selected["recharge_time"] / 60) * 100 + 0.5) / 100));
				GuiText(gui, 0, 0, tostring(wand_data_selected["mana_max"]));
				GuiText(gui, 0, 0, tostring(wand_data_selected["mana_charge_speed"]));
				GuiText(gui, 0, 0, tostring(wand_data_selected["capacity"]));
				GuiText(gui, 0, 0, tostring(math.floor(wand_data_selected["spread"] * 10 + 0.5) / 10));
				if GuiButton(gui, 0, 0, "Select", get_next_id()) then
					window_nr = 1;
				end
				if GuiButton(gui, 0, 0, "Select", get_next_id()) then
					window_nr = 2;
				end
				GuiLayoutEnd(gui);
				GuiLayoutAddHorizontalSpacing(gui);
				GuiLayoutAddHorizontalSpacing(gui);
				GuiLayoutAddHorizontalSpacing(gui);
				GuiLayoutBeginVertical(gui, 0, 0);
				if wand_data_selected["shuffle"] == false then
					if GuiButton(gui, 0, 0, ">", get_next_id()) then
						wand_data_selected["shuffle"] = true;
					end
				else
					GuiButton(gui, 0, 0, "  ", get_next_id());
				end
				if wand_data_selected["spells_per_cast"] < spells_per_cast then
					if GuiButton(gui, 0, 0, ">", get_next_id()) then
						wand_data_selected["spells_per_cast"] = wand_data_selected["spells_per_cast"] + 1;
					end
				else
					GuiButton(gui, 0, 0, "  ", get_next_id());
				end
				if wand_data_selected["cast_delay"] < cast_delay_max then
					if GuiButton(gui, 0, 0, ">", get_next_id()) then
						wand_data_selected["cast_delay"] = wand_data_selected["cast_delay"] + 1;
					end
				else
					GuiButton(gui, 0, 0, "  ", get_next_id());
				end
				if wand_data_selected["recharge_time"] < recharge_time_max then
					if GuiButton(gui, 0, 0, ">", get_next_id()) then
						wand_data_selected["recharge_time"] = wand_data_selected["recharge_time"] + 1;
					end
				else
					GuiButton(gui, 0, 0, "  ", get_next_id());
				end
				if wand_data_selected["mana_max"] < mana_max then
					if GuiButton(gui, 0, 0, ">", get_next_id()) then
						wand_data_selected["mana_max"] = wand_data_selected["mana_max"] + 1;
					end
				else
					GuiButton(gui, 0, 0, "  ", get_next_id());
				end
				if wand_data_selected["mana_charge_speed"] < mana_charge_speed then
					if GuiButton(gui, 0, 0, ">", get_next_id()) then
						wand_data_selected["mana_charge_speed"] = wand_data_selected["mana_charge_speed"] + 1;
					end
				else
					GuiButton(gui, 0, 0, "  ", get_next_id());
				end
				if wand_data_selected["capacity"] < capacity then
					if GuiButton(gui, 0, 0, ">", get_next_id()) then
						wand_data_selected["capacity"] = wand_data_selected["capacity"] + 1;
					end
				else
					GuiButton(gui, 0, 0, "  ", get_next_id());
				end
				if wand_data_selected["spread"] + 0.1 <= spread_max then
					if GuiButton(gui, 0, 0, ">", get_next_id()) then
						wand_data_selected["spread"] = wand_data_selected["spread"] + 0.1;
					end
				else
					GuiButton(gui, 0, 0, "  ", get_next_id());
				end
				GuiText(gui, 0, 0, "  ");
				GuiLayoutEnd(gui);
				GuiLayoutAddHorizontalSpacing(gui);
				GuiLayoutAddHorizontalSpacing(gui);
				GuiLayoutAddHorizontalSpacing(gui);
				GuiLayoutBeginVertical(gui, 0, 0);
				GuiText(gui, 0, 0, " ");
				GuiText(gui, 0, 0, " ");
				if wand_data_selected["cast_delay"] + 6 <= cast_delay_max then
					if GuiButton(gui, 0, 0, ">>", get_next_id()) then
						wand_data_selected["cast_delay"] = wand_data_selected["cast_delay"] + 6;
					end
				else
					GuiButton(gui, 0, 0, "    ", get_next_id());
				end
				if wand_data_selected["recharge_time"] + 6 <= recharge_time_max then
					if GuiButton(gui, 0, 0, ">>", get_next_id()) then
						wand_data_selected["recharge_time"] = wand_data_selected["recharge_time"] + 6;
					end
				else
					GuiButton(gui, 0, 0, "    ", get_next_id());
				end
				if wand_data_selected["mana_max"] + 10 <= mana_max then
					if GuiButton(gui, 0, 0, ">>", get_next_id()) then
						wand_data_selected["mana_max"] = wand_data_selected["mana_max"] + 10;
					end
				else
					GuiButton(gui, 0, 0, "    ", get_next_id());
				end
				if wand_data_selected["mana_charge_speed"] + 10 <= mana_charge_speed then
					if GuiButton(gui, 0, 0, ">>", get_next_id()) then
						wand_data_selected["mana_charge_speed"] = wand_data_selected["mana_charge_speed"] + 10;
					end
				else
					GuiButton(gui, 0, 0, "    ", get_next_id());
				end
				if wand_data_selected["capacity"] + 10 <= capacity then
					if GuiButton(gui, 0, 0, ">>", get_next_id()) then
						wand_data_selected["capacity"] = wand_data_selected["capacity"] + 10;
					end
				else
					GuiButton(gui, 0, 0, "    ", get_next_id());
				end
				if wand_data_selected["spread"] + 1 <= spread_max then
					if GuiButton(gui, 0, 0, ">>", get_next_id()) then
						wand_data_selected["spread"] = wand_data_selected["spread"] + 1;
					end
				else
					GuiButton(gui, 0, 0, "    ", get_next_id());
				end
				GuiText(gui, 0, 0, "    ");
				GuiLayoutEnd(gui);
				GuiLayoutAddHorizontalSpacing(gui);
				GuiLayoutAddHorizontalSpacing(gui);
				GuiLayoutAddHorizontalSpacing(gui);
				GuiLayoutBeginVertical(gui, 0, 0);
				GuiText(gui, 0, 0, " ");
				GuiText(gui, 0, 0, " ");
				if wand_data_selected["cast_delay"] + 60 <= cast_delay_max then
					if GuiButton(gui, 0, 0, ">>>", get_next_id()) then
						wand_data_selected["cast_delay"] = wand_data_selected["cast_delay"] + 60;
					end
				else
					GuiButton(gui, 0, 0, "      ", get_next_id());
				end
				if wand_data_selected["recharge_time"] + 60 <= recharge_time_max then
					if GuiButton(gui, 0, 0, ">>>", get_next_id()) then
						wand_data_selected["recharge_time"] = wand_data_selected["recharge_time"] + 60;
					end
				else
					GuiButton(gui, 0, 0, "      ", get_next_id());
				end
				if wand_data_selected["mana_max"] + 100 <= mana_max then
					if GuiButton(gui, 0, 0, ">>>", get_next_id()) then
						wand_data_selected["mana_max"] = wand_data_selected["mana_max"] + 100;
					end
				else
					GuiButton(gui, 0, 0, "      ", get_next_id());
				end
				if wand_data_selected["mana_charge_speed"] + 100 <= mana_charge_speed then
					if GuiButton(gui, 0, 0, ">>>", get_next_id()) then
						wand_data_selected["mana_charge_speed"] = wand_data_selected["mana_charge_speed"] + 100;
					end
				else
					GuiButton(gui, 0, 0, "      ", get_next_id());
				end
				GuiText(gui, 0, 0, " ");
				if wand_data_selected["spread"] + 10 <= spread_max then
					if GuiButton(gui, 0, 0, ">>>", get_next_id()) then
						wand_data_selected["spread"] = wand_data_selected["spread"] + 10;
					end
				else
					GuiButton(gui, 0, 0, "      ", get_next_id());
				end
				GuiText(gui, 0, 0, "      ");
				GuiLayoutEnd(gui);
				GuiLayoutEnd(gui);
				gui_sprite(22, 48, wand_type_to_sprite_file(wand_data_selected["wand_type"]));

				GuiLayoutBeginVertical(gui, 80, 50);
				for i = 1, get_template_count() do
					GuiText(gui, 0, 0, "Wand template slot " .. pad_number(i, #tostring(get_template_count())) .. ":");
					if get_template(save_id, i) == nil then
						if GuiButton(gui, 40, 0, "Save template", get_next_id()) then
							set_template(save_id, i, wand_data_selected);
						end
					else
						if GuiButton(gui, 40, 0, "Load template", get_next_id()) then
							wand_data_selected = get_template(save_id, i);
						end
						if delete_template_confirmation == i then
							if GuiButton(gui, 40, 0, "Press again to delete", get_next_id()) then
								delete_template_confirmation = 0;
								delete_template(save_id, i);
							end
						else
							if GuiButton(gui, 40, 0, "Delete template", get_next_id()) then
								delete_template_confirmation = i;
							end
						end
					end
				end
				GuiLayoutEnd(gui);
			elseif window_nr == 1 then
				if spell_columns[spells_page_number * 2 - 1] ~= nil then
					GuiLayoutBeginHorizontal(gui, 30, 15);
					GuiLayoutBeginVertical(gui, 0, 0);
					for _, value in ipairs(spell_columns[spells_page_number * 2 - 1]) do
						if GuiButton(gui, 0, 0, "[" .. (value.selected and "x" or " ") .. "]", get_next_id()) then
							toggle_select_spell(value.id);
						end
					end
					GuiLayoutEnd(gui);
					GuiLayoutAddHorizontalSpacing(gui);
					GuiLayoutAddHorizontalSpacing(gui);
					GuiLayoutAddHorizontalSpacing(gui);
					GuiLayoutBeginVertical(gui, 0, 0);
					for _, value in ipairs(spell_columns[spells_page_number * 2 - 1]) do
						GuiText(gui, 0, 0, value.name);
					end
					GuiLayoutEnd(gui);
					GuiLayoutEnd(gui);
				end
				if spell_columns[spells_page_number * 2] ~= nil then
					GuiLayoutBeginHorizontal(gui, 60, 15);
					GuiLayoutBeginVertical(gui, 0, 0);
					for _, value in ipairs(spell_columns[spells_page_number * 2]) do
						if GuiButton(gui, 0, 0, "[" .. (value.selected and "x" or " ") .. "]", get_next_id()) then
							toggle_select_spell(value.id);
						end
					end
					GuiLayoutEnd(gui);
					GuiLayoutAddHorizontalSpacing(gui);
					GuiLayoutAddHorizontalSpacing(gui);
					GuiLayoutAddHorizontalSpacing(gui);
					GuiLayoutBeginVertical(gui, 0, 0);
					for _, value in ipairs(spell_columns[spells_page_number * 2]) do
						GuiText(gui, 0, 0, value.name);
					end
					GuiLayoutEnd(gui);
					GuiLayoutEnd(gui);
				end
				if spells_page_number > 1 then
					GuiLayoutBeginHorizontal(gui, 48, 95);
					if GuiButton(gui, 0, 0, "<<", get_next_id()) then
						spells_page_number = spells_page_number - 1;
					end
					GuiLayoutEnd(gui);
				end
				GuiLayoutBeginHorizontal(gui, 50, 95);
				GuiText(gui, 0, 0, tostring(spells_page_number));
				GuiLayoutEnd(gui);
				if spells_page_number < math.ceil(#spell_columns / 2) then
					GuiLayoutBeginHorizontal(gui, 52, 95);
					if GuiButton(gui, 0, 0, ">>", get_next_id()) then
						spells_page_number = spells_page_number + 1;
					end
					GuiLayoutEnd(gui);
				end
			elseif window_nr == 2 then
				if wand_type_columns[wand_types_page_number * 2 - 1] ~= nil then
					for i, value in ipairs(wand_type_columns[wand_types_page_number * 2 - 1]) do
						GuiLayoutBeginHorizontal(gui, 20, 16 + i * 10);
						if GuiButton(gui, 0, 0, "Select", get_next_id()) then
							wand_data_selected["wand_type"] = value.wand_type;
							window_nr = 0;
							wand_types_page_number = 1;
						end
						GuiLayoutEnd(gui);
					end
					for i, value in ipairs(wand_type_columns[wand_types_page_number * 2 - 1]) do
						gui_sprite(25, 15 + i * 10, value.sprite_file);
					end
				end
				if wand_type_columns[wand_types_page_number * 2] ~= nil then
					for i, value in ipairs(wand_type_columns[wand_types_page_number * 2]) do
						GuiLayoutBeginHorizontal(gui, 60, 16 + i * 10);
						if GuiButton(gui, 0, 0, "Select", get_next_id()) then
							wand_data_selected["wand_type"] = value.wand_type;
							window_nr = 0;
							wand_types_page_number = 1;
						end
						GuiLayoutEnd(gui);
					end
					for i, value in ipairs(wand_type_columns[wand_types_page_number * 2]) do
						gui_sprite(65, 15 + i * 10, value.sprite_file);
					end
				end
				if wand_types_page_number > 1 then
					GuiLayoutBeginHorizontal(gui, 48, 95);
					if GuiButton(gui, 0, 0, "<<", get_next_id()) then
						wand_types_page_number = wand_types_page_number - 1;
					end
					GuiLayoutEnd(gui);
				end
				GuiLayoutBeginHorizontal(gui, 50, 95);
				GuiText(gui, 0, 0, tostring(wand_types_page_number));
				GuiLayoutEnd(gui);
				if wand_types_page_number < math.ceil(#wand_type_columns / 2) then
					GuiLayoutBeginHorizontal(gui, 52, 95);
					if GuiButton(gui, 0, 0, ">>", get_next_id()) then
						wand_types_page_number = wand_types_page_number + 1;
					end
					GuiLayoutEnd(gui);
				end
			end
			if window_nr ~= 0 then
				GuiLayoutBeginHorizontal(gui, 15, 15);
				if GuiButton(gui, 0, 0, "$menu_return", get_next_id()) then
					window_nr = 0;
					spells_page_number = 1;
					wand_types_page_number = 1;
				end
				GuiLayoutEnd(gui);
			end

			GuiLayoutBeginHorizontal(gui, 20, 95);
			if player_money < price then
				GuiText(gui, 0, 0, tostring(price) .. "$ You can't afford that");
			else
				if GuiButton(gui, 0, 0, tostring(price) .. "$ Buy", get_next_id()) then
					create_wand(wand_data_selected);
				end
			end
			GuiLayoutEnd(gui);
		end };
	else
		active_windows["buy_wands"] = { true, function(get_next_id)
			GuiLayoutBeginHorizontal(gui, 40, 30);
			GuiText(gui, 0, 0, "You don't have enough research to create a wand");
			GuiLayoutEnd(gui);
		end };
	end
end

function hide_buy_wands_gui()
	buy_wands_open = false;
	active_windows["buy_wands"] = nil;
end

local buy_spells_open = false;
function show_buy_spells_gui()
	buy_spells_open = true;
	local page_number = 1;
	local spells = get_spells(get_selected_save_id());
	local spell_data = {};

	for i = 1, #actions do
		if spells[actions[i].id] ~= nil then
			table.insert(spell_data, {
				["id"] = actions[i].id,
				["name"] = GameTextGetTranslatedOrNot(actions[i].name),
				["price"] = create_spell_price(actions[i].id)
			});
		end
	end

	table.sort(spell_data, function(a, b) return a.name < b.name end);
	local columns = split_array(spell_data, 20);

	active_windows["buy_spells"] = { true, function(get_next_id)
		local player_money = get_player_money();
		if columns[page_number * 2 - 1] ~= nil then
			GuiLayoutBeginHorizontal(gui, 30, 15);
			GuiLayoutBeginVertical(gui, 0, 0);
			for _, value in ipairs(columns[page_number * 2 - 1]) do
				if player_money < value.price then
					GuiText(gui, 0, 0, tostring(value.price) .. "$");
				else
					if GuiButton(gui, 0, 0, tostring(value.price) .. "$", get_next_id()) then
						create_spell(value.id);
					end
				end
			end
			GuiLayoutEnd(gui);
			GuiLayoutAddHorizontalSpacing(gui);
			GuiLayoutAddHorizontalSpacing(gui);
			GuiLayoutAddHorizontalSpacing(gui);
			GuiLayoutBeginVertical(gui, 0, 0);
			for _, value in ipairs(columns[page_number * 2 - 1]) do
				GuiText(gui, 0, 0, value.name);
			end
			GuiLayoutEnd(gui);
			GuiLayoutEnd(gui);
		end
		if columns[page_number * 2] ~= nil then
			GuiLayoutBeginHorizontal(gui, 60, 15);
			GuiLayoutBeginVertical(gui, 0, 0);
			for _, value in ipairs(columns[page_number * 2]) do
				if player_money < value.price then
					GuiText(gui, 0, 0, tostring(value.price) .. "$");
				else
					if GuiButton(gui, 0, 0, tostring(value.price) .. "$", get_next_id()) then
						create_spell(value.id);
					end
				end
			end
			GuiLayoutEnd(gui);
			GuiLayoutAddHorizontalSpacing(gui);
			GuiLayoutAddHorizontalSpacing(gui);
			GuiLayoutAddHorizontalSpacing(gui);
			GuiLayoutBeginVertical(gui, 0, 0);
			for _, value in ipairs(columns[page_number * 2]) do
				GuiText(gui, 0, 0, value.name);
			end
			GuiLayoutEnd(gui);
			GuiLayoutEnd(gui);
		end
		if page_number > 1 then
			GuiLayoutBeginHorizontal(gui, 48, 95);
			if GuiButton(gui, 0, 0, "<<", get_next_id()) then
				page_number = page_number - 1;
			end
			GuiLayoutEnd(gui);
		end
		GuiLayoutBeginHorizontal(gui, 50, 95);
		GuiText(gui, 0, 0, tostring(page_number));
		GuiLayoutEnd(gui);
		if page_number < math.ceil(#columns / 2) then
			GuiLayoutBeginHorizontal(gui, 52, 95);
			if GuiButton(gui, 0, 0, ">>", get_next_id()) then
				page_number = page_number + 1;
			end
			GuiLayoutEnd(gui);
		end
	end };
end

function hide_buy_spells_gui()
	buy_spells_open = false;
	active_windows["buy_spells"] = nil;
end

function show_menu_gui()
	hide_research_wands_gui();
	hide_research_spells_gui();
	hide_buy_wands_gui();
	hide_buy_spells_gui();
	active_windows["menu"] = { false, function(get_next_id)
		GuiLayoutBeginVertical(gui, 1, 30);
		if GuiButton(gui, research_wands_open and 10 or 0, 0, "Research Wands", get_next_id()) then
			hide_research_spells_gui();
			hide_buy_wands_gui();
			hide_buy_spells_gui();
			if research_wands_open then
				hide_research_wands_gui();
			else
				show_research_wands_gui();
			end
		end
		if GuiButton(gui, research_spells_open and 10 or 0, 0, "Research Spells", get_next_id()) then
			hide_research_wands_gui();
			hide_buy_wands_gui();
			hide_buy_spells_gui();
			if research_spells_open then
				hide_research_spells_gui();
			else
				show_research_spells_gui();
			end
		end
		if GuiButton(gui, buy_wands_open and 10 or 0, 0, "Buy Wands", get_next_id()) then
			hide_research_wands_gui();
			hide_research_spells_gui();
			hide_buy_spells_gui();
			if buy_wands_open then
				hide_buy_wands_gui();
			else
				show_buy_wands_gui();
			end
		end
		if GuiButton(gui, buy_spells_open and 10 or 0, 0, "Buy Spells", get_next_id()) then
			hide_research_wands_gui();
			hide_research_spells_gui();
			hide_buy_wands_gui();
			if buy_spells_open then
				hide_buy_spells_gui();
			else
				show_buy_spells_gui();
			end
		end
		GuiLayoutEnd(gui);
	end };
end

function hide_menu_gui()
	hide_research_wands_gui();
	hide_research_spells_gui();
	hide_buy_wands_gui();
	hide_buy_spells_gui();
	active_windows["menu"] = nil;
end

function show_lobby_gui()
	show_menu_gui();
	show_money_gui();
end

function hide_lobby_gui()
	hide_menu_gui();
	hide_money_gui();
end

function hide_all_gui()
	active_windows = {};
end

function gui_update()
	if gui ~= nil then
		if active_windows ~= nil then
			local is_dark_background = false;
			GuiStartFrame(gui);
			for _, window in pairs(active_windows) do
				if window[1] then
					is_dark_background = true;
				end
			end
			if is_dark_background then
				local cx, cy = GameGetCameraPos();
				GameCreateSpriteForXFrames("mods/persistence/files/gui_darken.png", cx, cy);
			end
			local start_gui_id = 14796823;
			for name, window in pairs(active_windows) do
				local gui_id = start_gui_id + simple_string_hash(name);
				window[2](function()
					gui_id = gui_id + 1;
					return gui_id;
				end);
			end
		end
	end
end