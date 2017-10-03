--------------------------------------------------------------------------------
--Options
--------------------------------------------------------------------------------
local ChargeSortedBags = Apollo.GetAddon("ChargeSortedBags")

  local Designs = {
   [1] = "AbilitiesSprites:spr_StatVertProgBase",
   [2] = "CRB_Basekit:kitScrollbase_Horiz_HoloSmall",
   [3] = "CRB_DEMO_CreationSprites:sprDemo_CCFrameBG",
   [4] = "CRB_MegamapSprites:sprMap_WorldMap",
   [5] = "CRB_TooltipSprites:sprTT_BasicBack",
   [6] = "charactercreate:sprCharC_BG02",

  }
---------------------------------------------------------------------------------------------------
-- Options Functions
---------------------------------------------------------------------------------------------------

function ChargeSortedBags:LoadOptions()
	local mainOptWnd = self.wndOptions:FindChild("OptionsDialogueControls")
	local list = self.wndOptions:FindChild("ListControls")
	mainOptWnd:DestroyChildren()
	list:DestroyChildren()

	for i,j in pairs(self.db.profile.general.optionsList) do
		local newOpt = Apollo.LoadForm(self.xmlDoc, "OptionsListItem", list, self)
		newOpt:SetText(i)
	end
	list:ArrangeChildrenVert(0)
end

function ChargeSortedBags:OnOptionsListClick( wndHandler, wndControl, eMouseButton )
	local OptionsName = wndControl:GetText()

	local mainOptWnd = self.wndOptions:FindChild("OptionsDialogueControls")
	mainOptWnd:DestroyChildren()
	local CurOptWnd = Apollo.LoadForm(self.xmlDoc, OptionsName.."Option", mainOptWnd, self)
	self:SetOptions(CurOptWnd)
end

function ChargeSortedBags:SetOptions(CurOptWnd)
	local Name = CurOptWnd:GetName()
	local Opt = self.db.profile.general.optionsList
	if Name == "GeneralOption" then

		CurOptWnd:FindChild("AutoRepairGuild"):SetCheck(Opt.General.autoRepairGuild)
		CurOptWnd:FindChild("AutoRepair"):SetCheck(Opt.General.autoRepair)
		CurOptWnd:FindChild("SellJunk"):SetCheck(Opt.General.sellJunk)
		CurOptWnd:FindChild("Scale_IconSize"):FindChild("EditBox"):SetText(tostring(Opt.General.knSizeIconOption))
		local min, max , tick = 35,60,5
		local sliderIconSize = CurOptWnd:FindChild("Scale_IconSize"):FindChild("SliderBar")
		sliderIconSize:SetMinMax(min,max,tick)
		sliderIconSize:SetValue(Opt.General.knSizeIconOption)

  elseif Name == "DesignOption" then
    --Opacity
    CurOptWnd:FindChild("Scale_Opacity"):FindChild("EditBox"):SetText(tostring(Opt.Design.fOpacity))
    local min, max , tick = 0, 1, 0.01
    local slider = CurOptWnd:FindChild("Scale_Opacity"):FindChild("SliderBar")
    slider:SetMinMax(min,max,tick)
		slider:SetValue(Opt.Design.fOpacity)

    --Design
    CurOptWnd:FindChild("Scale_Design"):FindChild("EditBox"):SetText(tostring(Opt.Design.BG))
    local min, max , tick = 0, 6, 1
    local slider = CurOptWnd:FindChild("Scale_Design"):FindChild("SliderBar")
    slider:SetMinMax(min,max,tick)
		slider:SetValue(Opt.Design.BG)

    --Color
    CurOptWnd:FindChild("Swatch"):SetBGColor(self.db.profile.general.optionsList.Design.BGColor)

  elseif Name == "CurrenciesOption" then

		local Number_of_Currencies = 14
		local grid = CurOptWnd:FindChild("Window:CurrenciesGrid")
		--Character Currencies (8 is gold)
		for i = 2, Number_of_Currencies, 1 do
				local Currency = GameLib.GetPlayerCurrency(i)
				local info =  Currency:GetDenomInfo()[1]
				local newCurrency = Apollo.LoadForm(self.xmlDoc, "CurrencyOptionForm", grid, self)
				newCurrency:FindChild("Name"):SetText(info.strName)
				newCurrency:FindChild("CheckBox"):SetCheck(Opt.Currencies[info.strName])
		end
		--Account Currencies
		for i = 1, Number_of_Currencies, 1 do
			if i ~=10 and i ~= 4 then
				local ACurrency = AccountItemLib.GetAccountCurrency(i)
				local Ainfo =  ACurrency:GetDenomInfo()[1]
				local newCurrency = Apollo.LoadForm(self.xmlDoc, "CurrencyOptionForm", grid, self)
				newCurrency:FindChild("Name"):SetText(Ainfo.strName)
				newCurrency:FindChild("CheckBox"):SetCheck(Opt.Currencies[Ainfo.strName])
			end
		end
		grid:ArrangeChildrenTiles(0)
	end
