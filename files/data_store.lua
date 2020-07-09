dofile_once("mods/persistence/config.lua");
dofile_once("data/scripts/gun/gun_actions.lua");
dofile_once("data/scripts/gun/procedural/wands.lua");
dofile_once("mods/persistence/files/wand_spell_helper.lua");

spells_per_cast_min = 0;
mana_max_min = 0;
mana_charge_speed_min = 0;
capacity_min = 0;

local data_store = {};
local flag_prefix = "persistence";
local selected_save_id;

function get_save_count()
	return 5;
end

function get_template_count()
	return 5;
end

local function number_to_hex(number)
	if number == nil then
		return nil;
	end
	local positive = math.abs(number);
	return (positive == number and "" or "-") .. string.format("%x", positive);
end

local function hex_to_number(hex)
	if hex == nil then
		return nil;
	end
	if string.sub(hex, 1, 1) == "-" then
		return tonumber(string.sub(hex, 2), 16) * -1;
	else
		return tonumber(hex, 16);
	end
end

local hex_chars = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f", "-" }
local function save_hex(name, hex)
	if hex == nil then
		for j = 1, #hex_chars do
			RemoveFlagPersistent(flag_prefix .. "_" .. name .. "_" .. 1 .. "_" .. hex_chars[j]);
		end
		return;
	end
	for i = 1, #hex do
		for j = 1, #hex_chars do
			RemoveFlagPersistent(flag_prefix .. "_" .. name .. "_" .. i .. "_" .. hex_chars[j]);
		end
		AddFlagPersistent(flag_prefix .. "_" .. name .. "_" .. i .. "_" .. string.sub(hex, i, i));
	end
	for j = 1, #hex_chars do
		RemoveFlagPersistent(flag_prefix .. "_" .. name .. "_" .. #hex + 1 .. "_" .. hex_chars[j]);
	end
end

local function load_hex(name)
	local output = "";
	local i = 1;
	repeat
		local hex_found = false;
		for j = 1, #hex_chars do
			if HasFlagPersistent(flag_prefix .. "_" .. name .. "_" .. i .. "_" .. hex_chars[j]) then
				output = output .. hex_chars[j];
				hex_found = true;
				break;
			end
		end
		i = i + 1;
	until not hex_found
	return (output == "" and nil or output);
end

function load_save_ids()
	for i = 1, get_save_count() do
		if HasFlagPersistent(flag_prefix .. "_" .. tostring(i)) then
			if data_store[i] == nil then
				data_store[i] = {};
			end
		end
	end
	return get_save_ids();
end

function set_run_created_with_mod()
	GameAddFlagRun(flag_prefix .. "_using_mod");
end

function get_run_created_with_mod()
	return GameHasFlagRun(flag_prefix .. "_using_mod");
end

function get_save_ids()
	local output = {};
	for i = 1, get_save_count() do
		if data_store[i] ~= nil then
			output[i] = true;
		end
	end
	return output;
end

function get_selected_save_id()
	if selected_save_id == nil then
		for i = 0, get_save_count() do
			if GameHasFlagRun(flag_prefix .. "_selected_save_" .. tostring(i)) then
				selected_save_id = i;
				return i;
			end
		end
		return nil;
	else
		return selected_save_id;
	end
end

function set_selected_save_id(id)
	for i = 0, get_save_count() do
		GameRemoveFlagRun(flag_prefix .. "_selected_save_" .. tostring(i));
	end
	GameAddFlagRun(flag_prefix .. "_selected_save_" .. tostring(id));
end

function create_new_save(save_id)
	delete_save(save_id);
	load(save_id);
	AddFlagPersistent(flag_prefix .. "_" .. tostring(save_id));
end

function delete_save(save_id)
	local save_id_string = tostring(save_id);

	save_hex(save_id_string .. "_spells_per_cast", nil);
	save_hex(save_id_string .. "_cast_delay_min", nil);
	save_hex(save_id_string .. "_cast_delay_max", nil);
	save_hex(save_id_string .. "_recharge_time_min", nil);
	save_hex(save_id_string .. "_recharge_time_max", nil);
	save_hex(save_id_string .. "_mana_max", nil);
	save_hex(save_id_string .. "_capacity", nil);
	save_hex(save_id_string .. "_spread_min", nil);
	save_hex(save_id_string .. "_spread_max", nil);
	save_hex(save_id_string .. "_money", nil);
	for i = 1, #actions do
		RemoveFlagPersistent(flag_prefix .. "_" .. save_id_string .. "_spell_" .. string.lower(actions[i].id));
		RemoveFlagPersistent(flag_prefix .. "_" .. save_id_string .. "_always_cast_spell_" .. string.lower(actions[i].id));
	end
	for i = 1, #wands do
		RemoveFlagPersistent(flag_prefix .. "_" .. save_id_string .. "_wand_type_" .. sprite_file_to_wand_type(wands[i].file));
	end

	for i = 1, get_template_count() do
		delete_template(save_id, i);
	end

	RemoveFlagPersistent(flag_prefix .. "_" .. save_id_string);
	data_store[save_id] = nil;
end

function get_player_money()
	local money = tonumber(ComponentGetValue(get_wallet(), "money"));
	return money == nil and 0 or money;
end

function set_player_money(value)
	ComponentSetValue(get_wallet(), "money", value);
end

function load(save_id)
	local save_id_string = tostring(save_id);

	data_store[save_id] = {};
	data_store[save_id]["spells_per_cast"] = hex_to_number(load_hex(save_id_string .. "_spells_per_cast"));
	data_store[save_id]["cast_delay_min"] = hex_to_number(load_hex(save_id_string .. "_cast_delay_min"));
	data_store[save_id]["cast_delay_max"] = hex_to_number(load_hex(save_id_string .. "_cast_delay_max"));
	data_store[save_id]["recharge_time_min"] = hex_to_number(load_hex(save_id_string .. "_recharge_time_min"));
	data_store[save_id]["recharge_time_max"] = hex_to_number(load_hex(save_id_string .. "_recharge_time_max"));
	data_store[save_id]["mana_max"] = hex_to_number(load_hex(save_id_string .. "_mana_max"));
	data_store[save_id]["mana_charge_speed"] = hex_to_number(load_hex(save_id_string .. "_mana_charge_speed"));
	data_store[save_id]["capacity"] = hex_to_number(load_hex(save_id_string .. "_capacity"));
	local spread_min = hex_to_number(load_hex(save_id_string .. "_spread_min"));
	if spread_min ~= nil then
		spread_min = spread_min / 10;
	end
	data_store[save_id]["spread_min"] = spread_min;
	local spread_max = hex_to_number(load_hex(save_id_string .. "_spread_max"));
	if spread_max ~= nil then
		spread_max = spread_max / 10;
	end
	data_store[save_id]["spread_max"] = spread_max;
	data_store[save_id]["money"] = hex_to_number(load_hex(save_id_string .. "_money"));

	data_store[save_id]["spells"] = {};
	data_store[save_id]["always_cast_spells"] = {};
	for i = 1, #actions do
		if HasFlagPersistent(flag_prefix .. "_" .. save_id_string .. "_spell_" .. string.lower(actions[i].id)) then
			data_store[save_id]["spells"][actions[i].id] = true;
		end
		if HasFlagPersistent(flag_prefix .. "_" .. save_id_string .. "_always_cast_spell_" .. string.lower(actions[i].id)) then
			data_store[save_id]["always_cast_spells"][actions[i].id] = true;
		end
	end

	data_store[save_id]["wand_types"] = {};
	for i = 1, #mod_config.default_wands do
		data_store[save_id]["wand_types"]["default_" .. tostring(i)] = true;
	end
	for i = 1, #wands do
		local wand_type = sprite_file_to_wand_type(wands[i].file);
		if HasFlagPersistent(flag_prefix .. "_" .. save_id_string .. "_wand_type_" .. string.lower(wand_type)) then
			data_store[save_id]["wand_types"][wand_type] = true;
		end
	end

	data_store[save_id]["templates"] = {};
	for i = 1, get_template_count() do
		if HasFlagPersistent(flag_prefix .. "_" .. save_id_string .. "_template_" .. tostring(i)) then
			data_store[save_id]["templates"][i] = {};
			if HasFlagPersistent(flag_prefix .. "_" .. save_id_string .. "_template_" .. tostring(i) .. "_shuffle") then
				data_store[save_id]["templates"][i]["shuffle"] = true;
			else
				data_store[save_id]["templates"][i]["shuffle"] = false;
			end
			data_store[save_id]["templates"][i]["spells_per_cast"] = hex_to_number(load_hex(save_id_string .. "_template_" .. tostring(i) .. "_spells_per_cast"));
			data_store[save_id]["templates"][i]["cast_delay"] = hex_to_number(load_hex(save_id_string .. "_template_" .. tostring(i) .. "_cast_delay"));
			data_store[save_id]["templates"][i]["recharge_time"] = hex_to_number(load_hex(save_id_string .. "_template_" .. tostring(i) .. "_recharge_time"));
			data_store[save_id]["templates"][i]["mana_max"] = hex_to_number(load_hex(save_id_string .. "_template_" .. tostring(i) .. "_mana_max"));
			data_store[save_id]["templates"][i]["mana_charge_speed"] = hex_to_number(load_hex(save_id_string .. "_template_" .. tostring(i) .. "_mana_charge_speed"));
			data_store[save_id]["templates"][i]["capacity"] = hex_to_number(load_hex(save_id_string .. "_template_" .. tostring(i) .. "_capacity"));
			data_store[save_id]["templates"][i]["spread"] = hex_to_number(load_hex(save_id_string .. "_template_" .. tostring(i) .. "_spread")) / 10;

			data_store[save_id]["templates"][i]["always_cast_spells"] = {};
			for key, _ in pairs(data_store[save_id]["always_cast_spells"]) do
				if HasFlagPersistent(flag_prefix .. "_" .. save_id_string .. "_template_" .. tostring(i) .. "_always_cast_spell_" .. string.lower(key)) then
					table.insert(data_store[save_id]["templates"][i]["always_cast_spells"], key);
					break;
				end
			end

			for key, _ in pairs(data_store[save_id]["wand_types"]) do
				if HasFlagPersistent(flag_prefix .. "_" .. save_id_string .. "_template_" .. tostring(i) .. "_wand_type_" .. string.lower(key)) then
					data_store[save_id]["templates"][i]["wand_type"] = key;
					break;
				end
			end
		end
	end
end

-- spells per cast
function get_spells_per_cast(save_id)
	if data_store[save_id] == nil then
		return nil;
	end
	return data_store[save_id]["spells_per_cast"] == nil and spells_per_cast_min or data_store[save_id]["spells_per_cast"];
end

local function set_spells_per_cast(save_id, value)
	if data_store[save_id] == nil then
		return;
	end
	data_store[save_id]["spells_per_cast"] = value;
	save_hex(tostring(save_id) .. "_spells_per_cast", number_to_hex(data_store[save_id]["spells_per_cast"]));
end

-- cast delay min
function get_cast_delay_min(save_id)
	if data_store[save_id] == nil then
		return nil;
	end
	return data_store[save_id]["cast_delay_min"];
end

local function set_cast_delay_min(save_id, value)
	if data_store[save_id] == nil then
		return;
	end
	data_store[save_id]["cast_delay_min"] = value;
	save_hex(tostring(save_id) .. "_cast_delay_min", number_to_hex(data_store[save_id]["cast_delay_min"]));
end

-- cast delay max
function get_cast_delay_max(save_id)
	if data_store[save_id] == nil then
		return nil;
	end
	return data_store[save_id]["cast_delay_max"];
end

local function set_cast_delay_max(save_id, value)
	if data_store[save_id] == nil then
		return;
	end
	data_store[save_id]["cast_delay_max"] = value;
	save_hex(tostring(save_id) .. "_cast_delay_max", number_to_hex(data_store[save_id]["cast_delay_max"]));
end

-- recharge time min
function get_recharge_time_min(save_id)
	if data_store[save_id] == nil then
		return nil;
	end
	return data_store[save_id]["recharge_time_min"];
end

local function set_recharge_time_min(save_id, value)
	if data_store[save_id] == nil then
		return;
	end
	data_store[save_id]["recharge_time_min"] = value;
	save_hex(tostring(save_id) .. "_recharge_time_min", number_to_hex(data_store[save_id]["recharge_time_min"]));
end

-- recharge time max
function get_recharge_time_max(save_id)
	if data_store[save_id] == nil then
		return nil;
	end
	return data_store[save_id]["recharge_time_max"];
end

local function set_recharge_time_max(save_id, value)
	if data_store[save_id] == nil then
		return;
	end
	data_store[save_id]["recharge_time_max"] = value;
	save_hex(tostring(save_id) .. "_recharge_time_max", number_to_hex(data_store[save_id]["recharge_time_max"]));
end

-- mana max
function get_mana_max(save_id)
	if data_store[save_id] == nil then
		return nil;
	end
	return data_store[save_id]["mana_max"] == nil and mana_max_min or data_store[save_id]["mana_max"];
end

local function set_mana_max(save_id, value)
	if data_store[save_id] == nil then
		return;
	end
	data_store[save_id]["mana_max"] = value;
	save_hex(tostring(save_id) .. "_mana_max", number_to_hex(data_store[save_id]["mana_max"]));
end

-- mana charge speed
function get_mana_charge_speed(save_id)
	if data_store[save_id] == nil then
		return nil;
	end
	return data_store[save_id]["mana_charge_speed"] == nil and mana_charge_speed_min or data_store[save_id]["mana_charge_speed"];
end

local function set_mana_charge_speed(save_id, value)
	if data_store[save_id] == nil then
		return;
	end
	data_store[save_id]["mana_charge_speed"] = value;
	save_hex(tostring(save_id) .. "_mana_charge_speed", number_to_hex(data_store[save_id]["mana_charge_speed"]));
end

-- capacity
function get_capacity(save_id)
	if data_store[save_id] == nil then
		return nil;
	end
	return data_store[save_id]["capacity"] == nil and capacity_min or data_store[save_id]["capacity"];
end

local function set_capacity(save_id, value)
	if data_store[save_id] == nil then
		return;
	end
	data_store[save_id]["capacity"] = value;
	save_hex(tostring(save_id) .. "_capacity", number_to_hex(data_store[save_id]["capacity"]));
end

-- spread min
function get_spread_min(save_id)
	if data_store[save_id] == nil then
		return nil;
	end
	return data_store[save_id]["spread_min"];
end

local function set_spread_min(save_id, value)
	if data_store[save_id] == nil then
		return;
	end
	data_store[save_id]["spread_min"] = value;
	save_hex(tostring(save_id) .. "_spread_min", number_to_hex(data_store[save_id]["spread_min"] == nil and nil or math.floor(data_store[save_id]["spread_min"] * 10)));
end

-- spread max
function get_spread_max(save_id)
	if data_store[save_id] == nil then
		return nil;
	end
	return data_store[save_id]["spread_max"];
end

local function set_spread_max(save_id, value)
	if data_store[save_id] == nil then
		return;
	end
	data_store[save_id]["spread_max"] = value;
	save_hex(tostring(save_id) .. "_spread_max", number_to_hex(data_store[save_id]["spread_max"] == nil and nil or math.ceil(data_store[save_id]["spread_max"] * 10)));
end

-- money
function get_safe_money(save_id)
	if data_store[save_id] == nil then
		return nil;
	end
	return data_store[save_id]["money"] == nil and 0 or data_store[save_id]["money"];
end

function set_safe_money(save_id, value)
	if data_store[save_id] == nil then
		return;
	end
	data_store[save_id]["money"] = value;
	save_hex(tostring(save_id) .. "_money", number_to_hex(data_store[save_id]["money"]));
end

-- spells
function get_spells(save_id)
	if data_store[save_id] == nil then
		return nil;
	end
	if data_store[save_id]["spells"] == nil then
		return {};
	end
	return data_store[save_id]["spells"];
end

local function add_spells(save_id, spells)
	if data_store[save_id] == nil or spells == nil or #spells == 0 then
		return;
	end
	if data_store[save_id]["spells"] == nil then
		data_store[save_id]["spells"] = {};
	end
	for i = 1, #spells do
		data_store[save_id]["spells"][spells[i]] = true;
		AddFlagPersistent(flag_prefix .. "_" .. tostring(save_id) .. "_spell_" .. string.lower(spells[i]));
	end
end

-- always cast spells
function get_always_cast_spells(save_id)
	if data_store[save_id] == nil then
		return nil;
	end
	if data_store[save_id]["always_cast_spells"] == nil then
		return {};
	end
	return data_store[save_id]["always_cast_spells"];
end

local function add_always_cast_spells(save_id, spells)
	if data_store[save_id] == nil or spells == nil or #spells == 0 then
		return;
	end
	if data_store[save_id]["always_cast_spells"] == nil then
		data_store[save_id]["always_cast_spells"] = {};
	end
	for i = 1, #spells do
		data_store[save_id]["always_cast_spells"][spells[i]] = true;
		AddFlagPersistent(flag_prefix .. "_" .. tostring(save_id) .. "_always_cast_spell_" .. string.lower(spells[i]));
	end
end

-- wand types
function get_wand_types(save_id)
	if data_store[save_id] == nil then
		return nil;
	end
	if data_store[save_id]["wand_types"] == nil then
		return {};
	end
	return data_store[save_id]["wand_types"];
end

local function add_wand_types(save_id, wand_types)
	if data_store[save_id] == nil or wand_types == nil or #wand_types == 0 then
		return;
	end
	if data_store[save_id]["wand_types"] == nil then
		data_store[save_id]["wand_types"] = {};
	end
	for i = 1, #wand_types do
		if string.sub(wand_types[i], 1, #"default") ~= "default" then
			data_store[save_id]["wand_types"][wand_types[i]] = true;
			AddFlagPersistent(flag_prefix .. "_" .. tostring(save_id) .. "_wand_type_" .. string.lower(wand_types[i]));
		end
	end
end

-- templates
function get_template(save_id, template_id)
	if data_store[save_id] == nil or data_store[save_id]["templates"] == nil then
		return nil;
	end
	return data_store[save_id]["templates"][template_id];
end

function set_template(save_id, template_id, wand_data)
	if data_store[save_id] == nil or data_store[save_id]["templates"] == nil then
		return;
	end
	delete_template(save_id, template_id);
	if wand_data == nil then
		return;
	end
	local template_prefix = tostring(save_id) .. "_template_" .. tostring(template_id);
	local template_flag_prefix = flag_prefix .. "_" .. template_prefix;
	if wand_data["shuffle"] then
		AddFlagPersistent(template_flag_prefix .. "_shuffle");
	end
	save_hex(template_prefix .. "_spells_per_cast", number_to_hex(wand_data["spells_per_cast"]));
	save_hex(template_prefix .. "_cast_delay", number_to_hex(wand_data["cast_delay"]));
	save_hex(template_prefix .. "_recharge_time", number_to_hex(wand_data["recharge_time"]));
	save_hex(template_prefix .. "_mana_max", number_to_hex(wand_data["mana_max"]));
	save_hex(template_prefix .. "_mana_charge_speed", number_to_hex(wand_data["mana_charge_speed"]));
	save_hex(template_prefix .. "_capacity", number_to_hex(wand_data["capacity"]));
	save_hex(template_prefix .. "_spread", number_to_hex(math.floor(wand_data["spread"] * 10 + 0.5)));

	for _, spell in ipairs(wand_data["always_cast_spells"]) do
		AddFlagPersistent(template_flag_prefix .. "_always_cast_spell_" .. string.lower(spell));
	end

	AddFlagPersistent(template_flag_prefix .. "_wand_type_" .. string.lower(wand_data["wand_type"]));

	AddFlagPersistent(template_flag_prefix);
	data_store[save_id]["templates"][template_id] = wand_data;
end

function delete_template(save_id, template_id)
	if data_store[save_id] == nil then
		return;
	end
	local template_prefix = tostring(save_id) .. "_template_" .. tostring(template_id);
	local template_flag_prefix = flag_prefix .. "_" .. template_prefix;
	RemoveFlagPersistent(template_flag_prefix .. "_shuffle");
	save_hex(template_prefix .. "_spells_per_cast", nil);
	save_hex(template_prefix .. "_cast_delay", nil);
	save_hex(template_prefix .. "_recharge_time", nil);
	save_hex(template_prefix .. "_mana_max", nil);
	save_hex(template_prefix .. "_mana_charge_speed", nil);
	save_hex(template_prefix .. "_capacity", nil);
	save_hex(template_prefix .. "_spread", nil);

	for i = 1, #actions do
		RemoveFlagPersistent(template_flag_prefix .. "_always_cast_spell_" .. string.lower(actions[i].id));
	end

	for i = 1, #mod_config.default_wands do
		RemoveFlagPersistent(template_flag_prefix .. "_wand_type_default_" .. tostring(i));
	end
	for i = 1, #wands do
		RemoveFlagPersistent(template_flag_prefix .. "_wand_type_" .. string.lower(sprite_file_to_wand_type(wands[i].file)));
	end

	RemoveFlagPersistent(template_flag_prefix);
	if data_store[save_id]["templates"] ~= nil then
		data_store[save_id]["templates"][template_id] = nil;
	end
end

function can_create_wand(save_id)
	return get_cast_delay_min(save_id) ~= nil and get_cast_delay_max(save_id) ~= nil and get_recharge_time_min(save_id) ~= nil and get_recharge_time_max(save_id) ~= nil and get_spread_min(save_id) ~= nil and get_spread_max(save_id) ~= nil;
end

function research_wand_is_new(save_id, entity_id)
	local wand_data = read_wand(entity_id);
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
	local always_cast_spells = get_always_cast_spells(save_id);
	local wand_types = get_wand_types(save_id);

	if wand_data["spells_per_cast"] > spells_per_cast then
		return true;
	end
	if cast_delay_min == nil or cast_delay_max == nil then
		return true;
	else
		if wand_data["cast_delay"] < cast_delay_min then
			return true;
		end
		if wand_data["cast_delay"] > cast_delay_max then
			return true;
		end
	end
	if recharge_time_min == nil or recharge_time_max == nil then
		return true;
	else
		if wand_data["recharge_time"] < recharge_time_min then
			return true;
		end
		if wand_data["recharge_time"] > recharge_time_max then
			return true;
		end
	end
	if wand_data["mana_max"] > mana_max then
		return true;
	end
	if wand_data["mana_charge_speed"] > mana_charge_speed then
		return true;
	end
	if wand_data["capacity"] > capacity then
		return true;
	end
	if spread_min == nil or spread_max == nil then
		return true;
	else
		if wand_data["spread"] < spread_min then
			return true;
		end
		if wand_data["spread"] > spread_max then
			return true;
		end
	end
	if wand_data["always_cast_spells"] ~= nil and #wand_data["always_cast_spells"] > 0 then
		for i = 1, #wand_data["always_cast_spells"] do
			if always_cast_spells[wand_data["always_cast_spells"][i]] == nil then
				for j = 1, #actions do
					if actions[j].id == wand_data["always_cast_spells"][i] then
						return true;
					end
				end
			end
		end
	end
	if wand_types[wand_data["wand_type"]] == nil then
		if wand_type_to_wand(wand_data["wand_type"]) ~= nil then
			return true;
		end
	end

	return false;
end

function research_wand_price(save_id, entity_id)
	local wand_data = read_wand(entity_id);
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
	local always_cast_spells = get_always_cast_spells(save_id);
	local wand_types = get_wand_types(save_id);
	local price = 0;

	if wand_data["spells_per_cast"] > spells_per_cast then
		price = price + (wand_data["spells_per_cast"] - spells_per_cast) * 1000;
	end
	if cast_delay_min == nil or cast_delay_max == nil then
		price = price + 0.01 ^ (wand_data["cast_delay"] / 60 - 1.8) + 200;
	else
		if wand_data["cast_delay"] < cast_delay_min then
			price = price + (0.01 ^ (wand_data["cast_delay"] / 60 - 1.8) + 200) - (0.01 ^ (cast_delay_min / 60 - 1.8) + 200);
		end
		if wand_data["cast_delay"] > cast_delay_max then
			price = price + (wand_data["cast_delay"] / 60 - cast_delay_max / 60) * 100;
		end
	end
	if recharge_time_min == nil or recharge_time_max == nil then
		price = price + 0.01 ^ (wand_data["recharge_time"] / 60 - 1.8) + 200;
	else
		if wand_data["recharge_time"] < recharge_time_min then
			price = price + (0.01 ^ (wand_data["recharge_time"] / 60 - 1.8) + 200) - (0.01 ^ (recharge_time_min / 60 - 1.8) + 200);
		end
		if wand_data["recharge_time"] > recharge_time_max then
			price = price + (wand_data["recharge_time"] / 60 - recharge_time_max / 60) * 100;
		end
	end
	if wand_data["mana_max"] > mana_max then
		price = price + (wand_data["mana_max"] - mana_max) * 10;
	end
	if wand_data["mana_charge_speed"] > mana_charge_speed then
		price = price + (wand_data["mana_charge_speed"] - mana_charge_speed) * 20;
	end
	if wand_data["capacity"] > capacity then
		price = price + (wand_data["capacity"] - capacity) * 1000;
	end
	if spread_min == nil or spread_max == nil then
		price = price + math.abs(5 - wand_data["spread"]) * 10;
	else
		if wand_data["spread"] < spread_min then
			price = price + (spread_min - wand_data["spread"]) * 10;
		end
		if wand_data["spread"] > spread_max then
			price = price + (wand_data["spread"] - spread_max) * 10;
		end
	end
	if wand_data["always_cast_spells"] ~= nil and #wand_data["always_cast_spells"] > 0 then
		for i = 1, #wand_data["always_cast_spells"] do
			if always_cast_spells[wand_data["always_cast_spells"][i]] == nil then
				for j = 1, #actions do
					if actions[j].id == wand_data["always_cast_spells"][i] then
						price = price + actions[j].price * 20;
						break;
					end
				end
			end
		end
	end
	if wand_types[wand_data["wand_type"]] == nil then
		if wand_type_to_wand(wand_data["wand_type"]) ~= nil then
			price = math.max(100, price);
		end
	end

	return math.ceil(price * mod_config.research_wand_price_multiplier);
end

function research_wand(save_id, entity_id)
	local wand_data = read_wand(entity_id);
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

	local price = research_wand_price(save_id, entity_id);
	if get_player_money() < price then
		return false;
	end

	if wand_data["spells_per_cast"] > spells_per_cast then
		set_spells_per_cast(save_id, wand_data["spells_per_cast"]);
	end
	if cast_delay_min == nil or wand_data["cast_delay"] < cast_delay_min then
		set_cast_delay_min(save_id, wand_data["cast_delay"]);
	end
	if cast_delay_max == nil or wand_data["cast_delay"] > cast_delay_max then
		set_cast_delay_max(save_id, wand_data["cast_delay"]);
	end
	if recharge_time_min == nil or wand_data["recharge_time"] < recharge_time_min then
		set_recharge_time_min(save_id, wand_data["recharge_time"]);
	end
	if recharge_time_max == nil or wand_data["recharge_time"] > recharge_time_max then
		set_recharge_time_max(save_id, wand_data["recharge_time"]);
	end
	if wand_data["mana_max"] > mana_max then
		set_mana_max(save_id, wand_data["mana_max"]);
	end
	if wand_data["mana_charge_speed"] > mana_charge_speed then
		set_mana_charge_speed(save_id, wand_data["mana_charge_speed"]);
	end
	if wand_data["capacity"] > capacity then
		set_capacity(save_id, wand_data["capacity"]);
	end
	if spread_min == nil or wand_data["spread"] < spread_min then
		set_spread_min(save_id, wand_data["spread"]);
	end
	if spread_max == nil or wand_data["spread"] > spread_max then
		set_spread_max(save_id, wand_data["spread"]);
	end
	if wand_data["always_cast_spells"] ~= nil and #wand_data["always_cast_spells"] > 0 then
		add_always_cast_spells(save_id, wand_data["always_cast_spells"]);
	end
	if wand_type_to_wand(wand_data["wand_type"]) ~= nil then
		add_wand_types(save_id, { wand_data["wand_type"] });
	end

	delete_wand(entity_id);
	set_player_money(get_player_money() - price);
	return true;
end

function research_spell_price(entity_id)
	local action_id = read_spell(entity_id);
	for i = 1, #actions do
		if actions[i].id == action_id then
			return math.ceil(actions[i].price * mod_config.research_spell_price_multiplier);
		end
	end
end

function research_spell(save_id, entity_id)
	local price = research_spell_price(entity_id);
	if get_player_money() < price then
		return false;
	end

	add_spells(save_id, { read_spell(entity_id) });

	delete_spell(entity_id);
	set_player_money(get_player_money() - price);
	return true;
end

function transfer_money_to_safe(save_id, amount)
	if get_player_money() < amount then
		return false;
	end

	set_safe_money(save_id, get_safe_money(save_id) + amount);
	set_player_money(get_player_money() - amount);
	return true;
end

function transfer_money_to_player(save_id, amount)
	if get_safe_money(save_id) < amount then
		return false;
	end

	set_player_money(get_player_money() + amount);
	set_safe_money(save_id, get_safe_money(save_id) - amount);
	return true;
end