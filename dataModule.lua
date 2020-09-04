core = LibStub("AceAddon-3.0"):GetAddon("DungeonManager") 
dataModule = core:NewModule("dataModule", "AceEvent-3.0", "AceHook-3.0")

local _G = _G
local UnitHealth, UnitAura, UnitDebuff, UnitBuff, UnitHealthMax = UnitHealth, UnitAura , UnitDebuff, UnitBuff, UnitHealthMax
local GetSpecializationInfo , GetSpecialization = GetSpecializationInfo, GetSpecialization
local GetMastery, GetTalentInfo, GetSpellBonusHealing = GetMastery, GetTalentInfo, GetSpellBonusHealing
local IsItemInRange, IsEquippedItem = IsItemInRange, IsEquippedItem
local GetCVar, GetCombatRatingBonus, GetVersatilityBonus = GetCVar, GetCombatRatingBonus , GetVersatilityBonus
local GetTime, UnitAttackPower, GetSpellBonusDamage = GetTime, UnitAttackPower, GetSpellBonusDamage
local GetSpellCharges, GetLifesteal, UnitClass,GetSpellInfo,GetAvoidance = GetSpellCharges, GetLifesteal, UnitClass,GetSpellInfo,GetAvoidance
local UnitArmor = UnitArmor

--special variables for event functions, to use for calculations
local damage_taken_5sec = {}
local advisor_Melandrus_Images_Stacks = 0
local advisor_Melandrus_trigger = 0


local ARMOR_CONSTANTS = {
	0, 157, 167, 177, 187,
	197, 207, 217, 227, 237, 
	247, 257, 267, 277, 287, 
	297, 307, 317, 327, 337, 
	347, 357, 367, 377, 387, 
	397, 407, 417, 427, 437, 
	447, 457, 467, 477, 487, 
	497, 507, 517, 527, 537, 
	547, 557, 567, 577, 587, 
	597, 607, 617, 627, 637, 
	647, 657, 667, 677, 687, 
	697, 707, 717, 727, 737, 
	747, 757, 767, 777, 787, 
	797, 807, 817, 827, 837, 
	847, 857, 867, 877, 887, 
	897, 907, 917, 927, 937, 
	947, 957, 967, 977, 987, 
	997, 1007, 1017, 1027, 1037, 
	1047, 1185, 1342, 1518, 1718, 
	1945, 2201, 2491, 2819, 3190, 
	3610, 5435, 5613, 5799, 5994, 
	6199, 6415, 6642, 6880, 7132, 
	7390, 7648, 7906, 8164
}

local ARMOR_CONSTANTS_BFA = {
0, 115, 121, 126, 132,	
 137, 143, 148, 154, 159, 
 164, 170, 175, 181, 186,
  192, 197, 203, 208, 214,
   219, 229, 238, 247, 256,
	266, 275, 284, 293, 303,
	 312, 321, 330, 340, 349,
	  358, 367, 377, 386, 395,
	   404, 414, 423, 432, 441,
		451, 459, 468, 477, 486,
		 495, 504, 514, 523, 533,
		  543, 553, 564, 574, 585,
		   596, 607, 619, 630, 642,
			654, 667, 679, 692, 705,
			 718, 732, 745, 759, 774,
			  788, 803, 818, 834, 849,
			   865, 882, 898, 915, 932,
				950, 968, 986, 1004, 1023,
				 1043, 1062, 1082, 1102, 1123,
				  1142, 1164, 1186, 1198, 1205,
				   1206, 1203, 1207, 1212, 1235,
					1258, 1285, 1309, 1333, 1359,
					 1384, 1717, 1883, 2049, 2210,
					  2359, 2522, 3824, 4741, 5163,
					   6300, 6300, 6300, 6300
}

local TYRANNICAL_HP_BONUS = 1.4 
local TYRANNICAL_DAMAGE_BONUS = 1.15

local AFFIX_DMG_MULTIPLIERS = {
	["Bolstering"] = 1.2,
	
}