end

function ChargeSortedBags:SaveOptions( wndHandler, wndControl, eMouseButton )
	local main = wndControl:GetParent():GetParent()
	local name = main:GetName()

	if name == "GeneralOption" then
		option = self.db.profile.general.optionsList.General
		option.sellJunk = main:FindChild("SellJunk"):IsChecked()
		option.autoRepairGuild = main:FindChild("AutoRepairGuild"):IsChecked()
		option.autoRepair = main:FindChild("AutoRepair"):IsChecked()
		option.knSizeIconOption = tonumber(main:FindChild("Scale_IconSize"):FindChild("EditBox"):GetText())
	elseif name == "CurrenciesGrid" then
		local Currency = wndControl:GetParent():FindChild("Name"):GetText()
		self.db.profile.general.optionsList.Currencies[Currency] = wndControl:IsChecked()

		self:LoadCurrencies()
	end
end

function ChargeSortedBags:OnIconSizeSlideChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local EditBox = wndControl:GetParent():FindChild("EditBox")
	local NewValue = math.ceil(fNewValue)
	EditBox:SetText(tostring(NewValue))
	self.db.profile.general.optionsList.General.knSizeIconOption = NewValue
	self:UpdateSize()
	self:ArrangeChildren()
  self:LoadBagWindow()
end

function ChargeSortedBags:OnOpacitySlideChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local EditBox = wndControl:GetParent():FindChild("EditBox")
	local NewValue = math.ceil(fNewValue*100)/100
	EditBox:SetText(tostring(NewValue))
	self.db.profile.general.optionsList.Design.fOpacity = NewValue
  self.wndMain:FindChild("BG"):SetOpacity(NewValue)
  self.wndBags:FindChild("BG"):SetOpacity(NewValue)
end

function ChargeSortedBags:OnDesignSlideChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local EditBox = wndControl:GetParent():FindChild("EditBox")
	local NewValue = math.ceil(fNewValue)
	EditBox:SetText(tostring(NewValue))
	self.db.profile.general.optionsList.Design.BG = NewValue
  self.wndMain:FindChild("BG"):SetSprite(Designs[NewValue])
end
---------------------------------------------------------------------------------------------------
-- ColorPickerCallback
---------------------------------------------------------------------------------------------------
function ChargeSortedBags:ColorPickerCallback(strColor)
	self.wndOptions:FindChild("OptionsDialogueControls"):FindChild("Swatch"):SetBGColor(strColor)
	self.db.profile.general.optionsList.Design.BGColor = strColor
  self.wndMain:FindChild("BG"):SetBGColor(self.db.profile.general.optionsList.Design.BGColor)
end
function ChargeSortedBags:OnColor( wndHandler, wndControl, eMouseButton )
	self.colorPicker:Show(true)
	self.colorPicker:ToFront()
end
