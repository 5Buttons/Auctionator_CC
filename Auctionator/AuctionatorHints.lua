
local addonName, addonTable = ...; 
local zc = addonTable.zc;
local zz = zc.md;
local _

-----------------------------------------

local auctionator_orig_GameTooltip_OnTooltipAddMoney;

-----------------------------------------

function auctionator_GameTooltip_OnTooltipAddMoney (self, cost, maxcost)

	if (AUCTIONATOR_V_TIPS == 1) then
		return;
	end

	auctionator_orig_GameTooltip_OnTooltipAddMoney (self, cost, maxcost);
end

-----------------------------------------

function Atr_Hook_OnTooltipAddMoney()
	auctionator_orig_GameTooltip_OnTooltipAddMoney = GameTooltip_OnTooltipAddMoney;
	GameTooltip_OnTooltipAddMoney = auctionator_GameTooltip_OnTooltipAddMoney;
end

------------------------------------------------

local function Atr_AppendHint (results, price, text, volume)

	if (price and price > 0) then
		local e = {};
		e.price		= price;
		e.text		= text;
		e.volume	= volume;
		
		table.insert (results, e);
	end

end

------------------------------------------------

function Atr_BuildHints (itemName, itemLink)

	local results = {};

	if (itemLink == nil and itemName == nil) then
		return results;
	end

	-- The Undermine Journal
	
	if (TUJMarketInfo) then
	
		local id = zc.ItemIDfromLink (itemLink);

		local tujData = {}
		TUJMarketInfo (tonumber(id), tujData)

		local stddevRaw = tujData['marketstddev']
		
		local stddev = "???"
		if (stddevRaw) then
			stddev = zc.priceToString (stddevRaw)
		end
		
		Atr_AppendHint (results, tujData['marketmedian'],  ZT("UnderMine Journal (median)"));
		Atr_AppendHint (results, tujData['marketaverage'], ZT("UnderMine Journal (average) standard deviation "..stddev));
	end

	-- Wowecon

	if (Wowecon and Wowecon.API) then
	
		local priceG, volG, priceS, volS;
		
		if (itemLink) then
			priceG, volG = Wowecon.API.GetAuctionPrice_ByLink (itemLink, Wowecon.API.GLOBAL_PRICE)
			priceS, volS = Wowecon.API.GetAuctionPrice_ByLink (itemLink, Wowecon.API.SERVER_PRICE)
		else
			priceG, volG = Wowecon.API.GetAuctionPrice_ByName (itemName, Wowecon.API.GLOBAL_PRICE)
			priceS, volS = Wowecon.API.GetAuctionPrice_ByName (itemName, Wowecon.API.SERVER_PRICE)
		end
		
		Atr_AppendHint (results, priceG, ZT("Wowecon global price"), volG);
		Atr_AppendHint (results, priceS, ZT("Wowecon server price"), volS);
		
	end
	
	if (itemLink) then
	
		-- GoingPrice Wowhead
		
		local id = zc.ItemIDfromLink (itemLink);
		
		id = tonumber(id);

		if (GoingPrice_Wowhead_Data and GoingPrice_Wowhead_Data[id] and GoingPrice_Wowhead_SV._index) then
			local index = GoingPrice_Wowhead_SV._index["Buyout price"];

			if (index ~= nil) then
				local price = GoingPrice_Wowhead_Data[id][index];
			
				Atr_AppendHint (results, price, "GoingPrice - Wowhead");
			end
		end

		-- GoingPrice Allakhazam
		
		if (GoingPrice_Allakhazam_Data and GoingPrice_Allakhazam_Data[id] and GoingPrice_Allakhazam_SV._index) then
			local index = GoingPrice_Allakhazam_SV._index["Median"];

			if (index ~= nil) then
				local price = GoingPrice_Allakhazam_Data[id][index];
			
				Atr_AppendHint (results, price, "GoingPrice - Allakhazam");
			end
		end
	end
	
	return results;

end

-----------------------------------------

function Atr_SetMFcolor (frameName, blue)

	local goldButton   = _G[frameName.."GoldButton"];
	local silverButton = _G[frameName.."SilverButton"];
	local copperButton = _G[frameName.."CopperButton"];

	if (blue) then
		goldButton:SetNormalFontObject(NumberFontNormalRightATRblue);
		silverButton:SetNormalFontObject(NumberFontNormalRightATRblue);
		copperButton:SetNormalFontObject(NumberFontNormalRightATRblue);
	else
		goldButton:SetNormalFontObject(NumberFontNormalRight);
		silverButton:SetNormalFontObject(NumberFontNormalRight);
		copperButton:SetNormalFontObject(NumberFontNormalRight);
	end
	
end


-----------------------------------------

function Atr_GetAuctionPrice (item)  -- itemName or itemID

	local itemName;
	
	if (type (item) == "number") then
		itemName = GetItemInfo (item);
	else
		itemName = item;
	end

	if (itemName == nil) then
		return nil;
	end

	if (gAtr_ScanDB and type (gAtr_ScanDB) ~= "table") then
		zc.msg_badErr ("Scanning history database appears to be corrupt")
		zc.msg_badErr ("gAtr_ScanDB:", gAtr_ScanDB)
		return nil
	end
	
	if ((type(gAtr_ScanDB) == "table") and gAtr_ScanDB[itemName] and gAtr_ScanDB[itemName].mr) then
		return gAtr_ScanDB[itemName].mr;
	end
	
	return nil;