local MYTHIC_PLUS_DAMAGE_MULTIPLIERS = {
	[1] = 1,
	[2] = 1.1,
	[3]= 1.21,
	[4] = 1.34,
	[5] = 1.47,
	[6] = 1.62,
	[7] = 1.78,
	[8] = 1.95,
	[9] = 2.15,
	[10] = 2.36,
	[11] = 2.6,
	[12] = 2.86,
	[13] = 3.14,
	[14] = 3.46,
	[15] = 3.8,
	[16] = 4.18,
	[17] = 4.6,
	[18] = 5.06,
	[19] = 5.56,
	[20] = 6.12,
	[21] = 6.73,
	[22] = 7.41,
	[23] = 8.15,
	[24] = 8.96,
	[25] = 9.85,
}
--spellid of the cast that is going to initiate the damage, not the
--aura is applied that is actually going to cause the damage
--pretty sure the values listed here are average values
--will need to calculate the min and max values
--MinDamage,MaxDamage,SpellSchool,DamageType,avoidance,Dodgeable,Blockable,ignoresArmor
SPELLS_TO_CHECK = {
	["Black Rook Hold"] = {
		--The Amalgam of Souls
		["The Amalgam of Souls"] = {
			[196587] =function()
				local SoulgorgeStacks = select(4, UnitBuff("The Amalgam of Souls", GetSpellInfo(196930))) or 0

				local MinDamage = 1579500 * (1+(SoulgorgeStacks * 0.5))
				local MaxDamage = 1579500 * (1+(SoulgorgeStacks * 0.5))
				return {MinDamage,MaxDamage,"Magical","AoE",1,0,0,0} --Soul Burst BRH
			end
		},
		--Illysanna Ravencrest
		["Illysanna Ravencrest"] = {
			[197418] = function()
				--add something here to track for active midigation (100% increased dmg without)
				return {3022110,3022110,"Physical","Single",0,0,0,0} --vengeful shear
			end,
			[197478] = function()
				return {376445,412445,"Physical","Single",0,0,0,0}--Dark Rush
			end
		},
		--Smashspite the Hateful
		["Smashspite the Hateful"] = {
			[198250] = function()
				local hatefulChargeStacks = select(4, UnitBuff("player", GetSpellInfo(198080))) or 0

				local MinDamage = 1793610 * (1+(hatefulChargeStacks * 3))
				local MaxDamage = 1793610 * (1+(hatefulChargeStacks * 3))

				return {MinDamage,MaxDamage,"Physical","Single",0,0,0,0}--Hateful Charge
			end,
			[198245] = function()
				--75% damage taken increase debuff
				return {3320460,3320460,"Physical","Single",0,0,0,0}--Brutal Haymaker
			end,
			[198073] = function()
				return {804051,878001,"Physical","AoE",1,0,0,0}--Earthshaking Stomp
			end
		},
		--Lord Kur'talos Ravencrest
		["Lord Kur'talos Ravencrest"] = {
			[198635] = function() 
				return {2138011,2138011,"Physical","Single",0,0,0,0}--Unerring Shear
			end
		},
		["Dantalionax"] = {
			[202019] = function()
				--needs avoidance test
				return {1797118,1965118,"Magical","AoE",1,0,0,0}--Shadow bolt volley BRH
			end
		},
	},
	["Cathedral of Eternal Night"] = {
		--Agronox
		["Agronox"] = {
			[235751] = function()
				return {2340000,2460000,"Physical","Single",0,0,0,0}--Timber Smash
			end
		},
		--Thrashbite the Scornful
		["Thrashbite the Scornful"] = {
			[237276] = function()
				return {489300,513975,"Physical","AoE",0,0,0,0}--Pulverizing Cudgel
			end
		},
		--Domotrax
		["Domatrax"] = {
			[236551] = function() 
				--needs avoidance test
				local aegis = UnitBuff("player",GetSpellInfo(238410))

				local MinDamage = 3927406 
				local MaxDamage = 4249026 

				if aegis then
					MinDamage = MinDamage * 0.1
					MaxDamage = MaxDamage * 0.1
				end
				return {MinDamage,MaxDamage,"Magical","AoE",0,0,0,0} --Chaotic Energy
			end
		},
		--Mephistroth
		["Mephistroth"] = {
			[233155] = function()
				return {1171100,1298500,"Magical","Single",0,0,0,0}--Carrion Swarm
			end,
			--needs avoidance test
			[243152] = function()
				return {186676,201283,"Magical","AoE",1,0,0,0}--Demonic Upheaval
			end
		},
	},
	["Court of Stars"] = {
		--Patrol Captain Gerdo
		--Talixae Flamewreath
		--Advisor Melandrus
		["Advisor Melandrus"] = {
			[209742] = function()
				-- damage caps out at 8 clones
				local MinDamage = 51446*4 * (1 + advisor_Melandrus_Images_Stacks)
				local MaxDamage = 54566*4 * (1 + advisor_Melandrus_Images_Stacks)
				return {MinDamage,MaxDamage,"Physical","AoE",1,0,0,0}--Slicing Maelstrom
			end
		},
		--mobs
		["Suspicious Noble"] = {
			[214692] = function()
				--needs avoidance test
				local shadowBoltStacks = select(4, UnitBuff("player", GetSpellInfo(214692))) or 0
				local MinDamage = 722356 * (1 + (shadowBoltStacks * 0.15 ))
				local MaxDamage = 787756 * (1 + (shadowBoltStacks * 0.15 ))
				return {MinDamage,MaxDamage,"Magical","AoE",1,0,0,0}--Shadow bolt volley CoS
			end
		},
	},
	["Darkheart Thicket"] = {
		--Archdruid Gladalis
		[198379] = {1695328,1800328},--Primal Rampage
		[198269] = {637589*2,676089*2},--Grievous Leap
		--Oakheart
		[204666] = {744469,788569},--Shattered Earth
		--Dresaron
		[199389] = {607228,643228},--Earthshaking roar
		--Shade of Xavius
		[200185] = {1024040,1086290},--Nightmare Bolt
		[200238] = {460512*5,460512*5},--Feed on the Weak
		[200050] = {1289923,1366923},--Apocalyptic Nightmare


	},
	["Eye of Azshara"] = {
		--Warlord Parjesh
		[191900] = {1546153,1641153},--Crashing Wave
		--Lady Hatecoil
		[193611] = {1128463,1195463},--Focused Lightning
		--King Deepbeard
		[193152] = {553152,553152},--Quake (may have a damage range, no sources specify)
		[193171] = {779218,801218},--Aftershock
		--Serpentrix
		--Wrath of Azshara

	},
	["Halls of Valor"] = {
		--Hymdall
		["Hymdall"] = {
			[193092] = {1772548,1782548,"Physical","AoE",0,0,0,0},--Bloodletting sweep
			[191284] = {874285,927947,"Physical","AoE",1,0,0,1},--Horn of Valor
		},


		--Hyrja
		[192018] = {2476303,2552803},--Shield of Light
		[191976] = {577543,595373},--Arcing Bolt
		[192044] = {672676,698230},--Expel Light
		--Fenryr
		--God-King Skovald
		[193660] = {1323180,1362280},--Felblaze Rush
		[193668] = {2299048,2339048 },--Savage Blade

		--Odyn
	},
	["Maw of Souls"] = {
		--Ymiron, the Fallen King
		[193211] = {2334148,2404148},--Dark Slash
		[193460] = {612949,612949},--Bane (may have a damage range, no sources specify)
		[193977] = {498699,512779},--Winds of northrend

		--Harbaron

		--Helya
		[185539] = {570000,630000},--Rapid Rupture

		--mobs 
		[201397] = {476000,525000},--Brackwater blast


	},
	["Neltharion's Lair"] = {
		--Rokmora
		[188114] = {572128,606128},--Shatter
		--Ularogg Cragshaper
		[198496] = {1365388,1448388},--Sunder
		--Naraxas
		--Dargrul the Underking
		[200732] = {1214458,1286458},--Molten Crash

	},
	["Return to Karazhan"] = {
		--Opera Hall: Wikket
		--Opera Hall: Westfall Story
		--Opera Hall: Beautiful Beast
		--Maiden of Virtue
		--Attumen the Huntsman
		[228852] = {6238186,6996428},--Shared Suffering

		--Moroes
		--The Curator
		--Shade of Medivh
		--Mana Devourer
		--Viz'aduum the Watcher
	},
	["Seat of the Triumvirate"] = {
		--Zuraal the Ascended
		--Saprish
		--Viceroy Nezhar
		--L'ura
		[245164] = {800000,800000},--Fragment of despair

	},
	["The Arcway"] = {
		--Ivanyr
		[196562] = {959211,989451},--volatile magic

		--Corstilax
		--General Xakal
		[197810] = {1526848,1569848},--Wicked Slam

		--Nal'tira
		[200284] = {407247,407247},--Tangled Web

		--Advisor Vandros

		--mobs
		[211771] = {764125,785125},--Prophecies of Doom

	},
	["Valut of the Wardens"] = {}
	


}


