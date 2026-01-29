
local _, BSYC = ...
local L = BSYC:NewLocale("koKR")
if not L then return end

--PLEASE LOOK AT enUS.lua for a complete localization list

--special thanks to WetU @ GitHub

L.Yes = "네"
L.No = "아니오"
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
L.Tooltip_warband = "전투부대"
L.TooltipSmall_bag = "P"
L.TooltipSmall_bank = "B"
L.TooltipSmall_reagents = "R"
L.TooltipSmall_equip = "E"
L.TooltipSmall_guild = "G"
L.TooltipSmall_mailbox = "M"
L.TooltipSmall_void = "V"
L.TooltipSmall_auction = "A"
L.TooltipSmall_warband = "W"
--do not touch these unless requiring a new image for a specific localization
L.TooltipIcon_bag = [[|TInterface\AddOns\BagSync\media\bag:13:13|t]]
L.TooltipIcon_bank = [[|TInterface\AddOns\BagSync\media\bank:13:13|t]]
L.TooltipIcon_reagents = [[|TInterface\AddOns\BagSync\media\reagents:13:13|t]]
L.TooltipIcon_equip = [[|TInterface\AddOns\BagSync\media\equip:13:13|t]]
L.TooltipIcon_guild = [[|TInterface\AddOns\BagSync\media\guild:13:13|t]]
L.TooltipIcon_mailbox = [[|TInterface\AddOns\BagSync\media\mailbox:13:13|t]]
L.TooltipIcon_void = [[|TInterface\AddOns\BagSync\media\void:13:13|t]]
L.TooltipIcon_auction = [[|TInterface\AddOns\BagSync\media\auction:13:13|t]]
L.TooltipIcon_warband = [[|TInterface\AddOns\BagSync\media\warband:13:13|t]]
L.TooltipTotal = "합계:"
L.TooltipTabs = "T:"
L.TooltipItemID = "[아이템ID]:"
L.TooltipCurrencyID = "[화폐ID]:"
L.TooltipFakeID = "[가짜ID]:"
L.TooltipExpansion = "[확장팩]:"
L.TooltipItemType = "[아이템유형]:"
L.TooltipDelimiter = ", "
L.TooltipRealmKey = "서버키:"
L.TooltipDetailsInfo = "아이템 상세 요약"
L.DetailsBagID = "가방:"
L.DetailsSlot = "슬롯:"
L.DetailsTab = "탭:"
L.DebugEnable = "디버그 활성화"
L.DebugCache = "캐시 비활성화"
L.DebugDumpOptions = "덤프 설정 |cff3587ff[디버그]|r"
L.DebugIterateUnits = "반복 단위 |cff3587ff[디버그]|r"
L.DebugDBTotals = "DB 합계 |cff3587ff[디버그]|r"
L.DebugAddonList = "애드온 목록 |cff3587ff[디버그]|r"
L.DebugExport = "출력"
L.DebugWarning = "|cFFDF2B2B경고:|R BagSync 디버그가 현재 사용중입니다! |cFFDF2B2B(랙을 발생시킬 수 있음)|r"
L.Search = "검색"
L.Debug = "디버그"
L.Reset = "초기화"
L.Clear = "초기화"
L.AdvancedSearch = "심화 검색"
L.AdvancedSearchInformation = "* BagSync |cffff7d0a[CR]|r 과 |cff3587ff[BNet]|r 설정을 사용합니다."
L.AdvancedLocationInformation = "* 아무 선택이 없으면 모두 선택한 것이 기본값입니다."
L.Units = "유닛:"
L.Locations = "위치:"
L.Profiles = "프로필"
L.SortOrder = "정렬 순서"
L.Professions = "전문기술"
L.Currency = "화폐"
L.Blacklist = "차단목록"
L.Whitelist = "허가목록"
L.Recipes = "제조법"
L.Details = "세부 정보"
L.Gold = "소지금"
L.Close = "닫기"
L.FixDB = "데이터 갱신"
L.Config = "설정"
L.DeleteWarning = "삭제할 프로필을 선택하세요.\n참고: 되돌릴 수 없습니다!!!"
L.Delete = "삭제"
L.SelectAll = "모두 선택"
L.FixDBComplete = "BagSync FixDB(데이터 갱신)이 실행되었습니다! 데이터베이스가 최적화됩니다!"
L.ResetDBInfo = "BagSync:\n데이터베이스를 초기화 하시겠습니까?\n|cFFDF2B2B주의: 추천하지 않습니다!|r"
L.ON = "ON"
L.OFF = "OFF"
L.LeftClickSearch = "|cffddff00클릭|r |cff00ff00= 검색창|r"
L.RightClickBagSyncMenu = "|cffddff00오른쪽 클릭|r |cff00ff00= BagSync 메뉴|r"
L.ProfessionInformation = "|cff00ff00제조법을 보려면 전문 기술을|r |cffddff00클릭|r|cff00ff00하세요.|r"
L.ErrorUserNotFound = "BagSync: 오류 사용자를 찾을 수 없음!"
L.EnterItemID = "아이템ID를 입력해주세요. (http://Wowhead.com/ 이용)"
L.AddGuild = "길드 추가"
L.AddItemID = "아이템ID 추가"
L.PleaseRescan = "|cFF778899[다시 갱신하세요.]|r"
L.UseFakeID = "전투 애완동물은 [ItemID] 대신 [FakeID]를 사용합니다."
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
L.ProfileBeenRemoved = "[%s] 프로필이 삭제되었습니다!"
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
L.ScanGuildBankDone = "길드 은행 스캔 완료!"
L.ScanGuildBankError = "경고: 길드 은행 스캔이 완료되지 않았습니다."
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
L.Display_GSC = "소지금 창에 |cFFFFD700골드|r, |cFFC0C0C0실버|r 및 |cFFB87333코퍼|r를 표시합니다."
L.DisplayMinimap = "BagSync 미니맵 버튼을 표시합니다."
L.DisplayFaction = "양 진영 아이템을 표시합니다 (얼라이언스/호드)."
L.DisplayClassColor = "캐릭터의 이름에 직업 색상을 적용합니다."
L.DisplayItemTotalsByClassColor = "캐릭터의 직업 색상으로 아이템의 합계를 표시합니다."
L.DisplayTooltipOnlySearch = "|cFF99CC33(오직)|r 검색 창에만 BagSync 툴팁을 표시합니다."
L.DisplayLineSeparator = "빈 줄로 분리하여 표시합니다."
L.DisplayCR = "|cffff7d0a[연결 서버]|r 캐릭터를 표시합니다. |cffff7d0a[CR]|r"
L.DisplayBNET = "모든 Battle.net 계정 캐릭터를 표시합니다. |cff3587ff[BNet]|r |cFFDF2B2B(권장하지 않음)|r"
L.DisplayItemID = "툴팁에 아이템ID를 표시합니다."
L.DisplayWhiteListOnly = "허가목록에 있는 아이템만 툴팁에 수량을 표시합니다."
L.DisplaySourceExpansion = "아이템 툴팁에 확장팩을 표시합니다. |cFF99CC33[현재 확장팩만 가능]|r"
L.DisplayItemTypes = "툴팁에 아이템 유형을 [아이템 유형 | 속성] 으로 표시합니다."
L.DisplayTooltipTags = "태그"
L.DisplayTooltipStorage = "아이템 위치"
L.DisplayTooltipExtra = "추가기능"
L.DisplayTooltipCurrencyData = "블리자드 화폐 창에 BagSync 툴팁 데이터를 표시합니다."
L.DisplaySortOrderHelp = "정렬 순서 도움말"
L.DisplaySortOrderStatus = "현재 정렬 순서: [%s]"
L.DisplayWhitelistHelp = "허가목록 도움말"
L.DisplayWhitelistStatus = "현재 허가목록: [%s]"
L.DisplayWhitelistHelpInfo = "허가목록에 아이템ID를 입력할 수 있습니다. \n\n애완동물을 입력하려면 아이템ID가 아니라 FakeID를 사용해야 합니다. 설정에서 아이템ID 툴팁을 사용하여 FakeID를 가져올 수 있습니다.\n\n|cFFDF2B2B화폐 창에서는 동작하지 않습니다.|r"
L.DisplayWhitelistHelpInfo2 = "\n\n\n\n|cFFFF7D0A경고: 이 허가목록 기능은 이 목록에 있는 아이템을 제외한 |cFFFFFFFF--모든--|r 아이템의 BagSync 카운트를 차단합니다.|r\n|cFF09DBE0블랙리스트의 반대입니다!|r"
L.DisplayTooltipAccountWide = "교차 서버"
L.DisplayAccountWideTagOpts = "|cFF99CC33태그 설정 ( |cffff7d0a[CR]|r & |cff3587ff[BNet]|r )|r"
L.DisplayGreenCheck = "현재 캐릭터 이름 옆에 %s를 표시합니다."
L.DisplayCurrentCharacter = "현재 캐릭터"
L.DisplayCurrentCharacterOnly = "현재 캐릭터 |cFFFFD700전용!|r BagSync 툴팁 데이터를 표시합니다. |cFFDF2B2B(추천하지 않음)|r"
L.DisplayBlacklistCurrentCharOnly = "현재 캐릭터 |cFFFFD700전용!|r 차단목록 아이템 수량을 표시합니다. |cFFDF2B2B(추천하지 않음)|r"
L.DisplayCurrentRealmName = "플레이어의 |cFF4CBB17[현재 서버]|r를 표시합니다."
L.DisplayCurrentRealmShortName = "|cFF4CBB17[현재 서버]|r의 짧은 이름을 사용합니다."
L.DisplayRealmIDTags = "캐릭터에 서버식별자 |cffff7d0a[CR]|r과 |cff3587ff[BNet]|r을 표시합니다."
L.DisplayRealmNames = "서버 이름을 표시합니다."
L.DisplayRealmAstrick = "|cffff7d0a[CR]|r과 |cff3587ff[BNet]|r 서버 이름 대신 [*]을 표시합니다."
L.DisplayShortRealmName = "|cffff7d0a[CR]|r과 |cff3587ff[BNet]|r 서버 이름을 축약해서 표시합니다."
L.DisplayFactionIcons = "툴팁에 진영 아이콘을 표시합니다."
L.DisplayGuildBankTabs = "툴팁에 길드은행 탭 [1,2,3, 등]을 사용합니다."
L.DisplayWarbandBankTabs = "툴팁에 전투부대 은행 탭 [1,2,3, 등]을 표시합니다."
L.DisplayBankTabs = "툴팁에 은행 탭 [1,2,3, 등]을 표시합니다."
L.DisplayEquipBagSlots = "툴팁에 장착한 가방 슬롯 <1,2,3, 등>을 표시합니다."
L.DisplayRaceIcons = "툴팁에 캐릭터 종족 아이콘을 표시합니다."
L.DisplaySingleCharLocs = "아이템의 위치를 단축문자를 사용하여 표시합니다."
L.DisplayIconLocs = "아이템의 위치를 아이콘을 사용하여 표시합니다."
L.DisplayAccurateBattlePets = "길드 은행 및 우편함에 정확한 전투 애완 동물 사용. |cFFDF2B2B(랙을 발생시킴)|r |cff3587ff[BagSync의 FAQ를 참고하세요.]|r"
L.DisplaySortCurrencyByExpansionFirst = "BagSync 화폐 창을 알파벳 순이 아니라 확장팩 기준으로 먼저 정렬합니다."
L.DisplaySorting = "툴팁 정렬"
L.DisplaySortInfo = "기본: 서버의 캐릭터 이름으로 툴팁은 알파벳 순으로 정렬되어 있습니다."
L.SortMode = "정렬 모드"
L.SortMode_RealmCharacter = "서버 후 캐릭터 (기본)"
L.SortMode_Character = "캐릭터"
L.SortMode_ClassCharacter = "직업 후 캐릭터"
L.SortCurrentPlayerOnTop = "기본 정렬을 사용하고 현재 캐릭터를 항상 맨 위에 표시합니다."
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
L.ColorWarband = "BagSync [전투부대] 툴팁 색상"
L.ColorCurrentRealm = "BagSync [현재 서버] 툴팁 색상"
L.ColorCR = "BagSync [연결 서버] 툴팁 색상"
L.ColorBNET = "BagSync [Battle.Net] 툴팁 색상"
L.ColorItemID = "BagSync [아이템ID] 툴팁 색상"
L.ColorExpansion = "[확장팩] 툴팁 색상"
L.ColorItemTypes = "[아이템유형] 툴팁 색상"
L.ColorGuildTabs = "길드 은행 탭 [1,2,3, 등] 툴팁 색상"
L.ColorWarbandTabs = "전투부대 은행 탭 [1,2,3, 등] 툴팁 색상"
L.ColorBankTabs = "은행 탭 [1,2,3, 등] 툴팁 색상"
L.ColorBagSlots = "가방 슬롯 <1,2,3, 등> 툴팁 색상"
L.ConfigDisplay = "표시"
L.ConfigTooltipHeader = "표시할 BagSync 툴팁 정보를 설정합니다."
L.ConfigColor = "색상"
L.ConfigColorHeader = "BagSync 툴팁 정보의 색상을 설정합니다."
L.ConfigMain = "일반"
L.ConfigMainHeader = "BagSync의 일반 설정입니다."
L.ConfigKeybindings = "단축키"
L.ConfigKeybindingsHeader = "BagSync 기능의 단축키 설정입니다."
L.ConfigExternalTooltip = "외부 툴팁"
L.ConfigFont = "글꼴"
L.ConfigFontSize = "글꼴 크기"
L.ConfigFontOutline = "외곽선"
L.ConfigFontOutline_NONE = "없음"
L.ConfigFontOutline_OUTLINE = "외곽선"
L.ConfigFontOutline_THICKOUTLINE = "ThickOutline"
L.ConfigFontMonochrome = "Monochrome"
L.ConfigTracking = "Tracking"
L.ConfigTrackingHeader = "Tracking settings for all stored BagSync database locations."
L.ConfigTrackingCaution = "주의"
L.ConfigTrackingModules = "모듈"
L.ConfigTrackingInfo = [[
|cFFDF2B2B참고|r: 모듈을 비활성화하면 BagSync가 해당 모듈의 추적과 데이터베이스 저장을 중지합니다.
비활성화된 모듈은 BagSync 창, 슬래시 명령어, 툴팁 또는 미니맵 버튼에 표시되지 않습니다.
]]
L.TrackingModule_Bag = "가방"
L.TrackingModule_Bank = "은행"
L.TrackingModule_Reagents = "재료 은행"
L.TrackingModule_Equip = "착용 아이템"
L.TrackingModule_Mailbox = "우편함"
L.TrackingModule_Void = "공허 은행"
L.TrackingModule_Auction = "경매장"
L.TrackingModule_Guild = "길드 은행"
L.TrackingModule_Professions = "전문 기술 / 제작"
L.TrackingModule_Currency = "화폐 / 토큰"
L.TrackingModule_WarbandBank = "전쟁부대 은행"
L.WarningItemSearch = "경고: 총 [|cFFFFFFFF%s|r]개의 아이템이 검색되지 않았습니다!\n\nBagSync는 계속해서 서버/캐시의 응답을 기다립니다.\n\n새로고침 버튼을 누르세요."
L.WarningCurrencyUpt = "화폐 업데이트에 실패했습니다. 다음 캐릭터로 로그인하세요: "
L.WarningHeader = "경고!"
L.SavedSearch = "저장된 검색"
L.SavedSearch_Add = "검색 추가"
L.SavedSearch_Warn = "검색창에 내용을 입력해야 합니다."
---------------------------------------
--Blizzard doesn't return the same header title in the Currency/Token window that is used in their expansion globals.
--Meaning that, "The Burning Crusade" is listed as "Burning Crusade" in the Currency/Token window.  The same for "The War Within" being shown as "War Within"
--In order to do a proper sorting of the Currency/Token Window for BagSync.  I've done the following steps
--1) Removed all spaces and special characters from the expansion name
--2) forced all characters to be lower case
--3) Use the filter below to remove any other additional words in the name to match it to the currency/token window.
--
--Example: "The War Within" and "War Within" gets matched as "warwithin".  "Battle for Azeroth" gets matched as "battleforazeroth"
--You can add as many words as you want below, just make sure it's lowercase, no spaces or symbols and to follow each entry with a comma
---------------------------------------
L.CurrencySortFilters = {
	"the",
}
---------------------------------------
--Localization Note:  Please be advised that the commands for the SearchHelp are english only, however the variables can be any language.  Example: class:<name of class in your locale>
--This includes name searches like name:<name in your locale>
---------------------------------------
L.SearchHelpHeader = "검색 도움말"
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
|cff00ffff<keyword>|r = |cFF99CC33k|r ; |cFF99CC33key|r ; |cFF99CC33keyword|r | |cFFFFD580k:<keyword>|r (key:quest) (keywords: soulbound, bound, boe, bop, bou, boa, quest, unique, toy, reagent, crafting, naval, follower, follow, power, appearance, apperance)
|cff00ffff<class>|r = |cFF99CC33c|r ; |cFF99CC33class|r | |cFFFFD580c:<classname>|r ; |cFFFFD580class:<classname>|r (class:shaman)
|cffff7d0aOperators <op>|r:
|cFF99CC33:|r | |cFF99CC33=|r | |cFF99CC33==|r | |cFF99CC33!=|r | |cFF99CC33~=|r | |cFF99CC33<|r | |cFF99CC33>|r | |cFF99CC33<=|r | |cFF99CC33>=|r
|cFFDF2B2BNote:|r |cFF99CC33!=|r and |cFF99CC33~=|r are supported (not equal).
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
L.FAQ_Question_1 = "툴팁에서 끊김/버벅임/렉이 발생합니다."
L.FAQ_Question_1_p1 = [[
이 문제는 보통 BagSync가 해석할 수 없는 오래되었거나 손상된 데이터가 데이터베이스에 있을 때 발생합니다. 또한 BagSync가 처리해야 하는 데이터가 너무 많을 때도 생길 수 있습니다. 여러 캐릭터에 수천 개의 아이템이 있다면, 1초 안에 처리해야 할 데이터가 매우 많아 잠깐 클라이언트가 버벅일 수 있습니다. 마지막으로, 매우 오래된 컴퓨터를 사용 중인 경우에도 BagSync가 수천 개의 아이템/캐릭터 데이터를 처리하면서 끊김이 발생할 수 있습니다. 일반적으로 더 빠른 CPU와 메모리를 가진 최신 컴퓨터에서는 이런 문제가 잘 발생하지 않습니다.

해결을 위해 데이터베이스를 초기화해 보세요. 대부분 이 방법으로 문제가 해결됩니다. 다음 명령어를 사용합니다: |cFF99CC33/bgs resetdb|r
그래도 해결되지 않으면 BagSync GitHub에 이슈를 등록해 주세요.
]]
L.FAQ_Question_2 = "|cFFDF2B2B단일|r |cff3587ffBattle.net|r 계정에서 다른 WoW 계정의 아이템 데이터가 보이지 않습니다."
L.FAQ_Question_2_p1 = [[
애드온은 다른 WoW 계정의 데이터를 읽을 수 없습니다. 이는 각 계정이 동일한 SavedVariables 폴더를 공유하지 않기 때문이며, Blizzard WoW 클라이언트의 내장 제한 사항입니다. 따라서 |cFFDF2B2B단일|r |cff3587ffBattle.net|r 계정 아래에 여러 WoW 계정이 있더라도 서로의 아이템 데이터를 볼 수 없습니다. BagSync는 동일한 WoW 계정 내에서 여러 서버의 캐릭터 데이터를 읽을 수 있을 뿐, Battle.net 계정 전체를 대상으로 하지는 않습니다.

다만 |cFFDF2B2B단일|r |cff3587ffBattle.net|r 계정 내의 여러 WoW 계정이 같은 SavedVariables 폴더를 공유하도록 연결하는 방법(심볼릭 링크/시mlink 폴더 생성)이 있긴 합니다. 이 방법에 대한 지원은 제공하지 않으니 묻지 마세요! 자세한 내용은 다음 가이드를 참고하세요: |cFF99CC33https://www.wowhead.com/guide=934|r
]]
L.FAQ_Question_3 = "|cFFDF2B2B여러|r |cff3587ffBattle.net|r 계정의 아이템 데이터를 볼 수 있나요?"
L.FAQ_Question_3_p1 = "아니요, 불가능합니다. 이 부분에 대한 지원은 제공하지 않으니 묻지 마세요!"
L.FAQ_Question_4 = "|cFFDF2B2B현재 로그인 중인|r 여러 WoW 계정의 아이템 데이터를 볼 수 있나요?"
L.FAQ_Question_4_p1 = "현재 BagSync는 동시에 로그인된 여러 WoW 계정 간의 데이터 전송을 지원하지 않습니다. 이는 향후 변경될 수 있습니다."
L.FAQ_Question_5 = "길드 은행 스캔이 완료되지 않았다는 메시지가 뜨는 이유는 무엇인가요?"
L.FAQ_Question_5_p1 = [[
BagSync는 길드 은행 정보를 |cFF99CC33모두|r 가져오기 위해 서버에 질의해야 합니다. 서버가 모든 데이터를 전송하는 데 시간이 걸리므로, BagSync가 아이템을 올바르게 저장하려면 서버 질의가 완료될 때까지 기다려야 합니다. 스캔이 완료되면 BagSync가 채팅으로 알려드립니다. 스캔이 끝나기 전에 길드 은행 창을 닫으면 길드 은행 데이터가 잘못 저장될 수 있습니다.
]]
L.FAQ_Question_6 = "전투 애완동물이 [ItemID] 대신 [FakeID]로 표시되는 이유는 무엇인가요?"
L.FAQ_Question_6_p1 = [[
Blizzard는 WoW의 전투 애완동물에 ItemID를 부여하지 않습니다. 대신 전투 애완동물은 서버에서 임시 PetID를 부여받습니다. 이 PetID는 고유하지 않으며 서버가 리셋되면 변경됩니다. 전투 애완동물을 추적하기 위해 BagSync는 FakeID를 생성합니다. FakeID는 전투 애완동물과 연관된 고정 숫자(정적 값)로 만들어집니다. FakeID를 사용하면 서버 리셋 이후에도 전투 애완동물을 추적할 수 있습니다.
]]
L.FAQ_Question_7 = "길드 은행/우편함의 전투 애완동물 '정확한 스캔'이란 무엇인가요?"
L.FAQ_Question_7_p1 = [[
Blizzard는 길드 은행이나 우편함에 전투 애완동물을 올바른 ItemID 또는 SpeciesID로 저장하지 않습니다. 실제로 전투 애완동물은 길드 은행과 우편함에 |cFF99CC33[Pet Cage]|r 형태로 저장되며 ItemID는 |cFF99CC3382800|r으로 표시됩니다. 이 때문에 특정 전투 애완동물에 대한 데이터를 애드온 제작자가 얻기 어렵습니다. 길드 은행 거래 기록을 보면 전투 애완동물이 |cFF99CC33[Pet Cage]|r로 저장되어 있는 것을 확인할 수 있습니다. 길드 은행에서 링크해도 |cFF99CC33[Pet Cage]|r로 표시됩니다.

이 문제를 우회하기 위해 두 가지 방법을 사용할 수 있습니다. 첫 번째는 전투 애완동물을 툴팁에 할당한 뒤, 그 툴팁에서 SpeciesID를 가져오는 방법입니다. 이는 서버가 WoW 클라이언트에 응답해야 하며, 특히 길드 은행에 전투 애완동물이 많을 경우 큰 렉을 유발할 수 있습니다. 두 번째는 전투 애완동물의 iconTexture를 이용해 SpeciesID를 찾는 방법입니다. 다만 일부 전투 애완동물은 같은 iconTexture를 공유하기 때문에 부정확할 수 있습니다. 예: Toxic Wasteling은 Jade Oozeling과 같은 iconTexture를 공유합니다. 이 옵션을 활성화하면 툴팁 스캔 방식이 가능한 한 정확하도록 강제하지만, 렉을 유발할 수 있습니다. |cFFDF2B2BBlizzard가 더 많은 데이터를 제공하기 전에는 완벽한 해결 방법이 없습니다.|r
]]
L.BagSyncInfoWindow = [[
BagSync는 기본적으로 연결된 서버의 캐릭터에 대한 툴팁 데이터만 표시합니다. ( |cffff7d0a[CR]|r )

연결된 서버 ( |cffff7d0a[CR]|r )는 서로 연결된 서버들입니다.

전체 목록은 다음을 참고하세요:
(|cFF99CC33 https://tinyurl.com/msncc7j6 |r)


|cFFfd5c63BagSync는 기본적으로 전체 Battle.Net 계정의 데이터를 표시하지 않습니다. 이 기능을 활성화해야 합니다!|r
( |cff3587ff[BNet]|r )

|cFF52D386전체 Battle.net 계정 ( |cff3587ff[BNet]|r )의 모든 캐릭터를 보고 싶다면, BagSync 설정 창의 [Account Wide]에서 옵션을 활성화하세요.|r

옵션 이름:
]]
