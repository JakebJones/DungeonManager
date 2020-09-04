DungeonManager = LibStub("AceAddon-3.0"):NewAddon("DungeonManager", "AceConsole-3.0", "AceEvent-3.0","AceTimer-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
dataModule = nil
PDM_main_frame = CreateFrame("Frame", "MainFrame", UIParent)

PDM_frame_texture = PDM_main_frame:CreateTexture("testText","BACKGROUND")
PDM_frame_texture:SetAllPoints(PDM_main_frame)
PDM_frame_texture:SetWidth(PDM_main_frame:GetWidth())
PDM_frame_texture:SetHeight(PDM_main_frame:GetHeight())

PDM_frame_texture.text = PDM_main_frame:CreateFontString(nil,"ARTWORK")
PDM_frame_texture.text:SetPoint("CENTER",PDM_main_frame)
PDM_frame_texture.text:SetFont(LSM:Fetch("font","Arial Narrow"),16)
PDM_frame_texture.text:Show()

PDM_frame_texture.buffs = PDM_main_frame:CreateFontString(nil,"ARTWORK")
PDM_frame_texture.buffs:SetPoint("BOTTOMRIGHT",PDM_main_frame)
PDM_frame_texture.buffs:SetFont(LSM:Fetch("font","Arial Narrow"),16)
PDM_frame_texture.buffs:Show()

PDM_frame_texture.heals = PDM_main_frame:CreateFontString(nil,"ARTWORK")
PDM_frame_texture.heals:SetPoint("TOP",PDM_main_frame)
PDM_frame_texture.heals:SetFont(LSM:Fetch("font","Arial Narrow"),16)
PDM_frame_texture.heals:Show()

PDM_frame_texture.absorbs = PDM_main_frame:CreateFontString(nil,"ARTWORK")
PDM_frame_texture.absorbs:SetPoint("BOTTOMLEFT",PDM_main_frame)
PDM_frame_texture.absorbs:SetFont(LSM:Fetch("font","Arial Narrow"),16)
PDM_frame_texture.absorbs:Show()

local delay = 1;

function DungeonManager:RegisterEvents()
	DungeonManager:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED",function(self,event,...) dataModule:CombatLog(self,event,...) end)
	DungeonManager:RegisterEvent("ENCOUNTER_START",function(self,event,...) dataModule:EncounterStart(self,event,...)end)
	DungeonManager:RegisterEvent("ENCOUNTER_END",function(self,event,...) dataModule:EncounterEnd(self,event,...)end)

end

function DungeonManager:OnInitialize()
	--DungeonManager:RegisterEvents()
	PDM_main_frame:SetWidth(100)
	PDM_main_frame:SetHeight(500)
	PDM_main_frame:SetClampedToScreen(true)
	PDM_main_frame:SetPoint("BOTTOMLEFT", GetScreenWidth()/2,GetScreenHeight()/2)
	PDM_main_frame:Show()

end

function DungeonManager:OnEnable()
	dataModule = DungeonManager:GetModule("dataModule")
	DungeonManager:EnableModule("dataModule")
	DungeonManager:UnlockFrame()
	DungeonManager:Update()
end

--Frame functionality functions-----------------------------
function OnDragStop(self)
	PDM_main_frame:StopMovingOrSizing()
end

function DungeonManager:OnStartMoving()
	PDM_main_frame:ClearAllPoints()
	PDM_main_frame:StartMoving()
end

function DungeonManager:LockFrame()
	PDM_main_frame:SetMovable(false)
	PDM_main_frame:EnableMouse(false)
	PDM_main_frame:RegisterForDrag()
	PDM_main_frame:SetScript("OnDragStart",nil)
	PDM_main_frame:SetScript("OnDragStop",nil)
end

function DungeonManager:UnlockFrame()
	PDM_main_frame:SetMovable(true)
	PDM_main_frame:EnableMouse(true)
	PDM_main_frame:RegisterForDrag("LeftButton")
	PDM_main_frame:SetScript("OnDragStart", PDM_main_frame.StartMoving)
	PDM_main_frame:SetScript("OnDragStop", OnDragStop)
end

function DungeonManager:Update()
	PDM_main_frame:SetScript("OnUpdate",function(self,elapsed)
		delay = delay - elapsed
		if delay <= 0 then
			dataModule:TestText()
			delay = 1
		end
		dataModule:clearDamageTaken()
		DungeonManager:ScanNameplates()
	end)
end
-------------------------------------------------------------

function DungeonManager:OnDisable()
	print("DungeonManager disabled")
end

function DungeonManager:ScanNameplates()

	local zone = GetZoneText()
	local rtn = ""
	if SPELLS_TO_CHECK[zone] ~= nil then
		if GetCVar("nameplateShowEnemies") == "1" then
			PDM_frame_texture.text:SetText("")
			for i=1,40,1 do
				local name = UnitName("nameplate"..i)
				if name then
					local value = SPELLS_TO_CHECK[zone][name]
					if value ~= nil then		
						for k , v in pairs(value) do
							local survival = dataModule:CalculateSpellSurvival(k , name, UnitLevel("nameplate"..i) , zone)
							rtn = rtn .. GetSpellInfo(k) .. "\n" ..
							"Survival : " ..tostring(survival[1]) .."\n" 
							.. "Spell Damage : " .. dataModule:FormatNumber(survival[2]) .. " HP : " ..dataModule:FormatNumber(survival[3]) .. "\n"
						end
					end
				end

			end
			PDM_frame_texture.text:SetText(rtn)
		end
	end
end