local DEFENSIVE_ARTIFACT_TRAITS = {
	["Death Knight"] = {
		["Blood"] = {
			208793,--5% vamp blood healing per rank
			238042,--5% death strike healing
			238114,--death strike / consumption overheal(50%) increases max hp, up to 30% max hp
	 },
		["Unholy"] = {
			191565,--Increases the effectiveness of Anti-Magic Shell and Icebound Fortitude by 8%
			191584,---Reduces all damage you take from area-of-effect attacks by 5%
		},
		["Frost"] ={
			189154,--death strike heals for 100% more while icebound fortitude is active
		}
	},
	["Druid"] = {
		["Balance"] = {
			202302,--Moonkin Form increases your armor by an additional 25%.
		},
		["Restoration"] = {
			189754,--Ironbark reduces all damage taken by the target by an additional 2%.
		},
		["Feral"] = {
			210650,--When you shapeshift out of Cat Form, you gain 100% increased dodge chance and armor for 5 sec or until you shapeshift back into Cat Form.
			238084,--Tiger's Fury grants 600 Versatility to you and 4 allies for 10 sec.
		},
		["Guardian"] = {
			200400,--Increases healing done by Frenzied Regeneration by 5%
			200415,--Survival Instincts reduces all damage you take by an additional 3.33**%
			200395,--Ironfur increases armor by an additional 4%
			238049,--Moonfire reduces damage dealt to you by 1%
		}
	},
	["Hunter"] = {
		["Marksman"] = {
			190503,--Aspect of the Turtle heals you for 12% of your maximum health over its duration.
			190514,--Activating Disengage reduces all damage you take by 3.3333 for 4 sec.
		},
		["Beast Mastery"] = {
			197160,--Aspect of the Turtle also heals you for 10% of your maximum health over its duration.
		},
		["Survival"] = {}
	},
	["Mage"] = {
		["Frost"] = {
			195354,--Increases damage absorbed by Ice Barrier by 20%.
			214626,--When Ice Lance deals damage, you take 2% less damage for 6 sec.
		},
		["Arcane"] = {
			210716,--Increases damage absorbed by Prismatic Barrier by 20%.
		},
		["Fire"] = {
			194315,--Blazing Barrier reduces all Physical damage you take by 5%.
		}
	},
	["Monk"] = {
		["Brewmaster"] = {
			227684,--reduce the target's damage done to you by 1%.
			238129,--Drinking Purifying Brew grants Ironskin Brew for 1 sec.
		},
		["Windwalker"] = {
			195295,--Damage redirected by Touch of Karma also heals you.
			195380,--(starts at 10%)Activating Transcendence: Transfer heals you for 5% of your maximum health over 6 sec.
		},
		["Mistweaver"] = {
			199365,--Reduces all damage you take by 3.333% while you are channeling Soothing Mist.
			199367,--Increases damage absorbed by Life Cocoon by 5%.
		}
	},
	["Paladin"] = {
		["Holy"] = {
			200302,--After Judgment strikes an enemy, all damage you take for the next 4 sec is reduced by 3%.
			200298,--Reduces the cooldown of Blessing of Freedom, Blessing of Protection, and Blessing of Sacrifice by 5%.
			200327,--Reduces the damage you take from Blessing of Sacrifice by 10%.
		},
		["Protection"] = {
			211913,--Increases your armor by 10% when under 40% health.
			213571,--Shield of the Righteous reduces damage you take by an additional 1%.
			209223,--Increases healing done by Light of the Protector by 6%.
		},
		["Retribution"] = {
			186944,--Reduces the cooldown of Blessing of Protection by 10%.
			184778,--Reduces the cooldown of Shield of Vengeance by 10 sec.
			186934,--Increases healing done by Flash of Light by 15%.

		}
	},
	["Demon Hunter"] = {
		["Vengeance"] = {
			212821,--Soul Cleave heals for an additional 3%
			212816,--Increases maximum health gained from Metamorphosis by an additional 5%.
		},
		["Havoc"] = {
			201459,--reduces magic damage taken by 4%
			207387,--Each Soul Fragment you consume reduces all damage you take by 3% for 4 sec.
		}
	},
	["Shaman"] = {
		["Restoration"] = {
			207351,--Reduces all damage you take while Ghost Wolf is active by 3%, increasing by another 3% every 1 sec, stacking up to 6 times and lasting 6 sec once fully stacked.
			207357,--Reduces the cooldown of Reincarnation by 10 min. After using Reincarnation you take 80% less damage for 6 sec.
			207354,--Casting Healing Stream Totem reduces all damage you take by 10% for 10 sec.
		},
		["Elemental"] = {
			191569,--Increases healing done by Healing Surge by 15%.
		},
		["Enhancement"] = {
			198296,--Increases healing done by Healing Surge by 10%.
		}
	},
	["Priest"] = {
		["Discipline"] = {
			197729,--Increases damage absorbed by Power Word: Shield by 5%.
			197781,--Casting Power Word: Shield on a target other than yourself also shields you for 15% as much.
			197711,--Activating Fade reduces all damage you take by 3.3333% for 6 sec.
			197713,--Reduces the cooldown of Pain Suppression by 10 sec.
			238063,--Atonement reduces damage taken by 0.5%.
			238099,--Pain Suppression also heals the target for 33% of damage taken during Pain Suppression.
			238135,--Power Word: Shield absorbs 50% additional damage, but the absorb amount decays by 3% every 1 sec.
	
		},
		["Holy"] = {

		},
		["Shadow"] = {
			194024,--Dispersion heals you for 50% of maximum health over its duration.
			194018,--Healing from Vampiric Touch when you are at maximum health will shield you for the same amount. Shield cannot exceed (Total health * 4 / 100) damage absorbed.
		}
	},
	["Warrior"] = {
		["Protection"] = {
			188683,--Last Stand increases health by an additional 10%.
			189059,--Critical blocks have a chance to cause an eruption from Scale of the Earth-Warder, increasing your armor by 30% and dealing (225% of Attack power) Physical damage to all enemies in front of you.
			203225,--Increases the total damage ignored by Ignore Pain by 6%.
			203576,--Blocking an attack has a chance to increase the total damage ignored by your next Ignore Pain by 40%.
			238077,--Increases the damage prevented by blocking by 8%.
			238113,--Spell Reflection reduces magical damage you take by an additional 20%.
			238149,--Thunderclap now applies Neltharion's Thunder, reducing your damage taken from the target by 1%, stacking up to 5 times.
		},
		["Arms"] = {
			209559,--While Die by the Sword is active, damage taken is reduced by an additional 5%.
			209483,--When Heroic Leap lands, you gain 10% increased armor and chance to parry for 4 sec.
	
		},
		["Fury"] = {
			238148,--Odyn's Fury is empowered by either Odyn or Helya. Odyn empowers Odyn's Fury with (300% of Attack power) Fire damage and generates 20 Rage. Helya empowers Odyn's Fury with (300% of Attack power) Shadow damage which heals you for 100% of the damage it deals.

		}
	},
	["Warlock"] = {
		["Destruction"] = {
			196305,--After casting Life Tap, you take 3% less damage for 6 sec.
			215223,--Reduces the cooldown of Unending Resolve by 30 sec.
		},
		["Affliction"] = {
			199220,--Your Healthstone heals you for an additional 25% of your maximum health. Any party or raid member using a Healthstone also heals you for that amount.
			199212,--Increases the amount absorbed by Soul Leech by 1%.
		},
		["Demonology"] = {
			211108,--Increases the haste and health provided by Demonic Empowerment by 2%.
			211144,--Increases healing done by Soul Link by 10%.
			211131,--Reduces the cooldown of Unending Resolve by 10 sec.
			218567,--When your health drops below 35%, Soul Link increases to split 40% of all damage you take with your demon pet.
		}
	},
	["Rogue"] = {
		["Assassination"] = {
			238102,--Crimson Vial reduces the damage you take by 4%, increasing by 4% every 1 sec.
		},
		["Outlaw"] = {

		},
		["Subtlety"] = {
			197604,--When you enter Stealth or Shadow Dance, you gain an absorb shield for Attack power damage.
		}
	}
}