end	

-----------------------------------------

local function Atr_CalcTextWid (price)

	local wid = 15;
	
	if (price > 9)			then wid = wid + 12;	end;
	if (price > 99)			then wid = wid + 44;	end;
	if (price > 999)		then wid = wid + 12;	end;
	if (price > 9999)		then wid = wid + 44;	end;
	if (price > 99999)		then wid = wid + 12;	end;
	if (price > 999999)		then wid = wid + 12;	end;
	if (price > 9999999)	then wid = wid + 12;	end;
	if (price > 99999999)	then wid = wid + 12;	end;
	
	return wid;
end

-----------------------------------------

local function Atr_CalcTTpadding (price1, price2)

	local padding = "";

	if (price1 and price2) then
		local vpwidth = Atr_CalcTextWid (price1);
		local apwidth = Atr_CalcTextWid (price2);

		local padlen = math.floor ((apwidth - vpwidth)/6);
		local k;
		
		for k = 1,padlen do
			padding = padding.." ";
		end
	end

	return padding;

end

-----------------------------------------

local UNCOMMON	= 2;
local RARE		= 3;
local EPIC		= 4;

local WEAPON = 1;
local ARMOR  = 2;

local LESSER_MAGIC		= 10938;
local GREATER_MAGIC		= 10939;
local STRANGE_DUST		= 10940;

local SMALL_GLIMMERING	= 10978;
local LESSER_ASTRAL		= 10998;

local GREATER_ASTRAL	= 11082;
local SOUL_DUST			= 11083;
local LARGE_GLIMMERING	= 11084;

local LESSER_MYSTIC		= 11134;
local GREATER_MYSTIC	= 11135;
local VISION_DUST		= 11137;
local SMALL_GLOWING		= 11138;
local LARGE_GLOWING		= 11139;

local LESSER_NETHER		= 11174;
local GREATER_NETHER	= 11175;
local DREAM_DUST		= 11176;
local SMALL_RADIANT		= 11177;
local LARGE_RADIANT		= 11178;

local SMALL_BRILLIANT	= 14343;
local LARGE_BRILLIANT	= 14344;

local LESSER_ETERNAL	= 16202;
local GREATER_ETERNAL	= 16203;
local ILLUSION_DUST		= 16204;

local NEXUS_CRYSTAL		= 20725;

local ARCANE_DUST		= 22445;
local GREATER_PLANAR	= 22446;
local LESSER_PLANAR		= 22447;
local SMALL_PRISMATIC	= 22448;
local LARGE_PRISMATIC	= 22449;
local VOID_CRYSTAL		= 22450;

local DREAM_SHARD		= 34052;
local SMALL_DREAM		= 34053;

local INFINITE_DUST		= 34054;
local GREATER_COSMIC	= 34055;
local LESSER_COSMIC		= 34056;
local ABYSS_CRYSTAL		= 34057;

local engDEnames = {};

engDEnames [LESSER_MAGIC]		= "Lesser Magic Essence";
engDEnames [GREATER_MAGIC]		= "Greater Magic Essence";
engDEnames [STRANGE_DUST]		= "Strange Dust";

engDEnames [SMALL_GLIMMERING]	= "Small Glimmering Shard";
engDEnames [LESSER_ASTRAL]		= "Lesser Astral Essence";

engDEnames [GREATER_ASTRAL]		= "Greater Astral Essence";
engDEnames [SOUL_DUST]			= "Soul Dust";
engDEnames [LARGE_GLIMMERING]	= "Large Glimmering Essence";

engDEnames [LESSER_MYSTIC]		= "Lesser Mystic Essence";
engDEnames [GREATER_MYSTIC]		= "Greater Mystic Essence";
engDEnames [VISION_DUST]		= "Vision Dust";
engDEnames [SMALL_GLOWING]		= "Small Glowing Shard";
engDEnames [LARGE_GLOWING]		= "Large Glowing Shard";

engDEnames [LESSER_NETHER]		= "Lesser Nether Essence";
engDEnames [GREATER_NETHER]		= "Greater Nether Essence";
engDEnames [DREAM_DUST]			= "Dream Dust";
engDEnames [SMALL_RADIANT]		= "Small Radiant";
engDEnames [LARGE_RADIANT]		= "Large Radiant";

engDEnames [SMALL_BRILLIANT]	= "Small Brilliant Shard";
engDEnames [LARGE_BRILLIANT]	= "Large Brilliant Shard";

engDEnames [LESSER_ETERNAL]		= "Lesser Eternal Essence";
engDEnames [GREATER_ETERNAL]	= "Greater Eternal Essence";
engDEnames [ILLUSION_DUST]		= "Illusion Dust";

engDEnames [NEXUS_CRYSTAL]		= "Nexus Crystal";

engDEnames [ARCANE_DUST]		= "Arcane Dust";
engDEnames [GREATER_PLANAR]		= "Greater Planar Essence";
engDEnames [LESSER_PLANAR]		= "Lesser Planar Essence";
engDEnames [SMALL_PRISMATIC]	= "Small Prismatic Shard";
engDEnames [LARGE_PRISMATIC]	= "Large Prismatic Shard";
engDEnames [VOID_CRYSTAL]		= "Void Crystal";

