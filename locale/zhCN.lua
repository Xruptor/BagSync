
local L = LibStub("AceLocale-3.0"):NewLocale("BagSync", "zhCN")
if not L then return end

--  zhCN client (NGA-[男爵凯恩])
--  Last update: 2024/8/15

L.Yes = "Yes"
L.No = "No"
L.Page = "页面"
L.Done = "完成"
L.Realm = "服务器:"
L.TooltipCR_Tag = "CR"
L.TooltipBNET_Tag = "BNet"
L.Tooltip_bag = "背包"
L.Tooltip_bank = "银行"
L.Tooltip_equip = "已装备"
L.Tooltip_guild = "公会"
L.Tooltip_mailbox = "信箱"
L.Tooltip_void = "虚空仓库"
L.Tooltip_reagents = "材料银行"
L.Tooltip_auction = "拍卖"
L.Tooltip_warband = "战团"
L.TooltipSmall_bag = "包"
L.TooltipSmall_bank = "银"
L.TooltipSmall_reagents = "材"
L.TooltipSmall_equip = "装"
L.TooltipSmall_guild = "公"
L.TooltipSmall_mailbox = "邮"
L.TooltipSmall_void = "虚"
L.TooltipSmall_auction = "拍"
L.TooltipSmall_warband = "战"
L.TooltipTotal = "总计:"
L.TooltipGuildTabs = "公:"
L.TooltipBagSlot = "位:"
L.TooltipItemID = "[物品ID]:"
L.TooltipDebug = "[Debug]:"
L.TooltipCurrencyID = "[货币ID]:"
L.TooltipFakeID = "[虚拟ID]:"
L.TooltipExpansion = "[版本]:"
L.TooltipItemType = "[类型]:"
L.TooltipDelimiter = ", "
L.TooltipRealmKey = "服务器:"
L.TooltipDetailsInfo = "物品详细摘要"
L.DetailsBagID = "背包位:"
L.DetailsSlot = "位置:"
L.DetailsTab = "标签:"
L.Debug_DEBUG = "Debug"
L.Debug_INFO = "信息"
L.Debug_TRACE = "追踪"
L.Debug_WARN = "警告"
L.Debug_FINE = "详情"
L.DebugEnable = "启用 Debug"
L.DebugCache = "禁用缓存"
L.DebugDumpOptions = "存储选项 |cff3587ff[Debug]|r"
L.DebugIterateUnits = "重复单位 |cff3587ff[Debug]|r"
L.DebugDBTotals = "数据库总计 |cff3587ff[Debug]|r"
L.DebugAddonList = "插件列表 |cff3587ff[Debug]|r"
L.DebugExport = "导出"
L.DebugWarning = "|cFFDF2B2B警告:|R BagSync Debug 当前已启用! |cFFDF2B2B（会导致滞后/卡顿）|r"
L.Search = "搜索"
L.Debug = "DeBug"
L.AdvSearchBtn = "搜索/刷新"
L.Reset = "重置"
L.Refresh = "刷新"
L.Clear = "清除"
L.AdvancedSearch = "高级搜索"
L.AdvancedSearchInformation = "* 使用 BagSync 的|cffff7d0a[CR]|r 和 |cff3587ff[BNet]|r 设置"
L.AdvancedLocationInformation = "* 选择所有因为无默认"
L.Units = "名字:"
L.Locations = "位置:"
L.Profiles = "信息"
L.SortOrder = "排序"
L.Professions = "专业"
L.Currency = "货币"
L.Blacklist = "黑名单"
L.Whitelist = "白名单"
L.Recipes = "配方"
L.Details = "详细信息"
L.Gold = "金币"
L.Close = "关闭"
L.FixDB = "优化数据库"
L.Config = "设置"
L.DeleteWarning = "选择要删除的设定档. 注意: 这是不可逆的!"
L.Delete = "删除"
L.Confirm = "确认"
L.SelectAll = "全选"
L.FixDBComplete = "已执行FixDB, 数据库已优化!"
L.ResetDBInfo = "BagSync:\n您确定要重置数据库吗?\n|cFFDF2B2B注意: 这是不可逆的!|r"
L.ON = "开[ON]"
L.OFF = "关[OFF]"
L.LeftClickSearch = "|cffddff00左键|r |cff00ff00= 搜索窗|r"
L.RightClickBagSyncMenu = "|cffddff00右键|r |cff00ff00= 菜单|r"
L.ProfessionInformation = "|cffddff00左键|r |cff00ff00查看专业配方|r"
L.ClickViewProfession = "点击查看专业: "
L.ClickHere = "点这里"
L.ErrorUserNotFound = "BagSync: 错误,未找到用户!"
L.EnterItemID = "输入物品ID（请用 http://Wowhead.com/ 查询。）"
L.AddGuild = "添加公会"
L.AddItemID = "添加物品ID"
L.RemoveItemID = "移除物品ID"
L.PleaseRescan = "|cFF778899[请重新扫描]|r"
L.UseFakeID = "使用虚拟ID[FakeID]用于战斗宠物的物品ID[ItemID]。"
L.ItemIDNotFound = "[%s] 未找到物品ID。再试一次!"
L.ItemIDNotValid = "[%s] 物品ID无效或者查询服务器未响应。再试一次!"
L.ItemIDRemoved = "[%s] 物品ID已移除"
L.ItemIDAdded = "[%s] 已添加物品ID"
L.ItemIDExistBlacklist = "[%s] 物品ID已在黑名单数据库中。"
L.ItemIDExistWhitelist = "[%s] 物品ID 已在白名单数据库中。"
L.GuildExist = "公会 [%s] 已在黑名单数据库中"
L.GuildAdded = "公会 [%s] 添加"
L.GuildRemoved = "公会 [%s] 移除"
L.BlackListRemove = "从黑名单中移除 [%s] ?"
L.WhiteListRemove = "从白名单中移除 [%s] ?"
L.BlackListErrorRemove = "黑名单移除时出错。"
L.WhiteListErrorRemove = "白名单移除时出错。"
L.ProfilesRemove = "移除 [%s][|cFF99CC33%s|r] 来自 BagSync 个人资料?"
L.ProfilesErrorRemove = "BagSync 移除时出错。"
L.ProfileBeenRemoved = "[%s][|cFF99CC33%s|r] 从 BagSync 中移除个人资料!"
L.ProfessionsFailedRequest = "[%s] 服务器请求失败。"
L.ProfessionHasRecipes = "左键点击查看专业。"
L.ProfessionHasNoRecipes = "没有查看内容。"
L.KeybindBlacklist = "显示黑名单窗口。"
L.KeybindWhitelist = "显示白名单窗口。"
L.KeybindCurrency = "显示货币窗口。"
L.KeybindGold = "显示金币窗口。"
L.KeybindProfessions = "显示专业窗口。"
L.KeybindProfiles = "显示配置文件。"
L.KeybindSearch = "显示搜索窗口。"
L.ObsoleteWarning = "\n\n注意：过时的物品将继续显示为缺失。 要修复此问题,请再次扫描您的角色以删除过时的物品。\n（背包、银行、虚空银行等 ...)"
L.DatabaseReset = "由于数据库的变化。您的BagSync数据库已重置。"
L.UnitDBAuctionReset = "所有角色的拍卖数据已重置。 "
L.ScanGuildBankStart = "公会银行内信息正在查询服务器,请稍候....."
L.ScanGuildBankDone = "公会银行扫描完成!"
L.ScanGuildBankError = "警告: 公会银行扫描不完整。"
L.ScanGuildBankScanInfo = "扫描公会标签（%s/%s）。"
L.DefaultColors = "默认颜色"
-- ----THESE ARE FOR SLASH COMMANDS OPERATORS
L.SlashItemName = "[物品名称]"
L.SlashSearch = "搜索"
L.SlashGold = "金币"
L.SlashMoney = "金币"
L.SlashConfig = "配置"
L.SlashCurrency = "货币"
L.SlashFixDB = "优化数据库"
L.SlashProfiles = "信息"
L.SlashProfessions = "专业"
L.SlashBlacklist = "黑名单"
L.SlashWhitelist = "白名单"
L.SlashResetDB = "重置"
L.SlashDebug = "Debug"
L.SlashResetPOS = "重置各模块" 
L.SlashSortOrder = "排序"
------------------------
-- ----THESE USE THE SLASH OPERATOR COMMANDS FOUND ABOVE
L.HelpSearchItemName = "快速搜索一件物品"
L.HelpSearchWindow = "打开搜索窗口"
L.HelpGoldTooltip = "显示各角色的金钱统计。"
L.HelpCurrencyWindow = "打开货币窗口。"
L.HelpProfilesWindow = "打开信息窗口。"
L.HelpFixDB = "在BagSync内运行数据库修复。"
L.HelpResetDB = "重置BagSync内的数据库。"
L.HelpConfigWindow = "打开配置文件。"
L.HelpProfessionsWindow = "打开专业窗口。"
L.HelpBlacklistWindow = "打开黑名单窗口。"
L.HelpWhitelistWindow = "打开白名单窗口。"
L.HelpDebug = "打开 BagSync Debug 窗口。"
L.HelpResetPOS = "重置BagSync所有模块的窗口位置。"
L.HelpSortOrder = "角色和公会的自定义排序。"
------------------------
L.EnableBagSyncTooltip = "启用BagSync鼠标提示"
L.ShowOnModifier = "设置BagSync提示快捷键:"
L.ShowOnModifierDesc = "显示在BagSync提示上快捷键设置。"
L.ModValue_NONE = "无（始终显示）"
L.ModValue_ALT = "ALT"
L.ModValue_CTRL = "CTRL"
L.ModValue_SHIFT = "SHIFT"
L.EnableExtTooltip = "在单独窗口上显示物品统计数据"
L.EnableLoginVersionInfo = "显示BagSync的登录信息"
L.FocusSearchEditBox = "打开搜索窗口时专注搜索框"
L.AlwaysShowAdvSearch = "始终显示Bagsync高级搜索窗口"
L.DisplayTotal = "显示[总计]金额。"
L.DisplayGuildGoldInGoldWindow = "显示[公会]金币总数。"
L.Display_GSC = "显示[详细]金额（|cFFFFD700金|r， |cFFC0C0C0银|r 和 |cFFB87333铜|r）。"
L.DisplayGuildBank = "显示[公会银行]物品。|cFF99CC33（需要扫描公会银行）|r"
L.DisplayMailbox = "显示[信箱]物品。"
L.DisplayAuctionHouse = "显示[拍卖行]物品。"
L.DisplayMinimap = "显示[小地图]图标。"
L.DisplayFaction = "显示[双方阵营]物品 （|cff3587ff联盟|r/|cFFDF2B2B部落|r）。"
L.DisplayClassColor = "显示职业颜色。"
L.DisplayItemTotalsByClassColor = "根据角色的职业颜色显示物品总计。"
L.DisplayTooltipOnlySearch = "在搜索窗内|cFF99CC33（仅）|r显示BagSync提示。"
L.DisplayTooltipCurrencyData = "在暴雪货币窗口中显示BagSync数据。"
L.DisplayLineSeparator = "显示空行分割线。"
L.DisplayCurrentCharacter = "当前角色" 
L.DisplayCurrentCharacterOnly = "|cFFFFD700仅限！|r鼠标提示上显示\"当前\"角色的BagSync数据。|cFFDF2B2B（不推荐）|r"
L.DisplayBlacklistCurrentCharOnly = "|cFFFFD700仅限！|r显示\"当前\"角色的黑名单物品数量。|cFFDF2B2B（不推荐）|r"
L.DisplayCurrentRealmName = "显示玩家的\"当前\"|cFF4CBB17[服务器]|r。"
L.DisplayCurrentRealmShortName = "为\"当前\"|cFF4CBB17[服务器]|r使用一个简短的名称。"
L.DisplayCR = "显示\"合并\"|cffff7d0a[服务器]|r信息。|cffff7d0a[CR]|r"
L.DisplayBNET = "显示所有[战网账号]信息 。|cff3587ff[BNet]|r |cFFDF2B2B(不推荐)|r"
L.DisplayItemID = "显示[物品ID]。"
L.DisplaySourceDebugInfo = "在鼠标提示中显示有用的[Debug]信息。"
L.DisplayWhiteListOnly = "在鼠标提示中仅显示[白名单]的物品。"
L.DisplaySourceExpansion = "在鼠标提示中显示[游戏版本]。 |cFF99CC33[仅正式服]|r"
L.DisplayItemTypes = "在鼠标提示中显示[物品类型|子类型]。"
L.DisplayTooltipTags = "各标识符号"
L.DisplayTooltipStorage = "仓库"
L.DisplayTooltipExtra = "其他统计"
L.DisplaySortOrderHelp = "排序帮助"
L.DisplaySortOrderStatus = "当前排序: [%s]"
L.DisplayWhitelistHelp = "白名单帮助"
L.DisplayWhitelistStatus = "当前白名单: [%s]"
L.DisplayWhitelistHelpInfo = "你只能在白名单数据库中输入物品ID. \n\n输入战斗宠物请使用虚拟ID[FakeID]而不是物品ID[ItemID], 你可以通过在BagSync设置内启用鼠标提示物品ID[ItemID]功能来获取虚拟ID[FakeID]。\n\n|cFFDF2B2B这对货币窗口不起作用。|r"
L.DisplayWhitelistHelpInfo2 = "\n\n\n\n|cFFFF7D0A警告：此白名单功能将阻止|cFFFFFFFF--所有--|r 物品被BagSync统计，但在此列表中找到的物品除外。|r\n|cFF09DBE0这是一个反向黑名单！|r"
L.DisplayTooltipAccountWide = "账号信息"
L.DisplayAccountWideTagOpts = "|cFF99CC33选项 ( |cffff7d0a[CR]|r和|cff3587ff[BNet]|r )|r"
L.DisplayGreenCheck = "在当前角色名前显示 %s 。"
L.DisplayRealmIDTags = "显示 |cffff7d0a[CR]|r和|cff3587ff[BNet]|r 符号。"
L.DisplayRealmNames = "显示[服务器[名字。"
L.DisplayRealmAstrick = "显示[*]而不是显示 |cffff7d0a[CR]|r和|cff3587ff[BNet]|r。"
L.DisplayShortRealmName = "显示短位名字 |cffff7d0a[CR]|r和|cff3587ff[BNet]|r。"
L.DisplayFactionIcons = "显示[阵营]图标。"
L.DisplayGuildBankTabs = "在鼠标提示中显示[银行]标签[1,2,3, 等...]。"
L.DisplayWarbandBankTabs = "在鼠标提示中显示[战团银行]标签[1,2,3, 等...]。"
L.DisplayEquipBagSlots = "在鼠标提示中显示[装备]背包栏位<1,2,3, 等...>。"
L.DisplayRaceIcons = "在鼠标提示中显示角色种族图标。"
L.DisplaySingleCharLocs = "|cff31d54f[简写]|r 显示物品存储的位置。"
L.DisplayIconLocs = "|cff31d54f[图标]|r 显示物品存储的位置。"
L.DisplayGuildSeparately = "显示[公会]名字和物品总计与角色总计分开。"
L.DisplayGuildCurrentCharacter = "显示[公会]仅限当前的游戏角色。"
L.DisplayGuildBankScanAlert = "显示公会银行扫描窗口。"
L.DisplayAccurateBattlePets = "启用精准扫描公会银行和邮箱中的战斗宠物。|cFFDF2B2B（可能导致滞后/卡顿）|r |cff3587ff[详见 BagSync FAQ]|r"
L.DisplaySorting = "鼠标提示排序"
L.DisplaySortInfo = "默认: 鼠标提示排序是根据服务器名的字母顺序，然后是角色名称来排序。"
L.SortTooltipByTotals = "按照总数进行排序，而不是字母顺序排列。"
L.SortByCustomSortOrder = "按照自定义顺序排序。"
L.CustomSortInfo = "列表使用升序排列 (1,2,3)"
L.CustomSortInfoWarn = "|cFF99CC33注意: 仅使用数字! (-1,0,3,4)|r"
L.DisplayShowUniqueItemsTotals = "启用该选项将允许物品总数量增加独特的物品,无论物品的统计信息。|cFF99CC33（推荐）|r"
L.DisplayShowUniqueItemsTotals_2 = [[
某些物品例如 |cffff7d0a[传说物品]|r 可以共享相同的名字但具有不同的统计数据。由于这些物品是彼此独立处理,因此有时不计入总物品数。启用此选项将完全忽略独特的物品统计数据并一视同仁,只要它们共享相同的物品名称。

禁用此选项将独立显示物品计数,因此将考虑物品统计信息。物品总数将只显示每个游戏角色共享相同的唯一物品和完全相同的统计数据|cFFDF2B2B(不推荐)|r
]]
L.DisplayShowUniqueItemsTotalsTitle = "在鼠标提示上显示唯一物品的总数"
L.DisplayShowUniqueItemsEnableText = "启用唯一物品的总数。"
L.ColorPrimary = "BagSync [主功能]  提示颜色。"
L.ColorSecondary = "BagSync [辅助]  提示颜色。"
L.ColorTotal = "BagSync [总计] 提示颜色。"
L.ColorGuild = "BagSync [公会] 提示颜色。"
L.ColorWarband = "BagSync [战团] 提示颜色"
L.ColorCurrentRealm = "BagSync \"当前\"[服务器] 提示颜色。"
L.ColorCR = "BagSync \"合并\"[服务器] 提示颜色。"
L.ColorBNET = "BagSync [战网] 提示颜色。"
L.ColorItemID = "BagSync [物品ID] 提示颜色。"
L.ColorExpansion = "BagSync [游戏版本] 提示颜色。"
L.ColorItemTypes = "BagSync [物品类型] 提示颜色。"
L.ColorGuildTabs = "公会标签 [1,2,3, 等...] 提示颜色。"
L.ColorWarbandTabs = "战团标签 [1,2,3, 等...] 提示颜色。"
L.ColorBagSlots = "背包位 <1,2,3, 等...> 提示颜色。"
L.ConfigHeader = "各种 BagSync 功能的设置。"
L.ConfigDisplay = "显示"
L.ConfigTooltipHeader = "显示的 BagSync 提示信息的设置。"
L.ConfigColor = "颜色"
L.ConfigColorHeader = "BagSync 提示信息的颜色设置。"
L.ConfigMain = "主设置"
L.ConfigMainHeader = "BagSync 的主设置。"
L.ConfigSearch = "搜索"
L.ConfigKeybindings = "快捷键设置"
L.ConfigKeybindingsHeader = "BagSync 各模块快捷键设置"
L.ConfigExternalTooltip = "外部鼠标提示"
L.ConfigSearchHeader = "搜索窗口的设置"
L.ConfigFont = "字体"
L.ConfigFontSize = "字体大小"
L.ConfigFontOutline = "轮廓"
L.ConfigFontOutline_NONE = "无"
L.ConfigFontOutline_OUTLINE = "细"
L.ConfigFontOutline_THICKOUTLINE = "粗"
L.ConfigFontMonochrome = "单一颜色"
L.ConfigTracking = "追踪"
L.ConfigTrackingHeader = "追踪BagSync存储数据位置的设置。"
L.ConfigTrackingCaution = "警告"
L.ConfigTrackingModules = "模块"
L.ConfigTrackingInfo = [[
|cFFDF2B2B注意|r: 禁用模块会导致BagSync停止追踪并将模块存储到数据库中。
禁用的模块不会在任何BagSync窗口，斜杠命令，鼠标提示或小地图按钮中显示。
]]
L.TrackingModule_Bag = "背包"
L.TrackingModule_Bank = "银行"
L.TrackingModule_Reagents = "材料银行"
L.TrackingModule_Equip = "已装备"
L.TrackingModule_Mailbox = "信箱"
L.TrackingModule_Void = "虚空仓库"
L.TrackingModule_Auction = "拍卖行"
L.TrackingModule_Guild = "公会银行"
L.TrackingModule_WarbandBank = "战团银行（战团）"
L.TrackingModule_Professions = "专业/交易"
L.TrackingModule_Currency = "货币"
L.WarningItemSearch = "警告：共有 [|cFFFFFFFF%s|r] 个物品未被搜索！\n\nBagSync 仍在等待服务器/数据库响应\n\n按“搜索”或“刷新”按钮。"
L.WarningUpdatedDB = "您已更新到最新的版本!您将需要再次重新扫描所有角色!|r "
L.WarningCurrencyUpt = "更新货币时出错。请登录到角色： "
L.WarningHeader = "警告!"
L.SavedSearch = "保存的搜索"
L.SavedSearch_Add = "添加搜索"
L.SavedSearch_Warn = "您必须在搜索框中输入一些信息。"
---------------------------------------
--Localization Note:  Please be advised that the commands for the SearchHelp are english only, however the variables can be any language.  Example: class:<name of class in your locale>
--This includes name searches like name:<name in your locale>
---------------------------------------
L.SearchHelpHeader = "搜索帮助"
L.SearchHelp = [[
|cffff7d0a搜索选项|r：
|cFFDF2B2B（注意: 所有命令及标点符号只能是英文！）|r

|cFF99CC33物品在角色位置的顺序|r:
@bag <背包>
@bank <银行>
@reagents <材料银行>
@equip <已装备>
@mailbox <信箱>
@void <虚空仓库>
@auction <拍卖行>
@guild <公会>

|cffff7d0a高级搜索|r （|cFF99CC33命令|r | |cFFFFD580示例|r）：

|cff00ffff<物品名称>|r = |cFF99CC33n|r ; |cFF99CC33name|r | 示例：|cFFFFD580[输入简称]:矿石|r ;  |cFFFFD580[输入全称]:宁铁矿石|r 

|cff00ffff<物品已装备>|r = |cFF99CC33bind|r | 示例|cFFFFD580bind:boe|r ; types（boe, bop, bou, boq）i.e   boe = 已绑定装备

|cff00ffff<品质>|r = |cFF99CC33q|r ; |cFF99CC33quality|r | 示例：|cFFFFD580q:史诗|r 

|cff00ffff<物品等级>|r = |cFF99CC33l|r ; |cFF99CC33level|r ; |cFF99CC33lvl|r ; |cFF99CC33ilvl|r |示例： |cFFFFD580ilvl:382|r  ;  |cFFFFD580lvl:>=370|r 

|cff00ffff<需要的等级>|r = |cFF99CC33r|r ; |cFF99CC33req|r ; |cFF99CC33rl|r ; |cFF99CC33reql|r ; |cFF99CC33reqlvl|r | 示例：|cFFFFD580r:>5|r  ;  |cFFFFD580req:>=20|r 

|cff00ffff<种类/部位>|r = |cFF99CC33t|r ; |cFF99CC33type|r ; 示例：|cFF99CC33饰品|r  ;  |cFFFFD580t:脚|r 

|cff00ffff<提示>|r = |cFF99CC33tt|r ; |cFF99CC33tip|r ; |cFF99CC33tooltip|r | |cFFFFD580tt:<text>|r（tt:summon）

|cff00ffff<item set>|r = |cFF99CC33s|r ; |cFF99CC33set|r | |cFFFFD580s:<setname>|r（setname can be * for all sets）

|cff00ffff<版本>|r = |cFF99CC33x|r ; |cFF99CC33xpac|r ; |cFF99CC33expansion|r | 示例： |cFFFFD580x:巨龙时代|r  ;   |cFFFFD580xpac:暗影国度|r 

|cff00ffff<关键字>|r = |cFF99CC33k|r ; |cFF99CC33key|r ; |cFF99CC33keyword|r | 示例：|cFFFFD580k:任务|r（关键字: soulbound, bound, boe, bop, bou, boa, quest, unique, toy, reagent, crafting, naval, follower, follow, power, apperance）

|cff00ffff<职业>|r = |cFF99CC33c|r ; |cFF99CC33class|r | 示例：|cFFFFD580class:战士|r  ;  |cFFFFD580c:恶魔猎手|r

|cffff7d0a函数 <op>|r:
|cFF99CC33:|r | |cFF99CC33=|r | |cFF99CC33==|r | |cFF99CC33!=|r | |cFF99CC33~=|r | |cFF99CC33<|r | |cFF99CC33>|r | |cFF99CC33<=|r | |cFF99CC33>=|r


|cffff7d0a否定命令|r:
示例: |cFF99CC33!|r|cFFFFD580bind:boe|r（不是已绑定装备）
示例: |cFF99CC33!|r|cFFFFD580bind:boe|r |cFF99CC33&&|r |cFFFFD580lvl:>20|r（不是已绑定装备且物品等级大于20）

|cffff7d0a联合搜索（和搜索）：|r
（使用 |cFF99CC33&&|r 符号）
示例: |cFFFFD580bind:boe|r |cFF99CC33&&|r |cFFFFD580lvl:>20|r

|cffff7d0a交叉搜索 (或搜索):|r
（使用竖 |cFF99CC33|||||r 符号）
示例: |cFFFFD580bind:boe|r |cFF99CC33|||||r |cFFFFD580lvl:>20|r

|cffff7d0a复杂搜索示例:|r
（已绑定装备, 物品等级正好是20名字中带有'长袍' 一词）
|cFFFFD580bind:boe|r|cFF99CC33&|r|cFFFFD580lvl:20|r|cFF99CC33&|r|cFFFFD580长袍|r
|cFFFFD580bind:boe|r |cFF99CC33&&|r |cFFFFD580lvl:20|r |cFF99CC33&&|r |cFFFFD580name:长袍|r

]]
L.ConfigFAQ= " FAQ / 帮助 "
L.ConfigFAQHeader = "BagSync 的常见问题和帮助介绍。"
L.FAQ_Question_1 = "我在鼠标提示上遇到卡顿/滞后。"
L.FAQ_Question_1_p1 = [[
当数据库中有旧的和损坏的数据 BagSync 无法解读时,通常会发生此问题。当 BagSync 需要处理大量的数据时,也会出现该问题,如果您在多个数据中数千个物品,那么在一秒钟内需要处理大量数据.这可能会导致您的计算机在短时间内滞后。最后,此问题的另一个原因是您拥有一台非常旧的计算机。当 BagSync 处理数以千计的物品和角色数据时,较旧的计算机会遇到滞后/卡顿的情况。通常具有更快的CPU和更大的内存的计算机不会出现这些问题。

为了解决这个问题,您可以尝试重置数据库。通常可以解决问题。使用以下命令： |cFF99CC33/bgs 重置|r
如果这不能解决您的问题,请在 GitHub 上的 BagSync 提交问题报告。
]]
L.FAQ_Question_2 = " 在|cFFDF2B2B单独|r |cff3587ff战网|r 帐号中。找不到我的其他魔兽世界帐号的物品数据。"
L.FAQ_Question_2_p1 = [[
插件无法从其他魔兽世界帐户读取数据。这是因为它们不共享相同的 SavedVariable 文件夹。这是暴雪魔兽世界客户端的内置限制。因此,您将无法在 |cFFDF2B2Bsingle|r |cff3587ffBattle.net|r 下看到多个魔兽世界帐户的物品数据。 BagSync 将只能读取同一魔兽世界帐户内同服务器内多个的角色数据,而不是整个战网帐户。|cFF99CC33https://www.wowhead.com/guide=934|r

有一种方法可以在 |cFFDF2B2Bsingle|r |cff3587ffBattle.net|r 帐户内连接多个魔兽世界帐户,以便它们共享相同的 SavedVariables 文件夹。这涉及创建服务器链接文件夹。我不会在这方面提供帮助。所以别问了！请访问以下指南了解更多详情。 
]]
L.FAQ_Question_3 = "可以查看来自 |cFFDF2B2B多个|r |cff3587ff战网|r 账号内的物品数据吗?"
L.FAQ_Question_3_p1 = "不,这不可能。我不会在这方面提供帮助。所以不要问!"
L.FAQ_Question_4 = "我可以在|cFFDF2B2B当前登录|r的帐号查看多个魔兽世界账户的物品数据吗?"
L.FAQ_Question_4_p1 = "目前 BagSync 不支持在多个登录的魔兽世界帐户之间传输数据。这在未来可能会改变。"
L.FAQ_Question_5 = "为什么会提示公会银行扫描未完成?"
L.FAQ_Question_5_p1 = [[
BagSync 必须向服务器查询您的公会银行的 |cFF99CC33全部|r 信息。服务器传输所有数据需要时间。为了让 BagSync 正确存储您的所有物品,您必须等到服务器查询完成。扫描过程完成后,BagSync 将在聊天栏通知您。在扫描过程完成之前关闭公会银行窗口,将导致为您的公会银行存储不完整的数据。 
]]
L.FAQ_Question_6 = "为什么我看到战斗宠物是虚拟ID[FakeID]而不是物品ID[ItemID]?"
L.FAQ_Question_6_p1 = [[
暴雪不会将物品ID[ItemID]分配给魔兽世界的战斗宠物。相反,魔兽世界中的战斗宠物会从服务器分配到一个临时的宠物ID[PetID]。这个宠物ID[PetID]不是唯一的,会在服务器重置时更改。为了跟踪战斗宠物,BagSync 会生成一个虚拟ID[FakeID]。 虚拟ID[FakeID]是根据与战斗宠物相关联的静态数字生成的。使用虚拟ID[FakeID]可以保证BagSync在服务器重置期间跟踪到战斗宠物。
]]
L.FAQ_Question_7 = "什么是公会银行和邮箱中准确的扫描战斗宠物?"
L.FAQ_Question_7_p1 = [[
暴雪不会将战斗宠物存储在公会银行或邮箱中，并带有适当的物品ID或种类ID。事实上，战斗宠物以|cFF99CC33[宠物笼]|r的形式存储在公会银行和邮箱中，物品ID为|cFF99CC3382800|r。这使得有关插件作者难以进行特定战斗宠物的抓取任何数据。您可以在公会银行交易日志中看到，您会注意到战斗宠物被存储为|cFF99CC33[宠物笼]|r。如果您从公会银行链接一个，它也将显示为|cFF99CC33[宠物笼]|r。为了解决这个问题，可以使用两种方法。第一种方法是将战斗宠物分配给鼠标提示，然后从那里找到。这要求服务器响应WOW客户端，并可能导致大量滞后，尤其是在公会银行中有很多战斗宠物的情况下。第二种方法使用战斗宠物的图标试图找到。有时由于某些战斗宠物共享相同的图标，这有时是不准确的。示例：毒毒与翡翠软泥怪具有相同的图标。启用此选项将迫使鼠标提示扫描方法尽可能准确，但可能会导致滞后。|cFF99CC33直到暴雪为我们提供更多数据来使用。|r
]]