--** indicates this is also the spellid of the aura applied
--values stored as {Physical Reduction, Magical Reduction, Armor increase %}
DAMAGE_MITIGATIONS = {
--ALL spells need checking for artifact traits
	--DEATH KNIGHT
	["Death Knight"] = {
		--[[ICEBOUND FORTITUDE--]] [48792] = 
		function() 
			local name = select(2,GetSpecializationInfo(GetSpecialization()))
			if name == "Blood" then
				return {0.3,0.3,0}
			else 
				return {0.2,0.2,0} 
			end
		end,
		--if attack is greater than 25% hp, 0.32DR if charges are >= 2 ????
		--[[BONE SHIELD--]] [195181] = 
		function() 
			return {0.16,0.16,0} 
		end,
		--[[BLOOD MIRROR--]] [206977] = 
		function()
			local selected = select(4,GetTalentInfo(7,2,1))
			local name = select(2,GetSpecializationInfo(GetSpecialization()))
			if name == "Blood" and selected == true then
				return {0.2,0.2,0}
			else 
				return {0,0,0}
			end
		end,
	},
	["Druid"] = {
		--[[BARKSKIN--**]] [22812] =
		function(current) 
			if current == 1 then
				local name = AuraUtil.FindAuraByName("Barkskin", "player")
				if name then
					return {0.2,0.2,0}
				end
			else 
				return {0.2,0.2,0}
			end
			return {0,0,0}
		 end,
		-- --[[IRONBARK--]] [102342] =
		-- function(current) 
		-- 	local name = select(2,GetSpecializationInfo(GetSpecialization()))
		-- 	if current == 1 then
		-- 		local name, icon, count, debuffType, duration, expirationTime, source, isStealable, 
		-- 		nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod, ... = AuraUtil.FindAuraByName("Ironbark", "Player")
		-- 		if aura then
		-- 			return {value1,value1,0}
		-- 		end
		-- 	else
		-- 		if name == "Restoration" then
		-- 			local rank = GetPlayerArtifactRank(189754)
		-- 			local dmgReduc = 0.2 + (rank * 0.02)
		-- 			return {dmgReduc,dmgReduc,0}
		-- 		end
		-- 	end
		-- 	return {0,0,0}
		-- end,
		--[[SURVIVAL INSTINCTS--]] [61336] =
		function(current) 
			local name = select(2,GetSpecializationInfo(GetSpecialization()))
			if current == 1 then
				local aura = AuraUtil.FindAuraByName("Survival Instincts","player")
				if aura then
					if name == "Guardian" then
						--local rank = dataModule:GetPlayerArtifactRank(200415)
						local dmgReduc = 0.5 --+ (rank * 0.0333)
						return {dmgReduc,dmgReduc,0}
					elseif name == "Feral" then
						return {0.5,0.5,0}
					end
				end
			else
				if name == "Guardian" then
					--local rank = dataModule:GetPlayerArtifactRank(200415)
					local dmgReduc = 0.5 --+ (rank * 0.0333)
					return {dmgReduc,dmgReduc,0} 
				elseif name == "Feral" then
					return {0.5,0.5,0}
				end
			end
			return {0,0,0}
		end,
		--[[BEAR FORM--**]] [5487] = 
		function(current) 
			if current == 1 then
				local aura = AuraUtil.FindAuraByName("Bear Form", "Player")
				if aura then
					return {0,0,2} 
				end
			else
				return {0,0,2}
			end
			return {0,0,0}
		end,
		--[[INCARNATION: GUARDIAN OF URSOC--]] [102558] =
		function(current)
			local name = select(2,GetSpecializationInfo(GetSpecialization()))

			if current == 1 then
				if name == "Guardian" then
					local aura = UnitAura("player", "Incarnation: Guardian of Ursoc")
					if aura then
						return {0,0,0.15} 
					else
						return {0,0,0} 
					end
				else
					return {0,0,0}
				end
			else
				if name == "Guardian" then 
					return {0,0,0.15} 
				end
			end
			return {0,0,0} 
		end,
		--[[REND AND TEAR--]] [204053] =
		function(current) 
			local name = select(2,GetSpecializationInfo(GetSpecialization()))
			if current == 1 then
				if name == "Guardian" then
					local count = select(4,UnitDebuff("target","Thrash"))
					if count then
						return {count * 0.02,count * 0.02,0}
					else
						return {0,0,0}
					end
				else
					return {0,0,0}
				end
			else
				--THIS NEEDS A HARDCODED VALUE TO RETURN AN ESTIMATED VALUE
				if name == "Guardian" then
					local count = 3
					--thrash legendary 2 more stacks
					local equipt =IsEquippedItem(137067)
					if equipt then
						count = 5
					end
					return {count * 0.02,count * 0.02,0}
				end
			end
			return {0,0,0}
		end,
		--[[RAGE OF THE SLEEPER--]] [200851] =
		function(current)
			local name = select(2,GetSpecializationInfo(GetSpecialization()))
			if current == 1 then
				if name =="Guardian" then
					local equipt = IsEquippedItem("Claws of Ursoc")
					if equipt then
						return {0.25,0.25,0} 
					else
						return {0,0,0}
					end
				else
					return {0,0,0}
				end
			else
				if name =="Guardian" then
					local equipt = IsEquippedItem("Claws of Ursoc")
					if equipt then
						return {0.25,0.25,0} 
					else
						return {0,0,0}
					end
				end
			end
			return {0,0,0}
		end,
		--[[GUARDIAN AFFINITY--]] [197491] =
		function(current)
			local selected = select(4,GetTalentInfo(3,2,1))
			local name = select(2,GetSpecializationInfo(GetSpecialization()))

			if current == 1 then
				if selected == true then
					local equipt = IsEquippedItem(137015)
					if equipt then --ekowrath
						return {0.06 * 1.75 ,0.06 * 1.75, 0}
					else
						return {0.06,0.06,0}
					end
				end
			else 
				if selected == true then
					local equipt = IsEquippedItem(137015)
					if equipt then --ekowrath
						return {0.06 * 1.75 ,0.06 * 1.75, 0}
					else
						return {0.06,0.06,0}
					end
				end
			end
			return {0,0,0}
		end,
		--[[MOONKIN FORM--]] [24858] =
		function(current)
			local name = select(2,GetSpecializationInfo(GetSpecialization()))
			local aura
			if current == 1 then
				aura = AuraUtil.FindAuraByName("Moonkin Form","player")
				if aura then
					-- if name =="Balance"then
					-- 	local bladedFeathers = dataModule:GetPlayerArtifactRank(202302)
					-- 	return {0,0,2 + (0.25 * bladedFeathers)}
					-- end
					return {0,0,2} 
				else
					return {0,0,0} 
				end
			else
				if name =="Balance" then
					-- local bladedFeathers = dataModule:GetPlayerArtifactRank(202302)
					-- return {0,0,2 + (0.25 * bladedFeathers)}
					return {0,0,2}
				end
				return {0,0,2} 
			end
			return {0,0,0} 
		end,
	},
	["Hunter"] = {
		--[[ASPECT OF THE TURTLE--]] [186265] =function() return {0.3,0.3,0} end,
	},
	
	["Mage"] = {
		--[[ICE BLOCK--]] [45438] =function() return {1,1,0} end,
		--[[GREATER INVISIBILITY--]] [110959] =function() return {0.6,0.6,0} end,
		--[[Prismatic Barrier--]] [235450] =function() return {0.15,0.15,0.15} end,
	},
	["Monk"] = {
		--dampen harm assumed at max effectiveness for very large hits
		--[[Dampen Harm--]] [122278] =function() return {0.5,0.5,0} end,
		--[[DIFFUSE MAGIC--]] [122783] =function()return  {0,0.6,0} end,
		--[[FORTIFYING BREW BREWMASTER--]] [115203] =function() return {0.2,0.2,0} end,
		--[[FORTIFYING BREW MISTWEAVER--]] [243435] =function() return {0.2,0.2,0} end,
		--[[ZEN MEDITATION--]] [115176] =function() return {0.6,0.6,0} end,
	},
	["Paladin"] = {
		-- need to factor in the one shot protection
		--[[ARDENT DEFENDER--]] [31850] =function(current) return {0.2,0.2,0} end,
		-- need to factor in <20% hp buff drop off
		--[[BLESSING OF SACRIFICE--]] [6940] =function(current) return {0.3,0.3,0} end,
		--[[BLESSING OF PROTECITON--]] [1022] =function(current) return {1,0,0} end,
		--[[DIVINE SHIED--]] [642] =function(current) return {1,1,0} end,
		--[[EYE OF TYR--]] [209202] =function(current) return {0.25,0.25,0} end,
		--[[GUARDIAN OF ANCIENT KINGS--]] [86659] =function(current) return {0.5,0.5,0} end,
		--[[SHIELD OF THE RIGHTEOUS--]] [53600] =
		function(current) 
			local base = 0.3
			local masteryMulti = (GetMastery()/2) /100
			local cons = ((select(4, GetTalentInfo(1,3,1))) or UnitBuff("player", GetSpellInfo(188370))) and 1.2 or 1
			local dmgReduc = (base + masteryMulti) * cons
			return {dmgReduc,dmgReduc,0}
		end,
		--[[KNIGHT TEMPLAR--]] [204139] =function(current) return {0.2,0.2,0} end,
		--[[AEGIS OF LIGHT--]] [204150] =function(current) return {0.2,0.2,0} end,
		--[[LAST DEFENDER--]] [203791] =
		function(current) 
			local count = 0
			if GetCVar("nameplateShowEnemies") == "1" then
				for i=1,40,1 do
					local inRange = IsItemInRange(63427, "nameplate"..i)
					if inRange then
						count = count + 1
					end
				end
			end
			return {1 - math.pow(0.97,count),0,0}
		end,
		--aura applied by devotion aura is 210320
		--[[DIVINE PROTECTION--]] [498] =function(current) return {0.2,0.2,0} end,	
		--[[DEVOTION AURA--]] [183425] =
		function(current) 
			if UnitAura("player","Devotion Aura") then
			local reduction = math.abs(select(17,UnitAura("player","Devotion Aura"))) / 100
			return {reduction,reduction,0}
			else 
				return {0,0,0}
			end
		end,
		--[[Eye for an Eye--]] [205191] =function() return {0.35,0,0} end,
	},
	
	["Demon Hunter"] = {
		--aura applied for blur 212800
		--[[BLUR--]] [198589] = 
		function() 

			local selected = select(4,GetTalentInfo(4,2,1))

			if selected == true then
				return {0.5,0.5,0}
			else 
				return {0.35,0.35,0}
			end
		end,
		--[[NETHERWALK--]] [196555] =function() return {1,1,0} end,
		--[[DEMON SPIKES--]] [196555] = 
		function() 
			local base = 0.12
			local masteryMulti = (GetMastery() * 0.75) /100
			return {masteryMulti + base, 0,0}
		end,
		--[[METAMORPHOSIS--]] [187827] =function() return {0,0,1} end,
		--[[FIERY BRAND--]] [204021] =function() return {0.4,0.4,0} end,
	},
	["Shaman"] = {
		--[[ASTRAL SHIFT--]] [108271] =function() return {0.4,0.4,0} end,
	},
	["Priest"] = {
		--[[DISPERSION--]] [47585] =
		function(current) 
			local name = select(2,GetSpecializationInfo(GetSpecialization()))
			if current == 1 then
				if name == "Shadow" then
					return {0.6,0.6,0} 
				else 
					return {0,0,0}
				end
			else
				return {0.6,0.6,0} 
			end
		end,
		--[[SHADOWFORM--]] [232698] =function() return {0.1,0,0} end,
		--[[MASOCHISM--]] [193063] =function() return {0.1,0.1,0} end,
		--[[PAIN SUPPRESSION--]] [33206] =function() return {0.4,0.4,0} end,
		--[[POWER WORD: BARRIER--]] [62618] =function() return {0.25,0.25,0} end,
		--[[FOCUSED WILL--]] [45243] =
		function()
			local count = select(4,UnitBuff("player","Focused Will"))
			if count then
				return {count * 0.15,count * 0.15,0}
			else
				return {0,0,0}
			end
		end,
	},
	["Warrior"] = {
		--[[DIE BY THE SWORD--]] [118038] =function() return {0.3,0.3,0} end,
		--[[DEFENSIVE STANCE--]] [197690] =
		function() 
			local selected = select(4,GetTalentInfo(4,3,1))
			local name = select(2,GetSpecializationInfo(GetSpecialization()))
			if name == "Arms" and selected == true then
				return {0.2,0.2,0}
			else
				return {0,0,0}
			end
		end,
		--[[ENRAGED REGENERATION--]] [184364] =function() return {0.3,0.3,0} end,
		--[[DEMORALIZING SHOUT--]] [1160] =function() return {0.2,0.2,0} end,
		--[[SHIELD WALL--]] [871] =function() return {0.4,0.4,0} end,
		--[[SPELL REFELCTION--]] [23920] =function() return {0,0.4,0} end,
		--[[SAFEGUARD--]] [223657] =function() return {0.3,0.3,0} end,
	},
	["Warlock"] = {
		--[[UNENDING RESOLVE--]] [104773] = function() return {0.4,0.4,0} end,
	},
	["Rogue"] = {
		--[[FEINT--]] [1966] = 
		function() 
			local selected = select(4,GetTalentInfo(4,2,1))
			local name = select(2,GetSpecializationInfo(GetSpecialization()))

			if name == "Outlaw" and selected == true then

				--50% reduction for aoe and 30% for non-aoe when talented
				return {0.5,0.5,0} 
			else
				--reduction only counts for AoE effects
				return {0.5,0.5,0} 
			end
		end,
		--[[CLOAK OF SHADOWS--]] [31224] = function() return {0,1,0} end,
		--85% reduced damage afterwards, left on 7% max hp after triggers
		--[[CHEAT DEATH--]] [31230] = function() return {1,1,0} end,
	},
	["General"] = {
		--[[FURY OF ASHAMANE--]][238084] = 
		function(current)
			if current == 1 then
				--vers increase already calculated
				return {0,0,0}
			else
				local dr = (600/475)/2
				return {dr,dr,0}
			end
		end,
	},
}


