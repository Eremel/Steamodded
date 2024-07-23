--- STEAMODDED CORE
--- UTILITY FUNCTIONS
function inspect(table)
	if type(table) ~= 'table' then
		return "Not a table"
	end

	local str = ""
	for k, v in pairs(table) do
		local valueStr = type(v) == "table" and "table" or tostring(v)
		str = str .. tostring(k) .. ": " .. valueStr .. "\n"
	end

	return str
end

function inspectDepth(table, indent, depth)
	if depth and depth > 5 then  -- Limit the depth to avoid deep nesting
		return "Depth limit reached"
	end

	if type(table) ~= 'table' then  -- Ensure the object is a table
		return "Not a table"
	end

	local str = ""
	if not indent then indent = 0 end

	for k, v in pairs(table) do
		local formatting = string.rep("  ", indent) .. tostring(k) .. ": "
		if type(v) == "table" then
			str = str .. formatting .. "\n"
			str = str .. inspectDepth(v, indent + 1, (depth or 0) + 1)
		elseif type(v) == 'function' then
			str = str .. formatting .. "function\n"
		elseif type(v) == 'boolean' then
			str = str .. formatting .. tostring(v) .. "\n"
		else
			str = str .. formatting .. tostring(v) .. "\n"
		end
	end

	return str
end

function inspectFunction(func)
    if type(func) ~= 'function' then
        return "Not a function"
    end

    local info = debug.getinfo(func)
    local result = "Function Details:\n"

    if info.what == "Lua" then
        result = result .. "Defined in Lua\n"
    else
        result = result .. "Defined in C or precompiled\n"
    end

    result = result .. "Name: " .. (info.name or "anonymous") .. "\n"
    result = result .. "Source: " .. info.source .. "\n"
    result = result .. "Line Defined: " .. info.linedefined .. "\n"
    result = result .. "Last Line Defined: " .. info.lastlinedefined .. "\n"
    result = result .. "Number of Upvalues: " .. info.nups .. "\n"

    return result
end

function SMODS._save_d_u(o)
    assert(not o._discovered_unlocked_overwritten)
    o._d, o._u = o.discovered, o.unlocked
    o._saved_d_u = true
end

