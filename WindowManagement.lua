--------------------------------------------------------------------------------------------
--Window Management
---------------------------------------------------------------------------------------------
local ChargeSortedBags = Apollo.GetAddon("ChargeSortedBags")

local Qualitys = {
	[1] = "BK3:UI_BK3_ItemQualityGrey",
	[2] = "BK3:UI_BK3_ItemQualityWhite",
	[3] = "BK3:UI_BK3_ItemQualityGreen",
	[4] = "BK3:UI_BK3_ItemQualityBlue",
	[5] = "BK3:UI_BK3_ItemQualityPurple",
	[6] = "BK3:UI_BK3_ItemQualityOrange",
	[7] = "BK3:UI_BK3_ItemQualityMagenta",
	}

  local Designs = {
   [1] = "AbilitiesSprites:spr_StatVertProgBase",
   [2] = "CRB_Basekit:kitScrollbase_Horiz_HoloSmall",
   [3] = "CRB_DEMO_CreationSprites:sprDemo_CCFrameBG",
   [4] = "CRB_MegamapSprites:sprMap_WorldMap",
   [5] = "CRB_TooltipSprites:sprTT_BasicBack",
   [6] = "charactercreate:sprCharC_BG02",

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
local fnSortItemsByName = function(itemLeft, itemRight)
	local strLeftName = itemLeft:GetName()
	local strRightName = itemRight:GetName()
	return strLeftName > strRightName
end

local fnSortItemsBylvl = function(itemLeft, itemRight)
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
-----------------------------------------------------------------------------------------------
-- Window Controls
-----------------------------------------------------------------------------------------------

function ChargeSortedBags:ShowMain()
	if self.bFirstLoad then
		--Timer
    	self:LoadSlots()
		self.Timer = ApolloTimer.Create(0.5, true, "OnItemCooldowns", self)
		self.Timer:Start()
		self:SetWindows()
		self:LoadBags()
		self:LoadCurrencies()
    	self:LoadBagWindow()
		self.bFirstLoad = false
		self:LoadGrid()
	end
	for i,j in pairs(self.db.profile.general.BagList) do
		self.db.profile.general.BagList[i] = self:MergeSortlvl(j)
		self.db.profile.general.BagList[i] = self:NameSort(self.db.profile.general.BagList[i])
	end
	if self.RealBag:GetTotalEmptyBagSlots() == 0 then
			self.wndMain:FindChild("Border"):Show(true)
			self.wndMain:FindChild("Full"):SetText("full")
	end
	self:LoadGrid()
	self:ArrangeChildren()
	self.wndMain:Invoke()
	self.wndMain:ToFront()
end


function ChargeSortedBags:ArrangeChildren()
	local Options = self.db.profile.general.optionsList.General
	local OptionsList = self.db.profile.general.optionsList
	local titleHeight = 35
	local compensate = 16--16 --Since ArrangeChilderenTile() cuts off Tiles even before the max width is reached the Window needs to wider than columns*IconSize (therefor compensate)
	local compensate2 = 25
	local BordersWidth = 14
	local smallBorder = Options.knSizeIconOption -10 -- The value needs to be smaller than the cube "-10" is best fitting
	local BagGrid = self.wndMain:FindChild("BagGrid")
	local Bags = BagGrid:GetChildren()
	local Fill = {}
	for i = 1,4 do--since 4 is the max columns
		Fill[i] = {}
	end
	if OptionsList.Category.bTrashLast then
		local trash = nil
		--Set Trash to last
		for i,j in pairs(Bags) do
			if j:GetName() == "Trash" then
				trash = j
				table.remove(Bags,i)
			end
		end 
		if trash ~= nil then
			table.insert(Bags,trash)	
		end
	end
	
	--Fill Columns
	for i,j in pairs(Bags) do
		if OptionsList.Category.ColumnFill[j:GetName()] ~= nil then
			table.insert(Fill[OptionsList.Category.ColumnFill[j:GetName()]],j:GetName())
		else
			table.insert(Fill[1],j:GetName())
		end
	end
	table.sort(Bags, fnSortBagBySize)

	local a,b,c,d = self.wndMain:GetAnchorOffsets()
	local Width = c-a
	local columnWidth = (Options.knBagsWidth)/OptionsList.Category.columns
	local gab = 5
	if OptionsList.Category.arrange == 0 then  --Best fit
		for k,v in pairs(Fill) do
			local LeftSlots = {}
			LeftSlots[1] = {(k-1)*(columnWidth + gab), 0 , (k-1)*(columnWidth + gab) , 0}
			local counter = 1	
			for i,j in pairs(v) do
				local Bag = BagGrid:FindChild(j)
				local slots = Bag:FindChild("BagGrid"):GetChildren()
				local slotsPerRow = 0
				if k == OptionsList.Category.columns then
					slotsPerRow = math.floor((columnWidth - BordersWidth-compensate2+1)/Options.knSizeIconOption)--+1 since every bag  has a border
				else
					slotsPerRow = math.floor((columnWidth-BordersWidth)/Options.knSizeIconOption)
				end
				if #slots >= slotsPerRow then
					local rows = math.ceil(#slots/slotsPerRow)
					counter = counter + 1
					if k == OptionsList.Category.columns then
						LeftSlots[counter] = {LeftSlots[counter-1][1], LeftSlots[counter-1][4], LeftSlots[counter-1][1] + columnWidth - BordersWidth + compensate - compensate2,
							LeftSlots[counter-1][4]+ rows*Options.knSizeIconOption + titleHeight}
						Bag:SetAnchorOffsets( LeftSlots[counter-1][1], LeftSlots[counter-1][4], LeftSlots[counter-1][1] + columnWidth - BordersWidth + compensate - compensate2,
							LeftSlots[counter-1][4]+ rows*Options.knSizeIconOption + titleHeight)
					else
						LeftSlots[counter] = {LeftSlots[counter-1][1], LeftSlots[counter-1][4], LeftSlots[counter-1][1] + columnWidth - BordersWidth + compensate,
							LeftSlots[counter-1][4]+ rows*Options.knSizeIconOption + titleHeight}
						Bag:SetAnchorOffsets( LeftSlots[counter-1][1], LeftSlots[counter-1][4], LeftSlots[counter-1][1] + columnWidth - BordersWidth + compensate,
							LeftSlots[counter-1][4]+ rows*Options.knSizeIconOption + titleHeight)
					end
				else
					local newHome = false
					for i,j in pairs(LeftSlots) do
						if i ~= 1 and newHome == false then
							local newWidth = j[3]+ #slots*Options.knSizeIconOption
							if k == OptionsList.Category.columns then
								if (newWidth < k*(columnWidth+gab)-BordersWidth-compensate2) then
									Bag:SetAnchorOffsets( j[3], j[2],newWidth+smallBorder,j[4])
									LeftSlots[i] = {j[1], j[2],newWidth+smallBorder,j[4]}
									newHome = true
								end
							else
								if (newWidth < k*(columnWidth+gab)-BordersWidth) then
									Bag:SetAnchorOffsets( j[3], j[2],newWidth+smallBorder,j[4])
									LeftSlots[i] = {j[1], j[2],newWidth+smallBorder,j[4]}
									newHome = true
								end
							end
						end
					end
					if newHome == false then
						counter = counter +1
						local newWidth = LeftSlots[counter-1][1]+ #slots*Options.knSizeIconOption+smallBorder
						LeftSlots[counter] = {LeftSlots[counter-1][1],LeftSlots[counter-1][4], newWidth,LeftSlots[counter-1][4]+ Options.knSizeIconOption + titleHeight}
						Bag:SetAnchorOffsets(LeftSlots[counter-1][1], LeftSlots[counter-1][4], newWidth,LeftSlots[counter-1][4]+ Options.knSizeIconOption + titleHeight)
					end
				end
					Bag:FindChild("BagGrid"):ArrangeChildrenTiles(0)
			end
		end
		
	elseif OptionsList.Category.arrange == 1 then --Same order
	
		for k,v in pairs(Fill) do
			local LeftSlots = {}
			LeftSlots[1] = {(k-1)*(columnWidth + gab), 0 , (k-1)*(columnWidth + gab) , 0}
			local counter = 1	
			for i,j in pairs(v) do
				local Bag = BagGrid:FindChild(j)
				local slots = Bag:FindChild("BagGrid"):GetChildren()
				local slotsPerRow = 0
				if k == OptionsList.Category.columns then
					slotsPerRow = math.floor((columnWidth - BordersWidth-compensate2+1)/Options.knSizeIconOption)--+1 since every bag  has a border
				else
					slotsPerRow = math.floor((columnWidth-BordersWidth)/Options.knSizeIconOption)
				end
				if #slots >= slotsPerRow then
					local rows = math.ceil(#slots/slotsPerRow)
					counter = counter + 1
					if k == OptionsList.Category.columns then
						LeftSlots[counter] = {LeftSlots[counter-1][1], LeftSlots[counter-1][4], LeftSlots[counter-1][1] + columnWidth - BordersWidth + compensate - compensate2,
							LeftSlots[counter-1][4]+ rows*Options.knSizeIconOption + titleHeight}
						Bag:SetAnchorOffsets( LeftSlots[counter-1][1], LeftSlots[counter-1][4], LeftSlots[counter-1][1] + columnWidth - BordersWidth + compensate - compensate2,
							LeftSlots[counter-1][4]+ rows*Options.knSizeIconOption + titleHeight)
					else
						LeftSlots[counter] = {LeftSlots[counter-1][1], LeftSlots[counter-1][4], LeftSlots[counter-1][1] + columnWidth - BordersWidth + compensate,
							LeftSlots[counter-1][4]+ rows*Options.knSizeIconOption + titleHeight}
						Bag:SetAnchorOffsets( LeftSlots[counter-1][1], LeftSlots[counter-1][4], LeftSlots[counter-1][1] + columnWidth - BordersWidth + compensate,
							LeftSlots[counter-1][4]+ rows*Options.knSizeIconOption + titleHeight)
					end
				else
					local newHome = false
					if i ~= 1 and newHome == false then
						local newWidth = LeftSlots[counter][3]+ #slots*Options.knSizeIconOption
						if k == OptionsList.Category.columns then
							if (newWidth < k*(columnWidth+gab)-BordersWidth-compensate2) then
								Bag:SetAnchorOffsets( LeftSlots[counter][3], LeftSlots[counter][2],newWidth+smallBorder,LeftSlots[counter][4])
								LeftSlots[counter] = {LeftSlots[counter][1], LeftSlots[counter][2],newWidth+smallBorder,LeftSlots[counter][4]}
								newHome = true
							end
						else
							if (newWidth < k*(columnWidth+gab)-BordersWidth) then
								Bag:SetAnchorOffsets( LeftSlots[counter][3], LeftSlots[counter][2],newWidth+smallBorder,LeftSlots[counter][4])
								LeftSlots[counter] = {LeftSlots[counter][1], LeftSlots[counter][2],newWidth+smallBorder,LeftSlots[counter][4]}
								newHome = true
							end
						end
					end
					if newHome == false then
						counter = counter +1
						local newWidth = LeftSlots[counter-1][1]+ #slots*Options.knSizeIconOption+smallBorder
						LeftSlots[counter] = {LeftSlots[counter-1][1],LeftSlots[counter-1][4], newWidth,LeftSlots[counter-1][4]+ Options.knSizeIconOption + titleHeight}
						Bag:SetAnchorOffsets(LeftSlots[counter-1][1], LeftSlots[counter-1][4], newWidth,LeftSlots[counter-1][4]+ Options.knSizeIconOption + titleHeight)
					end
				end
					Bag:FindChild("BagGrid"):ArrangeChildrenTiles(0)
			end
		end
		
	else --allways new row
		for k,v in pairs(Fill) do
			local LeftSlots = {}
			LeftSlots[1] = {(k-1)*(columnWidth + gab), 0 , (k-1)*(columnWidth + gab) , 0}
			local counter = 1	
			for i,j in pairs(v) do
				local Bag = BagGrid:FindChild(j)
				local slots = Bag:FindChild("BagGrid"):GetChildren()
				local slotsPerRow = 0
				if k == OptionsList.Category.columns then
					slotsPerRow = math.floor((columnWidth - BordersWidth-compensate2+1)/Options.knSizeIconOption)--+1 since every bag  has a border
				else
					slotsPerRow = math.floor((columnWidth-BordersWidth)/Options.knSizeIconOption)
				end
				if #slots >= slotsPerRow then
					local rows = math.ceil(#slots/slotsPerRow)
					counter = counter + 1
					if k == OptionsList.Category.columns then
						LeftSlots[counter] = {LeftSlots[counter-1][1], LeftSlots[counter-1][4], LeftSlots[counter-1][1] + columnWidth - BordersWidth + compensate - compensate2,
							LeftSlots[counter-1][4]+ rows*Options.knSizeIconOption + titleHeight}
						Bag:SetAnchorOffsets( LeftSlots[counter-1][1], LeftSlots[counter-1][4], LeftSlots[counter-1][1] + columnWidth - BordersWidth + compensate - compensate2,
							LeftSlots[counter-1][4]+ rows*Options.knSizeIconOption + titleHeight)
					else
						LeftSlots[counter] = {LeftSlots[counter-1][1], LeftSlots[counter-1][4], LeftSlots[counter-1][1] + columnWidth - BordersWidth + compensate,
							LeftSlots[counter-1][4]+ rows*Options.knSizeIconOption + titleHeight}
						Bag:SetAnchorOffsets( LeftSlots[counter-1][1], LeftSlots[counter-1][4], LeftSlots[counter-1][1] + columnWidth - BordersWidth + compensate,
							LeftSlots[counter-1][4]+ rows*Options.knSizeIconOption + titleHeight)
					end
				else
					counter = counter +1
					local newWidth = LeftSlots[counter-1][1]+ #slots*Options.knSizeIconOption+smallBorder
					LeftSlots[counter] = {LeftSlots[counter-1][1],LeftSlots[counter-1][4], newWidth,LeftSlots[counter-1][4]+ Options.knSizeIconOption + titleHeight}
					Bag:SetAnchorOffsets(LeftSlots[counter-1][1], LeftSlots[counter-1][4], newWidth,LeftSlots[counter-1][4]+ Options.knSizeIconOption + titleHeight)
				end
					Bag:FindChild("BagGrid"):ArrangeChildrenTiles(0)
			end
		end
	end
end
	
function ChargeSortedBags:ArrangeCurrencies()
	local Currencies = self.wndMain:FindChild("Currencies"):GetChildren()
	if #Currencies <= 0 then
		return
	end
	local il, it, ir, ib = self.wndMain:GetAnchorOffsets()
	local l,t,r,b = self.wndMain:FindChild("Currencies"):GetAnchorOffsets()
	local width = (il+l)-(ir+r)
	local Pos = {0,0}
	for i = 1, #Currencies do
		local cl, ct, cr,cb = Currencies[i]:GetAnchorOffsets()
		if Pos[1]+(cl-cr) < width then
			Pos[2] = Pos[2]+(cb-ct)
			Pos[1] = 0
		end
		Currencies[i]:SetAnchorOffsets(Pos[1]-(cr-cl),Pos[2],Pos[1],Pos[2]+(cb-ct))
		Pos[1]= Pos[1]-(cr-cl)
	end
end

function ChargeSortedBags:LoadBagWindow()
  local BagCount = 4
  local Options = self.db.profile.general.optionsList.General
  for i = 1,BagCount do
    self.wndBags:FindChild("BagHolder"..tostring(i)):SetAnchorOffsets( 0, 0, Options.knSizeIconOption, Options.knSizeIconOption)
    local item = self.wndBags:FindChild("BagHolder"..tostring(i)):FindChild(tostring(i)):GetItem()
    if item ~= nil then
      local details = item:GetDetailedInfo()["tPrimary"]
      local quality = details["eQuality"]
      self.wndBags:FindChild("BagHolder"..tostring(i)):SetSprite(Qualitys[quality])
    end
  end
  self.wndBags:FindChild("BagGrid"):ArrangeChildrenHorz(0)
end

function ChargeSortedBags:SetWindows()
	local l , t, r, b = unpack(self.db.profile.general.tAnchorOffsetInv)
	self.wndMain:SetAnchorOffsets(l , t, r, b)
	local l2, t2, r2, b2 = unpack(self.db.profile.general.tAnchorOffsetOpt)
	self.wndOptions:SetAnchorOffsets(l2, t2, r2, b2)
  local l3, t3, r3, b3 = unpack(self.db.profile.general.tAnchorOffsetBag)
  self.wndBags:SetAnchorOffsets(l3, t3, r3, b3)
  local l4, t4, r4, b4 = unpack(self.db.profile.general.tAnchorOffsetSpl)
  self.wndSplitSlot:SetAnchorOffsets(l4, t4, r4, b4)

  local BG = self.wndMain:FindChild("BG")
  --Background
  BG:SetSprite(Designs[self.db.profile.general.optionsList.Design.BG])
  --Opactity
  BG:SetOpacity(self.db.profile.general.optionsList.Design.fOpacity)
  --Color
  BG:SetBGColor(self.db.profile.general.optionsList.Design.BGColor)
end

function ChargeSortedBags:OnScroll()
	self.wndMain:FindChild("BagGrid"):SetVScrollPos(self.scroll)
end


function ChargeSortedBags:OnWindowMoved( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	if self:Split(wndControl:GetName(),"_")[1] == "InventoryBag" then
		local old = self.db.profile.general.tAnchorOffsetInv
		local new = {wndControl:GetAnchorOffsets()}
		self.db.profile.general.tAnchorOffsetInv = new

		if (old[1]-old[3]) == (new[1]-new[3]) and (old[2]-old[4]) == (new[2]-new[4]) then
			return
		end
		self.db.profile.general.optionsList.General.knBagsWidth = (new[3]-new[1])
		self:ArrangeChildren()
		self:ArrangeCurrencies()
	end

	if wndControl:GetName() == "Options" then
		local new = {wndControl:GetAnchorOffsets()}
		self.db.profile.general.tAnchorOffsetOpt = new
	end

  if wndControl:GetName() == "BagWindow" then
		local new = {wndControl:GetAnchorOffsets()}
		self.db.profile.general.tAnchorOffsetBag = new
	end

  if wndControl:GetName() == "SplittSlot" then
		local new = {wndControl:GetAnchorOffsets()}
		self.db.profile.general.tAnchorOffsetSpl = new
	end
end


function ChargeSortedBags:OnOptionClick( wndHandler, wndControl, eMouseButton )
	if self.wndOptions:IsShown() then
		self.wndOptions:Show(false)
	else
		self.wndOptions:Show(true)
		self:LoadOptions()
	end
end

function ChargeSortedBags:AddNewBag( wndHandler, wndControl, eMouseButton )
	self.wndNewBag:Show(true)
	self.wndNewBag:ToFront()
	self.wndNewBag:FindChild("EditBox"):SetText("Name")
end


function ChargeSortedBags:UpdateSize()
	local Opt = self.db.profile.general.optionsList.General
	local BagGrid = self.wndMain:FindChild("BagGrid"):GetChildren()
	for i,j in pairs(BagGrid) do
		local Bag = j:FindChild("BagGrid"):GetChildren()
		for k,l in pairs(Bag) do
			l:SetAnchorOffsets(0,0,Opt.knSizeIconOption,Opt.knSizeIconOption)
		end
		j:FindChild("BagGrid"):ArrangeChildrenTiles(0)
	end
end


function ChargeSortedBags:OnClose( wndHandler, wndControl, eMouseButton )
	wndControl:GetParent():Close()
end

function ChargeSortedBags:OnBagsClick( wndHandler, wndControl, eMouseButton )
	self.wndBags:Show(true)
end

function ChargeSortedBags:AdjustNumbers(Bag,Slot)
	for i,j in pairs(Bag:GetChildren()) do
		if(i >= Slot) then
			j:SetName(tostring(i))
		end
	end
end


function ChargeSortedBags:OnSystemBeginDragDrop( wndSource, strType, iData )
	if strType ~= "DDBagItem" then return end
  self.wndMain:FindChild("SalvageIcon"):Show(true)

	local item = self.RealBag:GetItem(iData)
  if self:IsCustom(item) then
    for i,j in pairs(self.wndMain:FindChild("BagGrid"):GetChildren()) do
        j:FindChild("MouseBlocker"):Show(true)
    end
  else
    for i,j in pairs(self.wndMain:FindChild("BagGrid"):GetChildren()) do
      if self:IsCustomBag(j:GetName()) then
        j:FindChild("MouseBlocker"):Show(true)
      end
    end
  end
	self.DragDrop = item

	if item and item:CanSalvage() then
		self.DragDropSalvage = true
	else
		self.DragDropSalvage = false
	end

	Sound.Play(Sound.PlayUI45LiftVirtual)
end


function ChargeSortedBags:OnSystemEndDragDrop(strType, iData)
  for i,j in pairs(self.wndMain:FindChild("BagGrid"):GetChildren()) do
    j:FindChild("MouseBlocker"):Show(false)
  end
  self.wndMain:FindChild("SalvageIcon"):Show(false)
	if not self.wndMain or not self.wndMain:IsValid() or strType == "DDGuildBankItem" or strType == "DDWarPartyBankItem" or strType == "DDGuildBankItemSplitStack" then
		return -- TODO Investigate if there are other types
	end
	Sound.Play(Sound.PlayUI46PlaceVirtual)
end

function ChargeSortedBags:OnDragDropMouseBlocker(wndHandler, wndControl, nX, nY, wndSource, strType, nIndex)
	if strType == "DDBagItem" then
    local newBag = wndControl:GetParent():GetName()
    local NewIsCustom = self:IsCustomBag(newBag)
    self:RemoveItemFromCustomBag(self.DragDrop)
    if NewIsCustom then
      if self.db.profile.general.BagList[newBag] == nil then
        self.db.profile.general.BagList[newBag] = {}
      end
      table.insert(self.db.profile.general.BagList[newBag], self:FindSlotNumber(self.DragDrop))
    end
	end
	return false
end

function ChargeSortedBags:OnQueryDragDropMouseBlocker(wndHandler, wndControl, nX, nY, wndSource, strType, nIndex)
	if strType == "DDBagItem" then
		return Apollo.DragDropQueryResult.Accept
	end
	return Apollo.DragDropQueryResult.Ignore
end

function ChargeSortedBags:OnEndDragDropRealBag()
  self:LoadBags()
  self:LoadGrid()
  self:ArrangeChildren()
end

function ChargeSortedBags:OnBagDragDropCancel(wndHandler, wndControl, strType, nIndex, eReason)
	if strType ~= "DDBagItem" or eReason == Apollo.DragDropCancelReason.EscapeKey or eReason == Apollo.DragDropCancelReason.ClickedOnNothing then
		return false
	end

	if eReason == Apollo.DragDropCancelReason.ClickedOnWorld or eReason == Apollo.DragDropCancelReason.DroppedOnNothing then
		self:InvokeDeleteConfirmWindow(nIndex)
	end
	return false
end

function ChargeSortedBags:OnCurrencyChanged()
  self:LoadCurrencies()
end

function ChargeSortedBags:OnColumnChange(wndHandler)
	local Category = self.db.profile.general.optionsList.Category
	local name = wndHandler:GetParent():GetName()
	if wndHandler:GetName() == "Left" then
		if Category.ColumnFill[name] ~= nil then
			Category.ColumnFill[name] = Category.ColumnFill[name]-1
		end
		if Category.ColumnFill[name] ~= nil and Category.ColumnFill[name] <= 1 then
			Category.ColumnFill[name] = 1
			Category.ColumnFill[name] = nil
		end
	else
		if Category.ColumnFill[name] == nil then 
			Category.ColumnFill[name] = 2 
		else
			Category.ColumnFill[name]=Category.ColumnFill[name]+1
		end
		if Category.ColumnFill[name] ~= nil and Category.ColumnFill[name] > Category.columns then
			Category.ColumnFill[name] = Category.columns
		end
	end
	self:ArrangeChildren()
end

function ChargeSortedBags:OnShowArrowClick( wndHandler, wndControl, eMouseButton )
	local Bags = self.wndMain:FindChild("BagGrid"):GetChildren()
	if Bags ~= nil and #Bags ~= 0 then
		local show = Bags[1]:FindChild("Left"):IsShown()
		
		for i,j in pairs(Bags) do
			j:FindChild("Left"):Show(not show)
			j:FindChild("Right"):Show(not show)
		end
	end
end

-----------------------------------------------------------------------------------------------
-- Delete/Salvage Screen
-----------------------------------------------------------------------------------------------

function ChargeSortedBags:InvokeDeleteConfirmWindow(iData)
	local itemData = Item.GetItemFromInventoryLoc(iData)
	if itemData and not itemData:CanDelete() then
		return
	end
	self.wndDeleteConfirm:SetData(iData)
	self.wndDeleteConfirm:Invoke()
	self.wndDeleteConfirm:FindChild("DeleteBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.DeleteItem, iData)
	self.wndMain:FindChild("DragDropMouseBlocker"):Show(true)
	Sound.Play(Sound.PlayUI55ErrorVirtual)
end

function ChargeSortedBags:InvokeSalvageConfirmWindow(iData)
	local item = Item.GetItemFromInventoryLoc(iData)
	if item:DoesSalvageRequireKey() then
		local nKeyCount = GameLib.SalvageKeyCount()
		self.wndSalvageWithKeyConfirm:SetData(iData)
		self.wndSalvageWithKeyConfirm:Invoke()
		self.wndSalvageWithKeyConfirm:FindChild("SalvageBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.SalvageItem, iData)
		if nKeyCount == 0 then
			self.wndSalvageWithKeyConfirm:FindChild("Hologram:GetKeysBtn"):Show(StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.LockboxKey))
			self.wndSalvageWithKeyConfirm:FindChild("Hologram:SalvageBtn"):Show(false)
			self.wndSalvageWithKeyConfirm:FindChild("NoticeText"):SetText(Apollo.GetString("Inventory_SalvageNoKey"))
			self.wndSalvageWithKeyConfirm:FindChild("NoticeText"):SetTextColor("Orangered")
		else
			self.wndSalvageWithKeyConfirm:FindChild("Hologram:GetKeysBtn"):Show(false)
			self.wndSalvageWithKeyConfirm:FindChild("Hologram:SalvageBtn"):Show(true)
			self.wndSalvageWithKeyConfirm:FindChild("NoticeText"):SetText(String_GetWeaselString(Apollo.GetString("Inventory_ConfirmSalvageWithKeyNotice"), nKeyCount))
			self.wndSalvageWithKeyConfirm:FindChild("NoticeText"):SetTextColor("UI_TextHoloTitle")
		end
	else
		self.wndSalvageConfirm:SetData(iData)
		self.wndSalvageConfirm:Invoke()
		self.wndSalvageConfirm:FindChild("SalvageBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.SalvageItem, iData)
	end
	self.wndMain:FindChild("DragDropMouseBlocker"):Show(true)
	Sound.Play(Sound.PlayUI55ErrorVirtual)
end

-- TODO SECURITY: These confirmations are entirely a UI concept. Code should have a allow/disallow.
function ChargeSortedBags:OnDeleteCancel()
	self.wndDeleteConfirm:SetData(nil)
	self.wndDeleteConfirm:Close()
	self.wndMain:FindChild("DragDropMouseBlocker"):Show(false)
end

function ChargeSortedBags:OnSalvageCancel()
	self.wndSalvageConfirm:SetData(nil)
	self.wndSalvageConfirm:Close()
	self.wndMain:FindChild("DragDropMouseBlocker"):Show(false)
end

function ChargeSortedBags:OnDeleteConfirm()
	self:OnDeleteCancel()
end

function ChargeSortedBags:OnSalvageConfirm()
	Event_ShowTutorial(GameLib.CodeEnumTutorial.CharacterWindow)
	self:OnSalvageCancel()
end

function ChargeSortedBags:OnToggleSupplySatchel(wndHandler, wndControl)
	--ToggleTradeSkillsInventory()
	local tAnchors = {}
	tAnchors.nLeft, tAnchors.nTop, tAnchors.nRight, tAnchors.nBottom = self.wndMain:GetAnchorOffsets()
	Event_FireGenericEvent("ToggleTradeskillInventoryFromBag", tAnchors)
end

-----------------------------------------------------------------------------------------------
-- Salvage All
-----------------------------------------------------------------------------------------------

function ChargeSortedBags:OnSalvageAllBtn(wndHandler, wndControl)
	Event_FireGenericEvent("RequestSalvageAll", tAnchors)
end

function ChargeSortedBags:OnDragDropSalvage(wndHandler, wndControl, nX, nY, wndSource, strType, iData)
	if strType == "DDBagItem" and self.wndMain:FindChild("SalvageIcon"):IsShown() then
		self:InvokeSalvageConfirmWindow(iData)
	end
	return false
end

function ChargeSortedBags:OnQueryDragDropSalvage(wndHandler, wndControl, nX, nY, wndSource, strType, iData)
	if strType == "DDBagItem" and self.wndMain:FindChild("SalvageIcon"):IsShown() then
		return Apollo.DragDropQueryResult.Accept
	end
	return Apollo.DragDropQueryResult.Ignore
end

-----------------------------------------------------------------------------------------------
-- TrashCan
-----------------------------------------------------------------------------------------------
function ChargeSortedBags:OnDragDropTrash(wndHandler, wndControl, nX, nY, wndSource, strType, nIndex)
	if strType == "DDBagItem" then
		self:InvokeDeleteConfirmWindow(nIndex)
	end
	return false
end

function ChargeSortedBags:OnQueryDragDropTrash(wndHandler, wndControl, nX, nY, wndSource, strType, nIndex)
	if strType == "DDBagItem" then
		return Apollo.DragDropQueryResult.Accept
	end
	return Apollo.DragDropQueryResult.Ignore
end

function ChargeSortedBags:OnDragDropNotifyTrash(wndHandler, wndControl, bMe)
	if bMe then
		self.wndMain:FindChild("MenuBottom"):FindChild("Trashcan"):FindChild("ItemRunner"):Show(true)
	else
		self.wndMain:FindChild("MenuBottom"):FindChild("Trashcan"):FindChild("ItemRunner"):Show(false)
	end
end

function ChargeSortedBags:OnExitTrashIcon( wndHandler, wndControl, x, y )
  self.wndMain:FindChild("MenuBottom"):FindChild("Trashcan"):FindChild("ItemRunner"):Show(false)
end