local ABSORB_AMOUNTS = {
	["Monk"] = {
		--125174 - aura applied for touch of karma
		--[[Touch of Karma--]] [122470] =function() return UnitHealthMax("player") / 2 end,
		--[[LIFE COCOON--]] [116849] =function() return (((GetSpellBonusHealing() * 42 + 0)) *  (1 + ((GetCombatRatingBonus(29) + GetVersatilityBonus(30)) / 100))) end,
	},
	["Death Knight"] = {
		--[[ANTI MAGIC SHELL--]] [48707] =
		function() 
			local name = select(2,GetSpecializationInfo(GetSpecialization()))
			
			--Spell Eater / Volatile Shielding talent 
			local selected = select(4,GetTalentInfo(5,1,1))

			if name == "Unholy" and selected == true then
				return ((UnitHealthMax("player") * 30/100) * (1 + ((GetCombatRatingBonus(29) + GetVersatilityBonus(30)) / 100))) * 1.2
			elseif name == "Frost" and selected == true then
				return ((UnitHealthMax("player") * 30/100) * (1 + ((GetCombatRatingBonus(29) + GetVersatilityBonus(30)) / 100))) * 1.35
			else
				return (UnitHealthMax("player") * 30/100) * (1 + ((GetCombatRatingBonus(29) + GetVersatilityBonus(30)) / 100))
			end
		end,
		--[[BLOOD SHIELD--]] [77535] = 
		function()
			local absorb = select(17,UnitAura("player","Blood Shield"))
			if absorb then
				return absorb
			else
				-- work out the estimated amount of damage that will be shielded
				return 0
			end
		end,
		--[[UMBILICUS ETERNUS--]] [193213] = 
		function()
			--blood plague ticks every 3 seconds
			--work out an estimate amount of damage blood plague will do in the 10
			--second window of vampiric blood, based on how many targets are effected

			local count3 = 0
			local count6 = 0
			local count9 = 0
			if GetCVar("nameplateShowEnemies") == "1" then
				for i=1,40,1 do
					local bloodPlague,_,_,_,_,_,expirationTime = UnitDebuff("nameplate"..i,"Blood Plague")

					if bloodPlague then
						local duration = expirationTime - GetTime()
						if duration >= 9 then
							count9 = count9 + 1
						elseif duration >= 6 then
							count6 = count6 + 1
						elseif duration > 0 then
							count3 = count3 + 1
						end
					end
				end
			end
			overallCount = (count3*1) + (count6 *2) + (count9 *3)
			--0.544 modifer is a backcalculated value, may now be entirely accurate as no info source provides the value
			return 5 * ( overallCount * (((UnitAttackPower("player") * 0.544 + 0)) *  (1 + ((GetCombatRatingBonus(29) + GetVersatilityBonus(30)) / 100))))
			

		end,
		--[[CORPSE SHIELD--]] [207319] = 
		function() 
			local selected = select(4,GetTalentInfo(5,2,1))
			local name = select(2,GetSpecializationInfo(GetSpecialization()))
			if name == "Unholy" and selected == true then 
				return (0.9 * UnitHealth("pet")) 
			else
				return 0
			end
		end,
		--[[TOMBSTONE--]] [219809] = 
		function() 
			if UnitAura("player","Bone Shield") then
				local boneShieldStacks = select(4,UnitAura("player","Bone Shield"))
				if boneShieldStacks >= 5 then
					return (UnitHealthMax("player") * 0.3 ) * (1 + ((GetCombatRatingBonus(29) + GetVersatilityBonus(30)) / 100))
				else
					return (UnitHealthMax("player") * (0.06 * boneShieldStacks)) * (1 + ((GetCombatRatingBonus(29) + GetVersatilityBonus(30)) / 100))
				end
			else 
				return 0
			end
		end,
	},
	["Mage"] = {
		--[[Blazing Barrier--]] [235313] =function() return GetSpellBonusDamage(3) * 7  * (1 + ((GetCombatRatingBonus(29) + GetVersatilityBonus(30)) / 100)) end,
		--[[Prismatic Barrier--]] [235450] =function() return GetSpellBonusDamage(7) * 7  * (1 + ((GetCombatRatingBonus(29) + GetVersatilityBonus(30)) / 100)) end,
		--[[Ice Barrier--]] [11426] =function() return GetSpellBonusDamage(5) * 10 * (1 + ((GetCombatRatingBonus(29) + GetVersatilityBonus(30)) / 100)) end,
	},
	["Paladin"] = {
		--[[SHIELD OF VENGEANCE--]] [184662] =
		function(current) 
			local ap = select(1,UnitAttackPower("player"))
			local vers = (1 + ((GetCombatRatingBonus(29) + GetVersatilityBonus(30)) / 100))
			return (ap * 20 * vers )
		end
	},
	["Demon Hunter"] = {
		--[[METAMORPHOSIS--]] [187827] =function() return UnitHealthMax("player") * 0.3 end,
	},
	["Priest"] = {
		--[[POWER WORD SHIELD--]] [17] =function() return GetSpellBonusHealing() * 5.5 * (1 + ((GetCombatRatingBonus(29) + GetVersatilityBonus(30)) / 100)) end,
	},
	["Warrior"] = {
		--[[IGNORE PAIN--]] [190456] = 
		function()
			--never surrender increases ignore pains max damage
			--scales linear 75% hp,25% increase , 25% hp 75% increase
			local neverSurrender = select(4,GetTalentInfo(5,2,1))
			local indomitable = select(4,GetTalentInfo(5,3,1))
			local name = select(2,GetSpecializationInfo(GetSpecialization()))
			local ignoreAmount = 22.3 * UnitAttackPower("player") * (1 + ((GetCombatRatingBonus(29) + GetVersatilityBonus(30)) / 100))

			if name == "Protection" and neverSurrender == true then 
				local absorbIncrease = 1 + (1 - UnitHealth("player") / UnitHealthMax("player"))
				ignoreAmount = ignoreAmount * absorbIncrease
			elseif name == "Protection" and indomitable == true then
				ignoreAmount = ignoreAmount * 1.2
			end
			return ignoreAmount
		end,
	},
	["Warlock"] = {
		--[[SOUL LINK--]] [108415] = 
		function() 
			local demonSkin = select(4,GetTalentInfo(5,1,1))
			local name = select(2,GetSpecializationInfo(GetSpecialization()))
			if ((name == "Demonology" or name == "Affliction") and demonSkin == true) then
				return (UnitHealthMax("player") * 0.2)
			else
				return (UnitHealthMax("player") * 0.15)
			end
		end,
		--[[Dark Pact--]] [108416] = 
		function() 
			local darkPact = select(4,GetTalentInfo(5,3,1))
			local name = select(2,GetSpecializationInfo(GetSpecialization()))
			if ((name == "Demonology" or name == "Affliction") and darkPact == true) then
				if UnitHealth("pet") ~= 0 then
					return (UnitHealth("pet") * 0.2) * 4
				else 
					return (UnitHealth("player") * 0.2) * 4
				end
			else
				return 0
			end
		end,
	},
	["Rogue"] = {

	},
	["Shaman"] = {

	},
	["Hunter"] = {

	},
	["Druid"] = {

	},
	["General"] = {
		--[[PRYDAZ--]][207472] = 
		function(current) 
			if current == 1 then
				if IsEquippedItem(132444) then
					if UnitAura("player",207472)then
						return UnitHealthMax * 0.25
					end
				else
					return 0
				end
			else
				return UnitHealthMax * 0.25
			end
		end,
		--[[FEL SHIELD EMMITER--]][253277] = 
		function(current) 

		end,
	},
}

