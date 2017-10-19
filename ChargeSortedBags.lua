-----------------------------------------------------------------------------------------------
-- Client Lua Script for ChargeSortedBags
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
--[[

todo:
SplittStack Funktion
TrashCan
CustomeBags

]]
require "Apollo"
require "GameLib"
require "Item"
require "Window"
require "Money"
require "AccountItemLib"
require "StorefrontLib"

local ChargeSortedBags = {}
local knMaxBags = 4 -- how many bags can the player have
local kChargeSortedBagsDefaults = {
	char = {
		currentProfile = nil,
	},
	profile = {
		general = {
			optionsList = {
				General = {
						sellJunk = true,
						autoRepairGuild = true,
						autoRepair = true,
						knSizeIconOption = 40,
						knBagsWidth = 381,
						autoWeapons = false,
						autoArmor = false,
						autoGadgets = false,
						autoDye = true,
						Ilvl = 50,
					},
				Currencies = {
          			["Platinum"]          = true,
					["Renown"] 						= true,
					["Elder Gem"]	 				= true,
					["Vouchers"]	 				= false,
					["Prestige"]	 				= true,
					["Shade Silver"	] 				= false,
					["Glory"] 						= true,
					["ColdCash"] 					= false,
					["Triploons"] 					= true,
					["Crimson Essence"] 			= false,
					["Cobalt Essence"] 				= false,
					["Viridian Essence"] 			= false,
					["Violet Essence"] 				= false,
					["C.R.E.D.D"] 					= false,
					["Realm Transfer"] 				= false,
					["Character Rename Token"] 		= false,
					["Fortune Coin"] 				= false,
					["OmniBits"] 					= true,
					["NCoin"] 						= false,
					["Cosmic Reward Point"] 		= false,
					["Service Token"] 				= true,
					["Protobucks"] 					= false,
					["Giant Point"] 				= false,
					["Character Boost Token"] 		= false,
					["Protostar Promissory Note"] 	= false,
					},
		        Design = {
		         fOpacity = 1,
		         Main = 1,
		         BG = 1,
		         BGColor = "ffffffff",
		        },
				Category = {
					arrange = 0,
					columns = 1,
					ColumnFill = {},
					bTrashLast = true,
				},
				Thanks = {
				},
			},
			BagList = {
				Armor = {},
				Weapons = {},
				Consumables = {},
				Trash = {},
				Toys = {},
				Token = {},
				Crafting = {},
				Rest = {},
				Housing = {},
				Collectibles = {},
			},
			BagListName = {"Armor", "Weapons", "Consumables", "Trash", "Toys", "Token", "Crafting", "Rest", "Housing", "Collectibles"
			 },
			CustomBagListName = {},

			tAnchorOffsetInv = { 10, 10, 456, 452 },
			tAnchorOffsetOpt = {-401, -261, 401, 300 },
      tAnchorOffsetBag = {360, 89, 587, 178 },
      tAnchorOffsetSpl = {393, 125, 581, 228 },
		},
	},
}


local Qualitys = {
	[1] = "BK3:UI_BK3_ItemQualityGrey",
	[2] = "BK3:UI_BK3_ItemQualityWhite",
	[3] = "BK3:UI_BK3_ItemQualityGreen",
	[4] = "BK3:UI_BK3_ItemQualityBlue",
	[5] = "BK3:UI_BK3_ItemQualityPurple",
	[6] = "BK3:UI_BK3_ItemQualityOrange",
	[7] = "BK3:UI_BK3_ItemQualityMagenta",
	}

local NumberQualitys = {
	[1] = "darkgray",
	[2] = "UI_WindowTextDefault",
	[3] = "AddonOk",
	[4] = "xkcdBrightBlue",
	[5] = "xkcdBarney",
	[6] = "Amber",
	[7] = "magenta",
	}


--compare Function
local fnSortItemsByName = function(Left, Right)
  local itemLeft = GameLib.GetBagItem(Left)
  local itemRight = GameLib.GetBagItem(Right)
	local strLeftName = itemLeft:GetName()
	local strRightName = itemRight:GetName()
	return strLeftName > strRightName
end

local fnSortItemsBylvl = function(Left, Right)
  local itemLeft = GameLib.GetBagItem(Left)
  local itemRight = GameLib.GetBagItem(Right)
	if itemLeft == itemRight then
		return 0
	end
	if itemLeft and itemRight == nil then
		return -1
	end
	if itemLeft == nil and itemRight then
		return 1
	end
	local leftilvl = itemLeft:GetDetailedInfo()["tPrimary"]["nItemLevel"]
	local rightilvl = itemRight:GetDetailedInfo()["tPrimary"]["nItemLevel"]
	if leftilvl < rightilvl then
		return -1
	end
	if leftilvl > rightilvl then
		return 1
	end

	return 0
end

