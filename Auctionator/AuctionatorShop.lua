
local addonName, addonTable = ...; 
local zc = addonTable.zc;
local zz = zc.md
local _
-----------------------------------------

Atr_SList = {}
Atr_SList.__index = Atr_SList

local SLITEMS_NUM_LINES = 15

local WEAPON = 1
local ARMOR  = 2

ATR_MAXNUM_ITEMS_ON_SHOPPING_LIST = 50

local gCurrentSList

local gTempShoppingList = nil

-----------------------------------------

function Atr_ShoppingListsInit ()

	if (AUCTIONATOR_SHOPPING_LISTS == nil) then
		AUCTIONATOR_SHOPPING_LISTS = {};
		Atr_SList.create (ZT("Recent Searches"), true);

		if (zc.IsEnglishLocale()) then
			local slist = Atr_SList.create ("Sample Shopping List #1");
			slist:AddItem ("Greater Cosmic Essence");
			slist:AddItem ("Infinite Dust");
			slist:AddItem ("Dream Shard");
			slist:AddItem ("Abyss Crystal");
		end
	end

	local num = #AUCTIONATOR_SHOPPING_LISTS;
	local x;
	
	for x = 1,num do
		setmetatable (AUCTIONATOR_SHOPPING_LISTS[x], Atr_SList);
	end
	
	for x = 1,num do
		local slist = AUCTIONATOR_SHOPPING_LISTS[x]
		
		if (slist.name == nil) then
			slist.name = "foo"
			zz ("null named shopping list found")
		end
	end
	
end

-----------------------------------------

function Atr_SList.create (name, isRecents, isTemporary)

	if (name == nil) then
		return
	end

	local slist = {};
	setmetatable (slist,Atr_SList);

	slist.name		= name;
	slist.items		= {};
	
	if (isRecents) then
		slist.isRecents = 1;
	end
	
	if (isTemporary) then
		gTempShoppingList  = slist
	else
		table.insert (AUCTIONATOR_SHOPPING_LISTS, slist)
	end
	
	local x
	for x = 1,#AUCTIONATOR_SHOPPING_LISTS do
		local slist = AUCTIONATOR_SHOPPING_LISTS[x]
		
		if (slist.name == nil) then
			slist.name = "foo"
			zz ("null named shopping list found")
		end
	end


	table.sort (AUCTIONATOR_SHOPPING_LISTS, Atr_SortSlists);
	
	CloseDropDownMenus();
	
	return slist;
end


-----------------------------------------

function Atr_SortSlists (x, y)

	if (x.isRecents) then return true; end;
	if (y.isRecents) then return false; end;

	return (string.lower(x.name) < string.lower(y.name));

end

-----------------------------------------

function Atr_SList.FindByName (name, options)

	local checkTempList = (options == nil or not options.skipTempList) 
	
	if (checkTempList and gTempShoppingList and zc.StringSame (gTempShoppingList.name, name)) then
		return gTempShoppingList
	end
	
	local num = #AUCTIONATOR_SHOPPING_LISTS;
	local x;
	
	for x = 1,num do
		if (zc.StringSame (AUCTIONATOR_SHOPPING_LISTS[x].name, name)) then
			return AUCTIONATOR_SHOPPING_LISTS[x];
		end
	end
end


-----------------------------------------