local HEAL_AMOUNTS = {
	["Monk"] = {
		--[[HEALING ELIXIR--]] [122281] =
		function() 
			local charges = GetSpellCharges("Healing Elixir")
			if charges == 2 then
				return UnitHealthMax("player") * 0.3
			elseif charges == 1 then
				return UnitHealthMax("player") * 0.15
			else
				return 0
			end
		end,
		--incorrect calculcation, cannot figure out exact calculation to match spellbook
		--[[REVIVAL--]] [115310] =function() return GetSpellBonusHealing() * 7.2 * (1 + ((GetCombatRatingBonus(29) + GetVersatilityBonus(30)) / 100)) end,
	},
	["Death Knight"] = {
		--[[VAMPIRIC BLOOD--]] [55233] =function() return 0.3 * UnitHealthMax("player") end,
		--[[ANTI MAGIC BARRIER--]] [48707] = 
		function() 
			local selected = select(4,GetTalentInfo(3,3,1))
			local name = select(2,GetSpecializationInfo(GetSpecialization()))
			if name == "Blood" and selected == true then
				return (UnitHealthMax("player") * 0.25)
			else
				return 0
			end
		end,
		--[[CONSUMPTION--]] [22842] = function() return UnitAttackPower() * 2.58 end,
	},
	["Druid"] = {
		--calculate amount that will be healed in its full duration
		--[[FRENZY REGENERATION--]] [22842] = 
		function(current) 
			local name = select(2,GetSpecializationInfo(GetSpecialization()))
			if current == 1 then
				if name == "Guardian" then
					--local ranks = dataModule:GetPlayerArtifactRank(200400)
					local damage = 0
					for k , v in pairs(damage_taken_5sec) do
						if v ~= nil then
							damage = damage + v
						end
					end
					heal = damage * 0.5 --+ (ranks * 0.05))
					if heal < UnitHealthMax("player") * 0.05 then
						heal = UnitHealthMax("player") * 0.05
					end
					return heal * (1 + ((GetCombatRatingBonus(29) + GetVersatilityBonus(30)) / 100))
				else
					local damage = 0
					for k , v in pairs(damage_taken_5sec) do
						if v ~= nil then
							damage = damage + v
						end
					end
					heal = damage * 0.5 
					if heal < UnitHealthMax("player") * 0.05 then
						heal = UnitHealthMax("player") * 0.05
					end
					return heal * (1 + ((GetCombatRatingBonus(29) + GetVersatilityBonus(30)) / 100))
				end
			else
				--unsure what to use as average expected heal value 
				return 0
			end
			return 0
		end,
		--[[RENEWAL--]] [108238] =function() return UnitHealthMax("player") * 0.3 end,
		--[[BEAR FORM]] [5487] = 
		function(current) 
			if current == 1 then
				if AuraUtil.FindAuraByName("Bear Form", "player") then
					return UnitHealth("player") * 1.55 
				else
					return 0
				end
			else
				return UnitHealth("player") * 1.55
			end
		end,
	},

	["Paladin"] = {
		--[[HAND OF THE PROTECTOR--]] [213652] =
		function(current)
			--get missing hp percentage
			local curHP = UnitHealth("player")
			local maxHP = UnitHealthMax("player")
			local misPerc = (maxHP - curHP) / maxHP
			--Versatility rating
			local vers = 1 + ((GetCombatRatingBonus(29) + GetVersatilityBonus(30)) / 100)
			--Leech
			local leech = 1 + GetLifesteal() / 100
			--check if standing in Consecration or Consecrated Hammer is skilled
			local cons = ((select(4, GetTalentInfo(1,3,1))) or UnitBuff("player", GetSpellInfo(188370))) and 1.2 or 1
			--check artifact traits
			--local currentRank = dataModule:GetPlayerArtifactRank(209223)
			--local trait = 1 + 0.06 * currentRank
			local perc = 0.3 * misPerc * cons * vers * leech --* trait
			local _prot_heal = perc * maxHP
			return _prot_heal
		end,
		--[[LAY ON HANDS--]] [633] =
		function(current) 
			local maxhp = UnitHealthMax("player") 
			return maxhp
		end,
	},
	["Mage"] = {
		--need to finish implementation, calculate somewhere that the player has to die to benefit from this
		--[[CAUTERIZE--]] [86949] = function() return 0 end,
	},
	["Warlock"] = {
		--[[LAST STAND--]] [12975] =function() return UnitHealthMax("player") * 0.3 end,
		--[[MORTAL COIL--]] [6789] =function() return UnitHealthMax("player") * 0.2 end,
	},
	["Shaman"] = {

	},
	["Hunter"] = {

	},
	["Rogue"] = {

	},
	["Priest"] = {

	},
	["Demon Hunter"] = {

	},
	["Warrior"] = {

	},
}

