
local addonName, addonTable = ...
local zc = addonTable.zc
local zz = zc.md

local ATR_BUY_NULL						= 0;
local ATR_BUY_QUERY_SENT				= 1;
local ATR_BUY_JUST_BOUGHT				= 2;
local ATR_BUY_CHECKING_PAGE_FOR_MATCHES	= 3;
local ATR_BUY_WAITING_FOR_AH_CAN_SEND	= 4;
local ATR_BUY_PAGE_WITH_ITEM_LOADED		= 5;

local gBuyState = ATR_BUY_NULL;

-----------------------------------------

local gAtr_Buy_BuyoutPrice;
local gAtr_Buy_ItemName;
local gAtr_Buy_ItemLink;
local gAtr_Buy_StackSize;
local gAtr_Buy_NumBought;
local gAtr_Buy_NumUserWants;
local gAtr_Buy_MaxCanBuy;
local gAtr_Buy_CurPage;
local gAtr_Buy_Waiting_Start;
local gAtr_Buy_Query;
local gAtr_Buy_Pass;
local gAtr_NextMatchIndex;
local gAtr_Buy_MatchList = {};

-----------------------------------------

function Atr_Buy_Debug1 (...)

	if (gBuyState == ATR_BUY_NULL)										then asstr = "ATR_BUY_NULL"; end;
	if (gBuyState == ATR_BUY_QUERY_SENT)								then asstr = "ATR_BUY_QUERY_SENT"; end;
	if (gBuyState == ATR_BUY_CHECKING_PAGE_FOR_MATCHES)					then asstr = "ATR_BUY_CHECKING_PAGE_FOR_MATCHES"; end;
	if (gBuyState == ATR_BUY_JUST_BOUGHT)								then asstr = "ATR_BUY_JUST_BOUGHT"; end;
	if (gBuyState == ATR_BUY_WAITING_FOR_AH_CAN_SEND)					then asstr = "ATR_BUY_WAITING_FOR_AH_CAN_SEND"; end;
	if (gBuyState == ATR_BUY_PAGE_WITH_ITEM_LOADED)						then asstr = "ATR_BUY_PAGE_WITH_ITEM_LOADED"; end;

	if (gBuyState ~= ATR_BUY_NULL) then
		zc.md (asstr, "curpage: ", gAtr_Buy_CurPage, "   numBought: ", gAtr_Buy_NumBought, "  ", ...);
	end
	
end

-----------------------------------------

function Atr_ClearBuyState()

	gBuyState = ATR_BUY_NULL;

end


-----------------------------------------

local function Atr_Set_BuyConfirm_Progress ()

	local numAvail = gAtr_Buy_MaxCanBuy - gAtr_Buy_NumBought;
	
	local s;
	
	if (gAtr_Buy_StackSize == 1) then
		s = string.format (ZT("%d available"), numAvail);
	elseif (numAvail == 1) then
		s = string.format (ZT("1 stack available"), numAvail);
	else
		s = string.format (ZT("%d stacks available"), numAvail);
	end
	
	Atr_Buy_NumAvail_Text:SetText (s);
	Atr_Buy_Continue_Text:SetText (string.format (ZT("%d of %d bought so far"), gAtr_Buy_NumBought, gAtr_Buy_NumUserWants));
	--Atr_Buy_Continue_Text:SetText (string.format (ZT("%d bought so far"), gAtr_Buy_NumBought));

end

-----------------------------------------

