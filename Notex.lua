-----------------------------------------------------------------------------------------------
-- Client Lua Script for Notex
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "ICCommLib"
require "ICComm" 

-----------------------------------------------------------------------------------------------
-- Notex Module Definition
-----------------------------------------------------------------------------------------------
local Notex = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Notex:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function Notex:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- Notex OnLoad
-----------------------------------------------------------------------------------------------
function Notex:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("Notex.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- Notex OnDocLoaded
-----------------------------------------------------------------------------------------------
function Notex:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "NotexForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(false, true)

		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("notex", "OnNotexOn", self)


		-- Do additional Addon initialization here
		self.ConnectTimer = ApolloTimer.Create(1, false, "Connect_Chatroom", self)
		self.ConnectTimer:Start()
	end
end

function Notex:Connect_Chatroom()
	local joined = false
	
	if self.Room then
		joined = true 
	end
	if joined then 
		self.ConnectTimer:Stop()
		return
	else
		self.Room = ICCommLib.JoinChannel("notex")
		if self.Room then
			self.Room:SetReceivedMessageFunction("OnMessageReceived", self)
		end
	end 
end

function Notex:OnMessageReceived(channel, strMessage, strSender)
	self.wndMain:FindChild("EditBox"):SetText(strMessage)
end 

-----------------------------------------------------------------------------------------------
-- Notex Functions
-----------------------------------------------------------------------------------------------

-- on SlashCommand "/notex"
function Notex:OnNotexOn(cmd, param)
	if param == "" then
		Print('on : show the window')
		Print('off : close the window')
		Print('share : Share with retards in the group')
		Print('lock : disable changes')
		Print('unlock : enable changes')
	elseif param == "lock" then
		self.wndMain:FindChild("EditBox"):AddStyleEx("ReadOnly")
	elseif param == "unlock" then
		self.wndMain:FindChild("EditBox"):RemoveStyleEx("ReadOnly")
	elseif param == "on" then
		self.wndMain:Invoke()
		local isLead = false
		local playerUnit = GameLib.GetPlayerUnit()
		local count = GroupLib.GetMemberCount()
		for i=1, count, 1 do
			local groupMember = GroupLib.GetGroupMember(i)
			if playerUnit:GetName() == groupMember.strCharacterName then
				if groupMember.bIsLeader or groupMember.bRaidAssistant or groupMember.bMainAssist then
					isLead = true
				end
			end	
		end
		if isLead == false then
			self.wndMain:FindChild("EditBox"):AddStyleEx("ReadOnly")
		end
	elseif param == "off" then
		self.wndMain:Close()
	elseif param == "share" then
		local playerUnit = GameLib.GetPlayerUnit()
		local count = GroupLib.GetMemberCount()
		for i=1, count, 1 do
			local groupMember = GroupLib.GetGroupMember(i)
			if playerUnit:GetName() == groupMember.strCharacterName then
				if groupMember.bIsLeader or groupMember.bRaidAssistant or groupMember.bMainAssist then
					local txt = self.wndMain:FindChild("EditBox"):GetText()
					self.Room:SendMessage(txt)
				end
			end	
		end
	end 
end


-----------------------------------------------------------------------------------------------
-- Notex Instance
-----------------------------------------------------------------------------------------------
local NotexInst = Notex:new()
NotexInst:Init()
