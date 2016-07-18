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
local PartyChatSharingKey = "}=>"

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Notex:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
	self.config = {}
	self.config.enabled = true
	self.config.opacity = 1
	self.config.wndLoc = nil
	self.config.lock = false
	self.config.size = 'CRB_HeaderSmall'
	self.lastmsgtime = 0
	self.shared = false
	self.joined = false
	
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
				self.wndMain:SetBGOpacity(self.config.opacity)
			end
			
			if self.config.lock then
				self.wndMain:FindChild("EditBox"):AddStyleEx("ReadOnly")
				self.wndMain:RemoveStyle("Sizable")
				self.wndMain:RemoveStyle("Moveable")
			end
			self.wndMain:FindChild("EditBox"):SetText("Write stuff here")	
			
			if self.config.size then
				self.wndMain:FindChild("EditBox"):SetFont(self.config.size)
			end					
		end
		
		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("notex", "OnNotexOn", self)
		Apollo.RegisterEventHandler("ChatMessage", "OnChatMessage", self)

		-- Do additional Addon initialization here
		self.ConnectTimer = ApolloTimer.Create(1, true, "Connect_Chatroom", self)
		self.ConnectTimer:Start()
	end
end

function Notex:Connect_Chatroom()
	if self.Room then
		self.joined = true 
	end
	if self.joined then 
		self.ConnectTimer:Stop()
		return
	else
		self.Room = ICCommLib.JoinChannel("notex")
		if self.Room then
			self.Room:SetReceivedMessageFunction("OnMessageReceived", self)
			if GameLib.GetPlayerUnit():IsInYourGroup() then
				self.RequestTimer = ApolloTimer.Create(1, true, "RequestMessage", self)
				self.RequestTimer:Start()
			end
		end
	end 
end

function Notex:RequestMessage() 
	if self.shared then 
		self.RequestTimer:Stop()
		return
	else
		local count = GroupLib.GetMemberCount()
		for i=1, count, 1 do	
			local groupMember = GroupLib.GetGroupMember(i)
			if groupMember.bIsLeader then
				self.Room:SendPrivateMessage(groupMember.strCharacterName, 'request')	
			end
		end
	end
end

function Notex:OnMessageReceived(channel, strMessage, strSender)
	local time =  os.time()
	if self.lastmsgtime > time then
		return	
	end
	
	self.wndMain:FindChild("EditBox"):SetText(strMessage)
	self.lastmsgtime = time
	self.shared = true
end 

function Notex:OnGroup_Left()
	self.wndMain:FindChild("EditBox"):SetText("Write stuff here")
end


function Notex:OnChatMessage(channelSource, tMessageInfo)
	if channelSource:GetType() ~= ChatSystemLib.ChatChannel_Party then
		return
	end
	
	local msg = {}
	for i, segment in ipairs(tMessageInfo.arMessageSegments) do
		table.insert(msg, segment.strText)
	end
	local strMsg = table.concat(msg, "")
	if strMsg:sub(0, PartyChatSharingKey:len()) ~= PartyChatSharingKey then
		return
	end
	
	local count = GroupLib.GetMemberCount()
	for i=1, count, 1 do	
		local groupMember = GroupLib.GetGroupMember(i)
		if tMessageInfo.strSender == groupMember.strCharacterName then
			if groupMember.bIsLeader or groupMember.bMainAssist or groupMember.bRaidAssistant then
				self.wndMain:FindChild("EditBox"):SetText(strMsg:sub(PartyChatSharingKey:len() + 1):gsub('~', '\n'))
				self.lastmsgtime = os.time()				
			end
		end
	end
end

-----------------------------------------------------------------------------------------------
-- Notex Functions
-----------------------------------------------------------------------------------------------

-- on SlashCommand "/notex"
function Notex:OnNotexOn(cmd, param)
	if param == "" then
		Print('show : show the window')
		Print('hide : close the window')
		Print('reset : reset the location')
		Print('opacity $num : change opacity with $number (between 0 and 1)')
		Print('size $num : change size of the text ({1, 2, 3, 4, 5, 6, 7})')
		Print('lock : disable changes')
		Print('unlock : enable changes')
	else
		local list = {}
		for arg in param:gmatch("[^%s]+") do
			table.insert(list, arg)
		end	
		if list[1] == "reset" then
			loc = {
				fPoints  = {0,0,0,0},
				nOffsets = {0,0,400,150}
			}
			self.wndMain:MoveToLocation(WindowLocation.new(loc))		
		elseif list[1] == "size" then
			if tonumber(list[2]) < 1 or tonumber(list[2]) > 7 then
				Print('size should be one of those : {1, 2, 3, 4, 5, 6, 7}')
			else 
				if tonumber(list[2]) == 1 then
					self.config.size = 'CRB_HeaderTiny'
				elseif tonumber(list[2]) == 2 then
					self.config.size = 'CRB_HeaderSmall'					
				elseif tonumber(list[2]) == 3 then
					self.config.size = 'CRB_HeaderMedium'
				elseif tonumber(list[2]) == 4 then
					self.config.size = 'CRB_HeaderLarge'
				elseif tonumber(list[2]) == 5 then
					self.config.size = 'CRB_HeaderHuge'
				elseif tonumber(list[2]) == 6 then
					self.config.size = 'CRB_HeaderHuger'
				elseif tonumber(list[2]) == 7 then
					self.config.size = 'CRB_HeaderGigantic'
				end
				self.wndMain:FindChild("EditBox"):SetFont(self.config.size)
			end
		elseif list[1] == "lock" then
			self.config.lock = true
			self.wndMain:FindChild("EditBox"):AddStyleEx("ReadOnly")
			self.wndMain:RemoveStyle("Sizable")
			self.wndMain:RemoveStyle("Moveable")
		elseif list[1] == "unlock" then
			self.config.lock = false
			self.wndMain:FindChild("EditBox"):RemoveStyleEx("ReadOnly")
			self.wndMain:AddStyle("Sizable")
			self.wndMain:AddStyle("Moveable")
		elseif list[1] == "show" then
			self.wndMain:Invoke()
			self.config.enabled = true
		elseif list[1] == "hide" then
			self.wndMain:Close()
			self.config.enabled = false
		elseif list[1] == "opacity" or list[1] == "op" then
				if tonumber(list[2]) < 0 or tonumber(list[2]) > 1 then
					Print('Opacity number should be > 0 and < 1')
				else
					self.config.opacity = tonumber(list[2])
					self.wndMain:SetBGOpacity(tonumber(list[2]))
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
	self.config.size = tSavedData.size
	
end


-----------------------------------------------------------------------------------------------
-- Notex Instance
-----------------------------------------------------------------------------------------------
local NotexInst = Notex:new()
NotexInst:Init()