local FocusTime;
function Atr_Buy1_Onclick ()

	if (not Atr_IsSelectedTab_Current()) then
		return;
	end
	
	gAtr_Buy_Query			= Atr_NewQuery();
	gAtr_Buy_NumUserWants	= -1;
	gAtr_Buy_NumBought		= 0;
	
	local currentPane = Atr_GetCurrentPane();
	
	local scan = currentPane.activeScan;
	
	local data = scan.sortedData[currentPane.currIndex];

	gAtr_Buy_BuyoutPrice	= data.buyoutPrice;
	gAtr_Buy_ItemName		= scan.itemName;
	gAtr_Buy_ItemLink		= scan.itemLink;
	gAtr_Buy_StackSize		= data.stackSize;
	gAtr_Buy_MaxCanBuy		= data.count;
	gAtr_Buy_Pass			= 1;		-- - first pass
	gAtr_NextMatchIndex		= 0;
	
	if gAtr_Buy_StackSize > 1 then
		Atr_Buy_Confirm_ItemPriceText:Show()
		Atr_Buy_Confirm_ItemPriceText:SetText("Price per item: ")	
		Atr_Buy_Confirm_ItemPrice:Show()
		MoneyFrame_Update("Atr_Buy_Confirm_ItemPrice", zc.round(data.itemPrice))
		Atr_Buy_Confirm_Item_Total:Show();
		Atr_Buy_Confirm_Max_Text:SetText (gAtr_Buy_StackSize.." items in total");
	else
		Atr_Buy_Confirm_ItemPriceText:Hide()
		Atr_Buy_Confirm_ItemPrice:Hide()
		Atr_Buy_Confirm_Item_Total:Hide();
	end

	Atr_Buy_Confirm_ItemName:SetText (gAtr_Buy_ItemName.." |cCCCCCCCCx"..gAtr_Buy_StackSize);
	Atr_Buy_Confirm_Numstacks:SetNumber (1);
	Atr_Buy_Confirm_Max_Text:SetText (ZT("max")..": "..gAtr_Buy_MaxCanBuy);
	
	Atr_Buy_Part1:Show();
	Atr_Buy_Part2:Hide();

	--Atr_Buy_Continue_Text:Hide();

	Atr_Buy_NumAvail_Text:SetText (string.format (ZT("%d available"), gAtr_Buy_MaxCanBuy));
	Atr_Buy_Continue_Text:SetText (string.format (ZT("%d bought so far"), 0));
	
	Atr_Set_BuyConfirm_Progress();
	
	Atr_Buy_Confirm_OKBut:SetText ("Buy")
	--Atr_Buy_Confirm_OKBut:SetText (ZT("Buy One"))
	Atr_Buy_Confirm_OKBut:Disable();
	Atr_Buy_Confirm_CancelBut:SetText (ZT("Cancel"))
	Atr_Buy_Confirm_Frame:Show();
	Atr_Buy_Confirm_Numstacks:SetFocus();
	FocusTime = time();
	Atr_Buy_Confirm_Update();

--zc.md (scan.searchText, " ", scan.itemName, "  data.minpage ", data.minpage);

	if (zc.StringSame (scan.searchText, scan.itemName) and data.minpage ~= nil) then
		Atr_Buy_QueueQuery(data.minpage);
	else
		Atr_Buy_QueueQuery(0);
	end


end

-----------------------------------------

function Atr_Buy_QueueQuery (page)

	gAtr_Buy_CurPage = page;

--zc.md ("Queuing query for page ", page);

	gBuyState = ATR_BUY_WAITING_FOR_AH_CAN_SEND;
	gAtr_Buy_Waiting_Start = time();
	
	Atr_Buy_SendQuery();		-- give it a shot
end

-----------------------------------------

function Atr_Buy_SendQuery ()

	gAtr_NextMatchIndex = 0;
			
	if (CanSendAuctionQuery()) then

		gBuyState = ATR_BUY_QUERY_SENT;

		Atr_Buy_ClearMatchList();
		
		local queryString = zc.UTF8_Truncate (gAtr_Buy_ItemName,63);	-- attempting to reduce number of disconnects

		-- QueryAuctionItems (queryString, "", "", nil, 0, 0, gAtr_Buy_CurPage, nil, nil);
		-- last parameter, qualityIndex, causes auction to fail when 0 is used.
		QueryAuctionItems (queryString, nil, nil, 0, 0, 0, gAtr_Buy_CurPage, false, -1);
	end
		
end

-----------------------------------------

function Atr_Buy_Idle ()

	local elapsed = -1;
	if (gAtr_Buy_Waiting_Start) then
		elapsed = time() - gAtr_Buy_Waiting_Start;
	end
	