engDEnames [DREAM_SHARD]		= "Dream Shard";
engDEnames [SMALL_DREAM]		= "Small Dream Shard";

engDEnames [INFINITE_DUST]		= "Infinite Dust";
engDEnames [GREATER_COSMIC]		= "Greater Cosmic Essence";
engDEnames [LESSER_COSMIC]		= "Lesser Cosmic Essence";
engDEnames [ABYSS_CRYSTAL]		= "Abyss Crystal";



local dustsAndEssences = {};

tinsert (dustsAndEssences, LESSER_MAGIC)
tinsert (dustsAndEssences, GREATER_MAGIC)
tinsert (dustsAndEssences, STRANGE_DUST)

tinsert (dustsAndEssences, SMALL_GLIMMERING)
tinsert (dustsAndEssences, LESSER_ASTRAL)

tinsert (dustsAndEssences, GREATER_ASTRAL)
tinsert (dustsAndEssences, SOUL_DUST)
tinsert (dustsAndEssences, LARGE_GLIMMERING)

tinsert (dustsAndEssences, LESSER_MYSTIC)
tinsert (dustsAndEssences, GREATER_MYSTIC)
tinsert (dustsAndEssences, VISION_DUST)
tinsert (dustsAndEssences, SMALL_GLOWING)
tinsert (dustsAndEssences, LARGE_GLOWING)

tinsert (dustsAndEssences, LESSER_NETHER)
tinsert (dustsAndEssences, GREATER_NETHER)
tinsert (dustsAndEssences, DREAM_DUST)
tinsert (dustsAndEssences, SMALL_RADIANT)
tinsert (dustsAndEssences, LARGE_RADIANT)

tinsert (dustsAndEssences, SMALL_BRILLIANT)
tinsert (dustsAndEssences, LARGE_BRILLIANT)

tinsert (dustsAndEssences, LESSER_ETERNAL)
tinsert (dustsAndEssences, GREATER_ETERNAL)
tinsert (dustsAndEssences, ILLUSION_DUST)

tinsert (dustsAndEssences, NEXUS_CRYSTAL)

tinsert (dustsAndEssences, ARCANE_DUST)
tinsert (dustsAndEssences, GREATER_PLANAR)
tinsert (dustsAndEssences, LESSER_PLANAR)
tinsert (dustsAndEssences, SMALL_PRISMATIC)
tinsert (dustsAndEssences, LARGE_PRISMATIC)
tinsert (dustsAndEssences, VOID_CRYSTAL)

tinsert (dustsAndEssences, DREAM_SHARD)
tinsert (dustsAndEssences, SMALL_DREAM)

tinsert (dustsAndEssences, INFINITE_DUST)
tinsert (dustsAndEssences, GREATER_COSMIC)
tinsert (dustsAndEssences, LESSER_COSMIC)
tinsert (dustsAndEssences, ABYSS_CRYSTAL)

gAtr_dustCacheIndex = 1;

local DUST_CACHE_READY_FOR_NEXT  = 0;
local DUST_CACHE_WAITING_ON_PREV = 1;

local dustCacheState = DUST_CACHE_READY_FOR_NEXT;

local dustCacheNotFound = 0;
local dustCacheFound = 0;
-----------------------------------------

function Atr_GetNextDustIntoCache()		-- make sure all the dusts and essences are in the RAM cache
										
	if (gAtr_dustCacheIndex == 0 or AtrScanningTooltip == nil) then
		return;
	end

	local itemID		= dustsAndEssences[gAtr_dustCacheIndex];
	local itemString	= "item:"..itemID..":0:0:0:0:0:0:0";
	
	local itemName, itemLink = GetItemInfo(itemString);
	
	if (itemLink == nil and dustCacheState == DUST_CACHE_READY_FOR_NEXT) then
		dustCacheState = DUST_CACHE_WAITING_ON_PREV;
		AtrScanningTooltip:SetHyperlink(itemString);
		local _, link = GetItemInfo(itemString);
--		zc.md ("pulling "..itemString.." into the local cache   ", dustCacheState);
		dustCacheNotFound = dustCacheNotFound + 1;
	end

	if (itemLink) then
