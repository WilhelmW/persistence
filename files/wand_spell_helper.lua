dofile_once("mods/persistence/config.lua");
dofile_once("mods/persistence/files/helper.lua");
dofile_once("data/scripts/gun/gun_actions.lua");
dofile_once("data/scripts/gun/procedural/gun_procedural.lua");

function wand_type_to_sprite_file(wand_type)
	if string.sub(wand_type, 1, #"default") == "default" then
		local nr = tonumber(string.sub(wand_type, #"default" + 2));
		return mod_config.default_wands[nr].file;
	else
		return "data/items_gfx/wands/" .. wand_type .. ".png";
	end
end

function wand_type_to_wand(wand_type)
	if string.sub(wand_type, 1, #"default") == "default" then
		local nr = tonumber(string.sub(wand_type, #"default" + 2));
		return mod_config.default_wands[nr];
	else
		for i = 1, #wands do
			if wands[i].file == "data/items_gfx/wands/" .. wand_type .. ".png" then
				return wands[i];
			end
		end
		return nil;
	end
end

function sprite_file_to_wand_type(sprite_file)
	for i = 1, #mod_config.default_wands do
		if mod_config.default_wands[i].file == sprite_file then
			return "default_" .. tostring(i);
		end
	end
	return string.sub(sprite_file, string.find(sprite_file, "/[^/]*$") + 1, -5);
end

function read_wand(entity_id)
	local wand_data = {};
	for _, comp in ipairs(EntityGetAllComponents(entity_id)) do
		if ComponentGetTypeName(comp) == "AbilityComponent" then
			wand_data["shuffle"] = tonumber(ComponentObjectGetValue(comp, "gun_config", "shuffle_deck_when_empty")) == 1 and true or false;
			wand_data["spells_per_cast"] = tonumber(ComponentObjectGetValue(comp, "gun_config", "actions_per_round"));
			wand_data["cast_delay"] = tonumber(ComponentObjectGetValue(comp, "gunaction_config", "fire_rate_wait"));
			wand_data["recharge_time"] = tonumber(ComponentObjectGetValue(comp, "gun_config", "reload_time"));
			wand_data["mana_max"] = tonumber(ComponentGetValue(comp, "mana_max"));
			wand_data["mana_charge_speed"] = tonumber(ComponentGetValue(comp, "mana_charge_speed"));
			wand_data["capacity"] = tonumber(ComponentObjectGetValue(comp, "gun_config", "deck_capacity"));
			wand_data["spread"] = tonumber(ComponentObjectGetValue(comp, "gunaction_config", "spread_degrees"));
			wand_data["wand_type"] = sprite_file_to_wand_type(ComponentGetValue(comp, "sprite_file"));
			break;
		end
	end
	wand_data["spells"] = {};
	wand_data["always_cast_spells"] = {};
	local childs = EntityGetAllChildren(entity_id);
	if childs ~= nil then
		for _, child_id in ipairs(childs) do
			local item_action_comp = EntityGetFirstComponentIncludingDisabled(child_id, "ItemActionComponent");
			if item_action_comp ~= nil and item_action_comp ~= 0 then
				local action_id = ComponentGetValue(item_action_comp, "action_id");
				if tonumber(ComponentGetValue(EntityGetFirstComponentIncludingDisabled(child_id, "ItemComponent"), "permanently_attached")) == 1 then
					table.insert(wand_data["always_cast_spells"], action_id);
				else
					table.insert(wand_data["spells"], action_id);
				end
			end
		end
	end
	wand_data["capacity"] = wand_data["capacity"] - #wand_data["always_cast_spells"];
	return wand_data;
end

function read_spell(entity_id)
	for _, comp_id in ipairs(EntityGetAllComponents(entity_id)) do
		if ComponentGetTypeName(comp_id) == "ItemActionComponent" then
			return ComponentGetValue(comp_id, "action_id");
		end
	end
end

function delete_wand(entity_id)
	if not EntityHasTag(entity_id, "wand") then
		return;
	end
	EntityKill(entity_id);
end

function delete_spell(entity_id)
	if not EntityHasTag(entity_id, "card_action") then
		return;
	end
	EntityKill(entity_id);
end

function create_wand_price(wand_data)
	local price = 0;
	if not wand_data["shuffle"] then
		price = price + 100;
	end
	price = price + math.max(wand_data["spells_per_cast"] - 1, 0) * 500;
	price = price + (0.01 ^ (wand_data["cast_delay"] / 60 - 1.8) + 200) * 0.1;
	price = price + (0.01 ^ (wand_data["recharge_time"] / 60 - 1.8) + 200) * 0.1;
	price = price + wand_data["mana_max"];
	price = price + wand_data["mana_charge_speed"] * 2;
	price = price + math.max(wand_data["capacity"] - 1, 0) * 50;
	price = price + math.abs(5 - wand_data["spread"]) * 5;
	if wand_data["always_cast_spells"] ~= nil and #wand_data["always_cast_spells"] > 0 then
		for i = 1, #wand_data["always_cast_spells"] do
			for j = 1, #actions do
				if actions[j].id == wand_data["always_cast_spells"][i] then
					price = price + actions[j].price * 5;
					break;
				end
			end
		end
	end
	return math.ceil(price * mod_config.buy_wand_price_multiplier);
end

function create_wand(wand_data)
	local price = create_wand_price(wand_data);
	if get_player_money() < price then
		return false;
	end

	local x, y = EntityGetTransform(get_player_id());
	local entity_id = EntityLoad("mods/persistence/files/wand_empty.xml", x, y);
	local ability_comp = EntityGetFirstComponentIncludingDisabled(entity_id, "AbilityComponent");
	local wand = wand_type_to_wand(wand_data["wand_type"]);

	ComponentSetValue(ability_comp, "ui_name", wand.name);
	ComponentObjectSetValue(ability_comp, "gun_config", "shuffle_deck_when_empty", wand_data["shuffle"] and "1" or "0");
	ComponentObjectSetValue(ability_comp, "gun_config", "actions_per_round", wand_data["spells_per_cast"]);
	ComponentObjectSetValue(ability_comp, "gunaction_config", "fire_rate_wait", wand_data["cast_delay"]);
	ComponentObjectSetValue(ability_comp, "gun_config", "reload_time", wand_data["recharge_time"]);
	ComponentSetValue(ability_comp, "mana_max", wand_data["mana_max"]);
	ComponentSetValue(ability_comp, "mana", wand_data["mana_max"]);
	ComponentSetValue(ability_comp, "mana_charge_speed", wand_data["mana_charge_speed"]);
	ComponentObjectSetValue(ability_comp, "gun_config", "deck_capacity", wand_data["capacity"]);
	ComponentObjectSetValue(ability_comp, "gunaction_config", "spread_degrees", wand_data["spread"]);
	ComponentObjectSetValue(ability_comp, "gunaction_config", "speed_multiplier", 1);
	ComponentSetValue(ability_comp, "item_recoil_recovery_speed", 15);
	if #wand_data["always_cast_spells"] > 0 then
		for i = 1, #wand_data["always_cast_spells"] do
			AddGunActionPermanent(entity_id, wand_data["always_cast_spells"][i]);
		end
	end
	SetWandSprite(entity_id, ability_comp, wand.file, wand.grip_x, wand.grip_y, (wand.tip_x - wand.grip_x), (wand.tip_y - wand.grip_y));

	set_player_money(get_player_money() - price);
	return true;
end

function create_spell_price(action_id)
	for i = 1, #actions do
		if actions[i].id == action_id then
			return math.ceil(actions[i].price * mod_config.buy_spell_price_multiplier);
		end
	end
end

function create_spell(action_id)
	local price = create_spell_price(action_id);
	if get_player_money() < price then
		return false;
	end

	local x, y = EntityGetTransform(get_player_id());
	CreateItemActionEntity(action_id, x, y);

	set_player_money(get_player_money() - price);
	return true;
end

function get_all_wands()
	local wands = {};
	if get_inventory_quick() == nil then
		return wands;
	end
	local inventory_quick_childs = EntityGetAllChildren(get_inventory_quick());
	if inventory_quick_childs ~=nil then
		for _, item in ipairs(inventory_quick_childs) do
			if EntityHasTag(item, "wand") then
				local inventory_comp = EntityGetFirstComponentIncludingDisabled(item, "ItemComponent");
				local x, _ = ComponentGetValue2(inventory_comp, "inventory_slot");
				wands[x] = item;
			end
		end
	end
	return wands;
end

function get_all_spells()
	local spells = {};
	if get_inventory_full() == nil then
		return spells;
	end
	local inventory_full_childs = EntityGetAllChildren(get_inventory_full());
	if inventory_full_childs ~=nil then
		for _, item in ipairs(inventory_full_childs) do
			table.insert(spells, item);
		end
	end
	return spells;
end