function Atr_SList:AddItem (itemName)

	if (itemName == "" or itemName == nil) then
		return;
	end

	if (self.isRecents) then
		table.insert (self.items, 1, itemName);
		
		while (#self.items > 50) do		-- max 50 items on recents list
			table.remove (self.items);
		end
	else
		table.insert (self.items, itemName);
		self.isSorted = false;
	end
end

-----------------------------------------

function Atr_SList:RemoveItem (itemName)

	local num = #self.items;
	local n;
	
	for n = 1,num do
		if (zc.StringSame (self.items[n], itemName)) then
			table.remove (self.items, n);
			return;
		end
	end

end

-----------------------------------------

function Atr_SList:Clear ()

	self.items = {}

end

-----------------------------------------

function Atr_DisplaySlist ()
	if (gCurrentSList) then
		gCurrentSList:DisplayX ();
	end
end



-----------------------------------------

function sortSlist (x, y)

	return (string.lower(x) < string.lower(y));

end

-----------------------------------------

function Atr_SList:DisplayX ()

	gCurrentSList = self;

	local currentPane = Atr_GetCurrentPane();

	if (not (self.isRecents or self.isSorted)) then
		self.isSorted = true;
		table.sort (self.items, sortSlist);
	end


	local numrows = #self.items;

	local line;							-- 1 through NN of our window to scroll
	local dataOffset;					-- an index into our data calculated from the scroll offset

	FauxScrollFrame_Update (Atr_Hlist_ScrollFrame, numrows, SLITEMS_NUM_LINES, 16);

	for line = 1,SLITEMS_NUM_LINES do

		currentPane.hlistScrollOffset = FauxScrollFrame_GetOffset (Atr_Hlist_ScrollFrame);
		
		dataOffset = line + currentPane.hlistScrollOffset;

		local lineEntry = _G["AuctionatorHEntry"..line];

		lineEntry:SetID(dataOffset);

		local slItem = self.items[dataOffset];
		
		if (dataOffset <= numrows and slItem) then

			local lineEntry_text = _G["AuctionatorHEntry"..line.."_EntryText"];

			lineEntry_text:SetText		(Atr_AbbrevItemName (slItem));

			if (Atr_IsShoppingListSearch (slItem)) then
				lineEntry_text:SetTextColor	(.7,.6,.5);
			else
				lineEntry_text:SetTextColor	(.6,.6,.6);
			end
			
			if (currentPane.activeSearch.origSearchText ~= "" and zc.StringSame (slItem , currentPane.activeSearch.origSearchText)) then
				lineEntry:SetButtonState ("PUSHED", true);
			elseif (currentPane.activeSearch.searchText == "" and zc.StringSame (slItem , Atr_Search_Box:GetText())) then
				lineEntry:SetButtonState ("PUSHED", true);
			else
				lineEntry:SetButtonState ("NORMAL", false);
			end

			lineEntry:Show();
		else
			lineEntry:Hide();
		end
	end


end

-----------------------------------------

function Atr_SList:FindItemIndex (itemName)

	local num = #self.items;
	local n;
	
	for n = 1,num do
		if (zc.StringSame (itemName, self.items[n])) then
			return n;
		end
	end
	
	return 0;

end

-----------------------------------------

function Atr_SList:GetNumItems ()

	return #self.items
end

-----------------------------------------

function Atr_SList:GetNthItemName (n)

	if (n <= #self.items) then
		return self.items[n];
	end
	
	return nil;
end


-----------------------------------------

function Atr_SList:IsItemOnList (itemName)

	return (self:FindItemIndex(itemName) > 0);
	
end

-----------------------------------------

function Atr_Search_Onclick ()

	local currentPane = Atr_GetCurrentPane();

	local searchText = Atr_Search_Box:GetText();

	if (string.gsub(searchText, "%s+", "") == "" or searchText == nil) then return end

	Atr_Search_Button:Disable();
	Atr_Adv_Search_Button:Disable();
	Atr_Buy1_Button:Disable();
	Atr_AddToSListButton:Disable();
	Atr_RemFromSListButton:Disable();
	
	Atr_ClearAll();
	
	currentPane:DoSearch (searchText);

	Atr_ClearHistory();
end

-----------------------------------------

function Atr_AddToRecents (searchText)

	local recentsList = AUCTIONATOR_SHOPPING_LISTS[1];
	if (recentsList) then

		local isRecentsShown = (gCurrentSList == recentsList);
		
		local n = recentsList:FindItemIndex(searchText);

		if (n > 14 or (not isRecentsShown and n > 0)) then
			table.remove (recentsList.items, n);
		end
		
		n = recentsList:FindItemIndex(searchText);
		
		if (n == 0) then
			recentsList:AddItem (searchText);
		end
		
		if (isRecentsShown) then
			FauxScrollFrame_SetOffset (Atr_Hlist_ScrollFrame, 0);
			Atr_Hlist_ScrollFrame:SetVerticalScroll(0);
		end
		
	end

end

-----------------------------------------

function Atr_SetSearchText (searchText)

	Atr_Search_Box:SetText (searchText)
	Atr_Search_Box:ClearFocus()

end

-----------------------------------------

function Atr_Shop_OnFinishScan ()
	
	local currentPane = Atr_GetCurrentPane();

	local searchText = currentPane.activeSearch.origSearchText;

	Atr_SetSearchText (searchText);

	local shplist = Atr_GetShoppingListFromSearchText (searchText)
	
	if (shplist and shplist == gTempShoppingList) then
		return  -- don't add to recents list
	end
	
	Atr_AddToRecents(searchText)

	if (#currentPane.activeScan.sortedData > 0) then
		currentPane.currIndex = 1;
	end

	currentPane.UINeedsUpdate = true;
	
	Atr_Search_Button:Enable();
	Atr_Adv_Search_Button:Enable();
end


-----------------------------------------

function Atr_DropDownSL_OnShow (self)

	local curIndex = 1;
	
	if (gCurrentSList) then
		local x;
		for x = 1,#AUCTIONATOR_SHOPPING_LISTS do
			if (gCurrentSList == AUCTIONATOR_SHOPPING_LISTS[x]) then
				curIndex = x;
				break;
			end
		end
	end


	UIDropDownMenu_Initialize		(self, Atr_DropDownSL_Initialize);
	UIDropDownMenu_SetSelectedValue	(self, curIndex);
	UIDropDownMenu_SetWidth			(self, 150);
	UIDropDownMenu_JustifyText		(self, "CENTER");
end

-----------------------------------------

function Atr_DropDownSL_Initialize(self)

	local num = #AUCTIONATOR_SHOPPING_LISTS;
	local x;
	
	for x = 1,num do
	
		local slist = AUCTIONATOR_SHOPPING_LISTS[x];
		Atr_Dropdown_AddPick (self, slist.name,	x, Atr_DropDownSL_OnClick);
	end

end

-----------------------------------------

function Atr_DropDownSL_OnClick(info)
	
	UIDropDownMenu_SetSelectedValue (info.owner, info.value);
	
	gCurrentSList = AUCTIONATOR_SHOPPING_LISTS[info.value];
	
	Atr_SetUINeedsUpdate();

end

-----------------------------------------

function Atr_SEntryOnClick (self)

	local entryIndex	= self:GetID();

	local itemName = gCurrentSList.items[entryIndex];
	
	if (itemName) then
		Atr_SetSearchText (itemName);

		if (IsAltKeyDown()) then
			Atr_GetCurrentPane():ClearSearch();
			Atr_RemFromSListOnClick();
		else
			Atr_Search_Onclick ();
		end
		
		Atr_Shop_UpdateUI();
	end
	
--	gCurrentSList:DisplayX();		-- for the highlight
end



-----------------------------------------

function Atr_RenameSList(index, newname)

	if (newname == nil or newname == "") then
		return
	end

	local oldname = AUCTIONATOR_SHOPPING_LISTS[index].name
	
	AUCTIONATOR_SHOPPING_LISTS[index].name = newname
	
	-- in case it's the currently selected one
	
	local curIndex = UIDropDownMenu_GetSelectedValue(Atr_DropDownSL)
	if (curIndex and curIndex > 0) then
		UIDropDownMenu_SetText (Atr_DropDownSL, AUCTIONATOR_SHOPPING_LISTS[curIndex].name)	-- needed to fix bug in UIDropDownMenu
	end
	
	-- run thru all the lists and fix up any lists that contain this list
	
	local n
	for n = 1, #AUCTIONATOR_SHOPPING_LISTS do
		local slist = AUCTIONATOR_SHOPPING_LISTS[n]
		
		local foundIndex = slist:FindItemIndex("{ "..oldname.." }")
		if (foundIndex > 0) then
			slist.items[foundIndex] = "{ "..newname.." }"
		end
	
		if (n == curIndex) then
			slist:DisplayX()
			Atr_SetUINeedsUpdate();
		end
	end
end

-----------------------------------------

local function FinishCreateNewSList(text)

	local slist = Atr_SList.create(text);

	local num = #AUCTIONATOR_SHOPPING_LISTS;
	local n;
	
	for n = 1,num do
		if (AUCTIONATOR_SHOPPING_LISTS[n] == slist) then
			UIDropDownMenu_SetSelectedValue(Atr_DropDownSL, n);
			UIDropDownMenu_SetText (Atr_DropDownSL, text);	-- needed to fix bug in UIDropDownMenu
			slist:DisplayX();
			Atr_SetUINeedsUpdate();
			break;
		end
	end
end



-----------------------------------------

StaticPopupDialogs["ATR_NEW_SHOPPING_LIST"] = {
	text = "",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 32,
	OnAccept = function(self)
		local text = self.editBox:GetText();
		FinishCreateNewSList (text);
	end,
	EditBoxOnEnterPressed = function(self)
		local text = self:GetParent().editBox:GetText();
		FinishCreateNewSList (text);
		self:GetParent():Hide();
	end,
	OnShow = function(self)
		self.editBox:SetText("");
		self.editBox:SetFocus();
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};


-----------------------------------------

function Atr_NewSlist_OnClick ()

	StaticPopupDialogs["ATR_NEW_SHOPPING_LIST"].text = ZT("Name for your new shopping list");

	StaticPopup_Show("ATR_NEW_SHOPPING_LIST");
	
end

-----------------------------------------

function Atr_MngSLists_OnClick ()

	InterfaceOptionsFrame_OpenToCategory ("Shopping Lists");

	local slist
	
	local currentPane = Atr_GetCurrentPane()

	if (gCurrentSList) then
		if (not gCurrentSList.isRecents) then
			slist = gCurrentSList
		elseif (currentPane and currentPane.activeSearch) then
			local searchText = strtrim (currentPane.activeSearch.searchText, "{}")
			slist = Atr_SList.FindByName (strtrim (searchText))
		end
	end
	
	if (slist) then
		local n
		for n=2,#AUCTIONATOR_SHOPPING_LISTS do
			if (AUCTIONATOR_SHOPPING_LISTS[n] == slist) then
				Atr_ShpListsEntry_Select(n)
				Atr_ShpListsEntry_ScrollToShow(n)
				return
			end
		end
	end	
end


-----------------------------------------

function Atr_AddToSListOnClick ()

	local currentPane = Atr_GetCurrentPane();

	if (gCurrentSList) then
		if (#gCurrentSList.items >= ATR_MAXNUM_ITEMS_ON_SHOPPING_LIST) then
			Atr_Error_Text:SetText (string.format (ZT("You may have no more than\n\n%d items on a shopping list."), ATR_MAXNUM_ITEMS_ON_SHOPPING_LIST));
			Atr_Error_Frame.withMask = 1;
			Atr_Error_Frame:Show ();
		else		
			gCurrentSList:AddItem (Atr_Search_Box:GetText());
			Atr_SetUINeedsUpdate();
		end
	end

end

-----------------------------------------

function Atr_RemFromSListOnClick ()

	local currentPane = Atr_GetCurrentPane();

	if (gCurrentSList) then
		gCurrentSList:RemoveItem (Atr_Search_Box:GetText());
		Atr_SetUINeedsUpdate();

	end

end

-----------------------------------------

function Atr_SrchSList_OnClick ()

	if (gCurrentSList) then
		local searchText = "{ "..gCurrentSList.name.." }";

		Atr_SetSearchText(searchText)
		Atr_Search_Onclick()
	end
end

-----------------------------------------

function Atr_ShpList_Validate ()

	if (gCurrentSList and getmetatable (gCurrentSList) ~= Atr_SList) then
		zc.msg_badErr ("gCurrentSList bad metatable; type gCurrentSList: ", type (gCurrentSList))
	end
	
	zz ("num shopping lists: ", #AUCTIONATOR_SHOPPING_LISTS)
	
	local x, slist
	for x = 1,#AUCTIONATOR_SHOPPING_LISTS do
	
		slist = AUCTIONATOR_SHOPPING_LISTS[x]
		
		if (slist == nil) then
			zz ("slist["..x.."] is nil")
		elseif (getmetatable (slist) ~= Atr_SList) then
			zc.msg_badErr ("slist["..x.."] bad metatable; type: ", type (slist))
		else
			zz ("slist["..x.."] is valid")
		
		end
		
	end
end

-----------------------------------------

function Atr_Shop_UpdateUI ()

	local currentPane = Atr_GetCurrentPane();

	Atr_AddToSListButton:Disable();
	Atr_RemFromSListButton:Disable();
	Atr_SrchSListButton:Disable();
	
	if (gCurrentSList == nil) then
		Atr_ShpList_SetToRecents()
	end

	if (getmetatable (gCurrentSList) ~= Atr_SList) then
		Atr_ShpList_Validate()
	end

	if (gCurrentSList and getmetatable (gCurrentSList) == Atr_SList) then		-- somehow gCurrentSList:DisplayX is sometimes nil - not sure why yet
		gCurrentSList:DisplayX ();
	
		local iName = Atr_Search_Box:GetText();

		if (gCurrentSList:IsItemOnList (iName)) then
			Atr_RemFromSListButton:Enable();
		elseif (iName ~= "" and iName ~= nil and gCurrentSList ~= AUCTIONATOR_SHOPPING_LISTS[1]) then
			Atr_AddToSListButton:Enable();
		end
		
		if (gCurrentSList ~= AUCTIONATOR_SHOPPING_LISTS[1]) then
			Atr_SrchSListButton:Enable();
		end
		
	end

	Atr_SaveThisList_Button:Hide()
	Atr_Back_Button:Hide()
	
	if (currentPane.activeSearch:NumScans() > 1 and not currentPane:IsScanNil()) then
		Atr_Back_Button:Show()
	elseif (gTempShoppingList) then
		local listWithSameName = Atr_SList.FindByName (gTempShoppingList.name, { skipTempList=true } )
	
		if (gTempShoppingList == currentPane.activeSearch.shplist and #gTempShoppingList.items > 1 and listWithSameName == nil) then
			Atr_SaveThisList_Button:Show()
		end
	end
	
end


-----------------------------------------

function Atr_ShpList_SetToRecents()

	gCurrentSList = AUCTIONATOR_SHOPPING_LISTS[1]
	
	UIDropDownMenu_SetSelectedValue(Atr_DropDownSL, 1);
	UIDropDownMenu_SetText (Atr_DropDownSL, gCurrentSList.name);	-- needed to fix bug in UIDropDownMenu

end

-----------------------------------------

function Atr_Onclick_SaveTempList()

	if (gTempShoppingList) then
		table.insert (AUCTIONATOR_SHOPPING_LISTS, gTempShoppingList)
		table.sort (AUCTIONATOR_SHOPPING_LISTS, Atr_SortSlists);
		Atr_ShpList_SetToRecents()
		Atr_AddToRecents("{ "..gTempShoppingList.name.." }")		-- nice visual confirmation
		gTempShoppingList = nil
		Atr_SetUINeedsUpdate()
	end
end

-----------------------------------------

function Atr_Adv_Search_Onclick ()

	Atr_Search_Box:ClearFocus()

	local searchText = Atr_Search_Box:GetText();

	Atr_Adv_Search_Dialog:Show();

	if (Atr_IsCompoundSearch (searchText)) then
		local queryString, itemClass, itemSubclass, minLevel, maxLevel, minItemLevel, maxItemLevel, qualityIndex = Atr_ParseCompoundSearch (searchText);
		
		Atr_AS_Searchtext:SetText (queryString);
		
		Atr_Dropdown_Refresh (Atr_ASDD_Rarity);
		UIDropDownMenu_SetSelectedValue (Atr_ASDD_Rarity, qualityIndex);
		Atr_Dropdown_Refresh (Atr_ASDD_Class);
		UIDropDownMenu_SetSelectedValue (Atr_ASDD_Class, itemClass);
		Atr_Dropdown_Refresh (Atr_ASDD_Subclass);
		UIDropDownMenu_SetSelectedValue (Atr_ASDD_Subclass, itemSubclass);

		if (minLevel == nil) then minLevel = ""; end
		if (maxLevel == nil) then maxLevel = ""; end
		
		Atr_AS_Minlevel:SetText (minLevel);
		Atr_AS_Maxlevel:SetText (maxLevel);

		if (minItemLevel == nil) then minItemLevel = ""; end
		if (maxItemLevel == nil) then maxItemLevel = ""; end
		
		Atr_AS_MinItemlevel:SetText (minItemLevel);
		Atr_AS_MaxItemlevel:SetText (maxItemLevel);

	else
		Atr_AS_Searchtext:SetText (searchText);
	end

	Atr_AS_Searchtext:SetFocus()
	
end

-----------------------------------------

function Atr_ASDD_Rarity_OnShow (self)

	UIDropDownMenu_Initialize		(self, Atr_ASDD_Rarity_Initialize);
	UIDropDownMenu_SetSelectedValue	(self, "-------");
end

-----------------------------------------

function Atr_ASDD_Rarity_Initialize (self)

	Atr_Dropdown_AddPick (Atr_ASDD_Rarity, "-------" , "-------" , Atr_ASDD_Rarity_OnClick);
	Atr_Dropdown_AddPick (Atr_ASDD_Rarity, "Poor"	 , "Poor"	 , Atr_ASDD_Rarity_OnClick);
	Atr_Dropdown_AddPick (Atr_ASDD_Rarity, "Common"	 , "Common"  , Atr_ASDD_Rarity_OnClick);
	Atr_Dropdown_AddPick (Atr_ASDD_Rarity, "Uncommon", "Uncommon", Atr_ASDD_Rarity_OnClick);
	Atr_Dropdown_AddPick (Atr_ASDD_Rarity, "Rare"	 , "Rare"	 , Atr_ASDD_Rarity_OnClick);
	Atr_Dropdown_AddPick (Atr_ASDD_Rarity, "Epic"	 , "Epic"    , Atr_ASDD_Rarity_OnClick);
	
end

-----------------------------------------

function Atr_ASDD_Rarity_OnClick (info)

	UIDropDownMenu_SetSelectedValue(info.owner, info.value);

end

-----------------------------------------


function Atr_ASDD_Class_OnShow (self)

	UIDropDownMenu_Initialize		(self, Atr_ASDD_Class_Initialize);
	UIDropDownMenu_SetSelectedValue	(self, 0);
end

-----------------------------------------

function Atr_ASDD_Class_Initialize (self)

	local itemClasses = Atr_GetAuctionClasses();
	local n;
	
	Atr_Dropdown_AddPick (Atr_ASDD_Subclass, "-------", 0);

	if (#itemClasses > 0) then
		local text;
		for n, text in pairs(itemClasses) do
			Atr_Dropdown_AddPick (self, text, n, Atr_ASDD_Class_OnClick);
		end
	end
	
end

-----------------------------------------

function Atr_ASDD_Class_OnClick (info)

	UIDropDownMenu_SetSelectedValue(info.owner, info.value);

	Atr_Dropdown_Refresh (Atr_ASDD_Subclass);

end


-----------------------------------------


function Atr_ASDD_Subclass_OnShow (self)

	UIDropDownMenu_Initialize		(self, Atr_ASDD_Subclass_Initialize);
	UIDropDownMenu_SetSelectedValue (self, 0);
end


-----------------------------------------

function Atr_ASDD_Subclass_Initialize (self)

	local itemClass = UIDropDownMenu_GetSelectedValue (Atr_ASDD_Class);

	Atr_Dropdown_AddPick (Atr_ASDD_Subclass, "-------", 0);

	if (itemClass) then

		local itemSubclasses = Atr_GetAuctionSubclasses(itemClass);
		local n;
		
		if (#itemSubclasses > 0) then
			local text;
			for n, text in pairs(itemSubclasses) do

				Atr_Dropdown_AddPick (Atr_ASDD_Subclass, text, n);
			end
		end
	end
	
	if (itemClass and (itemClass == WEAPON or itemClass == ARMOR)) then
		Atr_AS_ILevRange_Label:Show()
		Atr_AS_ILevRange_Dash:Show()
		Atr_AS_MinItemlevel:Show()
		Atr_AS_MaxItemlevel:Show()
	else
		Atr_AS_ILevRange_Label:Hide()
		Atr_AS_ILevRange_Dash:Hide()
		Atr_AS_MinItemlevel:Hide()
		Atr_AS_MaxItemlevel:Hide()
	end
	
end


-----------------------------------------

function Atr_Adv_Search_Reset()

	Atr_AS_Searchtext:SetText ("");
	
	Atr_Dropdown_Refresh (Atr_ASDD_Rarity);
	UIDropDownMenu_SetSelectedValue (Atr_ASDD_Rarity, 0);
	Atr_Dropdown_Refresh (Atr_ASDD_Class);
	UIDropDownMenu_SetSelectedValue (Atr_ASDD_Class, 0);
	Atr_Dropdown_Refresh (Atr_ASDD_Subclass);
	UIDropDownMenu_SetSelectedValue (Atr_ASDD_Subclass, 0);

	Atr_AS_Minlevel:SetText ("");
	Atr_AS_Maxlevel:SetText ("");
	Atr_AS_MinItemlevel:SetText ("");
	Atr_AS_MaxItemlevel:SetText ("");
end

-----------------------------------------

function Atr_Adv_Search_Do()

	local itemRarity = UIDropDownMenu_GetSelectedValue (Atr_ASDD_Rarity)
	if (zc.StringContains(itemRarity, "-")) then itemRarity = nil end
	

	local itemClass		= UIDropDownMenu_GetSelectedValue (Atr_ASDD_Class);
	local itemSublass	= UIDropDownMenu_GetSelectedValue (Atr_ASDD_Subclass);

	local itemClassList		= Atr_GetAuctionClasses();
	local itemSubclassList	= Atr_GetAuctionSubclasses(itemClass);
	
	local searchText = itemClassList[itemClass];

	if (searchText == nil) then
		zc.msg_anm ("|cffff0000Error getting itemClass from menu|r.  itemClass = ", itemClass)
		Atr_Adv_Search_Dialog:Hide()
		return
	end

	if (itemSublass > 0) then
		searchText = searchText.."/"..itemSubclassList[itemSublass];
	end
	
	local minLevel		= Atr_AS_Minlevel:GetNumber ();
	local maxLevel		= Atr_AS_Maxlevel:GetNumber ();
	local text			= Atr_AS_Searchtext:GetText();

	if (maxLevel > 0 and minLevel == 0) then
		minLevel = 1;
	end
	
	if (minLevel > 0)		then	searchText = searchText.."/"..minLevel;				end
	if (maxLevel > 0)		then	searchText = searchText.."/"..maxLevel;				end

	if (itemClass and (itemClass == WEAPON or itemClass == ARMOR)) then
		local minItemLevel	= Atr_AS_MinItemlevel:GetNumber()
		local maxItemLevel	= Atr_AS_MaxItemlevel:GetNumber()
		if (minItemLevel > 0)	then	searchText = searchText.."/i"..minItemLevel;		end
		if (maxItemLevel > 0)	then	searchText = searchText.."/i"..maxItemLevel;		end
	end
	
	if (text ~= "")			then	searchText = searchText.."/"..text;					end

	-- handle category only search
	
	if (not zc.StringContains (searchText, "/")) then
		searchText = searchText.."/"
	end
	
	if (itemRarity ~= nil) then searchText = itemRarity.."/"..searchText end
	
	Atr_SetSearchText(searchText);

	Atr_Search_Onclick();

	Atr_Adv_Search_Dialog:Hide();

end

-----------------------------------------

local gSLgather
local gSuspendGathering = false
local gSLpermittedUser
local gShpListShareRequester
local gRequestSentTime = 0

-----------------------------------------

StaticPopupDialogs["ATR_SL_REQUEST_SHARING"] = {
	text = "",
	button1 = "Allow",
	button2 = "Deny",
	OnAccept = function(self)
		gSLpermittedUser = gShpListShareRequester
		Atr_Send_ShoppingListData (gShpListShareRequester)
		SendAddonMessage ("ATR", "SLREQ_", "WHISPER", gShpListShareRequester)
		return
	end,
	OnCancel = function(self)
		gSLpermittedUser = nil
		SendAddonMessage ("ATR", "SLPERM_DENIED_", "WHISPER", gShpListShareRequester)
		return
	end,
	OnShow = function(self)
		local s = string.format (ZT("|cffffbb00%s|r\nwould like to share Auctionator shopping lists."), gShpListShareRequester);
		self.text:SetText (s);
	end,
	timeout = 20,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};

-----------------------------------------

StaticPopupDialogs["ATR_SL_REQUEST_DENIED"] = {
	text = "",
	button1 = "OK",
	OnAccept = function(self)
		gSLpermittedUser = nil
		return
	end,
	OnShow = function(self)
		local uname = zc.Val (gSLpermittedUser, "The player")
		gSLpermittedUser = nil
		
		local s = string.format (ZT("|cffffbb00%s|r\nhas turned down your request\nto share shopping lists."), uname);
		self.text:SetText (s);
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};


-----------------------------------------

function Atr_OnChatMsgAddon_ShoppingListCmds (prefix, msg, distribution, sender)

--zz (prefix, msg, distribution, sender)


	if (zc.StringStartsWith (msg, "SLPERM_REQ_")) then
	
		gSLpermittedUser		= nil
		gShpListShareRequester	= sender

		SendAddonMessage ("ATR", "SLREQACK_", "WHISPER", gShpListShareRequester)

		StaticPopup_Show ("ATR_SL_REQUEST_SHARING")
	end

	if (zc.StringStartsWith (msg, "SLREQACK_")) then
		gRequestSentTime = 0
	end

	if (zc.StringStartsWith (msg, "SLPERM_DENIED_")) then
		StaticPopup_Show("ATR_SL_REQUEST_DENIED")
	end
	
	if (zc.StringStartsWith (msg, "SLREQ_") and gSLpermittedUser and sender == gSLpermittedUser) then
		Atr_Send_ShoppingListData (gSLpermittedUser)
	end

	if (zc.StringStartsWith (msg, "SLSTART_")) then
		gSLgather = ""
	end
	
	if (zc.StringStartsWith (msg, "SLDATA_")) then
		local line = string.sub(msg, 8)
		if (zc.StringStartsWith (line, "***")) then
			local slistName = strtrim (string.sub (line, 4))
			gSuspendGathering = (Atr_SList.FindByName (slistName) ~= nil)
			zc.msg_anm ("You already have a list called|cffffbb00", slistName, "|r")
			line = "\n"..line
		end
		if (not gSuspendGathering) then
			gSLgather = gSLgather..line.."\n"
		end
	end

	if (zc.StringStartsWith (msg, "SLEND_")) then
		Atr_OnClick_ShpList_Import()
		Atr_ShpList_Edit_Text:SetText(gSLgather)
	end

end

-----------------------------------------

function Atr_Send_ShoppingListData (toWhom)

	local n
	local text = ""
	
	for n = 2,#AUCTIONATOR_SHOPPING_LISTS do
		text = text..Atr_ShpList_Export_GetText (AUCTIONATOR_SHOPPING_LISTS[n])
	end

	SendAddonMessage ("ATR", "SLSTART_", "WHISPER", toWhom)

	local lines = { strsplit("\n", text) }

	local existingListNames_Text = ""
	local existingListNames_Num  = 0
	
	if (lines ~= nil) then
		local n
		for n = 1,#lines do
			local line = strtrim(lines[n])
			if (line ~= "") then
				SendAddonMessage ("ATR", "SLDATA_"..line, "WHISPER", toWhom)
			end
		end
	end

	SendAddonMessage ("ATR", "SLEND_", "WHISPER", toWhom)

end

-----------------------------------------

function Atr_Send_ShareShoppingListRequest (target)

	if (UnitIsPlayer(target)) then
		gSLpermittedUser = target   -- sending this request implicitly grants permission to the target
		SendAddonMessage ("ATR", "SLPERM_REQ_", "WHISPER", gSLpermittedUser)
		gRequestSentTime = time()
	else
		zc.msg_anm ("You can only share lists with another player")
	end
end

-----------------------------------------

function Atr_Update_ShareRequest ()

	if (gRequestSentTime == 0 or time() - gRequestSentTime < 5) then
		return
	end

	zc.msg_anm ("|cffffbb00", gSLpermittedUser, "|ris either not an Auctionator user or is running a version that doesn't support sharing")

	gSLpermittedUser = nil
	gRequestSentTime = 0
	
end