function dataModule:TestText()
	local txt = ""
	local cephp , cemhp , acephp , acemhp = dataModule:CalculateEffectiveHealth("player" , 121)
	ephp, emhp , aephp , aemhp = PalaadDungeonManager:CalculatePotentialEffectiveHealth("player",121)
	[[
	PDM_frame_texture.text:SetText(
		"CEPHP " .. cephp .. "\n" ..
		"CEMHP " .. cemhp .. "\n" ..
		"ACEPHP " .. acephp .. "\n" ..
		"ACEMHP " .. acemhp .. "\n"
	)
	]]
	
	local buff = ""
	
	for k , v in pairs(DAMAGE_MITIGATIONS[UnitClass("player")]) do
		
		local vals = v(1)
		local pr , mr , armor = vals[1],vals[2],vals[3]

		buff =  buff .. GetSpellInfo(k) .. " PR : " .. pr .. " MR : " .. " ARMOR : " .. armor .. "\n"
	end
	PDM_frame_texture.buffs:SetText(buff)
	
	local heals = ""
	for k , v in pairs(HEAL_AMOUNTS[UnitClass("player")]) do
		
		local vals = v(1)
		local name = GetSpellInfo(k)
		heals =  heals .. name .. " Heal " .. vals .. "\n"
	end
	PDM_frame_texture.heals:SetText(heals)
	
	
	local absorbs = ""
	for k , v in pairs(ABSORB_AMOUNTS[UnitClass("player")]) do
		
		local vals = v(1)
		local name = GetSpellInfo(k)

		absorbs =  absorbs .. name .. " absorbs " .. vals .. "\n"
	end
	PDM_frame_texture.absorbs:SetText(absorbs)
	
end

function dataModule:clearDamageTaken()
	for k , v in pairs(damage_taken_5sec) do
		if v ~= nil then
			print(GetTime() - k)
			if (GetTime() - k) > 5 then
				damage_taken_5sec[k] = nil
				print("value removed")
			end
		end
	end
end

function dataModule:CombatLog(event, ...)
	if(event == "COMBAT_LOG_EVENT_UNFILTERED") then
		
		local timestamp, subevent, hideCaster,                                                                      -- arg1  to arg3
      		sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,   -- arg4  to arg11
      		spellId, spellName, spellSchool,                                                                      -- arg12 to arg14
			  amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = ...             -- arg15 to arg23

		if subevent == "SWING_DAMAGE" or subevent == "SPELL_DAMAGE" then
			if destName == UnitName("player") then
				local damage = select(12,...)
				damage_taken_5sec[GetTime()] = damage
				print(damage)
			end

		end
		if subevent == "ENVIRONMENTAL_DAMAGE" then
			if destName == UnitName("player") then
				local damage = select(13,...)
				print(damage)
				damage_taken_5sec[GetTime()] = damage
			end
		end
	
		if SPELLS_TO_CHECK[spellId] ~= nil then
			dataModule:CalculateSpellSurvival(spellId)
		end

		if subevent == "SPELL_CAST_START" then
			for k , v in pairs(SPELLS_TO_CHECK) do
				if k == spellId then
				end
			end
		end

		if advisor_Melandrus_trigger == 1 then
			if sourceName == "Advisor Melandrus" then
				if subevent == "SPELL_CAST_SUCCESS" then
					if spellName == "Blade Surge" then
						advisor_Melandrus_Images_Stacks = advisor_Melandrus_Images_Stacks + 1
					end
				end
			end
		end

	end