function SMODS.SAVE_UNLOCKS()
    boot_print_stage("Saving Unlocks")
	G:save_progress()
    -------------------------------------
    local TESTHELPER_unlocks = false and not _RELEASE_MODE
    -------------------------------------
    if not love.filesystem.getInfo(G.SETTINGS.profile .. '') then
        love.filesystem.createDirectory(G.SETTINGS.profile ..
            '')
    end
    if not love.filesystem.getInfo(G.SETTINGS.profile .. '/' .. 'meta.jkr') then
        love.filesystem.append(
            G.SETTINGS.profile .. '/' .. 'meta.jkr', 'return {}')
    end

    convert_save_to_meta()

    local meta = STR_UNPACK(get_compressed(G.SETTINGS.profile .. '/' .. 'meta.jkr') or 'return {}')
    meta.unlocked = meta.unlocked or {}
    meta.discovered = meta.discovered or {}
    meta.alerted = meta.alerted or {}

    G.P_LOCKED = {}
    for k, v in pairs(G.P_CENTERS) do
        if not v.wip and not v.demo then
            if TESTHELPER_unlocks then
                v.unlocked = true; v.discovered = true; v.alerted = true
            end --REMOVE THIS
            if not v.unlocked and (string.find(k, '^j_') or string.find(k, '^b_') or string.find(k, '^v_')) and meta.unlocked[k] then
                v.unlocked = true
            end
            if not v.unlocked and (string.find(k, '^j_') or string.find(k, '^b_') or string.find(k, '^v_')) then
                G.P_LOCKED[#G.P_LOCKED + 1] = v
            end
            if not v.discovered and (string.find(k, '^j_') or string.find(k, '^b_') or string.find(k, '^e_') or string.find(k, '^c_') or string.find(k, '^p_') or string.find(k, '^v_')) and meta.discovered[k] then
                v.discovered = true
            end
            if v.discovered and meta.alerted[k] or v.set == 'Back' or v.start_alerted then
                v.alerted = true
            elseif v.discovered then
                v.alerted = false
            end
        end
    end

	table.sort(G.P_LOCKED, function (a, b) return a.order and b.order and a.order < b.order end)

	for k, v in pairs(G.P_BLINDS) do
        v.key = k
        if not v.wip and not v.demo then 
            if TESTHELPER_unlocks then v.discovered = true; v.alerted = true  end --REMOVE THIS
            if not v.discovered and meta.discovered[k] then 
                v.discovered = true
            end
            if v.discovered and meta.alerted[k] then 
                v.alerted = true
            elseif v.discovered then
                v.alerted = false
            end
        end
    end
	for k, v in pairs(G.P_TAGS) do
        v.key = k
        if not v.wip and not v.demo then 
            if TESTHELPER_unlocks then v.discovered = true; v.alerted = true  end --REMOVE THIS
            if not v.discovered and meta.discovered[k] then 
                v.discovered = true
            end
            if v.discovered and meta.alerted[k] then 
                v.alerted = true
            elseif v.discovered then
                v.alerted = false
            end
        end
    end
    for k, v in pairs(G.P_SEALS) do
        v.key = k
        if not v.wip and not v.demo then
            if TESTHELPER_unlocks then
                v.discovered = true; v.alerted = true
            end                                                                   --REMOVE THIS
            if not v.discovered and meta.discovered[k] then
                v.discovered = true
            end
            if v.discovered and meta.alerted[k] then
                v.alerted = true
            elseif v.discovered then
                v.alerted = false
            end
        end
    end
    for _, t in ipairs{
        G.P_CENTERS,
        G.P_BLINDS,
        G.P_TAGS,
        G.P_SEALS,
    } do
        for k, v in pairs(t) do
            v._discovered_unlocked_overwritten = true
        end
    end
end

function SMODS.process_loc_text(ref_table, ref_value, loc_txt, key)
    local target = (type(loc_txt) == 'table') and
    (loc_txt[G.SETTINGS.language] or loc_txt['default'] or loc_txt['en-us']) or loc_txt
    if key and (type(target) == 'table') then target = target[key] end
    if not (type(target) == 'string' or target and next(target)) then return end
    ref_table[ref_value] = target
end

function SMODS.handle_loc_file(path)
    local dir = path .. 'localization/'
	local file_name
    for k, v in ipairs({ dir .. G.SETTINGS.language .. '.lua', dir .. 'default.lua', dir .. 'en-us.lua', dir .. G.SETTINGS.language .. '.json', dir .. 'default.json', dir .. 'en-us.json' }) do
        if NFS.getInfo(v) then
            file_name = v
            break
        end
    end
    if not file_name then return end

    -- check if file name ends in .json
    local loc_table = nil
    if file_name:lower():match("%.json$") then
        loc_table = assert(JSON.decode(NFS.read(file_name)))
    else
        loc_table = assert(loadstring(NFS.read(file_name)))()
    end
    local function recurse(target, ref_table)
        if type(target) ~= 'table' then return end --this shouldn't happen unless there's a bad return value
        for k, v in pairs(target) do
            if not ref_table[k] or (type(v) ~= 'table') then
                ref_table[k] = v
            else
                recurse(v, ref_table[k])
            end
        end
    end
	recurse(loc_table, G.localization)
end

function SMODS.insert_pool(pool, center, replace)
	if replace == nil then replace = center.taken_ownership end
	if replace then
		for k, v in ipairs(pool) do
            if v.key == center.key then
                pool[k] = center
            end
		end
    else
		local prev_order = (pool[#pool] and pool[#pool].order) or 0
		if prev_order ~= nil then 
			center.order = prev_order + 1
		end
		table.insert(pool, center)
	end
end

function SMODS.remove_pool(pool, key)
    local j
    for i, v in ipairs(pool) do
        if v.key == key then j = i end
    end
    if j then return table.remove(pool, j) end
end

function SMODS.juice_up_blind()
    local ui_elem = G.HUD_blind:get_UIE_by_ID('HUD_blind_debuff')
    for _, v in ipairs(ui_elem.children) do
        v.children[1]:juice_up(0.3, 0)
    end
    G.GAME.blind:juice_up()
end

function SMODS.eval_this(_card, effects)
    if effects then
        local extras = { mult = false, hand_chips = false }
        if effects.mult_mod then
            mult = mod_mult(mult + effects.mult_mod); extras.mult = true
        end
        if effects.chip_mod then
            hand_chips = mod_chips(hand_chips + effects.chip_mod); extras.hand_chips = true
        end
        if effects.Xmult_mod then
            mult = mod_mult(mult * effects.Xmult_mod); extras.mult = true
        end
        update_hand_text({ delay = 0 }, { chips = extras.hand_chips and hand_chips, mult = extras.mult and mult })
        if effects.message then
            card_eval_status_text(_card, 'jokers', nil, nil, nil, effects)
        end
    end
end

-- Return an array of all (non-debuffed) jokers or consumables with key `key`.
-- Debuffed jokers count if `count_debuffed` is true.
-- This function replaces find_joker(); please use SMODS.find_card() instead
-- to avoid name conflicts with other mods.
function SMODS.find_card(key, count_debuffed)
    local results = {}
    if not G.jokers or not G.jokers.cards then return {} end
    for k, v in pairs(G.jokers.cards) do
        if v and type(v) == 'table' and v.config.center.key == key and (count_debuffed or not v.debuff) then
            table.insert(results, v)
        end
    end
    for k, v in pairs(G.consumeables.cards) do
        if v and type(v) == 'table' and v.config.center.key == key and (count_debuffed or not v.debuff) then
            table.insert(results, v)
        end
    end
    return results
end

function SMODS.create_card(t)
    if not t.area and t.key and G.P_CENTERS[t.key] then
        t.area = G.P_CENTERS[t.key].consumeable and G.consumeables or G.P_CENTERS[t.key].set == 'Joker' and G.jokers
    end
    if not t.area and not t.key and t.set and SMODS.ConsumableTypes[t.set] then
        t.area = G.consumeables
    end
    SMODS.bypass_create_card_edition = t.no_edition
    local _card = create_card(t.set, t.area, t.legendary, t.rarity, t.skip_materialize, t.soulable, t.key, t.key_append)
    SMODS.bypass_create_card_edition = nil
    return _card
end

-- Recalculate whether a card should be debuffed
function SMODS.recalc_debuff(card)
    G.GAME.blind:debuff_card(card)
end

function SMODS.restart_game()
	if love.system.getOS() ~= 'OS X' then
		love.system.openURL('steam://rungameid/2379780')
	else
		os.execute('sh "/Users/$USER/Library/Application Support/Steam/steamapps/common/Balatro/run_lovely.sh" &')
	end
	love.event.quit()
end

function SMODS.create_mod_badges(obj, badges)
    if not SMODS.config.no_mod_badges and obj and obj.mod and obj.mod.display_name and not obj.no_mod_badges then
        local mods = {}
        badges.mod_set = badges.mod_set or {}
        if not badges.mod_set[obj.mod.id] and not obj.no_main_mod_badge then table.insert(mods, obj.mod) end
        badges.mod_set[obj.mod.id] = true
        if obj.dependencies then
            for _, v in ipairs(obj.dependencies) do
                local m = SMODS.Mods[v]
                if not badges.mod_set[m.id] then
                    table.insert(mods, m)
                    badges.mod_set[m.id] = true
                end
            end
        end
        for i, mod in ipairs(mods) do
            local mod_name = string.sub(mod.display_name, 1, 20)
            local size = 0.9
            local font = G.LANG.font
            local max_text_width = 2 - 2*0.05 - 4*0.03*size - 2*0.03
            local calced_text_width = 0
            -- Math reproduced from DynaText:update_text
            for _, c in utf8.chars(mod_name) do
                local tx = font.FONT:getWidth(c)*(0.33*size)*G.TILESCALE*font.FONTSCALE + 2.7*1*G.TILESCALE*font.FONTSCALE
                calced_text_width = calced_text_width + tx/(G.TILESIZE*G.TILESCALE)
            end
            local scale_fac =
                calced_text_width > max_text_width and max_text_width/calced_text_width
                or 1
            badges[#badges + 1] = {n=G.UIT.R, config={align = "cm"}, nodes={
                {n=G.UIT.R, config={align = "cm", colour = mod.badge_colour or G.C.GREEN, r = 0.1, minw = 2, minh = 0.36, emboss = 0.05, padding = 0.03*size}, nodes={
                  {n=G.UIT.B, config={h=0.1,w=0.03}},
                  {n=G.UIT.O, config={object = DynaText({string = mod_name or 'ERROR', colours = {mod.badge_text_colour or G.C.WHITE},float = true, shadow = true, offset_y = -0.05, silent = true, spacing = 1*scale_fac, scale = 0.33*size*scale_fac})}},
                  {n=G.UIT.B, config={h=0.1,w=0.03}},
                }}
              }}
        end
    end
end

function SMODS.create_loc_dump()
    local _old, _new = SMODS.dump_loc.pre_inject, G.localization
    local _dump = {}
    local function recurse(old, new, dump)
        for k, _ in pairs(new) do
            if type(new[k]) == 'table' then
                dump[k] = {}
                if not old[k] then
                    dump[k] = new[k]
                else
                    recurse(old[k], new[k], dump[k])
                end
            elseif old[k] ~= new[k] then
                dump[k] = new[k]
            end
        end
    end
    recurse(_old, _new, _dump)
    local function cleanup(dump)
        for k, v in pairs(dump) do
            if type(v) == 'table' then
                cleanup(v)
                if not next(v) then dump[k] = nil end
            end
        end
    end
    cleanup(_dump)
    local str = 'return ' .. serialize(_dump)
	NFS.createDirectory(SMODS.dump_loc.path..'localization/')
	NFS.write(SMODS.dump_loc.path..'localization/dump.lua', str)
end

-- Serializes an input table in valid Lua syntax
-- Keys must be of type number or string
-- Values must be of type number, boolean, string or table
function serialize(t, indent)
    indent = indent or ''
    local str = '{\n'
	for k, v in ipairs(t) do
        str = str .. indent .. '\t'
		if type(v) == 'number' then
            str = str .. v
        elseif type(v) == 'boolean' then
            str = str .. (v and 'true' or 'false')
        elseif type(v) == 'string' then
            str = str .. serialize_string(v)
        elseif type(v) == 'table' then
            str = str .. serialize(v, indent .. '\t')
        else
            -- not serializable
            str = str .. 'nil'
        end
		str = str .. ',\n'
	end
    for k, v in pairs(t) do
		if type(k) == 'string' then
        	str = str .. indent .. '\t' .. '[' .. serialize_string(k) .. '] = '
            
			if type(v) == 'number' then
				str = str .. v
            elseif type(v) == 'boolean' then
                str = str .. (v and 'true' or 'false')
			elseif type(v) == 'string' then
				str = str .. serialize_string(v)
			elseif type(v) == 'table' then
				str = str .. serialize(v, indent .. '\t')
			else
				-- not serializable
                str = str .. 'nil'
			end
			str = str .. ',\n'
		end
    end
    str = str .. indent .. '}'
	return str
end

function serialize_string(s)
	return string.format("%q", s)
end

-- Starting with `t`, insert any key-value pairs from `defaults` that don't already
-- exist in `t` into `t`. Modifies `t`.
-- Returns `t`, the result of the merge.
--
-- `nil` inputs count as {}; `false` inputs count as a table where
-- every possible key maps to `false`. Therefore,
-- * `t == nil` is weak and falls back to `defaults`
-- * `t == false` explicitly ignores `defaults`
-- (This function might not return a table, due to the above)
function SMODS.merge_defaults(t, defaults)
    if t == false then return false end
    if defaults == false then return false end

    -- Add in the keys from `defaults`, returning a table
    if defaults == nil then return t end
    if t == nil then t = {} end
    for k, v in pairs(defaults) do
        if t[k] == nil then
            t[k] = v
        end
    end
    return t
end

--#region alt textures
G.SETTINGS.selected_texture = G.SETTINGS.selected_texture or {}
default_palettes = { -- Default palettes mostly used for auto generated palettes
	Spectral = { 
	"344245","4f6367","bfc7d5","96aacb",
	"4e5779","4d6ca4","607192","5e7297","637699","5b7fc1","638fe1","7aa4f2","7fa5eb","b8d1ff","bfcce3","e2ebf9",
	"8b8361","918756","a79c67","e8d67f","dcc659","c7b24a"
	},
	Planet = {
		"4f6367","5b9baa","84c5d2","dff5fc","ffffff"
	},
	Tarot = {
		"4f6367","a58547","dab772","ffe5b4","ffffff"
	}
}

function create_base_game_atlas(self)
    self.image_data = love.image.newImageData(self.path)
    self.image = love.graphics.newImage(self.image_data, {mipmaps = true, dpiscale = G.SETTINGS.GRAPHICS.texture_scaling})
    G[self.atlas_table][self.key_noloc or self.key] = self

end

function prepare_palette(self)
    SMODS.AltTextures[self.type][self.name].old_colours = {}
    SMODS.AltTextures[self.type][self.name].new_colours = {}
    
    -- Grab the default palette if one is not given (mostly used for auto generated palettes)
    if not self.old_colours then self.old_colours = default_palettes[self.type] end
    for i=1, #self.old_colours do
        SMODS.AltTextures[self.type][self.name].old_colours[i] = type(self.old_colours[i]) == "string" and HEX(self.old_colours[i]) or self.old_colours[i]
        SMODS.AltTextures[self.type][self.name].new_colours[i] = type(self.new_colours[i]) == "string" and HEX(self.new_colours[i]) or self.new_colours[i]
    end
    
    recolour_atlases(get_atlas_keys(self.type), self.name, SMODS.AltTextures[self.type][self.name].old_colours, SMODS.AltTextures[self.type][self.name].new_colours)
end

function create_default_alt_texture(type)
    table.insert(SMODS.AltTextures[type].names, "Default")
    SMODS.AltTextures[type]["Default"] = {
        name = "Default",
        order = 1,
        old_colours = {},
        new_colours = {},
    }
    local atlas_keys = get_atlas_keys(type)
    for _,v in pairs(atlas_keys) do
        G.ASSET_ATLAS[v]["Default"] = {image_data = G.ASSET_ATLAS[v].image_data:clone()}
        G.ASSET_ATLAS[v]["Default"].image = love.graphics.newImage(G.ASSET_ATLAS[v]["Default"].image_data, {mipmaps = true, dpiscale = G.SETTINGS.GRAPHICS.texture_scaling})
    end
end

function get_atlas_keys(type)
    local atlas_keys = {}
    if type == "Suit" then
        atlas_keys = {"cards_1", "ui_1"}
    elseif type == "Seal" then
        atlas_keys = {"centers"}
    elseif type == "Tag" then
        atlas_keys = {"tags"}
    elseif type == "Blind" then
        atlas_keys = {"Blind"}
    else
        for _,v in pairs(G.P_CENTER_POOLS[type]) do
            atlas_keys[v.atlas or type] = v.atlas or type
        end
        if type == "Spectral" then atlas_keys["soul"] = "soul" end
    end
    return atlas_keys
end


function recolour_atlases(atlas_keys, name, old_colours, new_colours)
    for _,v in pairs(atlas_keys) do
        G.ASSET_ATLAS[v][name] = {image_data = G.ASSET_ATLAS[v].image_data:clone()}
        G.ASSET_ATLAS[v][name].image_data:mapPixel(function(x,y,r,g,b,a)
            return recolour_pixel(x,y,r,g,b,a,old_colours,new_colours)
        end)
        G.ASSET_ATLAS[v][name].image = love.graphics.newImage(G.ASSET_ATLAS[v][name].image_data, {mipmaps = true, dpiscale = G.SETTINGS.GRAPHICS.texture_scaling})
    end
end

function recolour_pixel(x,y,r,g,b,a,old_colours,new_colours)
		for i, old_colour in ipairs(old_colours) do
			if old_colour[1] == r and old_colour[2] == g and old_colour[3] == b then
				r = new_colours[i][1]
				g = new_colours[i][2]
				b = new_colours[i][3]
				return r,g,b,a
			end
		end
	return r, g, b, a
end

function atlas_to_texture(self)
    local atlas_key
    if self.type == "Suit" then
        atlas_key = "cards_1"
        local default_suit_colours = {HEX("235955"),HEX("3c4368"),HEX("f06b3f"),HEX("f03464")}
        local new_colours = {
            HEX(SMODS.AltTextures[self.type][self.name].suits.Clubs),
            HEX(SMODS.AltTextures[self.type][self.name].suits.Spades),
            HEX(SMODS.AltTextures[self.type][self.name].suits.Diamonds),
            HEX(SMODS.AltTextures[self.type][self.name].suits.Hearts)
        }
        if self.suit_pips then
            G.ASSET_ATLAS["ui_1"][self.name] = G.ASSET_ATLAS[self.suit_pips]
        else
            recolour_atlases({"ui_1"}, self.name, default_suit_colours, new_colours)
        end
    elseif self.type == "Spectral" then
        atlas_key = "Spectral"
        if G.ASSET_ATLAS[self.atlas_key.."_e"] then
            G.ASSET_ATLAS["soul"][self.name] = G.ASSET_ATLAS[self.atlas_key.."_e"]
        else
            G.ASSET_ATLAS["soul"][self.name] = {image_data = G.ASSET_ATLAS["soul"].image_data:clone()}
            G.ASSET_ATLAS["soul"][self.name].image = love.graphics.newImage(G.ASSET_ATLAS["soul"][self.name].image_data, {mipmaps = true, dpiscale = G.SETTINGS.GRAPHICS.texture_scaling})
        end
    elseif self.type == "Seal" then
        atlas_key = "centers"
    elseif self.type == "Tag" then
        atlas_key = "tags"
    elseif self.type == "Blind" then
        atlas_key = "Blind"
    else
        if G.ASSET_ATLAS[self.type] then
            atlas_key = self.type
        else
            for _,v in pairs(G.P_CENTER_POOLS[self.type]) do
                atlas_key = v.atlas
            end
        end
    end
    G.ASSET_ATLAS[atlas_key][self.name] = G.ASSET_ATLAS[self.atlas_key]
end

-- Call the `generate_colours` function of the appropriate type
-- TODO: Move to own mod
function create_colours(type, base_colours)
    if SMODS.ConsumableTypes[type].generate_colours then
        return SMODS.ConsumableTypes[type]:generate_colours(base_colours)
    end
    return {(type(base_colours) == 'table' and HEX(base_colours[1]) or HEX(base_colours))}
end 

-- Called from option selectors that control each type
G.FUNCS.select_texture = function(args)
    G.SETTINGS.selected_texture[args.cycle_config.type] = args.to_val
	G:save_settings()
	G.FUNCS.update_atlases(args.cycle_config.type)
end

-- Set the atlases of all cards of the correct type to be the new texture
G.FUNCS.update_atlases = function(type)
    local name = G.SETTINGS.selected_texture[type]
	if not SMODS.AltTextures[type][name] then return end
	local atlas_keys = {}
	if type == "Suit" then
		atlas_keys = {"cards_1", "ui_1"}
		for suit, _ in pairs(G.C["SO_1"]) do
			local colour = (SMODS.AltTextures.Suit[name].suits and SMODS.AltTextures.Suit[name].suits[suit] or SMODS.AltTextures.Suit["Default"].suits[suit] or nil)
			G.C["SO_1"][suit] =  (colour and HEX(colour) or G.C["SO_1"][suit])
			G.C.SUITS[suit] = G.C["SO_1"][suit]
		end		
    elseif type == "Seal" then
        atlas_keys = {"centers"}
    elseif type == "Tag" then
        atlas_keys = {"tags"}
    elseif type == "Blind" then
        if G.ASSET_ATLAS[type][name] then
            G.ANIMATION_ATLAS["blind_chips"].image = G.ASSET_ATLAS[type][name].image
        end
        return
	else
		for _, card in pairs(G.P_CENTER_POOLS[type]) do
			atlas_keys[card.atlas or type] = card.atlas or type
		end
        if type == "Spectral" then
            atlas_keys["soul"] = "soul"
        end
	end
	for _, atlas_key in pairs(atlas_keys) do
        sendInfoMessage(atlas_key .. " set to ".. name, "AltTexture")
		if G.ASSET_ATLAS[atlas_key][name] then
			G.ASSET_ATLAS[atlas_key].image = G.ASSET_ATLAS[atlas_key][name].image
		end
	end
end

-- Convert a hex code into HSL values
---@param base_colour string
function HEX_HSL(base_colour)
	local rgb = HEX(base_colour)
	local low = math.min(rgb[1], rgb[2], rgb[3])
	local high = math.max(rgb[1], rgb[2], rgb[3])
	local delta = high - low
	local sum = high + low
	local hsl = {0, 0, 0.5 * sum, rgb[4]}
	
	if delta == 0 then return hsl end
	
	if hsl[3] == 1 or hsl[3] == 0 then
		hsl[2] = 0
	else
		hsl[2] = delta/1-math.abs(2*hsl[3] - 1)
	end
	
	if high == rgb[1] then
		hsl[1] = ((rgb[2]-rgb[3])/delta) % 6
	elseif high == rgb[2] then
		hsl[1] = 2 + (rgb[3]-rgb[1])/delta
	else
		hsl[1] = 4 + (rgb[1]-rgb[2])/delta 
	end
	hsl[1] = hsl[1]/6
	return hsl
end

-- Convert a HSL values table to RGB values
---@param base_colour table
function HSL_RGB(base_colour)
	if base_colour[2] < 0.0001 then return {base_colour[3], base_colour[3], base_colour[3], base_colour[4]} end
	local t = (base_colour[3] < 0.5 and (base_colour[2]*base_colour[3] + base_colour[3]) or (-1 * base_colour[2] * base_colour[3] + (base_colour[2]+base_colour[3])))
	local s = 2 * base_colour[3] - t

	return {HUE(s, t, base_colour[1] + (1/3)), HUE(s,t,base_colour[1]), HUE(s,t,base_colour[1] - (1/3)), base_colour[4]}
end

-- Called within HSL_RGB to calculate the rgb values
function HUE(s, t, h)
	local hs = (h % 1) * 6
	if hs < 1 then return (t-s) * hs + s end
	if hs < 3 then return t end
	if hs < 4 then return (t-s) * (4-hs) + s end
	return s
end

--#endregion
