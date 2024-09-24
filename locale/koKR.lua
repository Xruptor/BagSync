
local L = LibStub("AceLocale-3.0"):NewLocale("BagSync", "koKR")
if not L then return end

--PLEASE LOOK AT enUS.lua for a complete localization list

--special thanks to WetU @ GitHub

L.Yes = "네"
L.No = "아니오"
L.Page = "페이지"
L.Done = "완료"
L.Realm = "서버:"
L.TooltipCR_Tag = "CR"
L.TooltipBNET_Tag = "BN"
L.Tooltip_bag = "가방"
L.Tooltip_bank = "은행"
L.Tooltip_equip = "착용중"
L.Tooltip_guild = "길드은행"
L.Tooltip_mailbox = "우편함"
L.Tooltip_void = "공허보관사"
L.Tooltip_reagents = "재료 은행"
L.Tooltip_auction = "경매장"
L.TooltipSmall_bag = "P"
L.TooltipSmall_bank = "B"
L.TooltipSmall_reagents = "R"
L.TooltipSmall_equip = "E"
L.TooltipSmall_guild = "G"
L.TooltipSmall_mailbox = "M"
L.TooltipSmall_void = "V"
L.TooltipSmall_auction = "A"
--do not touch these unless requiring a new image for a specific localization
L.TooltipTotal = "합계:"
L.TooltipGuildTabs = "T:"
L.TooltipItemID = "[아이템ID]:"
L.TooltipDebug = "[디버그]:"
L.TooltipCurrencyID = "[화폐ID]:"
L.TooltipFakeID = "[가짜ID]:"
L.TooltipExpansion = "[확장팩]:"
L.TooltipItemType = "[아이템유형]:"
L.TooltipDelimiter = ", "
L.TooltipRealmKey = "서버키:"
--[[Translation missing --]]
L.TooltipDetailsInfo = "Item detailed summary."
L.DetailsBagID = "Bag:"
L.DetailsSlot = "Slot:"
L.DetailsTab = "Tab:"
L.Debug_DEBUG = "디버그"
L.Debug_INFO = "정보"
L.Debug_TRACE = "추적"
L.Debug_WARN = "경고"
L.Debug_FINE = "이상없음"
L.Debug_SL1 = "하위레벨1" --sublevel 1
L.Debug_SL2 = "하위레벨2" --sublevel 2
L.Debug_SL3 = "하위레벨3" --sublevel 3
--[[Translation missing --]]
L.DebugEnable = "Enable Debug"
L.DebugDumpOptions = "덤프 설정 |cff3587ff[디버그]|r"
L.DebugIterateUnits = "반복 단위 |cff3587ff[디버그]|r"
L.DebugDBTotals = "DB 합계 |cff3587ff[디버그]|r"
L.DebugAddonList = "애드온 목록 |cff3587ff[디버그]|r"
L.DebugExport = "출력"
L.DebugWarning = "|cFFDF2B2B경고:|R BagSync 디버그가 현재 사용중입니다! |cFFDF2B2B(랙을 발생시킬 수 있음)|r"
L.Search = "검색"
L.Debug = "디버그"
L.AdvSearchBtn = "검색/새로고침"
L.Reset = "초기화"
L.Refresh = "새로고침"
L.Clear = "초기화"
L.AdvancedSearch = "심화 검색"
L.AdvancedSearchInformation = "* BagSync |cffff7d0a[CR]|r 과 |cff3587ff[BNet]|r 설정을 사용합니다."
L.AdvancedLocationInformation = "* 아무 선택이 없으면 모두 선택한 것이 기본값입니다."
L.Units = "유닛:"
L.Locations = "위치:"
L.Profiles = "프로필"
--[[Translation missing --]]
L.SortOrder = "Sort Order"
L.Professions = "전문기술"
L.Currency = "화폐"
L.Blacklist = "차단목록"
L.Whitelist = "허가목록"
L.Recipes = "제조법"
L.Gold = "소지금"
L.Close = "닫기"
L.FixDB = "데이터 갱신"
L.Config = "설정"
L.DeleteWarning = "삭제할 프로필을 선택하세요.\n참고: 되돌릴 수 없습니다!!!"
L.Delete = "삭제"
L.Confirm = "확인"
L.SelectAll = "모두 선택"
L.FixDBComplete = "BagSync FixDB(데이터 갱신)이 실행되었습니다! 데이터베이스가 최적화됩니다!"
L.ResetDBInfo = "BagSync:\n데이터베이스를 초기화 하시겠습니까?\n|cFFDF2B2B주의: 추천하지 않습니다!|r"
L.ON = "ON"
L.OFF = "OFF"
L.LeftClickSearch = "|cffddff00클릭|r |cff00ff00= 검색창|r"
L.RightClickBagSyncMenu = "|cffddff00오른쪽 클릭|r |cff00ff00= BagSync 메뉴|r"
L.ProfessionInformation = "|cff00ff00제조법을 보려면 전문 기술을|r |cffddff00클릭|r|cff00ff00하세요.|r"
L.ClickViewProfession = "클릭하여 볼 전문 기술: "
L.ClickHere = "클릭하세요"
L.ErrorUserNotFound = "BagSync: 오류 사용자를 찾을 수 없음!"
L.EnterItemID = "아이템ID를 입력해주세요. (http://Wowhead.com/ 이용)"
L.AddGuild = "길드 추가"
L.AddItemID = "아이템ID 추가"
L.RemoveItemID = "아이템ID 제거"
L.PleaseRescan = "|cFF778899[다시 갱신하세요.]|r"
L.ItemIDNotFound = "[%s] 아이템ID를 찾을 수 없습니다. 다시 시도하세요!"
L.ItemIDNotValid = "[%s] 아이템ID가 올바르지 않거나 서버가 응답하지 않습니다. 다시 시도하세요!"
L.ItemIDRemoved = "[%s] 아이템ID 제거됨"
L.ItemIDAdded = "[%s] 아이템ID 추가됨"
L.ItemIDExistBlacklist = "[%s]의 아이템ID가 차단목록에 등록되어 있습니다."
L.ItemIDExistWhitelist = "[%s]의 아이템ID가 허가목록에 등록되어 있습니다."
L.GuildExist = "[%s] 길드가 이미 차단목록 데이터베이스에 있습니다."
L.GuildAdded = "[%s] 길드가 추가되었습니다."
L.GuildRemoved = "[%s] 길드가 삭제되었습니다."
L.BlackListRemove = "[%s] 를 차단목록에서 삭제하시겠습니까?"
L.WhiteListRemove = "[%s] 를 허가목록에서 삭제하시겠습니까?"
L.BlackListErrorRemove = "차단목록에서 삭제하는데 오류가 발생했습니다."
L.WhiteListErrorRemove = "허가목록에서 삭제하는데 오류가 발생했습니다."
L.ProfilesRemove = "BagSync에서 [%s][|cFF99CC33%s|r] 프로필을 삭제하시겠습니까?"
L.ProfilesErrorRemove = "BagSync에서 삭제하는데 오류가 발생했습니다."
L.ProfileBeenRemoved = "[%s] 프로필이 삭제되었습니다!"
L.ProfessionsFailedRequest = "[%s] 서버 요청이 실패했습니다."
L.ProfessionHasRecipes = "제조법을 보려면 클릭하세요."
L.ProfessionHasNoRecipes = "확인할 제조법이 없습니다."
L.KeybindBlacklist = "차단목록 창 표시"
L.KeybindWhitelist = "허가목록 창 표시"
L.KeybindCurrency = "화폐 창 표시"
L.KeybindGold = "금액 툴팁 표시"
L.KeybindProfessions = "전문 기술 창 표시"
L.KeybindProfiles = "프로필 창 표시"
L.KeybindSearch = "검색 창 표시"
L.ObsoleteWarning = "\n\n주의: 일부 아이템이 누락된 것으로 표기됩니다. 이 문제를 해결하기 위해서는 일부 아이템을 재확인해야 합니다.\n(가방, 은행, 재료 은행, 공허보관사, 등등...)"
L.DatabaseReset = "데이터베이스 변경으로 인해 기존 데이터베이스가 초기화 됩니다."
L.UnitDBAuctionReset = "모든 캐릭터의 경매장 정보가 초기화 되었습니다."
L.ScanGuildBankStart = "길드 은행의 정보를 찾기 위해 서버에 문의중, 잠시 기다리세요...."
L.ScanGuildBankDone = "길드 은행 스캔 완료!"
L.ScanGuildBankError = "경고: 길드 은행 스캔이 완료되지 않았습니다."
L.ScanGuildBankScanInfo = "길드은행 탭 검색중 (%s/%s)."
L.DefaultColors = "기본 색상"
-- ----THESE ARE FOR SLASH COMMANDS OPERATORS
L.SlashItemName = "[아이템 이름]"
L.SlashSearch = "검색"
L.SlashGold = "소지금"
L.SlashMoney = "돈"
L.SlashConfig = "설정"
L.SlashCurrency = "화폐"
L.SlashFixDB = "db개선"
L.SlashProfiles = "프로필"
L.SlashProfessions = "전문기술"
L.SlashBlacklist = "차단목록"
L.SlashWhitelist = "허가목록"
L.SlashResetDB = "db초기화"
L.SlashDebug = "디버그"
L.SlashResetPOS = "위치초기화"
--[[Translation missing --]]
L.SlashSortOrder = "sortorder"
------------------------
-- ----THESE USE THE SLASH OPERATOR COMMANDS FOUND ABOVE
L.HelpSearchItemName = "빠른 아이템 찾기"
L.HelpSearchWindow = "검색창 열기"
L.HelpGoldTooltip = "툴팁에 각 캐릭터의 소지금을 표시합니다."
L.HelpCurrencyWindow = "화폐 창을 엽니다."
L.HelpProfilesWindow = "프로필 창을 엽니다."
L.HelpFixDB = "데이터베이스 개선 (FixDB) 실행"
L.HelpResetDB = "BagSync의 데이터베이스를 초기화 합니다."
L.HelpConfigWindow = "BagSync 설정 창 열기"
L.HelpProfessionsWindow = "전문기술 창을 엽니다."
L.HelpBlacklistWindow = "차단목록 창을 엽니다."
L.HelpWhitelistWindow = "허가목록 창을 엽니다."
L.HelpDebug = "BagSync 디버그 창을 엽니다."
L.HelpResetPOS = "BagSync의 각 모듈에서 사용하는 창을 전체 초기화 합니다."
L.HelpSortOrder = "사용자 정렬 순서"
------------------------
L.EnableBagSyncTooltip = "BagSync 툴팁 사용"
L.ShowOnModifier = "BagSync 툴팁 표시 기능키:"
L.ShowOnModifierDesc = "BagSync 툴팁을 기능키를 사용하여 표시합니다."
L.ModValue_NONE = "없음 (항상 표시)"
L.ModValue_ALT = "ALT"
L.ModValue_CTRL = "CTRL"
L.ModValue_SHIFT = "SHIFT"
L.EnableExtTooltip = "아이템 수량을 별도의 툴팁으로 표시합니다."
L.EnableLoginVersionInfo = "접속 시 BagSync 버전을 표시합니다."
L.FocusSearchEditBox = "검색 창을 열면 검색 입력창에 위치합니다."
L.AlwaysShowAdvSearch = "아이템 검색시 항상 심화 검색창을 같이 표시합니다."
L.DisplayTotal = "[총] 수량을 표시합니다."
L.DisplayGuildGoldInGoldWindow = "소지금 툴팁에 [길드]의 총 골드를 표시합니다."
L.DisplayMailbox = "우편함의 아이템을 표시합니다."
L.DisplayAuctionHouse = "경매장 아이템을 표시합니다."
L.DisplayMinimap = "BagSync 미니맵 버튼을 표시합니다."
L.DisplayFaction = "양 진영 아이템을 표시합니다 (얼라이언스/호드)."
L.DisplayClassColor = "캐릭터의 이름에 직업 색상을 적용합니다."
L.DisplayItemTotalsByClassColor = "캐릭터의 직업 색상으로 아이템의 합계를 표시합니다."
L.DisplayTooltipOnlySearch = "|cFF99CC33(오직)|r 검색 창에만 BagSync 툴팁을 표시합니다."
L.DisplayLineSeparator = "빈 줄로 분리하여 표시합니다."
--[[Translation missing --]]
L.DisplayCR = "Display |cffff7d0a[Connected Realm]|r characters. |cffff7d0a[CR]|r"
L.DisplayBNET = "Display all Battle.Net account characters. |cff3587ff[BNet]|r |cFFDF2B2B(Not Recommended)|r"
L.DisplayItemID = "툴팁에 아이템ID를 표시합니다."
L.DisplaySourceDebugInfo = "툴팁에 유용한 [디버그] 정보를 표시합니다."
L.DisplayWhiteListOnly = "허가목록에 있는 아이템만 툴팁에 수량을 표시합니다."
L.DisplaySourceExpansion = "아이템 툴팁에 확장팩을 표시합니다. |cFF99CC33[현재 확장팩만 가능]|r"
L.DisplayItemTypes = "툴팁에 아이템 유형을 [아이템 유형 | 속성] 으로 표시합니다."
L.DisplayTooltipTags = "태그"
L.DisplayTooltipStorage = "아이템 위치"
L.DisplayTooltipExtra = "추가기능"
L.DisplayWhitelistHelp = "허가목록 도움말"
L.DisplayWhitelistStatus = "현재 허가목록: [%s]"
L.DisplayWhitelistHelpInfo = "허가목록에 아이템ID를 입력할 수 있습니다. \n\n애완동물을 입력하려면 아이템ID가 아니라 FakeID를 사용해야 합니다. 설정에서 아이템ID 툴팁을 사용하여 FakeID를 가져올 수 있습니다.\n\n|cFFDF2B2B화폐 창에서는 동작하지 않습니다.|r"
L.DisplayTooltipAccountWide = "교차 서버"
L.DisplayAccountWideTagOpts = "|cFF99CC33태그 설정 ( |cffff7d0a[CR]|r & |cff3587ff[BNet]|r )|r"
L.DisplayGreenCheck = "현재 캐릭터 이름 옆에 %s를 표시합니다."
L.DisplayRealmIDTags = "캐릭터에 서버식별자 |cffff7d0a[CR]|r과 |cff3587ff[BNet]|r을 표시합니다."
L.DisplayRealmNames = "서버 이름을 표시합니다."
L.DisplayRealmAstrick = "|cffff7d0a[CR]|r과 |cff3587ff[BNet]|r 서버 이름 대신 [*]을 표시합니다."
L.DisplayShortRealmName = "|cffff7d0a[CR]|r과 |cff3587ff[BNet]|r 서버 이름을 축약해서 표시합니다."
L.DisplayFactionIcons = "툴팁에 진영 아이콘을 표시합니다."
L.DisplayGuildBankTabs = "툴팁에 길드은행 탭 [1,2,3, 등]을 사용합니다."
L.DisplayRaceIcons = "툴팁에 캐릭터 종족 아이콘을 표시합니다."
L.DisplaySingleCharLocs = "아이템의 위치를 단축문자를 사용하여 표시합니다."
L.DisplayIconLocs = "아이템의 위치를 아이콘을 사용하여 표시합니다."
L.DisplayGuildSeparately = "캐릭터의 합계와 분리하여 [길드] 이름 및 아이템 합계를 표시합니다."
L.DisplayGuildCurrentCharacter = "현재 접속한 캐릭터의 [길드] 아이템만 표시합니다."
L.DisplayGuildBankScanAlert = "길드 은행 스캔시 경고 창을 표시합니다."
L.DisplayAccurateBattlePets = "길드 은행 및 우편함에 정확한 전투 애완 동물 사용. |cFFDF2B2B(랙을 발생시킴)|r |cff3587ff[BagSync의 FAQ를 참고하세요.]|r"
L.DisplaySorting = "툴팁 정렬"
L.DisplaySortInfo = "기본: 서버의 캐릭터 이름으로 툴팁은 알파벳 순으로 정렬되어 있습니다."
L.SortTooltipByTotals = "BagSync의 툴팁에 알파벳 순이 아닌 총 갯수로 정렬합니다."
L.SortByCustomSortOrder = "사용자 정렬 순서로 정렬합니다."
L.CustomSortInfo = "오름차순으로 정렬합니다. (1,2,3)"
L.CustomSortInfoWarn = "|cFF99CC33주의: 반드시 숫자만 사용합니다! (-1,0,3,4)|r"
L.DisplayShowUniqueItemsTotals = "이 설정을 사용하면 아이템 상태와 상관없이 고유 아이템의 합계가 추가됩니다. |cFF99CC33(추천함)|r."
L.DisplayShowUniqueItemsTotals_2 = [[
\n|cffff7d0a[전설아이템]|r은 이름은 같지만 다른 상태를 가질 수 있습니다. (예:능력치가 다름) 이런 이유로 각각의 개별 아이템이 되어 합계에 표시되지 않습니다. 이 설정을 사용하게 되면 이러한 체계를 무시하고 동일한 이름의 아이템은 같은 종류로 합계에 표시됩니다.\n\n이 설정을 사용하지 않으면 앞서 언급한대로 개별적으로 합계가 표시됩니다. 정확하게 동일한 상태를 가진 아이템만 동일한 합계로 표시됩니다. |cFFDF2B2B(추천하지 않음)|r"
Disabling this option will display the item counts independently as item stats will be taken into consideration. Item totals will only display for each character that share the same unique item with the exact same stats. |cFFDF2B2B(추천하지 않음)|r
]]
L.DisplayShowUniqueItemsTotalsTitle = "고유 아이템 툴팁에 합계 표시"
L.DisplayShowUniqueItemsEnableText = "고유 아이템 합계를 사용"
L.ColorPrimary = "주 BagSync 툴팁 색상"
L.ColorSecondary = "보조 BagSync 툴팁 색상"
L.ColorTotal = "BagSync [총] 툴팁 색상"
L.ColorGuild = "BagSync [길드] 툴팁 색상"
--[[Translation missing --]]
L.ColorCR = "BagSync [Connected Realm] tooltip color."
L.ColorBNET = "BagSync [Battle.Net] 툴팁 색상"
L.ColorItemID = "BagSync [아이템ID] 툴팁 색상"
L.ColorExpansion = "[확장팩] 툴팁 색상"
L.ColorItemTypes = "[아이템유형] 툴팁 색상"
L.ColorGuildTabs = "길드 은행 탭 [1,2,3, 등] 툴팁 색상"
L.ConfigHeader = "여러 BagSync 기능을 설정합니다."
L.ConfigDisplay = "표시"
L.ConfigTooltipHeader = "표시할 BagSync 툴팁 정보를 설정합니다."
L.ConfigColor = "색상"
L.ConfigColorHeader = "BagSync 툴팁 정보의 색상을 설정합니다."
L.ConfigMain = "일반"
L.ConfigMainHeader = "BagSync의 일반 설정입니다."
L.ConfigSearch = "검색"
--[[Translation missing --]]
L.ConfigKeybindings = "Keybindings"
L.ConfigKeybindingsHeader = "Keybind settings for BagSync features."
L.ConfigExternalTooltip = "External Tooltip"
L.ConfigSearchHeader = "검색창에 대한 설정입니다."
--[[Translation missing --]]
L.ConfigFont = "Font"
L.ConfigFontSize = "Font Size"
L.ConfigFontOutline = "Outline"
L.ConfigFontOutline_NONE = "None"
L.ConfigFontOutline_OUTLINE = "Outline"
L.ConfigFontOutline_THICKOUTLINE = "ThickOutline"
L.ConfigFontMonochrome = "Monochrome"
L.ConfigTracking = "Tracking"
L.ConfigTrackingHeader = "Tracking settings for all stored BagSync database locations."
L.ConfigTrackingCaution = "Caution"
L.ConfigTrackingModules = "Modules"
L.ConfigTrackingInfo = [[
|cFFDF2B2BNOTE|r: Disabling a module will cause BagSync to stop tracking and storing the module to the database.
Disabled modules will not display in any of the BagSync windows, slash commands, tooltips or minimap button.
]]
L.TrackingModule_Bag = "Bags"
L.TrackingModule_Bank = "Bank"
L.TrackingModule_Reagents = "Reagent Bank"
L.TrackingModule_Equip = "Equipped Items"
L.TrackingModule_Mailbox = "Mailbox"
L.TrackingModule_Void = "Void Bank"
L.TrackingModule_Auction = "Auction House"
L.TrackingModule_Guild = "Guild Bank"
L.TrackingModule_Professions = "Professions / Tradeskills"
L.TrackingModule_Currency = "Curency Tokens"
L.WarningItemSearch = "경고: 총 [|cFFFFFFFF%s|r]개의 아이템이 검색되지 않았습니다!\n\nBagSync는 계속해서 서버/캐시의 응답을 기다립니다.\n\n새로고침 버튼을 누르세요."
L.WarningUpdatedDB = "최신 데이터베이스 버전으로 갱신했습니다! 당신의 모든 캐릭터를 다시 재탐색해야 합니다!|r"
L.WarningHeader = "경고!"
--[[Translation missing --]]
L.SavedSearch = "Saved Search"
L.SavedSearch_Add = "Add Search"
L.SavedSearch_Warn = "You must type something in the search box."
---------------------------------------
--Localization Note:  Please be advised that the commands for the SearchHelp are english only, however the variables can be any language.  Example: class:<name of class in your locale>
--This includes name searches like name:<name in your locale>
---------------------------------------
L.SearchHelpHeader = "Search Help"
L.SearchHelp = [[
|cffff7d0aSearch Options|r:
|cFFDF2B2B(NOTE: All commands are English only!)|r
|cFF99CC33Character items by location|r:
@bag
@bank
@reagents
@equip
@mailbox
@void
@auction
@guild
|cffff7d0aAdvanced Search|r (|cFF99CC33commands|r | |cFFFFD580example|r):
|cff00ffff<item name>|r = |cFF99CC33n|r ; |cFF99CC33name|r | |cFFFFD580n:<text>|r ; |cFFFFD580name:<text>|r (n:ore ; name:ore)
|cff00ffff<item bind>|r = |cFF99CC33bind|r | |cFFFFD580bind:<type>|r ; types (boe, bop, bou, boq) i.e boe = bind on equip
|cff00ffff<quality>|r = |cFF99CC33q|r ; |cFF99CC33quality|r | |cFFFFD580q<op><text>|r ; |cFFFFD580q<op><digit>|r (q:rare ; q:>2 ; q:>=3)
|cff00ffff<ilvl>|r = |cFF99CC33l|r ; |cFF99CC33level|r ; |cFF99CC33lvl|r ; |cFF99CC33ilvl|r | |cFFFFD580ilvl<op><number>|r ; |cFFFFD580lvl<op><number>|r (lvl:>5 ; lvl:>=20)
|cff00ffff<required ilvl>|r = |cFF99CC33r|r ; |cFF99CC33req|r ; |cFF99CC33rl|r ; |cFF99CC33reql|r ; |cFF99CC33reqlvl|r | |cFFFFD580req<op><number>|r ; |cFFFFD580req<op><number>|r (req:>5 ; req:>=20)
|cff00ffff<type / slot>|r = |cFF99CC33t|r ; |cFF99CC33type|r ; |cFF99CC33slot|r | |cFFFFD580t:<text>|r (slot:head)
|cff00ffff<tooltip>|r = |cFF99CC33tt|r ; |cFF99CC33tip|r ; |cFF99CC33tooltip|r | |cFFFFD580tt:<text>|r (tt:summon)
|cff00ffff<item set>|r = |cFF99CC33s|r ; |cFF99CC33set|r | |cFFFFD580s:<setname>|r (setname can be * for all sets)
|cff00ffff<expansion>|r = |cFF99CC33x|r ; |cFF99CC33xpac|r ; |cFF99CC33expansion|r | |cFFFFD580x:<expacID>|r ; |cFFFFD580x:<expansion name>|r ; |cFFFFD580xpac:<expansion name>|r (xpac:shadow)
|cff00ffff<keyword>|r = |cFF99CC33k|r ; |cFF99CC33key|r ; |cFF99CC33keyword|r | |cFFFFD580k:<keyword>|r (key:quest) (keywords: soulbound, bound, boe, bop, bou, boa, quest, unique, toy, reagent, crafting, naval, follower, follow, power, apperance)
|cff00ffff<class>|r = |cFF99CC33c|r ; |cFF99CC33class|r | |cFFFFD580c:<classname>|r ; |cFFFFD580class:<classname>|r (class:shaman)
|cffff7d0aOperators <op>|r:
|cFF99CC33:|r | |cFF99CC33=|r | |cFF99CC33==|r | |cFF99CC33!=|r | |cFF99CC33~=|r | |cFF99CC33<|r | |cFF99CC33>|r | |cFF99CC33<=|r | |cFF99CC33>=|r
|cffff7d0aNegate Commands|r:
Example: |cFF99CC33!|r|cFFFFD580bind:boe|r (not boe)
Example: |cFF99CC33!|r|cFFFFD580bind:boe|r |cFF99CC33&&|r |cFFFFD580lvl:>20|r (not boe and item level greater than 20)
|cffff7d0aUnion Searches (and searches):|r
(Use the double ampersand |cFF99CC33&&|r symbol)
Example: |cFFFFD580bind:boe|r |cFF99CC33&&|r |cFFFFD580lvl:>20|r
|cffff7d0aIntersect Searches (or searches):|r
(Use the double pipe |cFF99CC33|||||r symbol)
Example: |cFFFFD580bind:boe|r |cFF99CC33|||||r |cFFFFD580lvl:>20|r
|cffff7d0aComplex Search Example:|r
(bind on equip, lvl is exactly 20 with the word 'robe' in the name)
|cFFFFD580bind:boe|r |cFF99CC33&&|r |cFFFFD580lvl:20|r |cFF99CC33&&|r |cFFFFD580name:robe|r
]]
L.ConfigFAQ= "FAQ / 도움말"
L.ConfigFAQHeader = "BagSync의 자주 하는 질문 및 도움말 입니다."
--[[Translation missing --]]
L.FAQ_Question_1 = "I'm experiencing hitching/stuttering/lagging with tooltips."
--[[Translation missing --]]
L.FAQ_Question_1_p1 = [[
This issue normally happens when there is old or corrupt data in the database, which BagSync cannot interpret.  The problem can also occur when there is overwhelming amount of data for BagSync to go through.  If you have thousands of items across multiple characters, that's a lot of data to go through within a second.  This can lead to your client stuttering for a brief moment.  Finally, another cause for this problem is having an extremely old computer.  Older computer's will experience hitching/stuttering as BagSync processes thousands of item and character data.  Newer computer's with faster CPU's and memory don't typically have this issue.

In order to fix this problem, you can try resetting the database.  This usually resolves the problem.  Use the following slash command. |cFF99CC33/bgs resetdb|r
If this does not resolve your issue, please file an issue ticket on GitHub for BagSync.
]]
--[[Translation missing --]]
L.FAQ_Question_2 = "No item data for my other WOW accounts found in a |cFFDF2B2Bsingle|r |cff3587ffBattle.net|r account."
--[[Translation missing --]]
L.FAQ_Question_2_p1 = [[
Addon's do not have the ability to read data from other WOW accounts.  This is because they don't share the same SavedVariable folder.  This is a built in limitation within Blizzard's WOW Client.  Therefore, you will not be able to see item data for multiple WOW accounts under a |cFFDF2B2Bsingle|r |cff3587ffBattle.net|r.  BagSync will only be able to read character data across multiple realms within the same WOW Account, not the entire Battle.net account.

There is a way to connect multiple WOW Accounts, within a |cFFDF2B2Bsingle|r |cff3587ffBattle.net|r account, so that they share the same SavedVariables folder.  This involves creating Symlink folders.  I will not provide assistance on this.  So don't ask!  Please visit the following guide for more details.  |cFF99CC33https://www.wowhead.com/guide=934|r
]]
--[[Translation missing --]]
L.FAQ_Question_3 = "Can you view item data from |cFFDF2B2Bmultiple|r |cff3587ffBattle.net|r Accounts?"
--[[Translation missing --]]
L.FAQ_Question_3_p1 = "No, it's not possible.  I will not provide assistance in this.  So don't ask!"
--[[Translation missing --]]
L.FAQ_Question_4 = "Can I view item data from multiple WOW accounts |cFFDF2B2Bcurrently logged in|r?"
--[[Translation missing --]]
L.FAQ_Question_4_p1 = "Currently BagSync does not support transmitting data between multiple logged in WOW accounts.  This may change in the future."
--[[Translation missing --]]
L.FAQ_Question_5 = "Why do I get a message that guild bank scanning is incomplete?"
--[[Translation missing --]]
L.FAQ_Question_5_p1 = [[
BagSync has to query the server for |cFF99CC33ALL|r your guild bank information.  It takes time for the server to transmit all the data.  In order for BagSync to properly store all your items, you must wait until the server query is complete.  When the scanning process is complete, BagSync will notify you in chat.  Leaving the Guild Bank window before the scanning process is done, will result in incorrect data being stored for your Guild Bank.
]]
--[[Translation missing --]]
L.FAQ_Question_6 = "Why do I see [FakeID] instead of [ItemID] for Battle Pets?"
--[[Translation missing --]]
L.FAQ_Question_6_p1 = [[
Blizzard does not assign ItemID's to Battle Pets for WOW.  Instead, Battle Pets in WOW are assigned a temporary PetID from the server.  This PetID is not unique and will be changed when the server resets.  In order to keep track of Battle Pets, BagSync generates a FakeID.  A FakeID is generated from static numbers associated with the Battle Pet.  Using a FakeID allows BagSync to track Battle Pets even across server resets.
]]
--[[Translation missing --]]
L.FAQ_Question_7 = "What is accurate Battle Pet scanning in Guild Bank & Mailbox?"
--[[Translation missing --]]
L.FAQ_Question_7_p1 = [[
Blizzard does not store Battle Pets in the Guild Bank or Mailbox with a proper ItemID or SpeciesID.  In fact Battle Pets are stored in the Guild Bank and Mailbox as |cFF99CC33[Pet Cage]|r with an ItemID of |cFF99CC3382800|r.  This makes grabbing any data in regards to specific Battle Pets difficult for addon authors.  You can see for yourself in the Guild Bank transaction logs, you'll notice Battle Pets are stored as |cFF99CC33[Pet Cage]|r.  If you link one from a Guild Bank it will also be displayed as |cFF99CC33[Pet Cage]|r.  In order to get by this problem, there are two methods that can be used.  The first method is assigning the Battle Pet to a tooltip and then grabbing the SpeciesID from there.  This requires the server to respond to the WOW client and can potentially lead to massive lag, especially if there is a lot of Battle Pets in the Guild Bank.  The second method uses the iconTexture of the Battle Pet to try to find the SpeciesID.  This is sometimes inaccurate as certain Battle Pets share the same iconTexture.  Example:  Toxic Wasteling shares the same iconTexture as Jade Oozeling.  Enabling this option will force the tooltip scanning method to be as accurate as possible, but it can potentially cause lag.  |cFFDF2B2BThere is no way around this until Blizzard gives us more data to work with.|r
]]
