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
		CurOptWnd:FindChild("Weapons"):SetCheck(Opt.General.autoWeapons)
		CurOptWnd:FindChild("Armor"):SetCheck(Opt.General.autoArmor)
		CurOptWnd:FindChild("Gadgets"):SetCheck(Opt.General.autoGadgets)
		CurOptWnd:FindChild("SellDye"):SetCheck(Opt.General.autoDye)
		--iconSize
		CurOptWnd:FindChild("Scale_IconSize"):FindChild("EditBox"):SetText(tostring(Opt.General.knSizeIconOption))
		local min, max , tick = 35,60,5
		local sliderIconSize = CurOptWnd:FindChild("Scale_IconSize"):FindChild("SliderBar")
		sliderIconSize:SetMinMax(min,max,tick)
		sliderIconSize:SetValue(Opt.General.knSizeIconOption)
		--Autosell ilvl
		CurOptWnd:FindChild("Scale_Ilvl"):FindChild("EditBox"):SetText(tostring(Opt.General.Ilvl))
		local min, max , tick = 0,170,1
		local sliderIconSize = CurOptWnd:FindChild("Scale_Ilvl"):FindChild("SliderBar")
		sliderIconSize:SetMinMax(min,max,tick)
		sliderIconSize:SetValue(Opt.General.Ilvl)
		

  elseif Name == "DesignOption" then
    --Opacity
    CurOptWnd:FindChild("Scale_Opacity"):FindChild("EditBox"):SetText(tostring(Opt.Design.fOpacity))
    local min, max , tick = 0, 1, 0.01
    local slider = CurOptWnd:FindChild("Scale_Opacity"):FindChild("SliderBar")
    slider:SetMinMax(min,max,tick)
	slider:SetValue(Opt.Design.fOpacity)

    --BGDesign
    CurOptWnd:FindChild("Scale_BGDesign"):FindChild("EditBox"):SetText(tostring(Opt.Design.BG))
    local min, max , tick = 0, 6, 1
    local slider2 = CurOptWnd:FindChild("Scale_BGDesign"):FindChild("SliderBar")
    slider2:SetMinMax(min,max,tick)
		slider2:SetValue(Opt.Design.BG)

    --Main Theme
    CurOptWnd:FindChild("Scale_MainDesign"):FindChild("EditBox"):SetText(tostring(Opt.Design.Main))
    local min, max , tick = 1, 2, 1
    local slider3 = CurOptWnd:FindChild("Scale_MainDesign"):FindChild("SliderBar")
    slider3:SetMinMax(min,max,tick)
	slider3:SetValue(Opt.Design.Main)

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
		
	elseif Name == "CategoryOption" then
		
		for i = 0,2 do
			if i ~= self.db.profile.general.optionsList.Category.arrange then
				CurOptWnd:FindChild("CategoryOption:Mode:"..tostring(i)):SetCheck(false)
			else
				CurOptWnd:FindChild("CategoryOption:Mode:"..tostring(i)):SetCheck(true)
			end
		end
		
		CurOptWnd:FindChild("TrashLast"):SetCheck(Opt.Category.bTrashLast)
		
		--coloumns
	    CurOptWnd:FindChild("Scale_Columns"):FindChild("EditBox"):SetText(tostring(Opt.Category.columns))
	    local min, max , tick = 1, 4, 1
	    local slider = CurOptWnd:FindChild("Scale_Columns"):FindChild("SliderBar")
	    slider:SetMinMax(min,max,tick)
		slider:SetValue(Opt.Category.columns)
		
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
		option.autoWeapons = main:FindChild("Weapons"):IsChecked()
		option.autoArmor = main:FindChild("Armor"):IsChecked()
		option.autoGadgets = main:FindChild("Gadgets"):IsChecked()
		option.autoDye = main:FindChild("SellDye"):IsChecked()
		option.knSizeIconOption = tonumber(main:FindChild("Scale_IconSize"):FindChild("EditBox"):GetText())
		
	elseif name == "CurrenciesGrid" then
		local Currency = wndControl:GetParent():FindChild("Name"):GetText()
		self.db.profile.general.optionsList.Currencies[Currency] = wndControl:IsChecked()

		self:LoadCurrencies()
	elseif name == "CategoryOption" then 
		self.db.profile.general.optionsList.Category.bTrashLast = main:FindChild("TrashLast"):IsChecked()
		self:ArrangeChildren()
	end
end

function ChargeSortedBags:SaveMode( wndHandler, wndControl, eMouseButton )
	local mode = tonumber(wndHandler:GetName())
	self.db.profile.general.optionsList.Category.arrange = mode
	local parent = wndHandler:GetParent()
	for i = 0,2 do
		if i ~= mode then
			parent:FindChild(tostring(i)):SetCheck(false)
		end
	end
		
	self:ShowMain()
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

function ChargeSortedBags:OnIlvlSlideChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local EditBox = wndControl:GetParent():FindChild("EditBox")
	local NewValue = math.ceil(fNewValue)
	EditBox:SetText(tostring(NewValue))
	self.db.profile.general.optionsList.General.Ilvl = NewValue
end

function ChargeSortedBags:OnColumnsSlideChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local EditBox = wndControl:GetParent():FindChild("EditBox")
	local NewValue = math.ceil(fNewValue)
	
	if NewValue == self.db.profile.general.optionsList.Category.columns then return end
	
	EditBox:SetText(tostring(NewValue))
	self.db.profile.general.optionsList.Category.columns = NewValue
	self:ShowMain()
	for i,j in pairs(self.db.profile.general.optionsList.Category.ColumnFill) do
		if j > NewValue then
			self.db.profile.general.optionsList.Category.ColumnFill[i] = nil
		end
	end
	self:ArrangeChildren()
end


function ChargeSortedBags:OnMainDesignSlideChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local EditBox = wndControl:GetParent():FindChild("EditBox")
	local NewValue = math.ceil(fNewValue)
	EditBox:SetText(tostring(NewValue))
	self.db.profile.general.optionsList.Design.Main = NewValue
  	self.wndMain:Destroy()
  	self.wndMain = 	Apollo.LoadForm(self.xmlDoc, "InventoryBag_"..tostring(self.db.profile.general.optionsList.Design.Main), nil, self)
  	self.OneSlot = self.wndMain:FindChild("OneBagSlot")
  	self.RealBag = self.OneSlot:FindChild("RealBagWindow")
  	self:SetWindows()
  	self:LoadGrid()
  	self:LoadSlots()
  	self:LoadCurrencies()
  	if self.RealBag:GetTotalEmptyBagSlots() == 0 then
    	self.wndMain:FindChild("Border"):Show(true)
    	self.wndMain:FindChild("Full"):SetText("full")
  	end
  	self:LoadGrid()
  	self:ArrangeChildren()
  	self.wndMain:Show(true)
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
