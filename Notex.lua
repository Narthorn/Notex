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
	self.config = {}
	self.config.enabled = false
	self.config.opacity = 1
	self.config.wndLoc = nil
	self.config.lock = false
	
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
	Apollo.RegisterEventHandler("Group_Left", "OnGroup_Left", self)
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
		
		if self.config.enabled == true then
			self.wndMain:Invoke()
			if self.config.wndLoc then
				self.wndMain:MoveToLocation(WindowLocation.new(self.config.wndLoc))
			end
			if self.config.opacity then
				self.wndMain:SetOpacity(self.config.opacity)
			end
			
			if self.config.lock then
				self.wndMain:FindChild("EditBox"):AddStyleEx("ReadOnly")
				self.wndMain:RemoveStyle("Sizable")
				self.wndMain:RemoveStyle("Moveable")
			end
			self.wndMain:FindChild("EditBox"):SetText("Write stuff here")		
		end
		
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

function Notex:OnGroup_Left()
	self.wndMain:FindChild("EditBox"):SetText("Write stuff here")
end

-----------------------------------------------------------------------------------------------
-- Notex Functions
-----------------------------------------------------------------------------------------------

-- on SlashCommand "/notex"
function Notex:OnNotexOn(cmd, param)
	if param == "" then
		Print('show : show the window')
		Print('hide : close the window')
		Print('opacity / op $num : change opacity with $number (between 0 and 1)')
		Print('lock : disable changes')
		Print('unlock : enable changes')
	elseif param == "lock" then
		self.config.lock = true
		self.wndMain:FindChild("EditBox"):AddStyleEx("ReadOnly")
		self.wndMain:RemoveStyle("Sizable")
		self.wndMain:RemoveStyle("Moveable")
	elseif param == "unlock" then
		self.config.lock = false
		self.wndMain:FindChild("EditBox"):RemoveStyleEx("ReadOnly")
		self.wndMain:AddStyle("Sizable")
		self.wndMain:AddStyle("Moveable")
	elseif param == "show" then
		self.wndMain:Invoke()
		self.config.enabled = true
	elseif param == "hide" then
		self.wndMain:Close()
		self.config.enabled = false
	else
		local list = {}
		for arg in param:gmatch("[^%s]+") do
			table.insert(list, arg)
		end	
		if list[1] == "opacity" or list[1] == "op" then
			if tonumber(list[2]) < 0 or tonumber(list[2]) > 1 then
				Print('Opacity number should be > 0 and < 1')
			else
				self.config.opacity = tonumber(list[2])
				self.wndMain:SetOpacity(tonumber(list[2]))
			end
		end
	end
end

function Notex:OnSave(eType)	
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end
	
	self.config.wndLoc = self.wndMain:GetLocation():ToTable() 
	
	return self.config
end

function Notex:OnRestore(eLevel, tSavedData)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end
	
	self.config.enabled = tSavedData.enabled
	self.config.opacity = tSavedData.opacity
	self.config.wndLoc = tSavedData.wndLoc
	self.config.lock = tSavedData.lock
	
end


-----------------------------------------------------------------------------------------------
-- Notex Instance
-----------------------------------------------------------------------------------------------
local NotexInst = Notex:new()
NotexInst:Init()
