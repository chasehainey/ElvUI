local E, L, V, P, G = unpack(select(2, ...)); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule('Skins')

local _G = _G
local ipairs = ipairs
local hooksecurefunc = hooksecurefunc

-- 9.0 SHADOWLANDS

local function ReskinTalents(self)
	for frame in self.talentPool:EnumerateActive() do
		if not frame.IsSkinned then
			frame.Border:SetAlpha(0)
			frame.Background:SetAlpha(0)

			frame:CreateBackdrop('Transparent')
			frame.backdrop:SetInside()
			frame.backdrop:SetBackdropBorderColor(0, 1, 0)

			frame.Highlight:SetColorTexture(1, 1, 1, .25)
			frame.Highlight:SetInside(frame.backdrop)
			S:HandleIcon(frame.Icon, true)
			frame.Icon:SetPoint('TOPLEFT', 7, -7)

			frame.IsSkinned = true
		end
	end
end

local function HideRenownLevelBorder(frame)
	if not frame.IsSkinned then
		frame.Divider:SetAlpha(0)
		frame.BackgroundTile:SetAlpha(0)
		frame.Background:CreateBackdrop()

		frame.IsSkinned = true
	end

	for button in frame.milestonesPool:EnumerateActive() do
		if not button.IsSkinned then
			button.LevelBorder:SetAlpha(0)

			button.IsSkinned = true
		end
	end
end

function S:Blizzard_CovenantSanctum()
	if not (E.private.skins.blizzard.enable and E.private.skins.blizzard.covenantSanctum) then return end

	local frame = _G.CovenantSanctumFrame

	frame:HookScript('OnShow', function()
		if not frame.backdrop then
			frame:CreateBackdrop('Transparent')
			frame.NineSlice:SetAlpha(0)

			frame.CloseButton.Border:SetAlpha(0)
			S:HandleCloseButton(frame.CloseButton)
			frame.CloseButton:ClearAllPoints()
			frame.CloseButton:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 2, 2)

			frame.LevelFrame.Background:SetAlpha(0)
			frame.LevelFrame.Level:FontTemplate()

			local UpgradesTab = frame.UpgradesTab
			UpgradesTab.Background:SetAlpha(0)
			UpgradesTab.Background:CreateBackdrop('Transparent')
			S:HandleButton(UpgradesTab.DepositButton)
			for _, frame in ipairs(UpgradesTab.Upgrades) do
				frame.RankBorder:SetAlpha(0)
			end

			local TalentList = frame.UpgradesTab.TalentsList
			TalentList.Divider:SetAlpha(0)
			TalentList.BackgroundTile:SetAlpha(0)
			TalentList:CreateBackdrop('Transparent')
			S:HandleButton(TalentList.UpgradeButton)

			hooksecurefunc(TalentList, 'Refresh', ReskinTalents)
			hooksecurefunc(frame.RenownTab, "Refresh", HideRenownLevelBorder)
		end
	end)

	S:HandleTab(_G.CovenantSanctumFrameTab1)
	S:HandleTab(_G.CovenantSanctumFrameTab2)
	_G.CovenantSanctumFrameTab1:ClearAllPoints()
	_G.CovenantSanctumFrameTab1:SetPoint('BOTTOMLEFT', frame, 23, -32) --default is: 23, 9
end

S:AddCallbackForAddon('Blizzard_CovenantSanctum')