--	Atr_Buy_Debug1 ("elapsed", elapsed, "   pass: ", gAtr_Buy_Pass);

	if (gBuyState == ATR_BUY_WAITING_FOR_AH_CAN_SEND) then
	
		Atr_Buy_Confirm_OKBut:Disable();
		Atr_Buy_Confirm_OKBut:SetText (ZT("Scanning..."))

		if (GetMoney() < gAtr_Buy_BuyoutPrice) then
			Atr_Buy_Cancel (ZT("You do not have enough gold\n\nto make any more purchases."));
		elseif (time() - gAtr_Buy_Waiting_Start > 10) then
			Atr_Buy_Cancel (ZT("Auction House timed out"));
		else	
			Atr_Buy_SendQuery ();
		end

	-- elseif (gBuyState == ATR_BUY_PAGE_WITH_ITEM_LOADED) then

		-- if (Atr_Buy_PageHasMatch())	then		-- check if any left that haven't been bought
		
			-- Atr_Buy_Confirm_OKBut:Enable();

			-- if (gAtr_Buy_NumBought > 0) then
				-- Atr_Buy_Confirm_OKBut:SetText (ZT("Buy Another"))
				-- Atr_Buy_Confirm_CancelBut:SetText (ZT("Done"))
			-- else
				-- Atr_Buy_Confirm_OKBut:SetText (ZT("Buy One"))
				-- Atr_Buy_Confirm_CancelBut:SetText (ZT("Cancel"))
			-- end
		
		-- else
			-- local queueIf = (time() - gAtr_Buy_Waiting_Start > 2);		-- wait a few seconds for Auction List to Update after buys
		
			-- Atr_Buy_NextPage_Or_Cancel (queueIf);
		-- end
			
	-- end
	
	elseif (gBuyState == ATR_BUY_JUST_BOUGHT) then

		-- zc.msg_pink ("ATR_BUY_JUST_BOUGHT: ",  time() - gAtr_Buy_Waiting_Start);

		local queueIf = (time() - gAtr_Buy_Waiting_Start > 2);		-- wait a few seconds for Auction List to Update after buys
		
		Atr_Buy_NextPage_Or_Cancel (queueIf);
		
	end
 
end

-----------------------------------------

