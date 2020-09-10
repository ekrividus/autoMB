--[[
Copyright © 2020, Ekrividus
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of autoMB nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Ekrividus BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

--[[
autoMB will cast elements for magic bursts automatically
job/level is pulled from game and appropriate elements are used

single bursting only for now, but double may me introduced later

]]
_addon.version = '0.7.0'
_addon.name = 'autoMB'
_addon.author = 'Ekrividus'
_addon.commands = {'autoMB'}
_addon.lastUpdate = '6/11/2020'
_addon.windower = '4'

require 'tables'
require 'strings'
require 'logger'

res = require('resources')
config = require('config')
chat = require('chat')
packets = require('packets')

defaults = T{}
defaults.debug = false -- Show debug output
defaults.frequency = 1 -- How many times per second to update skillchain effects
defaults.show_skillchain = false -- Whether or not to show skillchain name
defaults.show_elements = false -- Whether or not to show skillchain element info
defaults.show_bonus_elements = false -- Whether or not to show Storm/Weather/Day elements
defaults.show_spell = false -- Whether or not to post the spell selection to chat
defaults.check_day = false -- Whether or not to use day bonus spell
defaults.check_weather = false -- Whether or not to use weather bonus, probably turn on if storms are being used
defaults.useAOE = false -- Whether or not to use AOE elements
defaults.cast_delay = 1.0 -- Delay from when skillchain occurs to when first spell is cast
defaults.double_burst = false -- Not implemented yet
defaults.double_burst_delay = 0 -- Time from when first spell starts casting to when second spell starts casting
defaults.mp = 100 -- Don't burst if it will leave you below this mark
defaults.cast_type = 'spell' -- Type of MB spell|jutsu|helix|ga|ja|ra
defaults.cast_tier = 1 -- What tier should we try to cast
defaults.step_down = 0 -- Step down a tier for double bursts (0: Never, 1: If target changed, 2: Always)
defaults.gearswap = false -- Tell gearswap when we're bursting
settings = config.load(defaults)

local skillchains = {
	[288] = {id=288,english='Light',elements={'Light','Thunder','Wind','Fire'}},
	[289] = {id=289,english='Darkness',elements={'Dark','Ice','Water','Earth'}},
	[290] = {id=290,english='Gravitation',elements={'Dark','Earth'}},
	[291] = {id=291,english='Fragmentation',elements={'Thunder','Wind'}},
	[292] = {id=292,english='Distortion',elements={'Ice','Water'}},
	[293] = {id=293,english='Fusion',elements={'Light','Fire'}},
	[294] = {id=294,english='Compression',elements={'Dark'}},
	[295] = {id=295,english='Liquefaction',elements={'Fire'}},
	[296] = {id=296,english='Induration',elements={'Ice'}},
	[297] = {id=297,english='Reverberation',elements={'Water'}},
	[298] = {id=298,english='Transfixion', elements={'Light'}},
	[299] = {id=299,english='Scission',elements={'Earth'}},
	[300] = {id=300,english='Detonation',elements={'Wind'}},
	[301] = {id=301,english='Impaction',elements={'Thunder'}}
}

local magic_tiers = {
	[1] = {suffix=''},
	[2] = {suffix='II'},
	[3] = {suffix='III'},
	[4] = {suffix='IV'},
	[5] = {suffix='V'},
	[6] = {suffix='VI'}
}

local jutsu_tiers = {
    [1] = {suffix='Ichi'},
    [2] = {suffix='Ni'},
    [3] = {suffix='San'}
}

local spell_priorities = {
	[1] = {element='Thunder'},
	[2] = {element='Ice'},
	[3] = {element='Wind'},
	[4] = {element='Fire'},
	[5] = {element='Water'},
	[6] = {element='Earth'},
	[7] = {element='Dark'},
	[8] = {element='Light'}
}

local storms = {
	[178] = {id=178,name='Firestorm',weather=4},
	[179] = {id=179,name='Hailstorm',weather=12},
	[180] = {id=180,name='Windstorm',weather=10},
	[181] = {id=181,name='Sandstorm',weather=8},
	[182] = {id=182,name='Thunderstorm',weather=14},
	[183] = {id=183,name='Rainstorm',weather=6},
	[184] = {id=184,name='Aurorastorm',weather=16},
	[185] = {id=185,name='Voidstorm',weather=18},
	[589] = {id=589,name='Firestorm',weather=5},
	[590] = {id=590,name='Hailstorm',weather=13},
	[591] = {id=591,name='Windstorm',weather=11},
	[592] = {id=592,name='Sandstorm',weather=9},
	[593] = {id=593,name='Thunderstorm',weather=15},
	[594] = {id=594,name='Rainstorm',weather=7},
	[595] = {id=595,name='Aurorastorm',weather=17},
	[596] = {id=596,name='Voidstorm',weather=19}
}

local elements = {
	['Light'] = {spell=nil,helix='Luminohelix',ga=nil,ja=nil,ra=nil,jutsu=nil,white='Banish',holy="Holy"},
	['Dark'] = {spell=nil,helix='Noctohelix',ga=nil,ja=nil,ra=nil,jutsu=nil,white=nil,holy=nil},
	['Thunder'] = {spell='Thunder',helix='Ionohelix',ga='Thundaga',ja='Thundaja',ra='Thundara',jutsu='Raiton',white=nil,holy=nil},
	['Ice'] = {spell='Blizzard',helix='Cryohelix',ga='Blizzaga',ja='Blizzaja',ra='Blizzara',jutsu='Hyoton',white=nil,holy=nil},
	['Fire'] = {spell='Fire',helix='Pyrohelix',ga='Firaga',ja='Firaja',ra='Fira',jutsu='Katon',white=nil,holy=nil},
	['Wind'] = {spell='Aero',helix='Anemohelix',ga='Aeroga',ja='Aeroja',ra='Aerora',jutsu='Huton',white=nil,holy=nil},
	['Water'] = {spell='Water',helix='Hydrohelix',ga='Waterga',ja='Waterja',ra='Watera',jutsu='Suiton',white=nil,holy=nil},
	['Earth'] = {spell='Stone',helix='Geohelix',ga='Stonega',ja='Stoneja',ra='Stonera',jutsu='Doton',white=nil,holy=nil},
}

local cast_types = {'spell', 'helix', 'ga', 'ja', 'ra', 'jutsu', 'white', 'holy'}
local spell_users = {'BLM', 'RDM', 'DRK', 'GEO'}
local jutsu_users = {'NIN'}
local helix_users = {'SCH'}

local active = false
local frequency = 1/settings.frequency
local last_skillchain = nil

local player = nil

local finish_act = L{2,3,5}
local start_act = L{7,8,9,12}
local is_busy = 0
local is_casting = false

local ability_delay = 1.5
local after_cast_delay = 2
local faild_cast_delay = 2

function message(text, to_log) 
	if (text == nil or #text < 1) then
		return
	end

	if (to_log) then
		log(text)
	else
		windower.add_to_chat(17, _addon.name..": "..text)
	end
end

function debug_message(text, to_log) 
	if (settings.debug == false or text == nil or #text < 1) then
		return
	end

	if (to_log) then
		log("(debug): "..text)
	else
		windower.add_to_chat(17, _addon.name.."(debug): "..text)
	end
end

function show_help()
	message('Usage:\nautoMB on|off - turn auto magic bursting on or off\nautoMB show on|off - display messages about skillchains|magic bursts')
	show_status()
end

function show_status()
	message('Auto Bursts: \t\t'..(active and 'On' or 'Off'))
	message('Magic Burst Type: \t'..settings.cast_type)
	message('Magic Burst Tier: \t'..(settings.cast_tier))
	message('Min MP: \t\t'..settings.mp)
	message('Cast Delay: '..settings.cast_delay..' seconds')
	message('Double Burst: '..(settings.double_burst and ('On'..' delay '..settings.double_burst_delay..' seconds') or 'Off'))
	message('Check Day Element: '..(settings.check_day and 'On' or 'Off'))
	message('Check Weather Element: '..(settings.check_weather and 'On' or 'Off'))
	message('Show Skillchain: \t\t'..(settings.show_skillchain and 'On' or 'Off'))
	message('Show Skillchain Elements: \t'..(settings.show_elements and 'On' or 'Off'))
	message('Show Day|Weather Elements: \t'..(settings.show_bonus_elements and 'On' or 'Off'))
	message('Show Spell: \t'..(settings.show_spell and 'On' or 'Off'))
end

function buff_active(id)
    if T(windower.ffxi.get_player().buffs):contains(BuffID) == true then
        return true
    end
    return false
end

function disabled()
    if (buff_active(0)) then -- KO
        return true
    elseif (buff_active(2)) then -- Sleep
        return true
    elseif (buff_active(6)) then -- Silence
        return true
    elseif (buff_active(7)) then -- Petrification
        return true
    elseif (buff_active(10)) then -- Stun
        return true
    elseif (buff_active(14)) then -- Charm
        return true
    elseif (buff_active(28)) then -- Terrorize
        return true
    elseif (buff_active(29)) then -- Mute
        return true
    elseif (buff_active(193)) then -- Lullaby
        return true
    elseif (buff_active(262)) then -- Omerta
        return true
    end
    return false
end

function low_mp(spell)
	local mp_cost = res.spells:with('name', spell).mp_cost
    if (mp_cost == nil or (player.vitals.mp - mp_cost <= settings.mp)) then
        return true
    end

	return false
end

function check_recast(spell_name)
    local recasts = windower.ffxi.get_spell_recasts()
	local spell = res.spells:with('name', spell_name)
	if (spell == nil) then
		return 0
	end

	local recast = recasts[spell.id]

    return recast
end

function get_bonus_elements()
	-- Use best possible bonus element, default to day
	local day_element = res.elements[res.days[windower.ffxi.get_info().day].element].en
	local weather_id = windower.ffxi.get_info().weather
	local player = windower.ffxi.get_player()

	-- Is a storm active, it wins
	if (#player.buffs > 0) then
		for i=1,#player.buffs do
			local buff = player.buffs[i]

			for _, storm in pairs(storms) do
				if (storm.id == buff) then
					weather_id = storm.weather
				end
			end
		end
	end
	weather_element = res.elements[res.weather[weather_id].element].en

	return weather_element, day_element
end

function clear_skillchain()
	last_skillchain = {}
	last_skillchain.english = 'None'
	last_skillchain.elements = {}
end

function cast_spell(spell_cmd, target) 
	if (settings.show_spell) then
		message("Casting - "..spell_cmd..' for the burst!')
	end
	windower.send_command('input /ma "'..spell_cmd..'" <t>')
end

function get_spell(skillchain, last_spell, second_burst, target_change)
	local spell_element = ''
	local weather_element, day_element = get_bonus_elements()
	local spell = ''
	local step_down = 0


	debug_message('Getting Spell ...',true)
	debug_message('Day Element: '..day_element,true)
	debug_message('Weather Element: '..weather_element,true)

	if (not second_burst or last_spell == nil) then
		last_spell = ''
	end

	if (second_burst) then
		if (settings.step_down == 2 or (settings.step_down == 1 and target_change ~= nil and target_change > 0)) then
			step_down = 1
		end
	end

	if (settings.check_weather and T(skillchain.elements):contains(weather_element)) then
		spell_element = weather_element
	elseif (settings.check_day and T(skillchain.elements):contains(day_element)) then
		spell_element = day_element
	else
		for i=1,#spell_priorities do
			if (T(skillchain.elements):contains(spell_priorities[i].element)) then
				spell_element = spell_priorities[i].element
				break
			end 
		end
	end

	debug_message('Best Spell Element: '..spell_element,true)

	local tier = settings.cast_tier - step_down
	-- Find spell/helix/jutsu that will be best based on best element
	if (elements[spell_element] ~= nil and elements[spell_element][settings.cast_type] ~= nil) then
		spell = elements[spell_element][settings.cast_type]

		tier = (tier >= 1 and tier or 1)
		spell = spell..(settings.cast_type == 'jutsu' and ':' or '')..(tier > 1 and ' ' or '')
		spell = spell..(settings.cast_type == 'jutsu' and jutsu_tiers[tier].suffix or magic_tiers[tier].suffix)

		local recast = check_recast(spell)
		if (recast > 0) then
			spell = ''
		end
	end

	debug_message('Spell: '..spell,true)

	if (spell == nil or spell == '') then
		for _,element in pairs(skillchain.elements) do
			if (elements[element] ~= nil and elements[element][settings.cast_type] ~= nil) then
				spell = elements[element][settings.cast_type]

				tier = (tier >= 1 and tier or 1)
				spell = spell..(settings.cast_type == 'jutsu' and ':' or '')..(tier > 1 and ' ' or '')
				spell = spell..(settings.cast_type == 'jutsu' and jutsu_tiers[tier].suffix or magic_tiers[tier].suffix)
			
				local recast = check_recast(spell)
				if (recast == 0) then
					break
				end
			end
		end
	end

	debug_message('Spell: '..(spell == nil and 'None Found' or spell),true)

	-- Display some skillchain/magic burst info, can show up whether auto bursts are on or not
	local element_list = ''
	local sc_info = _addon.name..': '

	for i=1,#skillchain.elements do
		element_list = element_list..skillchain.elements[i]..(i<#skillchain.elements and ', ' or '')
	end
	
	if (settings.show_skillchain) then sc_info = sc_info..'Skillchain effect '..skillchain.english..' ' end
	if (settings.show_elements) then sc_info = sc_info..'['..element_list..'] ' end
	if (settings.show_bonus_elements) then sc_info = sc_info..'Weather: '.. weather_element..' Day: '..day_element..' ' end
	if (settings.show_skillchain or settings.show_elements or settings.show_bonus_elements) then windower.add_to_chat(17, sc_info) end

	return spell
end -- get_spell()

function set_target(target)
	local cur_target = nil
	if (player.target_index) then
		cur_target = windower.ffxi.get_mob_by_index(player.target_index)
	end

	if (target == nil or not target.valid_target or not target.is_npc or target.hpp == nil or target.hpp <= 0) then
		return 0
	end

	if (cur_target ~= nil and cur_target.id == target.id) then
		return 0
	end

	packets.inject(packets.new('incoming', 0x058, {
		['Player'] = player.id,
		['Target'] = target.id,
		['Player Index'] = player.index,
	}))

	return 1
end

function do_burst(target, skillchain, second_burst, last_spell) 
	windower.send_command('gs c bursting')

	player = windower.ffxi.get_player()
	if (target == nil or not target.valid_target or target.hpp <= 0) then
		message("Bad Target!")
		return
	end

	local target_delay = set_target(target)

	local spell = get_spell(skillchain, last_spell, second_burst, target_delay >= 1)

	if (spell == nil or spell == '') then
		message("No spell found for burst!")
		windower.send_command('gs c notbursting')
		return
	elseif (disabled()) then
		message("Unable to cast, disabled!")
		windower.send_command('gs c notbursting')
		return
	elseif (low_mp(spell)) then
		message("Not enough MP for MB!")
		windower.send_command('gs c notbursting')
		return
	elseif (is_casting) then
		debug_message("Casting, delaying for 0.5")
		coroutine.schedule(do_burst:prepare(target, skillchain, second_burst, last_spell), 0.5)
		return
	elseif (is_busy > 0) then
		debug_message("Busy for "..is_busy.." seconds, delaying MB")
		coroutine.schedule(do_burst:prepare(target, skillchain, second_burst, last_spell), is_busy)
		return
	end
	
	local cast_delay = math.random(0, settings.cast_delay) + 0.1
	coroutine.schedule(cast_spell:prepare(spell, target), target_delay + cast_delay)

	if (settings.double_burst and not second_burst) then
		debug_message("Setting up double burst")
		local cast_time = res.spells:with('name', spell).cast_time
		local d = cast_time + settings.double_burst_delay + target_delay + 2
		coroutine.schedule(do_burst:prepare(target, skillchain, true, spell), d)
	else
		local cast_time = res.spells:with('name', spell).cast_time
		local d = cast_time + target_delay + ability_delay
		coroutine.schedule(finish_burst, d)
	end
end

function finish_burst()
	clear_skillchain()
	windower.send_command('gs c notbursting')
end

--[[ Windower Events ]]--
-- Check for skillchain effects applied, this can get wonky if/when a group is skillchaining on multiple mobs at once
windower.register_event('incoming chunk', function(id, packet, data, modified, is_injected, is_blocked)
	if (id ~= 0x28 or not active) then
		return
	end
	
	local actions_packet = windower.packets.parse_action(packet)
	local mob_array = windower.ffxi.get_mob_array()
	local valid = false
	local party = windower.ffxi.get_party()
	local party_ids = T{}

	player = windower.ffxi.get_player()

	if (data:unpack('I', 6) == player.id) then 
		local category, param = data:unpack( 'b4b16', 11, 3)
		local recast, targ_id = data:unpack('b32b32', 15, 7)
		local effect, message = data:unpack('b17b10', 27, 6)
		if category == 6 then                       -- Use Job Ability
			is_busy = ability_delay
		elseif category == 4 then                   -- Finish Casting
			is_busy = after_cast_delay
			is_casting = false
		elseif finish_act:contains(category) then   -- Finish Range/WS/Item Use
			is_busy = 0
			is_casting = false
		elseif start_act:contains(category) then
			if param == 24931 then                  -- Begin Casting/WS/Item/Range
				is_busy = 0
				is_casting = true
			elseif param == 28787 then              -- Failed Casting/WS/Item/Range
				is_casting = false
				is_busy = faild_cast_delay
			end
		end
	end

	for _, member in pairs (party) do
		if (type(member) == 'table' and member.mob) then
			party_ids:append(member.mob.id)
		end
	end

	for _, target in pairs(actions_packet.targets) do
		local t = windower.ffxi.get_mob_by_id(target.id)

		if (party_ids:contains(t.claim_id)) then
			if (t and (t.is_npc and t.valid_target and not t.in_party and not t.charmed) and t.distance:sqrt() < 22) then
				for _, action in pairs(target.actions) do
					if (action.add_effect_message > 287 and action.add_effect_message < 302) then
						last_skillchain = skillchains[action.add_effect_message]
						coroutine.schedule(do_burst:prepare(t, last_skillchain, false, '', 0), settings.cast_delay)
					end
				end
			end
		end
	end
end)

-- Change spell type based on job/sub
windower.register_event('job change', function(main_id, main_lvl, sub_id, sub_lvl)
	local main = res.jobs[main_id].english_short
	local sub = res.jobs[sub_id].english_short

	-- Set settings.cast_type to 'none' to stop casting if job/sub doesn't support casting
	settings.cast_type = 'none'

	if (T(spell_users):contains(main)) then
		settings.cast_type = 'spell'
	elseif (T(jutsu_users):contains(main)) then
		settings.cast_type = 'jutsu'
	elseif (T(helix_users):contains(main)) then
		settings.cast_type = 'helix'
	elseif (T(spell_users):contains(sub)) then
		settings.cast_type = 'spell'
	elseif (T(jutsu_users):contains(sub)) then
		settings.cast_type = 'jutsu'
	elseif (T(helix_users):contains(sub)) then
		settings.cast_type = 'helix'
	end
	message('> Cast type set to: '..settings.cast_type)
end)

-- Stop checking if logout happens
windower.register_event('logout', function(...)
	windower.send_command('autoMB off')
	player = nil
	return
end)

-- Process incoming commands
windower.register_event('addon command', function(...)
	local cmd = 'help'
	if (#arg > 0) then
		cmd = arg[1]
	end

	if (cmd == 'test') then
		local test_skillchain = {}
		local test_spell = nil

		test_skillchain.english = 'Test Chain'
		test_skillchain.elements = {'Earth','Light','Fire', 'Ice'}
		test_spell = get_spell(test_skillchain, nil, false, true)
		message('Test Spell: '..test_spell ~= nil and test_spell or 'Not Found')
		return
	elseif (cmd == 'help') then
		show_help()
		return
	elseif (cmd == 'status' or cmd == 'show') then
		show_status()
		return
	elseif (cmd == 'on') then
		windower.add_to_chat(17, 'AutoMB activating')
		player = windower.ffxi.get_player()
		active = true
		last_check_time = os.clock()
        return
    elseif (cmd == 'off') then
        windower.add_to_chat(17, 'AutoMB deactivating')
        active = false
		return
	elseif (cmd == 'cast' or cmd == 'c') then
		if (#arg < 2) then
			windower.add_to_chat(17, "Usage: autoMB cast spell|helix|jutsu\nTells AutoMB what magic type to try to cast if the default is not what you want.")
			return
		end
		if (T(cast_types):contains(arg[2]:lower())) then
			settings.cast_type = arg[2]:lower()
			return
		end
		settings:save()
		return
	elseif (cmd == 'tier' or cmd == 't') then
		if (#arg < 2) then
			windower.add_to_chat(17, "Usage: tier 1~6\nTells autoMB what tier spell to use for Ninjutsu 1~3 will become ichi|ni|san.")
			return
		end
		local t = tonumber(arg[2])
		if (settings.cast_type == 'jutsu') then
			if (settings.cast_tier > 0 and settings.cast_tier < 4) then
				settings.cast_tier = t
			end
		else
			if (t > 0 and t < 7) then
				settings.cast_tier = t
			end		
		end
		settings:save()
		message("Cast Tier set to: "..t.." ["..(settings.cast_type == 'jutsu' and jutsu_tiers[settings.cast_tier].suffix or magic_tiers[settings.cast_tier].suffix).."]")
		return
	elseif (cmd == 'mp') then
		local n = tonumber(arg[2])
		if (n == nil or n < 0) then
			windower.add_to_chat(17, "Usage: autoMB mp #")
			return
		end
		settings.mp = n
		settings:save()
		return
	elseif (cmd == 'delay' or cmd == 'd') then
		local n = tonumber(arg[2])
		if (n == nil or n < 0) then
			windower.add_to_chat(17, "Usage: autoMB delay #")
			return
		end
		settings.cast_delay = n
		settings:save()
		return
	elseif (cmd == 'frequency' or cmd == 'f') then
		local n = tonumber(arg[2])
		if (n == nil or n < 0) then
			windower.add_to_chat(17, "Usage: autoMB (f)requency #")
			return
		end
		settings.frequency = n
		settings:save()
		return
	elseif (cmd == 'doubleburst' or cmd == 'double' or cmd == 'dbl') then
		settings.double_burst = not settings.double_burst
		settings:save()
		return
	elseif (cmd == 'doubleburstdelay' or cmd == 'doubledelay' or cmd == 'dbldelay' or cmd == 'dbld') then
		local n = tonumber(arg[2])
		if (n == nil or n < 0) then
			windower.add_to_chat(17, "Usage: autoMB doubleburstdelay #")
			return
		end
		settings.double_burst_delay = n
		settings:save()
		return
	elseif (cmd == 'weather') then
		settings.check_weather = not settings.check_weather
		message('Will'..settings.check_weather and ' ' or ' not '..'use current weather bonuses')
	elseif (cmd == 'day') then
		settings.check_day = not settings.check_day
		message('Will'..settings.check_day and ' ' or ' not '..'use current day bonuses')
	elseif (cmd == 'toggle' or cmd == 'tog') then
		local what = 'all'
		local toggle = 'toggle'

		if (#arg > 1) then
			what = arg[2]:lower()
		end

		if (#arg > 2) then
			toggle = arg[3]:lower()
		end

		-- Show/Hide skillchain name/elements and spell(s) to be cast
		if (what == 'skillchain' or what == 'sc' or what == 'all') then
			if (toggle == '' or toggle == 'toggle') then
				settings.show_skillchain = not settings.show_skillchain
			else
				settings.show_skillchain = (toggle == 'on')
			end
			windower.add_to_chat(17, 'AutoMB: Skillchain info will be '..(settings.show_skillchain == true and 'shown' or 'hidden'))
        end
		
		if (what == 'elements' or what == 'element' or what == 'all') then
			if (toggle == 'toggle') then
				settings.show_elements = not settings.show_elements
			else
				settings.show_elements = (toggle == 'on')
			end
			windower.add_to_chat(17, 'AutoMB: Skillchain element info will be '..(settings.show_elements == true and 'shown' or 'hidden'))
        end

		if (what == 'weather' or what == 'bonus' or what == 'all') then
			if (toggle == 'toggle') then
				settings.show_bonus_elements = not settings.show_bonus_elements
			else
				settings.show_bonus_elements = (toggle == 'on')
			end
			windower.add_to_chat(17, 'AutoMB: Day/Weather element info will be '..(settings.show_bonus_elements == true and 'shown' or 'hidden'))
        end

		if (what == 'spell' or what == 'sp' or what == 'all') then
			if (toggle == 'toggle') then
				settings.show_spell = not settings.show_spell
			else
				settings.show_spell = (toggle == 'on')
			end
			windower.add_to_chat(17, 'AutoMB: Spell info will be '..(settings.show_spell == true and 'shown' or 'hidden'))
		end

		settings:save()
		return
	elseif (cmd == 'stepdown' or cmd == 'sd') then
		local txt = ''
		if (settings.step_down == 0) then
			settings.step_down = 1
			txt = 'on target change'
		elseif (settings.step_down == 1) then
			settings.step_down = 2
			txt = 'always'
		else
			settings.step_down = 0
			txt = 'never'
		end
		settings:save()
		message("Double burst Step Down set to "..txt)
		return
	elseif (cmd == 'gearswap' or cmd == 'gs') then
		if (settings.gearswap) then
			settings.gearswap = false
		else
			settings.gearswap = true
		end
		message("Will "..(settings.gearswap and '' or ' not ').."use 'gs c bursting' and 'gs c notbursting'")
		settings:save()
		return
	elseif (cmd == 'debug') then
		settings.debug = not settings.debug
		message("Will "..(settings.debug and '' or ' not ').."show debug information")

		settings:save()
		return
    end
	show_help()
end) -- Addon Command