--		zc.md (itemLink.." is in RAM cache");
		dustCacheFound = dustCacheFound + 1;
		dustCacheState = DUST_CACHE_READY_FOR_NEXT;
		gAtr_dustCacheIndex = gAtr_dustCacheIndex + 1;
		
		if (gAtr_dustCacheIndex > #dustsAndEssences) then
			gAtr_dustCacheIndex = 0;		-- finished
--			zc.md ("num items pulled into memory: ", dustCacheNotFound, "out of", dustCacheFound);
		end
	end
end

-----------------------------------------

local deItemNames = {};

local function Atr_GetDEitemName (itemID)

	if (deItemNames[itemID] == nil) then
		local itemName = GetItemInfo (itemID);
		if (itemName == nil) then
			zc.md ("defaulting to english DE mat name: "..engDEnames [itemID]);
			return engDEnames [itemID];
		end
		
		deItemNames[itemID] = itemName;
	end
	
	return deItemNames[itemID];

end

-----------------------------------------

function Atr_GetAuctionPriceDE (itemID)  -- same as Atr_GetAuctionPrice but understands that some "lesser" essences are convertible with "greater"

	local lesserPrice;
	local greaterPrice;
	
	if (itemID == LESSER_CEL) then
		lesserPrice  = Atr_GetAuctionPrice (Atr_GetDEitemName (LESSER_CEL));
		greaterPrice = Atr_GetAuctionPrice (Atr_GetDEitemName (GREATER_CEL));
	end
	
	if (itemID == LESSER_COSMIC) then
		lesserPrice  = Atr_GetAuctionPrice (Atr_GetDEitemName (LESSER_COSMIC));
		greaterPrice = Atr_GetAuctionPrice (Atr_GetDEitemName (GREATER_COSMIC));
	end
	
	if (itemID == LESSER_PLANAR) then
		lesserPrice  = Atr_GetAuctionPrice (Atr_GetDEitemName (LESSER_PLANAR));
		greaterPrice = Atr_GetAuctionPrice (Atr_GetDEitemName (GREATER_PLANAR));
	end
	
	if (lesserPrice ~= nil and greaterPrice ~= nil and lesserPrice * 3 > greaterPrice) then
		return math.floor (greaterPrice / 3);
	end
	
	return Atr_GetAuctionPrice (Atr_GetDEitemName (itemID));
end

-----------------------------------------

local deTable = {};

-----------------------------------------

local function deKey (itemType, itemRarity)
	local s = tostring(itemType).."_"..itemRarity
	return s;
end

-----------------------------------------

local function DEtableInsert(t, info)

	local entry = {};

	local x, i, n;
	
	entry[1]	= info[1];
	entry[2]	= info[2];
	
	n = 3;
	
	for x = 3,#info,3 do
		local nums = info[x+1];
		if (type(nums) == "number") then
			entry[n]   = info[x];
			entry[n+1] = info[x+1];
			entry[n+2] = info[x+2];
			n = n + 3;
		else
			for i = nums[1],nums[2] do
				entry[n]   = info[x]/(nums[2]-nums[1]+1);
				entry[n+1] = i;
				entry[n+2] = info[x+2];
				n = n + 3;				
			end
		end
	end
	
	table.insert (t, entry);

end


-----------------------------------------

function Atr_InitDETable()


	-- UNCOMMON (GREEN) ARMOR

	deTable[deKey(ARMOR, UNCOMMON)] = {};
	
	local t = deTable[deKey(ARMOR, UNCOMMON)];
	
	
	DEtableInsert (t, {5, 15,		80, {1,2}, STRANGE_DUST,	20, {1,2}, LESSER_MAGIC});
	DEtableInsert (t, {16, 20,		75, {2,3}, STRANGE_DUST,	20, {1,2}, GREATER_MAGIC,	5, 1, SMALL_GLIMMERING});
	DEtableInsert (t, {21, 25,		75, {4,6}, STRANGE_DUST,	15, {1,2}, LESSER_ASTRAL,	10, 1, SMALL_GLIMMERING});
	DEtableInsert (t, {26, 30,		75, {1,2}, SOUL_DUST,		20, {1,2}, GREATER_ASTRAL,	5, 1, LARGE_GLIMMERING});
	DEtableInsert (t, {31, 35,		75, {2,5}, SOUL_DUST,		20, {1,2}, LESSER_MYSTIC,	5, 1, SMALL_GLOWING});
	DEtableInsert (t, {36, 40,		75, {1,2}, VISION_DUST,		20, {1,2}, GREATER_MYSTIC,	5, 1, LARGE_GLOWING});
	DEtableInsert (t, {41, 45,		75, {2,5}, VISION_DUST,		20, {1,2}, LESSER_NETHER,	5, 1, SMALL_RADIANT});
	DEtableInsert (t, {46, 50,		75, {1,2}, DREAM_DUST,		20, {1,2}, GREATER_NETHER,	5, 1, LARGE_RADIANT});
	DEtableInsert (t, {51, 55,		75, {2,5}, DREAM_DUST,		20, {1,2}, LESSER_ETERNAL,	5, 1, SMALL_BRILLIANT});
	DEtableInsert (t, {56, 60,		75, {1,2}, ILLUSION_DUST,	20, {1,2}, GREATER_ETERNAL,	5, 1, LARGE_BRILLIANT});
	DEtableInsert (t, {61, 65,		75, {2,5}, ILLUSION_DUST,	20, {2,3}, GREATER_ETERNAL,	5, 1, LARGE_BRILLIANT});
	DEtableInsert (t, {66, 80,		75, {1,3}, ARCANE_DUST,		22, {1,3}, LESSER_PLANAR,	3, 1, SMALL_PRISMATIC});
	DEtableInsert (t, {81, 99,		75, {2,3}, ARCANE_DUST,		22, {2,3}, LESSER_PLANAR,	3, 1, SMALL_PRISMATIC});
	DEtableInsert (t, {100, 120,	75, {2,5}, ARCANE_DUST,		22, {1,2}, GREATER_PLANAR,	3, 1, LARGE_PRISMATIC});
	DEtableInsert (t, {121, 151,	75, {1,3}, INFINITE_DUST,	22, {1,2}, LESSER_COSMIC,	3, 1, SMALL_DREAM});
	DEtableInsert (t, {152, 200,	75, {4,7}, INFINITE_DUST,	22, {1,2}, GREATER_COSMIC,	3, 1, DREAM_SHARD});

	-- UNCOMMON (GREEN) WEAPONS

	deTable[deKey(WEAPON, UNCOMMON)] = {};
	
	local t = deTable[deKey(WEAPON, UNCOMMON)];

	DEtableInsert (t, {6, 15,		20, {1,2}, STRANGE_DUST,	80, {1,2}, LESSER_MAGIC});
	DEtableInsert (t, {16, 20,		20, {2,3}, STRANGE_DUST,	75, {1,2}, GREATER_MAGIC,	5, 1, SMALL_GLIMMERING});
	DEtableInsert (t, {21, 25,		15, {4,6}, STRANGE_DUST,	75, {1,2}, LESSER_ASTRAL,	10, 1, SMALL_GLIMMERING});
	DEtableInsert (t, {26, 30,		20, {1,2}, SOUL_DUST,		75, {1,2}, GREATER_ASTRAL,	5, 1, LARGE_GLIMMERING});
	DEtableInsert (t, {31, 35,		20, {2,5}, SOUL_DUST,		75, {1,2}, LESSER_MYSTIC,	5, 1, SMALL_GLOWING});
	DEtableInsert (t, {36, 40,		20, {1,2}, VISION_DUST,		75, {1,2}, GREATER_MYSTIC,	5, 1, LARGE_GLOWING});
	DEtableInsert (t, {41, 45,		20, {2,5}, VISION_DUST,		75, {1,2}, LESSER_NETHER,	5, 1, SMALL_RADIANT});
	DEtableInsert (t, {46, 50,		20, {1,2}, DREAM_DUST,		75, {1,2}, GREATER_NETHER,	5, 1, LARGE_RADIANT});
	DEtableInsert (t, {51, 55,		22, {2,5}, DREAM_DUST,		75, {1,2}, LESSER_ETERNAL,	5, 1, SMALL_BRILLIANT});
	DEtableInsert (t, {56, 60,		22, {1,2}, ILLUSION_DUST,	75, {1,2}, GREATER_ETERNAL,	5, 1, LARGE_BRILLIANT});
	DEtableInsert (t, {61, 65,		22, {2,5}, ILLUSION_DUST,	75, {2,3}, GREATER_ETERNAL,	5, 1, LARGE_BRILLIANT});
	DEtableInsert (t, {66, 99,		22, {2,3}, ARCANE_DUST,		75, {2,3}, LESSER_PLANAR,	3, 1, SMALL_PRISMATIC});
	DEtableInsert (t, {100, 120,	22, {2,5}, ARCANE_DUST,		75, {1,2}, GREATER_PLANAR,	3, 1, LARGE_PRISMATIC});
	DEtableInsert (t, {121, 151,	22, {1,3}, INFINITE_DUST,	75, {1,2}, LESSER_COSMIC,	3, 1, SMALL_DREAM});
	DEtableInsert (t, {152, 200,	22, {4,7}, INFINITE_DUST,	75, {1,2}, GREATER_COSMIC,	3, 1, DREAM_SHARD});

	-- RARE (BLUE) ARMOR
	
	deTable[deKey(ARMOR, RARE)] = {};
	
	t = deTable[deKey(ARMOR, RARE)];

	DEtableInsert (t, {11, 25,		100, 1, SMALL_GLIMMERING});
	DEtableInsert (t, {26, 30,		100, 1, LARGE_GLIMMERING});
	DEtableInsert (t, {31, 35,		100, 1, SMALL_GLOWING});
	DEtableInsert (t, {36, 40,		100, 1, LARGE_GLOWING});
	DEtableInsert (t, {41, 45,		100, 1, SMALL_RADIANT});
	DEtableInsert (t, {46, 50,		100, 1, LARGE_RADIANT});
	DEtableInsert (t, {51, 55,		100, 1, SMALL_BRILLIANT});
	DEtableInsert (t, {56, 65,		99.5, 1, LARGE_BRILLIANT,		0.5, 1, NEXUS_CRYSTAL});
	DEtableInsert (t, {66, 99,		99.5, 1, SMALL_PRISMATIC,		0.5, 1, NEXUS_CRYSTAL});
	DEtableInsert (t, {100, 120,	99.5, 1, LARGE_PRISMATIC,		0.5, 1, VOID_CRYSTAL});
	DEtableInsert (t, {121, 164,	99.5, 1, SMALL_DREAM,			0.5, 1, ABYSS_CRYSTAL});
	DEtableInsert (t, {165, 280,	99.5, 1, DREAM_SHARD,			0.5, 1, ABYSS_CRYSTAL});
  
	-- RARE (BLUE) WEAPON
	
	deTable[deKey(WEAPON, RARE)] = {};
	
	t = deTable[deKey(WEAPON, RARE)];

	DEtableInsert (t, {11, 25,		100, 1, SMALL_GLIMMERING});
	DEtableInsert (t, {26, 30,		100, 1, LARGE_GLIMMERING});
	DEtableInsert (t, {31, 35,		100, 1, SMALL_GLOWING});
	DEtableInsert (t, {36, 40,		100, 1, LARGE_GLOWING});
	DEtableInsert (t, {41, 45,		100, 1, SMALL_RADIANT});
	DEtableInsert (t, {46, 50,		100, 1, LARGE_RADIANT});
	DEtableInsert (t, {51, 55,		100, 1, SMALL_BRILLIANT});
	DEtableInsert (t, {56, 65,		99.5, 1, LARGE_BRILLIANT,		0.5, 1, NEXUS_CRYSTAL});
	DEtableInsert (t, {66, 99,		99.5, 1, SMALL_PRISMATIC,		0.5, 1, NEXUS_CRYSTAL});
	DEtableInsert (t, {100, 120,	99.5, 1, LARGE_PRISMATIC,		0.5, 1, VOID_CRYSTAL});
	DEtableInsert (t, {121, 164,	99.5, 1, SMALL_DREAM,			0.5, 1, ABYSS_CRYSTAL});
	DEtableInsert (t, {165, 280,	99.5, 1, DREAM_SHARD,			0.5, 1, ABYSS_CRYSTAL});

	-- EPIC ITEMS
	
	deTable[deKey(ARMOR, EPIC)] = {};
	
	t = deTable[deKey(ARMOR, EPIC)];

	DEtableInsert (t, {40, 45,		100, {2,4}, SMALL_RADIANT});
	DEtableInsert (t, {46, 50,		100, {2,4}, LARGE_RADIANT});
	DEtableInsert (t, {51, 55,		100, {2,4}, SMALL_BRILLIANT});
	DEtableInsert (t, {56, 60,		100, 1, NEXUS_CRYSTAL});
--	DEtableInsert (t, {61, 80,  FILLED IN BELOW
	DEtableInsert (t, {95, 100,		100, {1,2}, VOID_CRYSTAL});
	DEtableInsert (t, {105, 164,	33.3, 1, VOID_CRYSTAL,	66.6, 2, VOID_CRYSTAL});
	DEtableInsert (t, {165, 280,	100, 1, ABYSS_CRYSTAL});
  
	deTable[deKey(WEAPON, EPIC)] = {};
	zc.CopyDeep (deTable[deKey(WEAPON, EPIC)], deTable[deKey(ARMOR, EPIC)]);	-- copy it this time because of differences

	DEtableInsert (deTable[deKey(ARMOR,  EPIC)], {61, 80,	50,   1, NEXUS_CRYSTAL, 	50,   2, NEXUS_CRYSTAL});
	DEtableInsert (deTable[deKey(WEAPON, EPIC)], {61, 80,	33.3, 1, NEXUS_CRYSTAL, 	66.6, 2, NEXUS_CRYSTAL});

end

-----------------------------------------

local function Atr_FindDEentry (itemType, itemRarity, itemLevel)

	local itemTypeNum = Atr_ItemType2AuctionClass (itemType);

	local t = deTable[deKey(itemTypeNum, itemRarity)];

	if (t) then
		local n;
		for n = 1, #t do
			
			local ta = t[n];
			
			if (itemLevel >= ta[1] and itemLevel <= ta[2]) then
				return ta;
			end
		end
	end


end

-----------------------------------------

function Atr_AddDEDetailsToTip (tip, itemType, itemRarity, itemLevel)

	local ta = Atr_FindDEentry (itemType, itemRarity, itemLevel);

	if (ta) then
		local x;
		for x = 3,#ta,3 do
			local percent = math.floor (ta[x]*100) / 100;

			local deitem = Atr_GetDEitemName(ta[x+2]);
			if (deitem == nil) then
				deitem = "???";
			end

			if (percent > 0) then
				tip:AddLine ("  |cFFFFFFFF"..percent.."%|r   "..ta[x+1].." "..deitem)
			end
		end
	end

end

-----------------------------------------

function Atr_DumpDETable (itemType, itemRarity)

	local t = deTable[deKey(itemType, itemRarity)];

	if (t) then
		local n, x;
		for n = 1, #t do
			local ta = t[n];
			
			zc.msg_pink ("iLvl: "..ta[1].."-"..ta[2]);
			
			for x = 3,#ta,3 do
				zc.msg_pink ("   "..ta[x].."%  "..ta[x+1].."  "..Atr_GetDEitemName(ta[x+2]).."  ("..Atr_GetAuctionPrice (Atr_GetDEitemName(ta[x+2]))..")");
			end
		end
	end

end

-----------------------------------------

function Atr_CalcDisenchantPrice (itemType, itemRarity, itemLevel)

	if (Atr_IsWeaponType (itemType) or Atr_IsArmorType (itemType)) then
		if (itemRarity == UNCOMMON or itemRarity == RARE or itemRarity == EPIC) then

			local dePrice = 0;

			local ta = Atr_FindDEentry (itemType, itemRarity, itemLevel);
			if (ta) then
				local x;
				for x = 3,#ta,3 do
					local price = Atr_GetAuctionPriceDE (ta[x+2]);
					if (price) then
						dePrice = dePrice + (ta[x] * ta[x+1] * price);
					end
				end
			end

			return math.floor (dePrice/100);
		end
	end
	
	return nil;		-- can't be disenchanted
end

-----------------------------------------

function Atr_STWP_AddVendorInfo (tip, xstring, vendorPrice, auctionPrice)
	
	
	if (AUCTIONATOR_V_TIPS == 1 and vendorPrice > 0) then
		local vpadding = Atr_CalcTTpadding (vendorPrice, auctionPrice);
		tip:AddDoubleLine (ZT("Vendor")..xstring, "|cFFFFFFFF"..zc.priceToMoneyString (vendorPrice))
	end
	
end
	
-----------------------------------------

function Atr_STWP_AddAuctionInfo (tip, xstring, link, auctionPrice, lastScan)
	
	
	if (AUCTIONATOR_A_TIPS == 1) then
	
		if lastScan then
			tip:AddDoubleLine ("Last Scanned", lastScan);
		end
	
		
		
		local itemID = zc.ItemIDfromLink (link);
		itemID = tonumber(itemID);
	
		local bondtype = Atr_GetBondType (itemID);
		
		if (bondtype == ATR_BIND_ON_PICKUP) then
			tip:AddDoubleLine (ZT("Auction")..xstring, "|cFFFFFFFF"..ZT("BOP").."  ");		
		elseif (bondtype == ATR_BINDS_TO_ACCOUNT) then
			tip:AddDoubleLine (ZT("Auction")..xstring, "|cFFFFFFFF"..ZT("BOA").."  ");		
		elseif (bondtype == ATR_QUEST_ITEM) then
			tip:AddDoubleLine (ZT("Auction")..xstring, "|cFFFFFFFF"..ZT("Quest Item").."  ");		
		elseif (auctionPrice ~= nil) then
			tip:AddDoubleLine (ZT("Auction")..xstring, "|cFFFFFFFF"..zc.priceToMoneyString (auctionPrice));
		else
			tip:AddDoubleLine (ZT("Auction")..xstring, "|cFFFFFFFF"..ZT("unknown").."  ");
		end
	end
		
end
	
-----------------------------------------

function Atr_STWP_AddBasicDEInfo (tip, xstring, dePrice)
	
	if (AUCTIONATOR_D_TIPS == 1 and dePrice ~= nil) then
		if (dePrice > 0) then
			tip:AddDoubleLine (ZT("Disenchant")..xstring, "|cFFFFFFFF"..zc.priceToMoneyString(dePrice));
		else
			tip:AddDoubleLine (ZT("Disenchant")..xstring, "|cFFFFFFFF"..ZT("unknown").."  ");
		end
	end

end
	
-----------------------------------------

function Atr_STWP_GetPrices (link, num, showStackPrices, itemVendorPrice, itemName, itemType, itemRarity, itemLevel)

	local vendorPrice	= 0;
	local auctionPrice	= 0;
	local dePrice		= nil;
	
	if (AUCTIONATOR_V_TIPS == 1) then vendorPrice	= itemVendorPrice; end;
	if (AUCTIONATOR_A_TIPS == 1) then auctionPrice	= Atr_GetAuctionPrice (itemName); end;
	if (AUCTIONATOR_D_TIPS == 1) then dePrice		= Atr_CalcDisenchantPrice (itemType, itemRarity, itemLevel); end;
	
	if (num and showStackPrices) then
		if (auctionPrice)	then	auctionPrice = auctionPrice * num;	end;
		if (vendorPrice)	then	vendorPrice  = vendorPrice  * num;	end;
		if (dePrice)  		then	dePrice  	 = dePrice  * num;	end;
	end;

	if (vendorPrice == nil) then
		vendorPrice = 0;
	end

	return vendorPrice, auctionPrice, dePrice;

end

-----------------------------------------

function Atr_ShowTipWithPricing (tip, link, num)

	-- if (link == nil or zc.IsBattlePetLink(link)) then
		-- return;
	-- end
	
	if link == nil then
		return;
	end
	
	local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, _, _, _, _, itemVendorPrice = GetItemInfo (link);
		

	local showStackPrices = IsShiftKeyDown();
	if (AUCTIONATOR_SHIFT_TIPS == 2) then
		showStackPrices = not IsShiftKeyDown();
	end

	local xstring = "";
	if (num and showStackPrices) then
		xstring = "|cFFAAAAFF x"..num.."|r";
	end


	local vendorPrice, auctionPrice, dePrice = Atr_STWP_GetPrices (link, num, showStackPrices, itemVendorPrice, itemName, itemType, itemRarity, itemLevel);

	-- vendor info

	Atr_STWP_AddVendorInfo (tip, xstring, vendorPrice, auctionPrice)
	
	-- auction info

	local TimeDiff = time()
	if ((type(gAtr_ScanDB) == "table") and gAtr_ScanDB[itemName] and gAtr_ScanDB[itemName].lastScan) then
		TimeDiff = TimeDiff - gAtr_ScanDB[itemName].lastScan
		
		local timeColor = "|cffff0000"
		if TimeDiff < 60 * 60 * 3 then
			timeColor = "|cff00ff00"
		elseif TimeDiff < 60 * 60 * 12 then
			timeColor = "|cffffff00"
		end
		local MakeTimeString = format(timeColor.."%s ago".."|r", SecondsToTime(TimeDiff))
		
		Atr_STWP_AddAuctionInfo (tip, xstring, link, auctionPrice, MakeTimeString)
		
	else
		Atr_STWP_AddAuctionInfo (tip, xstring, link, auctionPrice)
	end

	-- disenchanting info

	Atr_STWP_AddBasicDEInfo (tip, xstring, dePrice)

	local showDetails = true;
	
	if (AUCTIONATOR_DE_DETAILS_TIPS == 1) then showDetails = IsShiftKeyDown(); end;
	if (AUCTIONATOR_DE_DETAILS_TIPS == 2) then showDetails = IsControlKeyDown(); end;
	if (AUCTIONATOR_DE_DETAILS_TIPS == 3) then showDetails = IsAltKeyDown(); end;
	if (AUCTIONATOR_DE_DETAILS_TIPS == 4) then showDetails = false; end;
	if (AUCTIONATOR_DE_DETAILS_TIPS == 5) then showDetails = true; end;
	
	if (showDetails and dePrice ~= nil) then
		Atr_AddDEDetailsToTip (tip, itemType, itemRarity, itemLevel)
	end
	

	tip:Show()

end

-----------------------------------------

hooksecurefunc (GameTooltip, "SetBagItem",
	function(tip, bag, slot)
		local _, num = GetContainerItemInfo(bag, slot);
		Atr_ShowTipWithPricing (tip, GetContainerItemLink(bag, slot), num);
	end
);

hooksecurefunc (GameTooltip, "SetAuctionItem",
	function (tip, type, index)
		local _, _, num = GetAuctionItemInfo(type, index);
		Atr_ShowTipWithPricing (tip, GetAuctionItemLink(type, index), num);
	end
);

hooksecurefunc (GameTooltip, "SetAuctionSellItem",
	function (tip)
		local name, _, count = GetAuctionSellItemInfo();
		local __, link = GetItemInfo(name);
		Atr_ShowTipWithPricing (tip, link, num);
	end
);

hooksecurefunc (GameTooltip, "SetLootItem",
	function (tip, slot)
		if LootSlotIsItem(slot) then
			local link, _, num = GetLootSlotLink(slot);
			Atr_ShowTipWithPricing (tip, link, num);
		end
	end
);

hooksecurefunc (GameTooltip, "SetLootRollItem",
	function (tip, slot)
		local _, _, num = GetLootRollItemInfo(slot);
		Atr_ShowTipWithPricing (tip, GetLootRollItemLink(slot), num);
	end
);


hooksecurefunc (GameTooltip, "SetInventoryItem",
	function (tip, unit, slot)
		Atr_ShowTipWithPricing (tip, GetInventoryItemLink(unit, slot), GetInventoryItemCount(unit, slot));
	end
);

hooksecurefunc (GameTooltip, "SetGuildBankItem",
	function (tip, tab, slot)
		local _, num = GetGuildBankItemInfo(tab, slot);
		Atr_ShowTipWithPricing (tip, GetGuildBankItemLink(tab, slot), num);
	end
);

hooksecurefunc (GameTooltip, "SetTradeSkillItem",
	function (tip, skill, id)
		local link = GetTradeSkillItemLink(skill);
		local num  = GetTradeSkillNumMade(skill);
		if id then
			link = GetTradeSkillReagentItemLink(skill, id);
			num = select (3, GetTradeSkillReagentInfo(skill, id));
		end

		Atr_ShowTipWithPricing (tip, link, num);
	end
);

hooksecurefunc (GameTooltip, "SetTradePlayerItem",
	function (tip, id)
		local _, _, num = GetTradePlayerItemInfo(id);
		Atr_ShowTipWithPricing (tip, GetTradePlayerItemLink(id), num);
	end
);

hooksecurefunc (GameTooltip, "SetTradeTargetItem",
	function (tip, id)
		local _, _, num = GetTradeTargetItemInfo(id);
		Atr_ShowTipWithPricing (tip, GetTradeTargetItemLink(id), num);
	end
);

hooksecurefunc (GameTooltip, "SetQuestItem",
	function (tip, type, index)
		local _, _, num = GetQuestItemInfo(type, index);
		Atr_ShowTipWithPricing (tip, GetQuestItemLink(type, index), num);
	end
);

hooksecurefunc (GameTooltip, "SetQuestLogItem",
	function (tip, type, index)
		local num, _;
		if type == "choice" then
			_, _, num = GetQuestLogChoiceInfo(index);
		else
			_, _, num = GetQuestLogRewardInfo(index)
		end

		Atr_ShowTipWithPricing (tip, GetQuestLogItemLink(type, index), num);
	end
);

hooksecurefunc (GameTooltip, "SetInboxItem",
	function (tip, index, attachIndex)
		local _, _, num = GetInboxItem(index, attachIndex);
		Atr_ShowTipWithPricing (tip, GetInboxItemLink(index, attachIndex), num);
	end
);

hooksecurefunc (GameTooltip, "SetSendMailItem",
	function (tip, id)
		local name, _, num = GetSendMailItem(id)
		local name, link = GetItemInfo(name);
		Atr_ShowTipWithPricing (tip, link, num);
	end
);

hooksecurefunc (GameTooltip, "SetHyperlink",
	function (tip, itemstring, num)
		local name, link = GetItemInfo (itemstring);
		Atr_ShowTipWithPricing (tip, link, num);
	end
);

hooksecurefunc (ItemRefTooltip, "SetHyperlink",
	function (tip, itemstring)
		local name, link = GetItemInfo (itemstring);
		Atr_ShowTipWithPricing (tip, link);
	end
);