function Atr_Buy_OnAuctionUpdate()

	if (gBuyState == ATR_BUY_QUERY_SENT) then

		
		-- if (gAtr_Buy_Query:CheckForDuplicatePage(gAtr_Buy_CurPage)) then
		
			-- Atr_Buy_QueueQuery (gAtr_Buy_CurPage);
			
		-- else
			-- gBuyState = ATR_BUY_CHECKING_PAGE_FOR_MATCHES;

			-- Atr_Buy_BuildMatchList();
			
			-- if (#gAtr_Buy_MatchList > 0) then
				-- gBuyState = ATR_BUY_PAGE_WITH_ITEM_LOADED;
			-- else
				-- Atr_Buy_NextPage_Or_Cancel();
			-- end
		-- end
		
		Atr_Buy_CheckForMatches ();

	end

	return (gBuyState ~= ATR_BUY_NULL);
end

-----------------------------------------


function Atr_Buy_CheckForMatches ()

	gBuyState = ATR_BUY_PROCESSING_QUERY_RESULTS;
	
	if (gAtr_Buy_Query:CheckForDuplicatePage(gAtr_Buy_CurPage)) then
		Atr_Buy_QueueQuery (gAtr_Buy_CurPage);
		return;
	end

	local isLastPage = gAtr_Buy_Query:IsLastPage(gAtr_Buy_CurPage);
	
	local numMatches = Atr_Buy_CountMatches();
	
	if (numMatches > 0) then		-- update the confirmation screen
	
		Atr_Buy_Confirm_OKBut:Enable();
		Atr_Buy_Confirm_OKBut:SetText ("Buy")

		if (gAtr_Buy_NumUserWants ~= -1) then	
			Atr_Set_BuyConfirm_Progress()
			--Atr_Buy_Continue_Text:SetText (string.format (ZT("%d of %d bought so far"), gAtr_Buy_NumBought, gAtr_Buy_NumUserWants));
			-- Atr_Buy_Part1:Hide();
			-- Atr_Buy_Part2:Show();
			Atr_Buy_Confirm_OKBut:SetText (ZT("Continue"))
		end

	else
		Atr_Buy_NextPage_Or_Cancel();
	end

end


-----------------------------------------


function Atr_Buy_BuyMatches ()
	return Atr_Buy_CountMatches (true);
end


-----------------------------------------


function Atr_Buy_CountMatches (andBuy)

	local numMatches		= 0;
	local numBoughtThisPage	= 0;
	local i = 1;

	while (true) do
	
		local name, _, count, _, _, _, _, _, buyoutPrice = GetAuctionItemInfo ("list", i);

		if (name == nil) then
			break;
		end

		if (zc.StringSame (name, gAtr_Buy_ItemName) and buyoutPrice == gAtr_Buy_BuyoutPrice and count == gAtr_Buy_StackSize) then
			
			numMatches = numMatches + 1;
			
			if (andBuy and gAtr_Buy_NumUserWants > gAtr_Buy_NumBought) then
				PlaceAuctionBid("list", i, gAtr_Buy_BuyoutPrice);
				
				numBoughtThisPage  = numBoughtThisPage + 1;
				gAtr_Buy_NumBought = gAtr_Buy_NumBought + 1;
				Atr_Buy_Continue_Text:SetText (string.format (ZT("%d of %d bought so far"), gAtr_Buy_NumBought, gAtr_Buy_NumUserWants));
			end
		end

		i = i + 1;
	end

	return numMatches, numBoughtThisPage;
end


-----------------------------------------


function Atr_Buy_PageHasMatch ()

	return (#gAtr_Buy_MatchList > 0);
end

-----------------------------------------

function Atr_Buy_ClearMatchList()

	gAtr_Buy_MatchList = {};

end


-----------------------------------------

function Atr_Buy_BuildMatchList ()

	local i 		= 1;
	local x			= 1;
	local numInList = Atr_GetNumAuctionItems ("list");

	Atr_Buy_ClearMatchList();

	for i = 1,numInList do
	
		if (Atr_DoesAuctionMatch ("list", i, gAtr_Buy_ItemName, gAtr_Buy_BuyoutPrice, gAtr_Buy_StackSize)) then
			gAtr_Buy_MatchList[x] = i;
			x = x + 1;
		end
	end

end

-----------------------------------------

-- function Atr_Buy_BuyNextOnPage ()

	-- local numMatches		= 0;
	-- local numBoughtThisPage	= 0;
	-- local i;
	-- local x;
	
	-- local numInMatchList = #gAtr_Buy_MatchList;

	-- for x = numInMatchList,1,-1 do
	
		-- i = gAtr_Buy_MatchList[x];
		
		-- table.remove (gAtr_Buy_MatchList);
		
		-- if (Atr_DoesAuctionMatch ("list", i, gAtr_Buy_ItemName, gAtr_Buy_BuyoutPrice, gAtr_Buy_StackSize)) then
			
			-- PlaceAuctionBid("list", i, gAtr_Buy_BuyoutPrice);
				
			-- numBoughtThisPage  = numBoughtThisPage + 1;
			-- gAtr_Buy_NumBought = gAtr_Buy_NumBought + 1;

			-- Atr_Set_BuyConfirm_Progress();
			-- Atr_Buy_Continue_Text:Show();
		
			-- break;
		-- end

	-- end

	-- return numBoughtThisPage;
-- end



-----------------------------------------

--local abcu_num = -1;

function Atr_Buy_Confirm_Update ()

	local num = Atr_Buy_Confirm_Numstacks:GetNumber();
	
	-- if (num ~= abcu_num) then	
		-- abcu_num = num;
	-- end
	Atr_Buy_Confirm_Numstacks:SetNumber(Atr_Buy_Confirm_Numstacks:GetNumber());
	if num > gAtr_Buy_MaxCanBuy then
		Atr_Buy_Confirm_Numstacks:SetNumber(gAtr_Buy_MaxCanBuy);
		num = gAtr_Buy_MaxCanBuy;
	elseif num < 1 then	
		Atr_Buy_Confirm_Numstacks:SetNumber(1);
		num = 1;
		FocusTime = time()
	end
	Atr_Buy_Confirm_Item_Total:SetText(gAtr_Buy_StackSize * num.." items in total");

	if (num == 1) then
		Atr_Buy_Confirm_Text2:SetText (ZT("stack for"));
	else
		Atr_Buy_Confirm_Text2:SetText (ZT("stacks for"));
	end

	MoneyFrame_Update ("Atr_Buy_Confirm_TotalPrice",  gAtr_Buy_BuyoutPrice * num);

	if (FocusTime + 0.1) > time() then
		Atr_Buy_Confirm_Numstacks:HighlightText();
	end

end

-----------------------------------------

function Atr_Buy_NextPage_Or_Cancel ( queueIf )

	if (Atr_Buy_IsComplete()) then
		
		Atr_Buy_Cancel();
		
		local currentPane = Atr_GetCurrentPane();

		if (currentPane.activeScan and #currentPane.activeScan.sortedData == 0) then
			Atr_Onclick_Back();
		end
		
	elseif (queueIf == nil or queueIf == true) then
	
		if (Atr_Buy_IsFirstPassComplete()) then
			gAtr_Buy_Pass = 2;
			Atr_Buy_QueueQuery(0);
		else
			Atr_Buy_QueueQuery(gAtr_Buy_CurPage + 1);
		end
		
	--else	
		--AuctionatorSubtractFromScan (gAtr_Buy_ItemLink, gAtr_Buy_StackSize, gAtr_Buy_BuyoutPrice, gAtr_Buy_NumBought);
		
	end
end

-----------------------------------------

function Atr_Buy_IsComplete ()

	if (gAtr_Buy_NumUserWants ~= -1 and gAtr_Buy_NumUserWants <= gAtr_Buy_NumBought) then
		return true;
	end
	
	if (gAtr_Buy_MaxCanBuy <= gAtr_Buy_NumBought) then
		return true;
	end

	if (gAtr_Buy_Query:IsLastPage(gAtr_Buy_CurPage) and gAtr_Buy_Pass == 2) then
		return true;
	end

	return false;

end

-----------------------------------------

function Atr_Buy_IsFirstPassComplete ()

	if (gAtr_Buy_Query:IsLastPage(gAtr_Buy_CurPage) and gAtr_Buy_Pass == 1) then
		return true;
	end

	return false;

end

-----------------------------------------

function Atr_Buy_Confirm_OK ()

	-- local numJustBought = Atr_Buy_BuyNextOnPage()

	-- if (numJustBought > 0) then

		-- AuctionatorSubtractFromScan (gAtr_Buy_ItemLink, gAtr_Buy_StackSize, gAtr_Buy_BuyoutPrice, numJustBought);
		-- Atr_Buy_Confirm_OKBut:Disable();
	-- end

	if (gAtr_Buy_NumUserWants == -1) then
		local numToBuy = Atr_Buy_Confirm_Numstacks:GetNumber();

		if (numToBuy > gAtr_Buy_MaxCanBuy) then
			Atr_Error_Text:SetText (string.format (ZT("You can buy at most %d auctions"), gAtr_Buy_MaxCanBuy));
			Atr_Error_Frame:Show ();
			return;
		end
		
		gAtr_Buy_NumUserWants = numToBuy;
	end
	
	if gAtr_Buy_NumUserWants > 1 then
		Atr_Buy_Part1:Hide();
		Atr_Buy_Part2:Show();
	end
	
	local _, numJustBought = Atr_Buy_BuyMatches ();

	if (numJustBought > 0) then	
		AuctionatorSubtractFromScan (gAtr_Buy_ItemLink, gAtr_Buy_StackSize, gAtr_Buy_BuyoutPrice, gAtr_Buy_NumBought);
		gBuyState = ATR_BUY_JUST_BOUGHT;
		gAtr_Buy_Waiting_Start = time();
		Atr_Buy_Confirm_OKBut:Disable();
		Atr_Buy_Confirm_OKBut:SetText (ZT("Scanning..."))
	else
		Atr_Buy_NextPage_Or_Cancel();
	end
	
end
	

-----------------------------------------

function Atr_Buy_Cancel (msg)
	
	gBuyState = ATR_BUY_NULL;

	Atr_Buy_Confirm_Frame:Hide();
	
	Atr_Error_Display(msg);
end