end

function dataModule:EncounterStart(event , ...)
	if event == "ENCOUNTER_START" then
		encounterID , encounterName , difficultyID = ...
		if encounterID == 1870 then --Advisor Melandrus
			advisor_Melandrus_trigger = 1
		end
	end
end

function dataModule:EncounterEnd(event , ...)
	if event == "ENCOUNTER_END" then
		encounterID , encounterName , difficultyID = ...
		if encounterID == 1870 then --Advisor Melandrus
			advisor_Melandrus_Images_Stacks = 0
			advisor_Melandrus_trigger = 0
		end
	end
end

function dataModule:FormatNumber(num)
	number = num
    if math.abs(number) >= 1e9 then
        number = format("%.1fG", number / 1e9)
    elseif math.abs(number) >= 1e6 then
        number = format("%.1fM", number / 1e6)
    elseif math.abs(number) >= 1e3 then
        number = format("%.1fk", number / 1e3)
    else
        number = format("%d", number)
    end
    return number
end

function dataModule:CalculateSpellSurvival(spellid, enemyName, enemyLevel , zone)
	--MinDamage,MaxDamage,SpellSchool,DamageType,Avoidable,Dodgeable,Blockable
	local spellVars = SPELLS_TO_CHECK[zone][enemyName][spellid]

	
	local spellDamageMin = spellVars[1]
	local spellDamageMax = spellVars[2]
	local spellSchool = spellVars[3]
	local DamageType = spellVars[4]
	local Avoidable = spellVars[5]
	local Dodgeable = spellVars[6]
	local Blockable = spellVars[7]
	local ignoresArmor = spellVars[8]


	local level, affixes = C_ChallengeMode.GetActiveKeystoneInfo() -- get level and affixes of the current key
	local DmgPct, HealthPct = C_ChallengeMode.GetPowerLevelDamageHealthMod(level)  -- get damage and health 

	--[[
		1 : Overflowing
		2 : Skittish
		3 : Volcanic
		4 : Necrotic
		5 : Teeming
		6 : Raging
		7 : Bolstering
		8 : Sanguine
		9 : Tyrannical
		10 : Fortified
		11 : Bursting
		12 : Grievous
		13 : Explosive
		14 : Quaking
		15 : Relentless
	]]
	local affixInfo1 = C_ChallengeMode.GetAffixInfo(affixes[1])
	local affixInfo2 = C_ChallengeMode.GetAffixInfo(affixes[2])
	local affixInfo3 = C_ChallengeMode.GetAffixInfo(affixes[3])

	if affixInfo3 == "Tyrannical" then
		spellDamageMax = spellDamageMax * 1.15
		spellDamageMin = spellDamageMin * 1.15
	end

	if affixInfo3 == "Fortified" then
		spellDamageMax = spellDamageMax * 1.3
		spellDamageMin = spellDamageMin * 1.3
	end

	spellDamageMax = spellDamageMax * (1+(DmgPct/100))
	spellDamageMin = spellDamageMin * (1+(DmgPct/100))

	local EPHP , EMHP , AEPHP , AEMHP = dataModule:CalculateEffectiveHealth("player",enemyLevel,spellVars)

	local predictedHP = 0

	if spellSchool == "Physical" then
		if Avoidable == 1 then
			predictedHP = AEPHP - spellDamageMax

		else
			predictedHP = EPHP - spellDamageMax
		end
	else
		if Avoidable == 1 then
			predictedHP = AEMHP - spellDamageMax

		else
			predictedHP = EMHP - spellDamageMax
		end
	end


	if predictedHP > 0 then
		return {true,spellDamageMax,predictedHP}
	end
	return {false,spellDamageMax,predictedHP}
end

function dataModule:CalculateEffectiveHealth(unitId , enemyLevel , spellvars)
	local ignoresArmor = spellvars[8]

	--local enemyLevel = 110
	local vers = 1 +  GetCombatRatingBonus(31) / 100
	local avoidance = 1 +  (GetAvoidance() / 100)

	local baseArmor ,effectiveArmor, currentArmor  = UnitArmor("player")	 	
	--magical effective health
	local EMHP = UnitHealth("player")
	--physical effective health
	local EPHP = UnitHealth("player")

	local PRDR = 1
	local MRDR = 1

	for k , v in pairs(DAMAGE_MITIGATIONS[UnitClass("player")]) do
		local vals = v(1)
		local pr , mr , _ = vals[1],vals[2],vals[3]

		PRDR = PRDR * (1 + pr)
		PRDR = MRDR * (1 + mr)
	end

	if ignoresArmor == 0 then
		local armorDR = (currentArmor / (currentArmor + ARMOR_CONSTANTS[enemyLevel]))
		if armorDR > 0.85 then
			armorDR = 0.85
		end
		PRDR = PRDR * (armorDR) 
	end
	PDM_frame_texture.absorbs:SetText(PRDR)

	EPHP = EPHP * PRDR * vers
	EMHP = EMHP * vers

	--store the values avoidance would increase effectiveness too
	local AEPHP = EPHP * avoidance
	local AEMHP = EMHP * avoidance
	return EPHP , EMHP , AEPHP , AEMHP
end

function dataModule:CalculatePotentialEffectiveHealth(unitId, enemyLevel, spellDamage)
	--local enemyLevel = 110
	local vers = 1 +  GetCombatRatingBonus(31) / 100
	local avoidance = 1 +  (GetAvoidance() / 100)

	local baseArmor ,effectiveArmor, currentArmor  = UnitArmor("player")
 	local armorBuffs = 1

	--magical effective health
	local EMHP = UnitHealth("player")
	--physical effective health
	local EPHP = UnitHealth("player")

	for k , v in pairs(DAMAGE_MITIGATIONS[UnitClass("player")]) do
		local vals = v(0)
		local pr , mr , armor = vals[1],vals[2],vals[3]
		EPHP = EPHP * (1 + pr)
		EMHP = EMHP * (1 + mr)

		armorBuffs = armorBuffs * armor
	end

	local armorDR = 1 + ((currentArmor * armorBuffs) / ((currentArmor * armorBuffs) + ARMOR_CONSTANTS[enemyLevel]))
	local armorCap = 1.85
	if armorDR > 1.85 then
		armorDR = 1.85
	end

	EPHP = EPHP * (armorDR) * vers
	EMHP = EMHP * vers

	--store the values avoidance would increase effectiveness too
	local AEPHP = EPHP * avoidance
	local AEMHP = EMHP * avoidance

	return EPHP , EMHP , AEPHP , AEMHP
end

-- function dataModule:GetPlayerArtifactRank(traitid)
-- 		local currentRank = 4 -- defaults rank is 4
-- 		if LAD then
-- 			if not LAD:GetActiveArtifactID() then
-- 				LAD:ForceUpdate()
-- 			end
-- 			--pos, traitid, spellid, name, icon, rank, max, bonus, gold, first, last
-- 			for _, _, spellid, name, _, rank in LAD:IterateTraits() do
-- 				if spellid == traitid then
-- 					currentRank = rank
-- 					break
-- 				end
-- 			end
-- 		end
-- 	return currentRank
-- end