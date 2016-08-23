
local L = LibStub("AceLocale-3.0"):NewLocale("BagSync", "enUS", true)
if not L then return end

L["Bags: %d"] = true
L["Bank: %d"] = true
L["Equip: %d"] = true
L["Guild: %d"] = true
L["Mail: %d"] = true
L["Void: %d"] = true
L["Reagent: %d"] = true
L["AH: %d"] = true
L["Search"] = true
L["Total:"] = true
L["Tokens"] = true
L["Profiles"] = true
L["Professions"] = true
L["Blacklist"] = true
L["Gold"] = true
L["Close"] = true
L["FixDB"] = true
L["Config"] = true
L["Select a profile to delete.\nNOTE: This is irreversible!"] = true
L["Delete"] = true
L["Confirm"] = true
L["Toggle Search"] = true
L["Toggle Tokens"] = true
L["Toggle Profiles"] = true
L["Toggle Professions"] = true
L["Toggle Blacklist"] = true
L["A FixDB has been performed on BagSync!  The database is now optimized!"] = true
L["ON"] = true
L["OFF"] = true
L["Left Click = Search Window"] = true
L["Right Click = BagSync Menu"] = true
L["Left Click = Link to view tradeskill."] = true
L["Right Click = Insert tradeskill link."] = true
L["Click to view profession: "] = true
L["Click Here"] = true
L["BagSync: Error user not found!"] = true
L["Please enter an itemid. (Use Wowhead.com)"] = true
L["Add ItemID"] = true
L["Remove ItemID"] = true
-- ----THESE ARE FOR SLASH COMMANDS
L["[itemname]"] = true
L["search"] = true
L["gold"] = true
L["config"] = true
L["tokens"] = true
L["fixdb"] = true
L["profiles"] = true
L["professions"] = true
L["blacklist"] = true
------------------------
L["/bgs [itemname] - Does a quick search for an item"] = true
L["/bgs search - Opens the search window"] = true
L["/bgs gold - Displays a tooltip with the amount of gold on each character."] = true
L["/bgs tokens - Opens the tokens/currency window."] = true
L["/bgs profiles - Opens the profiles window."] = true
L["/bgs fixdb - Runs the database fix (FixDB) on BagSync."] = true
L["/bgs config - Opens the BagSync Config Window"] = true
L["/bgs professions - Opens the professions window."] = true
L["/bgs blacklist - Opens the blacklist window."] = true
L["Display [Total] amount."] = true
L["Display [Guild Name] for guild bank items."] = true
L["Display guild bank items."] = true
L["Display mailbox items."] = true
L["Display auction house items."] = true
L["Display BagSync minimap button."] = true
L["Display items for both factions (Alliance/Horde)."] = true
L["Display class colors for characters."] = true
L["Display BagSync tooltip ONLY in the search window."] = true
L["Enable BagSync Tooltips"] = true
L["Display empty line seperator."] = true
L["Display Cross-Realms characters."] = true
L["Display Battle.Net Account characters |cFFDF2B2B(Not Recommended)|r."] = true
L["Primary BagSync tooltip color."] = true
L["Secondary BagSync tooltip color."] = true
L["BagSync [Total] tooltip color."] = true
L["BagSync [Guild] tooltip color."] = true
L["BagSync [Cross-Realms] tooltip color."] = true
L["BagSync [Battle.Net] tooltip color."] = true
L["Settings for various BagSync features."] = true
L["Display"] = true
L["Settings for the displayed BagSync tooltip information."] = true
L["Color"] = true
L["Color settings for BagSync tooltip information."] = true
L["Main"] = true
L["Main settings for BagSync."] = true
L["WARNING: A total of [%d] items were not searched!\nBagSync is still waiting for the server/cache to respond.\nPress the Search button again to retry."] = true
L["You have been updated to latest database version!  You will need to rescan all your characters again!|r"] = true