local fnSortBagBySize = function(BagLeft, BagRight)
	local left = BagLeft:FindChild("BagGrid"):GetChildren()
	local right = BagLeft:FindChild("BagGrid"):GetChildren()

	return (#left) > (#right)
end


function ChargeSortedBags:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.bCostumesOpen = false
	o.bShouldSortItems = false
	o.nSortItemType = 1

	return o
end

function ChargeSortedBags:Init()
    Apollo.RegisterAddon(self)
end


function ChargeSortedBags:OnLoad()
  self.xmlDoc = XmlDoc.CreateFromFile("ChargeSortedBags.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, kChargeSortedBagsDefaults)
	--Sprites
	Apollo.LoadSprites("NewSprite.xml")

end

function ChargeSortedBags:OnDocLoaded()
	if self.xmlDoc == nil then return end
    --Color Picker
    GeminiColor = Apollo.GetPackage("GeminiColor").tPackage
	  self.colorPicker = GeminiColor:CreateColorPicker(self, "ColorPickerCallback", false, "ffffffff")
    self.colorPicker:Show(false, true)

			--Windows
		self.wndDeleteConfirm = 		Apollo.LoadForm(self.xmlDoc, "InventoryDeleteNotice", nil, self)
		self.wndSalvageConfirm = 		Apollo.LoadForm(self.xmlDoc, "InventorySalvageNotice", nil, self)
		self.wndSalvageWithKeyConfirm = Apollo.LoadForm(self.xmlDoc, "InventorySalvageWithKeyNotice", nil, self)
		self.wndMain = 					Apollo.LoadForm(self.xmlDoc, "InventoryBag_"..tostring(self.db.profile.general.optionsList.Design.Main), nil, self)
		self.wndOptions =				Apollo.LoadForm(self.xmlDoc, "Options", nil, self)
    	self.wndSplitSlot =     		Apollo.LoadForm(self.xmlDoc, "SplittSlot", nil, self)
		self.wndSplit = 				Apollo.LoadForm(self.xmlDoc, "SplitStackContainer", nil, self)
		self.wndBags = 					Apollo.LoadForm(self.xmlDoc, "BagWindow", nil, self)
		self.wndNewBag = 				Apollo.LoadForm(self.xmlDoc, "NewBagForm", nil, self)
		self.OneSlot = self.wndMain:FindChild("OneBagSlot")
		self.RealBag = self.OneSlot:FindChild("RealBagWindow")
    	self.wndSplitSlot:Show(false)
		self.wndNewBag:Show(false)
		self.wndOptions:Show(false,true)
		self.wndMain:Show(false, true)
		self.wndBags:Show(false,true)
		self.wndSalvageConfirm:Show(false, true)
		self.wndDeleteConfirm:Show(false, true)
		self.wndNewSatchelItemRunner = self.wndMain:FindChild("BGBottom:SatchelBG:SatchelBtn:NewSatchelItemRunner")
		self.wndSalvageAllBtn = self.wndMain:FindChild("SalvageAllBtn")



		--Events
		Apollo.RegisterEventHandler("InterfaceMenu_ToggleInventory", 				"OnToggleVisibility", self)
		Apollo.RegisterEventHandler("GuildBank_ShowPersonalInventory", 			"OnToggleVisibilityAlways", self)
		Apollo.RegisterEventHandler("InvokeVendorWindow", 						"OnToggleVisibilityAlways", self)
		Apollo.RegisterEventHandler("ShowBank",									"OnToggleVisibilityAlways", self)
		Apollo.RegisterEventHandler("ToggleInventory", 							"OnToggleVisibility", self) -- todo: figure out if show inventory is needed
		Apollo.RegisterEventHandler("ShowInventory", 								"OnToggleVisibilityAlways", self)
		Apollo.RegisterEventHandler("LevelUpUnlock_Inventory_Salvage", 			"OnLevelUpUnlock_Inventory_Salvage", self)
		Apollo.RegisterEventHandler("LevelUpUnlock_Path_Item", 					"OnLevelUpUnlock_Path_Item", self)
		Apollo.RegisterEventHandler("PlayerEquippedItemChanged",					"OnEquippedItem", self)
		Apollo.RegisterEventHandler("InvokeVendorWindow",							"OnOpenVendor", self)
		Apollo.RegisterEventHandler("CloseVendorWindow", 							"OnCloseVendor", self)
		Apollo.RegisterEventHandler("GuildBankerOpen", 							"OnOpenGBank", self)
		Apollo.RegisterEventHandler("GuildBankerClose", 							"OnCloseGBank", self)
		Apollo.RegisterEventHandler("HideBank", 									"OnCloseBank", self)
		Apollo.RegisterEventHandler("ShowBank", 									"OnOpenBank", self)
		Apollo.RegisterEventHandler("UpdateInventory", 							"OnUpdateInventory", self)
		Apollo.RegisterEventHandler("GenericEvent_SplitItemStack", 				"OnGenericEvent_SplitItemStack", self)
		Apollo.RegisterEventHandler("DragDropSysBegin",							"OnSystemBeginDragDrop", self)
		Apollo.RegisterEventHandler("DragDropSysEnd", 							"OnSystemEndDragDrop", self)
    	Apollo.RegisterEventHandler("PlayerCurrencyChanged", 							"OnCurrencyChanged", self)
    	Apollo.RegisterEventHandler("AccountCurrencyChanged", 							"OnCurrencyChanged", self)



		--SlashCommands
		Apollo.RegisterSlashCommand("csb", "OnOptionClick", self)

		--Variables
		self.nEquippedBagCount = 0
		self.bFirstLoad = true
		self.VendorOpen = false
		self.LastItem = nil
		self.DragDrop = nil
		self.DragDropSalvage = false
		self.ScrollAmount = 0
		self.BankOpen = false
		self.GBankOpen = false
		self.BagCount = 0
		self.scroll = nil
    	self.OverSlot = false
end


function ChargeSortedBags:LoadBags()
	for i,j in pairs(self.db.profile.general.BagListName) do
		self.db.profile.general.BagList[j] = {}
	end
	self.wndMain:FindChild("BagGrid"):DestroyChildren()
	local Bag = self.wndMain:FindChild("RealBagWindow")
	local maxSlots = Bag:GetTotalBagSlots()
	for i = 1 , maxSlots do
		local item = GameLib.GetBagItem(i)
		if item ~= nil then
			local isCustom = self:IsCustom(item)
			if not isCustom then
				local type = item:GetItemFamilyName()
				if type == "Gear" or type == "Armor" or type == "Costume" then
					table.insert(self.db.profile.general.BagList.Armor, i)
				elseif type == "Weapon" then
					table.insert(self.db.profile.general.BagList.Weapons, i)
				elseif type == "Junk" or type == "Miscellaneous" or type == "Trash" then
					if item:GetItemCategoryName()== "Toys" then
						table.insert(self.db.profile.general.BagList.Toys, i)
					elseif item:GetItemCategoryName() == "Loot Bag" or item:GetItemCategoryName() == "Salvageable Item" then
						table.insert(self.db.profile.general.BagList.Rest, i)
					else
						table.insert(self.db.profile.general.BagList.Trash, i)
					end
				elseif type == "Consumable" or type == "Imbuement Consumable" then
					table.insert(self.db.profile.general.BagList.Consumables, i)
				elseif type == "Housing" then
					table.insert(self.db.profile.general.BagList.Housing, i)
				elseif type == "Toys" then
					table.insert(self.db.profile.general.BagList.Toys, i)
				elseif type == "Token" then
					table.insert(self.db.profile.general.BagList.Token, i)
				elseif type == "Crafting" or type == "Rune" then
					table.insert(self.db.profile.general.BagList.Crafting, i)
				elseif type == "Collectible" then
					if item:GetItemTypeName() ==  "PvP Imbuement Material" then
						table.insert(self.db.profile.general.BagList.Consumables, i)
					else
						table.insert(self.db.profile.general.BagList.Collectibles, i)
					end
				else
					table.insert(self.db.profile.general.BagList.Rest, i)
				end
			end
		end
	end
	for i,j in pairs(self.db.profile.general.BagList) do
    if not self:IsCustomBag(i) then
		  self.db.profile.general.BagList[i] = self:MergeSortlvl(j)
		  self.db.profile.general.BagList[i] = self:NameSort(self.db.profile.general.BagList[i])
    end
	end

	self.BagCount = self.RealBag:GetTotalEmptyBagSlots()
	self.RealBag:MarkAllItemsAsSeen()
end

function ChargeSortedBags:LoadGrid()

	local BagGrid = self.wndMain:FindChild("BagGrid")
	BagGrid:DestroyChildren()
	for i,j in pairs(self.db["profile"]["general"]["BagListName"]) do
		local Bag = self.db["profile"]["general"]["BagList"][j]
		if Bag ~= nil and #Bag ~= 0 then
			local NewBag = Apollo.LoadForm(self.xmlDoc, "NewBag", BagGrid, self)
			NewBag:SetName(j)
			NewBag:FindChild("Title"):SetText(j)
			for l,k in ipairs(Bag) do
        local item = GameLib.GetBagItem(k)
				local NewSlot = Apollo.LoadForm(self.xmlDoc, "BagItem", NewBag:FindChild("BagGrid"), self)
				NewSlot:SetAnchorOffsets(0, 0, self.db.profile.general.optionsList.General.knSizeIconOption, self.db.profile.general.optionsList.General.knSizeIconOption)
				NewSlot:SetName(l)
				NewSlot:FindChild("BagItemIcon"):SetSprite(item:GetIcon())--NewItem Sprite: BK3:UI_BK3_Holo_InsetSimple

				local details = item:GetDetailedInfo()["tPrimary"]

				--Stacks
				local count = details["tStack"]["nCount"]
				if count > 1 then
					NewSlot:FindChild("stack"):SetText(tostring(count))
				end
				--ilvl
				if j == "Armor" or j == "Weapons" then
					NewSlot:FindChild("ilvl"):SetText(tostring(details["nItemLevel"]))
				else
					NewSlot:FindChild("ilvl"):SetText("")
				end

				--Quality
				local quality = details["eQuality"]
				if quality ~= nil then
					NewSlot:SetSprite(Qualitys[quality])
					NewSlot:FindChild("ilvl"):SetTextColor(NumberQualitys[quality])
				end
			end
			NewBag:FindChild("BagGrid"):ArrangeChildrenTiles(0)
		end
	end


	for i,j in pairs(self.db["profile"]["general"]["CustomBagListName"]) do
		local Bag = self.db["profile"]["general"]["BagList"][j]
		if Bag ~= nil and #Bag ~= 0 then
			local NewBag = Apollo.LoadForm(self.xmlDoc, "NewBag", BagGrid, self)
			NewBag:SetName(j)
			NewBag:FindChild("Title"):SetText(j)
			NewBag:FindChild("Close"):Show(true)
			for l,k in ipairs(Bag) do
				local NewSlot = Apollo.LoadForm(self.xmlDoc, "BagItem", NewBag:FindChild("BagGrid"), self)
				NewSlot:SetAnchorOffsets(0, 0, self.db.profile.general.optionsList.General.knSizeIconOption, self.db.profile.general.optionsList.General.knSizeIconOption)
				NewSlot:SetName(l)
        local item = GameLib.GetBagItem(k)
        local type = item:GetItemFamilyName()
				NewSlot:FindChild("BagItemIcon"):SetSprite(item:GetIcon())--NewItem Sprite: BK3:UI_BK3_Holo_InsetSimple
				local details = item:GetDetailedInfo()["tPrimary"]

				--Stacks
				local count = details["tStack"]["nCount"]
				if count > 1 then
					NewSlot:FindChild("stack"):SetText(tostring(count))
				end
				--ilvl
				if type == "Weapon" or type == "Gear" or type == "Armor" or type == "Costume" then
					NewSlot:FindChild("ilvl"):SetText(tostring(details["nItemLevel"]))
				else
					NewSlot:FindChild("ilvl"):SetText("")
				end

				--Quality
				local quality = details["eQuality"]
				if quality ~= nil then
					NewSlot:SetSprite(Qualitys[quality])
					NewSlot:FindChild("ilvl"):SetTextColor(NumberQualitys[quality])
				end
			end
			NewBag:FindChild("BagGrid"):ArrangeChildrenTiles(0)
		else
			local NewBag = Apollo.LoadForm(self.xmlDoc, "NewBag", BagGrid, self)
			NewBag:SetName(j)
			NewBag:FindChild("Title"):SetText(j)
			local EmptySlot = Apollo.LoadForm(self.xmlDoc, "BagItem", NewBag:FindChild("BagGrid"), self)
			EmptySlot:SetName("1")
			EmptySlot:FindChild("Empty"):Show(true)
			EmptySlot:FindChild("ilvl"):SetText("")
			EmptySlot:SetSprite(Qualitys[1])
			NewBag:FindChild("Close"):Show(true)
			EmptySlot:SetAnchorOffsets(0, 0, self.db.profile.general.optionsList.General.knSizeIconOption, self.db.profile.general.optionsList.General.knSizeIconOption)
			NewBag:FindChild("BagGrid"):ArrangeChildrenTiles(0)
		end
	end
end

function ChargeSortedBags:LoadCurrencies()
	self.wndMain:FindChild("Currencies"):DestroyChildren()
	local CurrencyGrip = self.wndMain:FindChild("Currencies")
	local OptionList = self.db.profile.general.optionsList.Currencies
	local Number_of_Currencies = 14
	--Platin
  if OptionList["Platinum"] then
	 local Platin = Apollo.LoadForm(self.xmlDoc, "MainCashWindow", CurrencyGrip, self)
	 Platin:SetTooltip("Currency")
	 Platin:SetAmount(GameLib.GetPlayerCurrency(),true)
  end
	--Character Currencies --self.OmniBitsCashWindow:SetAmount(AccountItemLib.GetAccountCurrency(6)) (true with chracter settings)
	for i = 2, Number_of_Currencies, 1 do
		if i ~= 8 then -- 8 = Gold
			local Currency = GameLib.GetPlayerCurrency(i)
			local info =  Currency:GetDenomInfo()[1]
			if OptionList[info.strName] then
				local newCurrency = Apollo.LoadForm(self.xmlDoc, "CurrencyForm", CurrencyGrip, self)
				newCurrency:SetTooltip(info.strName)
				newCurrency:SetAmount(GameLib.GetPlayerCurrency(i),true)
			end
		end
	end
	--Account Currencies
	for i = 1, 14, 1 do
		if i ~=10 and i ~= 4 then
			local Currency = AccountItemLib.GetAccountCurrency(i)
			local info =  Currency:GetDenomInfo()[1]
			if OptionList[info.strName] then
				local newCurrency = Apollo.LoadForm(self.xmlDoc, "CurrencyForm", CurrencyGrip, self)
				newCurrency:SetTooltip(info.strName)
				newCurrency:SetAmount(AccountItemLib.GetAccountCurrency(i))
			end
		end
	end
	self:ArrangeCurrencies()
end

function ChargeSortedBags:LoadSlots()
  local Bag = self.wndMain:FindChild("RealBagWindow")
  local maxSlots = Bag:GetTotalBagSlots()
  local TextBox = self.wndMain:FindChild("Slots")

  --BagCount describes the empty Slot Count ;)
  self.BagCount = self.RealBag:GetTotalEmptyBagSlots()
	if self.RealBag:GetTotalEmptyBagSlots() == 0 then
		self.wndMain:FindChild("Border"):Show(true)
		self.wndMain:FindChild("Full"):SetText("full")
    TextBox:SetText("[ "..tostring(maxSlots).."/"..tostring(maxSlots).." ]")
    TextBox:SetTextColor("red")
  else
    self.wndMain:FindChild("Border"):Show(false)
		self.wndMain:FindChild("Full"):SetText("")
    if self.BagCount <= 5 then
      TextBox:SetText("[ "..tostring(maxSlots-self.BagCount).."/"..tostring(maxSlots).." ]")
      TextBox:SetTextColor("AttributeName")
    else
      TextBox:SetText("[ "..tostring(maxSlots-self.BagCount).."/"..tostring(maxSlots).." ]")
      TextBox:SetTextColor("cyan")
    end
	end
end

function ChargeSortedBags:RemoveItemFromCustomBag(item)
  local number = self:FindSlotNumber(item)
  local general = self.db.profile.general
  for i,j in pairs(general.CustomBagListName) do
    if general.BagList[j] ~= nil then
      for k,l in pairs(general.BagList[j]) do
          if l == number then
            table.remove(general.BagList[j],k)
            return true
          end
      end
    end
  end
  return false
end

function ChargeSortedBags:IsCustomBag(BagName)

  for i,j in pairs(self.db.profile.general.CustomBagListName) do
    if j == BagName then
      return true
    end
  end

  return fale
end

function ChargeSortedBags:OnOpenBank()
	self.BankOpen = true
end

function ChargeSortedBags:OnCloseBank()
	self.BankOpen = false
end

function ChargeSortedBags:OnOpenGBank(unit)
	self.GBankOpen = true
end

function ChargeSortedBags:OnCloseGBank()
	self.GBankOpen = false
end

function ChargeSortedBags:OnOpenVendor()
	self:ShowMain()
	self.VendorOpen = true
	if self.db.profile.general.optionsList.General.sellJunk then
    self.db.profile.general.BagList["Trash"] = {}
		SellJunkToVendor()
	end

	if self.db.profile.general.optionsList.General.autoRepairGuild then
		local myGuild = nil
		for i,j in pairs(GuildLib.GetGuilds()) do
			if j:GetType() == GuildLib.GuildType_Guild then
				myGuild = j
				break
			end
		end
		if myGuild then
			myGuild:RepairAllItemsVendor()
		end
	end


	if self.db.profile.general.optionsList.General.autoRepair then
		RepairAllItemsVendor()
	end
	if self.db.profile.general.BagList.Weapons == nil then
		self.db.profile.general.BagList.Weapons = {}
	end
	if self.db.profile.general.BagList.Armor == nil then
		self.db.profile.general.BagList.Armor = {}
	end
	if self.db.profile.general.BagList.Consumables == nil then
		self.db.profile.general.BagList.Consumables = {}
	end
	
	if self.db.profile.general.optionsList.General.autoWeapons then
		local Ilvl = self.db.profile.general.optionsList.General.Ilvl
		for i,j in pairs(self.db.profile.general.BagList.Weapons) do
			local item = GameLib.GetBagItem(j)
			local ilvl = item:GetDetailedInfo()["tPrimary"]["nItemLevel"]
			if ilvl <= Ilvl then
				SellItemToVendorById(item:GetInventoryId(), 1)
			end
		end
	end
	if self.db.profile.general.optionsList.General.autoGadgets then
		local Ilvl = self.db.profile.general.optionsList.General.Ilvl
		for i,j in pairs(self.db.profile.general.BagList.Armor) do
			local item = GameLib.GetBagItem(j)
			local type = item:GetItemFamilyName()
			if type == "Gear" then
				local details = item:GetDetailedInfo()["tPrimary"]
				local ilvl = details["nItemLevel"]
				if ilvl <= Ilvl and details["arSpells"] ~= nil then
					SellItemToVendorById(item:GetInventoryId(), 1)
				end
			end
		end
	end
	if self.db.profile.general.optionsList.General.autoArmor then
		local Ilvl = self.db.profile.general.optionsList.General.Ilvl
		for i,j in pairs(self.db.profile.general.BagList.Armor) do
			local item = GameLib.GetBagItem(j)
			local type = item:GetItemFamilyName()
			if type == "Armor" or "Gear" then
				local details = item:GetDetailedInfo()["tPrimary"]
				local ilvl = details["nItemLevel"]
				if ilvl <= Ilvl and details["arSpells"] == nil then
					SellItemToVendorById(item:GetInventoryId(), 1)
				end
			end
		end
	end
	
	if self.db.profile.general.optionsList.General.autoDye then
		for i,j in pairs(self.db.profile.general.BagList.Consumables) do
			local Ilvl = self.db.profile.general.optionsList.General.Ilvl
			local item = GameLib.GetBagItem(j)
			local type = item:GetItemCategoryName()
			if type == "Dyes" then
				local details = item:GetDetailedInfo()["tPrimary"]
				if details["arUnlocks"]~= nil and details["arUnlocks"][1]["bUnlocked"] then
					SellItemToVendorById(item:GetInventoryId(), 1)
				end
			end
		end
	end
end

function ChargeSortedBags:OnCloseVendor()
	self.VendorOpen = false
end

function ChargeSortedBags:OnToggleVisibility()
	if self.wndMain:IsShown() then
		self.wndMain:Close()
		Sound.Play(Sound.PlayUIBagClose)
		for i,j in pairs(self.wndMain:FindChild("BagGrid"):GetChildren()) do
			for k,l in pairs(j:FindChild("BagGrid"):GetChildren()) do
				l:FindChild("ItemNew"):Show(false)
			end
		end
	else
		self:ShowMain()
		Sound.Play(Sound.PlayUIBagOpen)
	end

	if self.wndMain:IsShown() then
		--self:UpdateSquareSize()
		--self:UpdateBagSlotItems()
		--self:OnQuestObjectiveUpdated() -- Populate Virtual Inventory Btn from reloadui/load
		--self:HelperSetSalvageEnable()
	end
end

function ChargeSortedBags:OnToggleVisibilityAlways()
	self:ShowMain()

	if self.wndMain:IsShown() then
		--self:UpdateSquareSize()
		--self:UpdateBagSlotItems()
		--self:OnQuestObjectiveUpdated() -- Populate Virtual Inventory Btn from reloadui/load
		--self:HelperSetSalvageEnable()
	end
end

function ChargeSortedBags:OnLevelUpUnlock_Inventory_Salvage()
	self:OnToggleVisibilityAlways()
end

function ChargeSortedBags:OnLevelUpUnlock_Path_Item(itemFromPath)
	self:OnToggleVisibilityAlways()
end

function ChargeSortedBags:OnEquippedItem(eSlot, itemNew, itemOld)
	if itemNew then
		itemNew:PlayEquipSound()
	else
		itemOld:PlayEquipSound()
	end
end


function ChargeSortedBags:OnUpdateInventory()

  if self.wndSplitSlot:IsShown() then
    self.wndSplitSlot:Show(false)
  end

	self:LoadBags()
	if self.wndMain:IsShown() then
    self:LoadSlots()
		local scroll = self.wndMain:FindChild("BagGrid"):GetVScrollPos()
		self:LoadGrid()
		self:ArrangeChildren()
		self.scroll = scroll
	end
  self.RealBag:MarkAllItemsAsSeen()
end

---------------------------------------------------------------------------------------------------
-- BagItem Functions
---------------------------------------------------------------------------------------------------
function ChargeSortedBags:IsCustom( item )

	local id = item:GetInventoryId()
	for i,j in pairs(self.db.profile.general.CustomBagListName) do
		if self.db.profile.general.BagList[j] ~= nil then
			for k,l in pairs(self.db.profile.general.BagList[j]) do
        local nextItem = GameLib.GetBagItem(l)
				if nextItem == nil then
					table.remove(self.db.profile.general.BagList[j],k)
				else
					if nextItem:GetInventoryId() == id then
						return true
					end
				end
			end
		end
	end
	return false
end


function ChargeSortedBags:OnItemCooldowns()
	if not self.wndMain:IsShown() then
		return
	end
	local Bags = self.db.profile.general.BagList
	for i,j in pairs(self.wndMain:FindChild("BagGrid"):GetChildren())do
		local BagName = j:GetName()
		if Bags[BagName] ~= {} and Bags[BagName] ~= nil then
			for k,l in pairs(j:FindChild("BagGrid"):GetChildren()) do
				local item =  GameLib.GetBagItem(Bags[BagName][k])
				if item ~= nil then
					local details = item:GetDetailedInfo(Item.CodeEnumItemDetailedTooltip.Spell).tPrimary
					if details and details.arSpells and details.arSpells[1].splData:GetCooldownRemaining() > 0 then
						local time = details.arSpells[1].splData:GetCooldownRemaining()
						if time > 60 then
							time = math.floor(time/60+0.5).."m"
						else
							time = math.floor(time).."s"
						end
						l:FindChild("BagItemIcon"):UpdatePixie(1,{
						strText = time,
						strFont = "CRB_Header9_O",
						bLine = false,
						strSprite = "AbilitiesSprites:spr_StatVertProgBase",
						cr = "white",
						loc = {
						fPoints = {0,0,1,1},
						nOffsets = {-2,-2,2,2},
						},
						flagsText = { DT_CENTER = true, DT_VCENTER = true, }
						})
					else
						l:FindChild("BagItemIcon"):UpdatePixie(1,{
						strText = "",
						strFont = "CRB_Header9_O",
						bLine = false,
						strSprite = "",
						cr = "white",
						loc = {
						fPoints = {0,0,1,1},
						nOffsets = {-2,-2,2,2},
						},
						flagsText = { DT_CENTER = true, DT_VCENTER = true, }
						})
					end
				end
			end
		end
	end
end

function ChargeSortedBags:OnGenerateTooltip( wndHandler, wndControl, eToolTipType, x, y )

	if wndHandler:FindChild("Empty"):IsShown() then
		return
	end

	if wndControl ~= wndHandler then return end
	wndControl:SetTooltipDoc(nil)
	local ItemNumber = tonumber(wndControl:GetParent():GetName())
	local list = wndControl:GetParent():GetParent():GetParent():FindChild("Title"):GetText()
	item =  GameLib.GetBagItem(self.db.profile.general.BagList[list][ItemNumber])
	if item ~= nil then
		local itemEquipped = item:GetEquippedItemForItemType()
		Tooltip.GetItemTooltipForm(self, wndControl, item, {bPrimary = true, bSelling = false, itemCompare = itemEquipped})
	end
end

function ChargeSortedBags:OnBagItemMouseExit( wndHandler, wndControl, x, y )
  if self.OverSlot == wndHandler then
    self.RealBag:Show(false)
  end

  local Highl = wndControl:GetParent():FindChild("ItemHighlight")
  if Highl ~= nil then
	 Highl:Show(false)
  end
end


function ChargeSortedBags:OnBagItemMousEnter( wndHandler, wndControl, x, y )
	if wndHandler:FindChild("Empty"):IsShown() then
		return
	end
  self.OverSlot = wndHandler
	--Highlight
	local Highlight = wndHandler:GetParent():FindChild("ItemHighlight")
	local NewItem = wndHandler:GetParent():FindChild("ItemNew")
	Highlight:Show(true)
	NewItem:Show(false)

	--Setting up BagWindow
	local OneSlot = self.wndMain:FindChild("OneBagSlot")
	local BagWindow = self.wndMain:FindChild("RealBagWindow")
	local maxSlots = BagWindow:GetBagCapacity()
	local iconSize = self.db.profile.general.optionsList.General.knSizeIconOption
	BagWindow:SetSquareSize(iconSize+1, iconSize+1)
	BagWindow:SetBoxesPerRow(maxSlots)

	local slot = tonumber(wndControl:GetParent():GetName())
	local Bag = wndControl:GetParent():GetParent()
	local BagName = Bag:GetParent():FindChild("Title"):GetText()
	local item = GameLib.GetBagItem(self.db.profile.general.BagList[BagName][slot])
  if item ~= nil then
  	local SlotNum = self:FindSlotNumber(item)
  	local leftBorder, topBorder = self.wndMain:FindChild("BagGrid"):GetAnchorOffsets()-- The gab between wndMain and the BagGrid is 9  -- The gab between wndMain at the top is 44
  	local itemgab =  math.floor(0.5*iconSize)-- idk why but it works
  	local l,t,r,b = wndControl:GetParent():GetAnchorOffsets()
  	local pl,pt,pr,pb = Bag:GetAnchorOffsets()
  	local ppl,ppt, ppr,ppb = Bag:GetParent():GetAnchorOffsets()
  	local scroll = self.wndMain:FindChild("BagGrid"):GetVScrollPos()
  	OneSlot:SetAnchorOffsets(l+pl+ppl+leftBorder, t+pt+ppt+topBorder-scroll, l+pl+ppl+iconSize+leftBorder, t+pt+ppt+iconSize+topBorder-scroll)

  	local offset =	SlotNum*-(iconSize+1)
  	BagWindow:SetAnchorOffsets(offset+iconSize-itemgab,-1,(maxSlots)*(iconSize+1)+offset+iconSize-itemgab,iconSize-1)
  	self.RealBag:Show(true)
    end
end

function ChargeSortedBags:FindSlotNumber(item)
	local BagWindow = self.wndMain:FindChild("RealBagWindow")
	local maxSlots = BagWindow:GetBagCapacity()
	local id = item:GetInventoryId()
	for i =1 , maxSlots do
		local CurrItem = GameLib.GetBagItem(i)
		if CurrItem ~= nil and CurrItem:GetInventoryId() == id then
			return i
		end
	end
	return -1
end

---------------------------------------------------------------------------------------------------
-- BagWindow Functions
---------------------------------------------------------------------------------------------------

function ChargeSortedBags:OnBagBtnMouseEnter( wndHandler, wndControl, x, y )
	local item = wndHandler:GetItem()
	wndControl:SetTooltipDoc(nil)
	Tooltip.GetItemTooltipForm(self, wndControl, item, {bPrimary = true, bSelling = false, itemCompare = nil})

end


function ChargeSortedBags:OnBagBtnMouseExit( wndHandler, wndControl, x, y )
	wndControl:SetTooltipDoc(nil)
end

function ChargeSortedBags:AddNewBagConfirm( wndHandler, wndControl)
	self.wndNewBag:Show(false)
	local BagName = wndControl:GetParent():FindChild("EditBox"):GetText()
	if BagName ~= "" and BagName ~= nil then
		BagName = self:NameOkTest(BagName)
		self.db.profile.general.BagList[BagName] = {}
		table.insert(self.db.profile.general.CustomBagListName,BagName)
	end
	self:LoadGrid()
	self:ArrangeChildren()
end

function ChargeSortedBags:NameOkTest(BagName)
	local Test = false
	local Number = 1
	local NewBagName = BagName
	while Test == false do
		local NoNameChange = true
		for i,j in pairs(self.db.profile.general.CustomBagListName) do
			if NewBagName == j then
				NewBagName = BagName.."("..tostring(Number)..")"
				Number = Number + 1
				NoNameChange = false
			end
		end
		if NoNameChange then
			return NewBagName
		end
	end
end


function ChargeSortedBags:OnDeleteCustomeBag( wndHandler, wndControl, eMouseButton )
	local BagName = wndControl:GetParent():FindChild("Title"):GetText()
	self.db.profile.general.BagList[BagName] = nil
	for i,j in pairs(self.db.profile.general.CustomBagListName) do
		if j == BagName then
			table.remove(self.db.profile.general.CustomBagListName, i)
			break
		end
	end
	wndControl:GetParent():Destroy()
  self:LoadBags()
  self:LoadGrid()
	self:ArrangeChildren()
end

function ChargeSortedBags:GetLastFreeSpace()
	local MaxBagSlots =  self.RealBag:GetBagCapacity()
	local capacity = MaxBagSlots

	for i = capacity, 1, -1 do
		local item = GameLib.GetBagItem(i)
		if item == nil then
			self.LastFreeSlot = i
			return i
		end
	end
	return -1
end

-----------------------------------------------------------------------------------------------
-- Stack Splitting
-----------------------------------------------------------------------------------------------

function ChargeSortedBags:OnGenericEvent_SplitItemStack(item)
	if not item then
		return
	end

	local knPaddingTop = 20
	local nStackCount = item:GetStackCount()
	if nStackCount < 2 then
		self.wndSplit:Show(false)
		return
	end
	self.wndSplit:Invoke()
	local tMouse = Apollo.GetMouse()
	self.wndSplit:Move(tMouse.x - math.floor(self.wndSplit:GetWidth() / 2) , tMouse.y - knPaddingTop - self.wndSplit:GetHeight(), self.wndSplit:GetWidth(), self.wndSplit:GetHeight())


	self.wndSplit:SetData(item)
	self.wndSplit:FindChild("SplitValue"):SetValue(1)
	self.wndSplit:FindChild("SplitValue"):SetMinMax(1, nStackCount - 1)
	self.wndSplit:Show(true)
end

function ChargeSortedBags:OnSplitStackCloseClick()
	self.wndSplit:Show(false)
end

function ChargeSortedBags:OnSplitStackConfirm(wndHandler, wndCtrl)
	self.wndSplit:Close()
	self.RealBag:StartSplitStack(self.wndSplit:GetData(), self.wndSplit:FindChild("SplitValue"):GetValue())
  if self.RealBag:GetTotalEmptyBagSlots()  > 0 then

    local freeSlot = self:GetLastFreeSpace()-1
    local iconSize = self.db.profile.general.optionsList.General.knSizeIconOption
    local offset =	freeSlot*-(41)+41
    local maxSlots =  self.RealBag:GetBagCapacity()
  	self.wndSplitSlot:FindChild("RealBagWindow"):SetAnchorOffsets(-20+offset,0,3250+offset,48)
    self.wndSplitSlot:Show(true)
  end
end


---------------------------------------------------------------------------------------------------
-- Utils
---------------------------------------------------------------------------------------------------

--all numbers are positive
function ChargeSortedBags:MergeSortlvl(tables)
	if #tables < 2 then
		return tables
	end

	local h = #tables/2
	local LTable = {}
	local RTable = {}
	for i = 1, #tables do
		if i <= h then
			table.insert(LTable,tables[i])
		else
			table.insert(RTable,tables[i])
		end
	end
	LTable = self:MergeSortlvl(LTable)
	RTable = self:MergeSortlvl(RTable)
	local max = #tables
	local Table = {}
	local left = 1
	local right = 1
	for i = 1, max do
		local leftilvl  = -1
		local rightilvl = -1
		if left < #LTable+1 then
			leftilvl  = GameLib.GetBagItem(LTable[left]):GetDetailedInfo()["tPrimary"]["nItemLevel"]
		end
		if right < #RTable+1 then
			rightilvl = GameLib.GetBagItem(RTable[right]):GetDetailedInfo()["tPrimary"]["nItemLevel"]
		end
		if leftilvl > rightilvl then
			Table[i] = LTable[left]
			left = left+1
		else
			Table[i] = RTable[right]
			right = right+1
		end
	end
	return Table
end


function ChargeSortedBags:NameSort(tables)
	if #tables == 0 then
		return
	end
	--the input is a ilvl-sorted table
	local All = {}
	local order = {}
	local t = 1
	for i = 1, #tables do
		local ilvl  = GameLib.GetBagItem(tables[i]):GetDetailedInfo()["tPrimary"]["nItemLevel"]
		if All[ilvl] == nil then
			All[ilvl] = {}
			order[t] = ilvl
			t= t+1
		end
		table.insert(All[ilvl],tables[i])
	end
	local returnTable = {}
	local z = 1;
	for i,j in pairs(order) do
		table.sort(All[j], fnSortItemsByName)
		for t,l in pairs(All[j]) do
			returnTable[z] = l
			z = z+1
		end
	end
	return returnTable
end


--thanks to Johan Lindström (Jabbit-EU, Joxye Nadrax / Wildstar) for the Split Function
-- Compatibility: Lua-5.1
function ChargeSortedBags:Split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end



local InventoryBagInst = ChargeSortedBags:new()
InventoryBagInst:Init()
