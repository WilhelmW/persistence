dofile_once("mods/persistence/config.lua");
dofile_once("mods/persistence/files/helper.lua");

local inventory_gui;
local inventory2;
local controls_component;
local is_in_lobby = false;
local inventory_open = false;
local teleport_component;
local screen_size_x, screen_size_y;

local function enter_lobby()
	enable_edit_wands_in_lobby();
	show_lobby_gui();
end

local function exit_lobby()
	disable_edit_wands_in_lobby();
	hide_lobby_gui();
end

function disable_controlls()
	EntitySetComponentIsEnabled(player_id, inventory_gui, false);
	EntitySetComponentIsEnabled(player_id, inventory2, false);
	EntitySetComponentIsEnabled(player_id, controls_component, false);
end

function enable_controlls()
	EntitySetComponentIsEnabled(player_id, controls_component, true);
	EntitySetComponentIsEnabled(player_id, inventory2, true);
	EntitySetComponentIsEnabled(player_id, inventory_gui, true);
end

function update_screen_size()
	teleport_component = EntityGetFirstComponentIncludingDisabled(player_id, "TeleportComponent");
	if teleport_component ~= nil and teleport_component ~= 0 then
		EntitySetComponentIsEnabled(player_id, teleport_component, true);
	else
		teleport_component = EntityAddComponent(player_id, "TeleportComponent", {});
	end
end

function get_screen_size()
	return screen_size_x, screen_size_y;
end

local is_post_player_spawned = false;
function OnWorldPostUpdate()
	if player_id == nil or not EntityGetIsAlive(player_id) then
		return;
	end

	if teleport_component ~= nil then
		local a, b, c, d = ComponentGetValue2(teleport_component, "source_location_camera_aabb");
		if a ~= 0 or b ~= 0 or c ~= 0 or d ~= 0 then
			screen_size_x = math.floor(c - a + 0.5);
			screen_size_y = math.floor(d - b + 0.5);
			EntitySetComponentIsEnabled(player_id, teleport_component, false);
			ComponentSetValue2(teleport_component, "source_location_camera_aabb", 0, 0, 0, 0);
		end
	end

	if not is_post_player_spawned then
		OnPostPlayerSpawned();
		is_post_player_spawned = true;
	end

	if get_selected_save_id == nil or get_selected_save_id() == 0 then
		return;
	end

	if gui_update ~= nil then
		gui_update();
	end

	if get_selected_save_id() == nil then
		return;
	end
	if GlobalsGetValue("lobby_collider_triggered") ~= nil and GlobalsGetValue("lobby_collider_triggered") == "1" then
		if not is_in_lobby then
			is_in_lobby = true;
			enter_lobby();
			if inventory_open then
				hide_menu_gui();
			end
		end
		GlobalsSetValue("lobby_collider_triggered", "0");
	else
		if is_in_lobby then
			is_in_lobby = false;
			exit_lobby();
		end
	end
	if tonumber(ComponentGetValue(inventory_gui, "mActive")) == 1 then
		if not inventory_open then
			inventory_open = true;
			if is_in_lobby then
				hide_menu_gui();
			end
		end
	else
		if inventory_open then
			inventory_open = false;
			if is_in_lobby then
				show_menu_gui();
			end
		end
	end
end

function OnPlayerSpawned(player_entity)
	player_id = player_entity;
	wallet = EntityGetFirstComponentIncludingDisabled(player_id, "WalletComponent");
	inventory_quick = EntityGetWithName("inventory_quick");
	inventory_full = EntityGetWithName("inventory_full");
	inventory_gui = EntityGetFirstComponentIncludingDisabled(player_id, "InventoryGuiComponent");
	inventory2 = EntityGetFirstComponentIncludingDisabled(player_id, "Inventory2Component");
	controls_component = EntityGetFirstComponentIncludingDisabled(player_id, "ControlsComponent");

	local lobby_collider = EntityGetWithName("persistence_lobby_collider");
	if lobby_collider == nil or lobby_collider == 0 then
		local x, y = EntityGetTransform(player_id);
		EntityLoad("mods/persistence/files/lobby_collider.xml", x, y);
	end

	update_screen_size();
end

function OnPostPlayerSpawned()
	dofile_once("mods/persistence/files/data_store.lua");
	dofile_once("mods/persistence/files/gui.lua");

	if GameGetFrameNum() < 20 then
		set_run_created_with_mod();
	end

	local selected_save_id = get_selected_save_id();
	if selected_save_id == nil then
		if not get_run_created_with_mod() then
			set_selected_save_id(0);
		end
		load_save_ids();
		disable_controlls();
		show_save_selector_gui();
	else
		if selected_save_id ~= 0 then
			load(selected_save_id);
			OnSaveAvailable(selected_save_id);
		end
	end
end

function OnSaveAvailable(save_id)
	local lobby_collider = EntityGetWithName("persistence_lobby_collider");
	for _, comp in ipairs(EntityGetAllComponents(lobby_collider)) do
		EntitySetComponentIsEnabled(lobby_collider, comp, true);
	end
end

function OnPlayerDied(player_entity)
	hide_all_gui();
	if get_selected_save_id() == nil or get_selected_save_id() == 0 then
		return;
	end
	local money = get_player_money();
	local money_to_save = math.floor(money * mod_config.money_to_keep_on_death);
	GamePrintImportant("You died", "You lost " .. tostring(money - money_to_save) .. " Gold");
	set_safe_money(get_selected_save_id(), get_safe_money(get_selected_save_id()) + money_to_save);
end