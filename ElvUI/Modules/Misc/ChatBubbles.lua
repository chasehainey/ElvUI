local E, L, V, P, G = unpack(select(2, ...)); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local M = E:GetModule('Misc')
local CH = E:GetModule('Chat')

local format, wipe, unpack, pairs = format, wipe, unpack, pairs
local strmatch, strlower, gmatch, gsub = strmatch, strlower, gmatch, gsub

local Ambiguate = Ambiguate
local CreateFrame = CreateFrame
local GetInstanceInfo = GetInstanceInfo
local RemoveExtraSpaces = RemoveExtraSpaces
local PRIEST_COLOR = RAID_CLASS_COLORS.PRIEST
local C_ChatBubbles_GetAllChatBubbles = C_ChatBubbles.GetAllChatBubbles

--Message caches
local messageToGUID = {}
local messageToSender = {}

function M:UpdateBubbleBorder()
	local backdrop = self.backdrop
	local str = backdrop and backdrop.String
	if not str then return end

	if E.private.general.chatBubbles == 'backdrop' then
		backdrop:SetBackdropBorderColor(str:GetTextColor())
	end

	local name = self.Name and self.Name:GetText()
	if name then self.Name:SetText() end

	local text = str:GetText()
	if not text then return end

	if E.private.general.chatBubbleName then
		M:AddChatBubbleName(self, messageToGUID[text], messageToSender[text])
	end

	if E.private.chat.enable and E.private.general.classColorMentionsSpeech then
		local isFirstWord, rebuiltString
		if text and strmatch(text, "%s-%S+%s*") then
			for word in gmatch(text, "%s-%S+%s*") do
				local tempWord = gsub(word, "^[%s%p]-([^%s%p]+)([%-]?[^%s%p]-)[%s%p]*$", "%1%2")
				local lowerCaseWord = strlower(tempWord)

				local classMatch = CH.ClassNames[lowerCaseWord]
				local wordMatch = classMatch and lowerCaseWord

				if wordMatch and not E.global.chat.classColorMentionExcludedNames[wordMatch] then
					local classColorTable = E:ClassColor(classMatch)
					if classColorTable then
						word = gsub(word, gsub(tempWord, "%-","%%-"), format("\124cff%.2x%.2x%.2x%s\124r", classColorTable.r*255, classColorTable.g*255, classColorTable.b*255, tempWord))
					end
				end

				if not isFirstWord then
					rebuiltString = word
					isFirstWord = true
				else
					rebuiltString = format("%s%s", rebuiltString, word)
				end
			end

			if rebuiltString then
				str:SetText(RemoveExtraSpaces(rebuiltString))
			end
		end
	end
end

function M:AddChatBubbleName(chatBubble, guid, name)
	if not name then return end

	local color = PRIEST_COLOR
	local data = guid and guid ~= "" and CH:GetPlayerInfoByGUID(guid)
	if data and data.classColor then
		color = data.classColor
	end

	chatBubble.Name:SetFormattedText("|c%s%s|r", color.colorStr, name)
	chatBubble.Name:SetWidth(chatBubble:GetWidth()-10)
end

local yOffset --Value set in M:LoadChatBubbles()
function M:SkinBubble(frame, backdrop)
	local bubbleFont = E.Libs.LSM:Fetch("font", E.private.general.chatBubbleFont)
	if backdrop.String then
		backdrop.String:FontTemplate(bubbleFont, E.private.general.chatBubbleFontSize, E.private.general.chatBubbleFontOutline)
	end

	if E.private.general.chatBubbles == 'backdrop' then
		if not backdrop.template then
			backdrop:SetBackdrop()
			backdrop:SetTemplate('Transparent', nil, true)
		end
	elseif E.private.general.chatBubbles == 'backdrop_noborder' then
		if not backdrop.noBorder then
			backdrop:SetBackdrop()
			backdrop.noBorder = backdrop:CreateTexture(nil, 'ARTWORK')
		end

		backdrop.noBorder:SetInside(frame, 4, 4)
		backdrop.noBorder:SetColorTexture(unpack(E.media.backdropfadecolor))
	elseif E.private.general.chatBubbles == 'nobackdrop' then
		backdrop:SetBackdrop()
	end

	if not frame.Name then
		local name = frame:CreateFontString(nil, "BORDER")
		name:SetHeight(10) --Width set in M:AddChatBubbleName()
		name:SetPoint("BOTTOM", frame, "TOP", 0, yOffset)
		name:FontTemplate(bubbleFont, E.private.general.chatBubbleFontSize * 0.85, E.private.general.chatBubbleFontOutline)
		name:SetJustifyH("LEFT")
		frame.Name = name
	end

	if not frame.backdrop then
		frame.backdrop = backdrop
		backdrop.Tail:Hide()

		frame:HookScript('OnShow', M.UpdateBubbleBorder)
		frame:SetFrameStrata('DIALOG') --Doesn't work currently in Legion due to a bug on Blizzards end
		frame:SetClampedToScreen(false)

		M.UpdateBubbleBorder(frame)
	end

	frame.isSkinnedElvUI = true
end

local function ChatBubble_OnEvent(_, event, msg, sender, _, _, _, _, _, _, _, _, _, guid)
	if event == 'PLAYER_ENTERING_WORLD' then --Clear caches
		wipe(messageToGUID)
		wipe(messageToSender)
	elseif E.private.general.chatBubbleName then
		messageToGUID[msg] = guid
		messageToSender[msg] = Ambiguate(sender, "none")
	end
end

local function ChatBubble_OnUpdate(eventFrame, elapsed)
	eventFrame.lastupdate = (eventFrame.lastupdate or -2) + elapsed
	if eventFrame.lastupdate < 0.1 then return end
	eventFrame.lastupdate = 0

	for _, frame in pairs(C_ChatBubbles_GetAllChatBubbles()) do
		local backdrop = frame:GetChildren(1)
		if backdrop and not backdrop:IsForbidden() and not frame.isSkinnedElvUI then
			M:SkinBubble(frame, backdrop)
		end
	end
end

function M:ToggleChatBubbleScript()
	local _, instanceType = GetInstanceInfo()
	if instanceType == "none" and E.private.general.chatBubbles ~= "disabled" then
		M.BubbleFrame:SetScript('OnEvent', ChatBubble_OnEvent)
		M.BubbleFrame:SetScript('OnUpdate', ChatBubble_OnUpdate)
	else
		M.BubbleFrame:SetScript('OnEvent', nil)
		M.BubbleFrame:SetScript('OnUpdate', nil)
	end
end

function M:LoadChatBubbles()
	yOffset = (E.private.general.chatBubbles == "backdrop" and 2) or (E.private.general.chatBubbles == "backdrop_noborder" and -2) or 0
	self.BubbleFrame = CreateFrame("Frame")
	self.BubbleFrame:RegisterEvent("CHAT_MSG_SAY")
	self.BubbleFrame:RegisterEvent("CHAT_MSG_YELL")
	self.BubbleFrame:RegisterEvent("CHAT_MSG_MONSTER_SAY")
	self.BubbleFrame:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self.BubbleFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
end
