local _, BSYC = ...
local L = BSYC:NewLocale("zhCN")
if not L then return end

--  zhCN client (NGA-[男爵凯恩])
--  Last update: 2026/05/25 （本次修正参考了https://www.townlong-yak.com/framexml/live/Helix/GlobalStrings.lua/CN 现在大部分翻译同步暴雪游戏内显示）

L.Yes = "是"
L.No = "否"
L.Realm = "服务器:"
L.TooltipCR_Tag = "连"
L.TooltipBNET_Tag = "战网"
L.Tooltip_bag = "背包"
L.Tooltip_bank = "银行"
L.Tooltip_equip = "装备"
L.Tooltip_guild = "公会"
L.Tooltip_mailbox = "信箱"
L.Tooltip_void = "虚空"
L.Tooltip_reagents = "材料"
L.Tooltip_auction = "拍卖"
L.Tooltip_warband = "战团"
L.TooltipSmall_bag = "背"
L.TooltipSmall_bank = "银"
L.TooltipSmall_reagents = "材"
L.TooltipSmall_equip = "装"
L.TooltipSmall_guild = "公"
L.TooltipSmall_mailbox = "信"
L.TooltipSmall_void = "虚"
L.TooltipSmall_auction = "拍"
L.TooltipSmall_warband = "战"
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
L.TooltipTotal = "总计:"
L.TooltipTabs = "标签页"
L.TooltipItemID = "[物品ID]："
L.TooltipCurrencyID = "[货币ID]："
L.TooltipFakeID = "[虚拟ID]："
L.TooltipExpansion = "[内容更新]："
L.TooltipItemType = "[物品类型]："
L.TooltipDelimiter = "，"
L.TooltipRealmKey = "服务器标识:"
L.TooltipDetailsInfo = "物品详细信息汇总。"
L.DetailsBagID = "ID："
L.DetailsSlot = "栏位："
L.DetailsTab = "标签页："
L.DebugEnable = "启用调试"
L.DebugCache = "禁用缓存"
L.DebugDumpOptions = "导出调试选项 |cff3587ff[调试]|r"
L.DebugIterateUnits = "遍历角色 |cff3587ff[调试]|r"
L.DebugDBTotals = "数据库总计 |cff3587ff[调试]|r"
L.DebugAddonList = "插件列表 |cff3587ff[调试]|r"
L.DebugExport = "导出"
L.DebugWarning = "|cFFDF2B2B警告：|R BagSync 调试模式已开启！|cFFDF2B2B（会导致卡顿）|r"
L.Search = "搜索"
L.Debug = "调试"
L.Reset = "重置"
L.Clear = "清除"
L.SearchFilters = "搜索筛选"
L.SearchFiltersInformation = "* 使用 BagSync 的 |cffff7d0a[连]|r 和 |cff3587ff[战网]|r 设置。"
L.SearchFiltersLocationInformation = "* 不选择任何项则默认为全选。"
L.Units = "角色："
L.Locations = "位置："
L.Profiles = "角色"
L.SortOrder = "排序"
L.Professions = "专业"
L.Currency = "货币"
L.Blacklist = "黑名单"
L.Whitelist = "白名单"
L.Recipes = "配方"
L.Details = "详情"
L.Gold = "金币"
L.Close = "关闭"
L.FixDB = "修复数据库"
L.Config = "设置"
L.DeleteWarning = "选择要删除的设置。注意：此操作不可逆！"
L.Delete = "删除"
L.SelectAll = "全选"
L.FixDBComplete = "BagSync 已完成数据库修复！数据库现已优化！"
L.ResetDBInfo = "BagSync：\n确定要重置数据库吗？\n|cFFDF2B2B注意：此操作不可逆！|r"
L.ON = "开启"
L.OFF = "关闭"
L.LeftClickSearch = "|cffddff00左键点击|r |cff00ff00= 打开搜索窗口|r"
L.RightClickBagSyncMenu = "|cffddff00右键点击|r |cff00ff00= 打开 BagSync 菜单|r"
L.ProfessionInformation = "|cffddff00左键点击|r |cff00ff00专业以查看配方。|r"
L.ErrorUserNotFound = "BagSync：错误，未找到用户！"
L.EnterItemID = "请输入物品ID。（使用 http://Wowhead.com/）"
L.AddGuild = "添加公会"
L.AddItemID = "添加物品ID"
L.PleaseRescan = "|cFF778899[请重新扫描]|r"
L.UseFakeID = "对战斗宠物使用[虚拟ID]而非[物品ID]。"
L.ItemIDNotValid = "[%s] 物品ID无效或服务器无响应。请重试！"
L.ItemIDRemoved = "[%s] 物品ID已移除"
L.ItemIDAdded = "[%s] 物品ID已添加"
L.ItemIDExistBlacklist = "[%s] 物品ID已存在于黑名单数据库中。"
L.ItemIDExistWhitelist = "[%s] 物品ID已存在于白名单数据库中。"
L.GuildExist = "公会[%s]已存在于黑名单数据库中。"
L.GuildAdded = "公会[%s]已添加"
L.GuildRemoved = "公会[%s]已移除"
L.BlackListRemove = "从黑名单中移除[%s]？"
L.WhiteListRemove = "从白名单中移除[%s]？"
L.BlackListErrorRemove = "黑名单删除时出错。"
L.WhiteListErrorRemove = "白名单删除时出错。"
L.ProfilesRemove = "从 BagSync 中删除配置[%s][|cFF99CC33%s|r]？"
L.ProfileBeenRemoved = "已从 BagSync 删除配置[%s][|cFF99CC33%s|r]！"
L.ProfessionHasRecipes = "左键点击查看配方。"
L.ProfessionHasNoRecipes = "没有可查看的配方。"
L.KeybindBlacklist = "显示黑名单窗口。"
L.KeybindWhitelist = "显示白名单窗口。"
L.KeybindCurrency = "显示货币窗口。"
L.KeybindGold = "显示金币窗口。"
L.KeybindProfessions = "显示专业窗口。"
L.KeybindProfiles = "显示角色窗口。"
L.KeybindSearch = "显示搜索窗口。"
L.ObsoleteWarning = "\n\n注意：过时物品仍会显示为缺失。要解决此问题，请再次扫描您的角色以移除过时物品。\n（背包、银行、材料、虚空等）"
L.DatabaseReset = "由于数据库变更，您的 BagSync 数据库已被重置。"
L.UnitDBAuctionReset = "所有角色的拍卖行数据已重置。"
L.ScanGuildBankDone = "公会银行扫描完成！"
L.ScanGuildBankError = "警告：公会银行扫描未完成。"
L.DefaultColors = "默认颜色"
-- ----THESE ARE FOR SLASH COMMANDS OPERATORS
L.SlashItemName = "[物品名称]"
L.SlashSearch = "搜索"
L.SlashGold = "金币"
L.SlashMoney = "金币"
L.SlashConfig = "设置"
L.SlashCurrency = "货币"
L.SlashFixDB = "修复数据库"
L.SlashProfiles = "角色"
L.SlashProfessions = "专业"
L.SlashBlacklist = "黑名单"
L.SlashWhitelist = "白名单"
L.SlashResetDB = "重置数据库"
L.SlashDebug = "调试"
L.SlashResetPOS = "重置位置" 
L.SlashSortOrder = "排序"
------------------------
-- ----THESE USE THE SLASH OPERATOR COMMANDS FOUND ABOVE
L.HelpSearchItemName = "快速搜索物品"
L.HelpSearchWindow = "打开搜索窗口"
L.HelpGoldTooltip = "显示每个角色的金币数量提示框。"
L.HelpCurrencyWindow = "打开货币窗口。"
L.HelpProfilesWindow = "打开角色窗口。"
L.HelpFixDB = "对 BagSync 执行数据库修复。"
L.HelpResetDB = "重置整个 BagSync 数据库。"
L.HelpConfigWindow = "打开 BagSync 设置窗口。"
L.HelpProfessionsWindow = "打开专业窗口。"
L.HelpBlacklistWindow = "打开黑名单窗口。"
L.HelpWhitelistWindow = "打开白名单窗口。"
L.HelpDebug = "打开 BagSync 调试窗口。"
L.HelpResetPOS = "重置所有 BagSync 模块的框架位置。"
L.HelpSortOrder = "自定义角色与公会的排列顺序。"
------------------------
L.EnableBagSyncTooltip = "启用 BagSync 提示框"
L.ShowOnModifier = "BagSync 提示框修饰键："
L.ShowOnModifierDesc = "按住修饰键时显示 BagSync 提示框。"
L.ModValue_NONE = "无（始终显示）"
L.ModValue_ALT = "ALT"
L.ModValue_CTRL = "CTRL"
L.ModValue_SHIFT = "SHIFT"
L.EnableExtTooltip = "在外部提示框中显示物品数量数据。"
L.EnableLoginVersionInfo = "登录时显示 BagSync 版本信息。"
L.FocusSearchEditBox = "打开搜索窗口时自动聚焦搜索框。"
L.AlwaysShowSearchFilters = "始终显示 BagSync 搜索筛选窗口。"
L.DisplayTotal = "显示[总计]数量。"
L.DisplayGuildGoldInGoldWindow = "在金币窗口中显示[公会]金币总量。"
L.Display_GSC = "在金币窗口中分别显示|CFFFFD700金币|r、|CFFC0C0C0银币|r和|CFFB87333铜币|r。"
L.DisplayMinimap = "显示 BagSync 小地图按钮。"
L.EnableAddonCompartment = "启用暴雪插件收纳盒集成。"
L.ResetMinimapBtn = "重置小地图按钮位置。"
L.AddonCompartmentReloadMsg = "插件收纳盒更改需要重载界面。请使用 /reload 重载界面生效。"
L.DisplayFaction = "显示双方阵营的物品（|cff3587ff联盟|r/|cFFDF2B2B部落|r）。"
L.DisplayClassColor = "为角色名称显示职业颜色。"
L.DisplayItemTotalsByClassColor = "按角色职业颜色显示物品总计。"
L.DisplayTooltipOnlySearch = "仅在搜索窗口中显示 BagSync 提示框 |cFF99CC33（仅限）|r。"
L.DisplayTooltipCurrencyData = "在暴雪货币窗口中显示 BagSync 提示框数据。"
L.DisplayLineSeparator = "显示空行分隔符。"
L.DisplayCurrentCharacter = "当前角色" 
L.DisplayCurrentCharacterOnly = "|cFFDF2B2B仅|r 为当前角色显示 BagSync 提示框数据 |cFFFFD700（不推荐）|r"
L.DisplayBlacklistCurrentCharOnly = "|cFFDF2B2B仅|r 为当前角色显示黑名单物品数量 |cFFFFD700（不推荐）|r"
L.DisplayCurrentRealmName = "显示玩家的 |cFF4CBB17[当前服务器]|r。"
L.DisplayCurrentRealmShortName = "为 |cFF4CBB17[当前服务器]|r 使用简称。"
L.DisplayCR = "显示 |cffff7d0a[连]|r 角色（连服）。"
L.DisplayBNET = "显示所有战网账号角色。|cff3587ff[战网]|r |cFFDF2B2B（不推荐）|r"
L.DisplayItemID = "在提示框中显示物品ID。"
L.DisplayWhiteListOnly = "仅显示白名单物品的提示框总量。"
L.DisplaySourceExpansion = "在提示框中显示物品的来源内容更新。|cFF99CC33[正式服专用]|r"
L.DisplayItemTypes = "在提示框中显示[物品类型 | 子类型]类别。"
L.DisplayTooltipTags = "标签"
L.DisplayTooltipStorage = "仓库"
L.DisplayTooltipExtra = "附加"
L.DisplaySortOrderHelp = "排序帮助"
L.DisplaySortOrderStatus = "当前排序：[%s]"
L.DisplayWhitelistHelp = "白名单帮助"
L.DisplayWhitelistStatus = "当前白名单: [%s]"
L.DisplayWhitelistHelpInfo = "您只能向白名单数据库输入物品ID数字。\n\n要输入战斗宠物，请使用虚拟ID而非物品ID。您可以在 BagSync 配置中启用物品ID提示框功能来获取虚拟ID。\n\n|cFFDF2B2B这对货币窗口无效。|r"
L.DisplayWhitelistHelpInfo2 = "\n\n\n\n|cFFFF7D0A警告：此白名单功能将阻止 BagSync 统计 |cFFFFFFFF--所有--|r 物品，除非它们在此列表中。|r\n|cFF09DBE0这是一个反向黑名单！|r"
L.DisplayTooltipAccountWide = "战网通行证"
L.DisplayAccountWideTagOpts = "|cFF99CC33标签选项（|cffff7d0a[连]|r 和 |cff3587ff[战网]|r）|r"
L.DisplayGreenCheck = "在当前角色名称旁显示 %s。"
L.DisplayRealmIDTags = "显示 |cffff7d0a[连]|r 和 |cff3587ff[战网]|r 服务器标识。"
L.DisplayRealmNames = "显示服务器名称。"
L.DisplayRealmAstrick = "为 |cffff7d0a[连]|r 和 |cff3587ff[战网]|r 显示 [*] 代替服务器名称。"
L.DisplayShortRealmName = "为 |cffff7d0a[连]|r 和 |cff3587ff[战网]|r 显示简称。"
L.DisplayFactionIcons = "在提示框中显示阵营图标。"
L.DisplayGuildBankTabs = "在提示框中显示公会银行标签页[1、2、3等]。"
L.DisplayWarbandBankTabs = "在提示框中显示战团银行标签页[1、2、3等]。"
L.DisplayBankTabs = "在提示框中显示银行标签页[1、2、3等]。"
L.DisplayEquipBagSlots = "在提示框中显示装备的背包栏位<1、2、3等>。"
L.DisplayRaceIcons = "在提示框中显示角色种族图标。"
L.DisplaySingleCharLocs = "为仓库位置显示单字符缩写。"
L.DisplayIconLocs = "为仓库位置显示图标。"
L.DisplayStorageLocStyle = "仓库位置标签样式。"
L.DisplayStorageLocStyle_Full = "显示完整的仓库位置文本。"
L.DisplayRealmNameStyle = "服务器名称样式。"
L.None = "无"
L.DisplayAccurateBattlePets = "启用公会银行和邮件中的精确战斗宠物统计。|cFFDF2B2B（可能导致卡顿）|r |cff3587ff[参见 BagSync 常见问题]|r"
L.DisplaySortCurrencyByExpansionFirst = "在 BagSync 货币窗口中优先按资料片排序，而非字母顺序。"
L.DisplaySorting = "提示框排序"
L.DisplaySortInfo = "默认：提示框按服务器名称字母顺序排序，然后按角色名称排序。"
L.SortMode = "排序模式"
L.SortMode_RealmCharacter = "先服务器再角色（默认）"
L.SortMode_Character = "角色"
L.SortMode_ClassCharacter = "先职业再角色"
L.SortCurrentPlayerOnTop = "默认排序并将当前角色始终置顶。"
L.SortTooltipByTotals = "按总量排序，而非字母顺序。"
L.SortByCustomSortOrder = "按自定义排序顺序排序。"
L.CustomSortInfo = "列表按升序排列（1、2、3）"
L.CustomSortInfoWarn = "|cFF99CC33注意：仅使用数字！例如：（-1、0、3、4、37、99、-45）|r"
L.DisplayShowUniqueItemsTotals = "启用此选项后，无论物品属性如何，独特物品都将计入总物品数量。|cFF99CC33（推荐）|r。"
L.DisplayShowUniqueItemsTotals_2 = [[
某些物品如|cffff7d0a[传说物品]|r可能名称相同但属性不同。由于这些物品彼此独立处理，它们有时不计入总物品数量。启用此选项将完全忽略独特物品属性，只要它们共享相同的物品名称，就视为相同物品。

禁用此选项将根据物品属性独立显示物品数量。物品总计将仅对拥有完全相同属性的独特物品的每个角色显示。|cFFDF2B2B（不推荐）|r
]]
L.DisplayShowUniqueItemsTotalsTitle = "显示独特物品提示框总量"
L.DisplayShowUniqueItemsEnableText = "启用独特物品总量统计。"
L.ColorPrimary = "BagSync 主提示框颜色。"
L.ColorSecondary = "BagSync 辅助提示框颜色。"
L.ColorTotal = "BagSync [总计]提示框颜色。"
L.ColorGuild = "BagSync [公会]提示框颜色。"
L.ColorWarband = "BagSync [战团]提示框颜色。"
L.ColorCurrentRealm = "BagSync [当前服务器]提示框颜色。"
L.ColorCR = "BagSync [连]提示框颜色。"
L.ColorBNET = "BagSync [战网]提示框颜色。"
L.ColorItemID = "BagSync [物品ID]提示框颜色。"
L.ColorExpansion = "BagSync [内容更新]提示框颜色。"
L.ColorItemTypes = "BagSync [物品类型]提示框颜色。"
L.ColorGuildTabs = "公会标签页[1、2、3等]提示框颜色。"
L.ColorWarbandTabs = "战团标签页[1、2、3等]提示框颜色。"
L.ColorBankTabs = "银行标签页[1、2、3等]提示框颜色。"
L.ColorBagSlots = "背包栏位<1、2、3等>提示框颜色。"
L.ConfigDisplay = "显示"
L.ConfigTooltipHeader = "显示的 BagSync 提示框信息设置。"
L.ConfigColor = "颜色"
L.ConfigColorHeader = "BagSync 提示框信息的颜色设置。"
L.ConfigCache = "缓存"
L.ConfigCacheHeader = "BagSync 的物品缓存设置和限流选项。"
L.ConfigCacheHowTitle = "缓存工作原理"
L.ConfigCacheHowText_1 = "登录时物品信息并非完全可用。像 |cFFB19CD9GetItemInfo|r 或 |cFFB19CD9C_Item.GetItemInfo|r 这样的API在该物品尚未为当前会话缓存时会返回nil（或无返回值）。"
L.ConfigCacheHowText_2 = "BagSync 会分小批次请求缺失的物品数据，并等待客户端从服务器接收数据。"
L.ConfigCacheHowText_3 = "限流机制可在缓存预热时保持流畅性能，使搜索和提示框能随时间逐渐填充数据。"
L.ConfigCacheRatesTitle = "当前速率"
L.ConfigCacheSpeedTitle = "缓存速度"
L.ConfigCacheSpeedLabel = "限流"
L.ConfigCacheSpeedHelp = "|cFFB19CD9慢速|r 是默认选项，性能最佳，但搜索需要更长时间才能完全缓存。\n|cFFB19CD9中速|r 更快，但可能导致登录时轻微卡顿。\n|cFFB19CD9快速|r 强度最高，登录时可能导致严重卡顿。\n|cFFFF4D4D禁用|r |cFFFF4D4D不推荐|r（|cFFFFFFFF禁用后，搜索窗口打开和搜索期间 BagSync 将使用 |cFFB19CD9快速|r 限流。）|r"
L.CacheSpeedSlow = "慢速（后台 + 渐进）"
L.CacheSpeedMedium = "中速"
L.CacheSpeedFast = "快速"
L.CacheSpeedDisabled = "禁用（无后台缓存）"
L.CacheSpeedRampIntro = "慢速模式每 %d 秒渐进一次。"
L.CacheSpeedRampLine = "第 %d 步：每 %.2f 秒 %d 件物品（约每秒 %d 件）。"
L.CacheSpeedSingleLine = "每 %.2f 秒 %d 件物品（约每秒 %d 件）。"
L.CacheSpeedDisabledSummary = "后台缓存已禁用。打开 BagSync 使用快速限流，搜索时也使用快速限流。"
L.ConfigMain = "主要"
L.ConfigMainHeader = "BagSync 的主要设置。"
L.ConfigKeybindings = "按键绑定"
L.ConfigKeybindingsHeader = "BagSync 功能的按键绑定设置。"
L.ConfigExternalTooltip = "外部提示框"
L.ConfigFont = "字体"
L.ConfigExtTooltipAnchor = "游戏提示框位置"
L.ConfigExtTipPositionSettings = "外部提示框位置设置"
L.ConfigExtTipCustomAnchorEnable = "启用自定义锚点位置"
L.ConfigExtTipCustomAnchorLocation = "自定义位置"
L.ConfigExtTipCustomAnchorShow = "显示外部提示框锚点"
L.ExtTipCustomAnchor_TopLeft = "左上"
L.ExtTipCustomAnchor_TopRight = "右上"
L.ExtTipCustomAnchor_BottomLeft = "左下"
L.ExtTipCustomAnchor_BottomRight = "右下"
L.ExtTipCustomAnchor_Center = "居中"
L.ExtTipCustomAnchor_CenterTop = "中上"
L.ExtTipCustomAnchor_CenterBottom = "中下"
L.ExtTipCustomAnchor_UseAnchor = "使用外部提示框锚点"
L.ExtTipAnchorLabel = "BagSync 外部提示框锚点\n\n（右键点击保存位置）"
L.ConfigFontSize = "字体大小"
L.ConfigFontOutline = "轮廓"
L.ConfigFontOutline_NONE = "无"
L.ConfigFontOutline_OUTLINE = "轮廓"
L.ConfigFontOutline_THICKOUTLINE = "粗轮廓"
L.ConfigFontMonochrome = "单色"
L.ExtTooltipAnchor_Bottom = "底部"
L.ExtTooltipAnchor_Left = "左侧"
L.ExtTooltipAnchor_Right = "右侧"
L.ExtTipNoticeTitle = "外部提示框注意事项"
L.ExtTipNoticeText = "|cFFFFFFFF暴雪的|cFFFF0000秘密值|r|cFFFFFFFF可能会阻止外部提示框定位。BagSync 添加了保护措施，但如果找不到安全的提示框，计数将回退到 |cFFFF0000GameTooltip|r|cFFFFFFFF。详细信息请参阅有关|cFFFF0000“秘密值”|r|cFFFFFFFF的常见问题解答。|r"
L.ConfigTracking = "追踪"
L.ConfigTrackingHeader = "所有已存储 BagSync 数据库位置的追踪设置。"
L.ConfigTrackingCaution = "注意"
L.ConfigTrackingModules = "模块"
L.ConfigTrackingInfo = [[
|cFFDF2B2B注意|r：禁用模块将导致 BagSync 停止追踪该模块并将其存储到数据库。

禁用的模块将不会显示在任何 BagSync 窗口、斜杠命令、提示框或小地图按钮中。
]]
L.TrackingModule_Bag = "背包"
L.TrackingModule_Bank = "银行"
L.TrackingModule_Reagents = "材料银行"
L.TrackingModule_Equip = "已装备物品"
L.TrackingModule_Mailbox = "信箱"
L.TrackingModule_Void = "虚空银行"
L.TrackingModule_Auction = "拍卖行"
L.TrackingModule_Guild = "公会银行"
L.TrackingModule_WarbandBank = "战团银行"
L.TrackingModule_Professions = "专业/商业技能"
L.TrackingModule_Currency = "货币"
L.WarningItemSearch = "警告：共有 [|cFFFFFFFF%s|r] 件物品未被搜索！\n\nBagSync 仍在等待服务器/缓存响应。\n\n请按搜索或刷新按钮。"
L.CachingItemData = "正在缓存物品数据...（剩余 %d 件）"
L.WarningCurrencyUpt = "更新货币时出错。请登录角色："
L.WarningHeader = "警告！"
L.SavedSearch = "已保存的搜索"
L.SavedSearch_Add = "添加搜索"
L.SavedSearch_Warn = "请在搜索框中输入内容。"
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
--This includes name searches like name:<name in your locale>  [EXPANSION 翻译应该是“资料片” 可是游戏内使用了 EXPANSION_FILTER_TEXT = "内容更新"; 应该是为了应对中国市场的特殊翻译，所以也使用"内容更新"]
---------------------------------------
L.SearchHelpHeader = "搜索帮助"
L.SearchHelp = [[
|cffff7d0a搜索选项|r：
|cFFDF2B2B（注意：所有命令均为英文！）|r

|cFF99CC33按位置搜索角色物品|r：
@bag       （背包）
@bank      （银行）
@reagents  （材料）
@equip     （装备）
@mailbox   （信箱）
@void      （虚空）
@auction   （拍卖）
@guild     （公会）
@warband   （战团）

|cffff7d0a搜索筛选|r（|cFF99CC33命令|r | |cFFFFD580示例|r）：

|cff00ffff<物品名称>|r = |cFF99CC33n|r ; |cFF99CC33name|r | |cFFFFD580n:<文本>|r ; |cFFFFD580name:<文本>|r （例如：n:矿石 ; name:矿石）

|cff00ffff<物品绑定类型>|r = |cFF99CC33bind|r | |cFFFFD580bind:<类型>|r ；类型（boe、bop、bou、boq）如：boe = 装备后绑定

|cff00ffff<品质>|r = |cFF99CC33q|r ; |cFF99CC33quality|r | |cFFFFD580q<运算符><文本>|r ; |cFFFFD580q<运算符><数字>|r （例如：q:史诗 ; q:>2 ; q:>=3）

|cff00ffff<物品等级>|r = |cFF99CC33l|r ; |cFF99CC33level|r ; |cFF99CC33lvl|r ; |cFF99CC33ilvl|r | |cFFFFD580ilvl<运算符><数字>|r ; |cFFFFD580lvl<运算符><数字>|r （例如：lvl:>5 ; lvl:>=20）

|cff00ffff<需求等级>|r = |cFF99CC33r|r ; |cFF99CC33req|r ; |cFF99CC33rl|r ; |cFF99CC33reql|r ; |cFF99CC33reqlvl|r | |cFFFFD580req<运算符><数字>|r ; |cFFFFD580req<运算符><数字>|r （例如：req:>5 ; req:>=20）

|cff00ffff<类型/栏位>|r = |cFF99CC33t|r ; |cFF99CC33type|r ; |cFF99CC33slot|r | |cFFFFD580t:<文本>|r （例如：slot:头部 ; t:战斗宠物 或 t:宠物笼 ; t:护甲 ; t:武器）

|cff00ffff<提示框文本>|r = |cFF99CC33tt|r ; |cFF99CC33tip|r ; |cFF99CC33tooltip|r | |cFFFFD580tt:<文本>|r （例如：tt:召唤）

|cff00ffff<物品套装>|r = |cFF99CC33s|r ; |cFF99CC33set|r | |cFFFFD580s:<套装名称>|r （套装名称可用 * 表示所有套装）

|cff00ffff<内容更新>|r = |cFF99CC33x|r ; |cFF99CC33xpac|r ; |cFF99CC33expansion|r | |cFFFFD580x:<内容更新ID>|r ; |cFFFFD580x:<内容更新名称>|r ; |cFFFFD580xpac:<内容更新名称>|r （例如：xpac:暗影）

|cff00ffff<关键词>|r = |cFF99CC33k|r ; |cFF99CC33key|r ; |cFF99CC33keyword|r | |cFFFFD580k:<关键词>|r （关键词：任务、灵魂绑定、绑定、装备绑定、拾取绑定、使用绑定、战网通行证绑定、任务、唯一、玩具、材料、制造、海军、追随者、随从、力量、外观）

|cff00ffff<职业>|r = |cFF99CC33c|r ; |cFF99CC33class|r | |cFFFFD580c:<职业名称>|r ; |cFFFFD580class:<职业名称>|r （例如：class:萨满）

|cffff7d0a运算符 <运算符>|r：
|cFF99CC33:|r | |cFF99CC33=|r | |cFF99CC33==|r | |cFF99CC33!=|r | |cFF99CC33~=|r | |cFF99CC33<|r | |cFF99CC33>|r | |cFF99CC33<=|r | |cFF99CC33>=|r
|cFFDF2B2B注意：|r 支持 |cFF99CC33!=|r 和 |cFF99CC33~=|r（不等于）。


|cffff7d0a否定命令|r：
示例：|cFF99CC33!|r|cFFFFD580bind:boe|r （非装备绑定）
示例：|cFF99CC33!|r|cFFFFD580bind:boe|r |cFF99CC33&&|r |cFFFFD580lvl:>20|r （非装备绑定 且 物品等级大于20）

|cffff7d0a交集搜索（与搜索）|r：
（使用双 & 符号 |cFF99CC33&&|r）
示例：|cFFFFD580bind:boe|r |cFF99CC33&&|r |cFFFFD580lvl:>20|r

|cffff7d0a并集搜索（或搜索）|r：
（使用双竖线 |cFF99CC33|||||r）
示例：|cFFFFD580bind:boe|r |cFF99CC33|||||r |cFFFFD580lvl:>20|r

|cffff7d0a复杂搜索示例|r：
（装备绑定，等级正好为20，且名称中包含“长袍”一词）
|cFFFFD580bind:boe|r |cFF99CC33&&|r |cFFFFD580lvl:20|r |cFF99CC33&&|r |cFFFFD580name:长袍|r

]]
L.ConfigFAQ = "常见问题 / 帮助"
L.ConfigFAQHeader = "BagSync 的常见问题与帮助部分。"
L.FAQ_Question_1 = "使用提示框时遇到卡顿/掉帧/延迟。"
L.FAQ_Question_1_p1 = [[
此问题通常发生在数据库中存在旧数据或损坏数据，BagSync 无法解析时。当 BagSync 需要处理海量数据时也可能发生。如果您在多个角色中拥有数千件物品，这意味着每秒需要处理大量数据，可能导致客户端短暂卡顿。最后，使用极度老旧的电脑也可能导致此问题。老旧电脑在处理数千件物品和角色数据时会出现卡顿/掉帧。配备更快 CPU 和内存的新电脑通常不会有此问题。

要解决此问题，您可以尝试重置数据库。这通常能解决问题。请使用以下斜杠命令：|cFF99CC33/bgs 重置数据库|r
如果这未能解决您的问题，请在 GitHub 上为 BagSync 提交问题反馈。
]]
L.FAQ_Question_2 = "在 |cFFDF2B2B单个|r |cff3587ff战网|r 账号下找不到我其他魔兽账号的物品数据。"
L.FAQ_Question_2_p1 = [[
插件无法读取其他魔兽账号的数据，因为它们不共享同一个 SavedVariable 文件夹。这是暴雪魔兽客户端内置的限制。因此，您无法在 |cFFDF2B2B单个|r |cff3587ff战网|r 账号下查看多个魔兽账号的物品数据。BagSync 只能读取同一魔兽账号下多个服务器的角色数据，而非整个战网账号。

有一种方法可以让 |cFFDF2B2B单个|r |cff3587ff战网|r 账号下的多个魔兽账号共享同一个 SavedVariables 文件夹，即创建符号链接文件夹。我不会就此提供帮助，所以请不要询问！更多详情请访问以下指南：|cFF99CC33https://www.wowhead.com/guide=934|r 
]]
L.FAQ_Question_3 = "能否查看 |cFFDF2B2B多个|r |cff3587ff战网|r 账号的物品数据？"
L.FAQ_Question_3_p1 = "不可能。我不会就此提供帮助，所以请不要询问！"
L.FAQ_Question_4 = "能否查看 |cFFDF2B2B当前同时登录|r 的多个魔兽账号的物品数据？"
L.FAQ_Question_4_p1 = "目前 BagSync 不支持在多个同时登录的魔兽账号之间传输数据。未来可能会改变。"
L.FAQ_Question_5 = "为什么会收到公会银行扫描未完成的消息？"
L.FAQ_Question_5_p1 = [[
BagSync 需要向服务器查询您 |cFF99CC33全部|r 的公会银行信息。服务器传输所有数据需要时间。为了让 BagSync 正确存储您的所有物品，您必须等待服务器查询完成。扫描过程完成后，BagSync 会在聊天中通知您。在扫描过程完成前离开公会银行窗口将导致存储的公会银行数据不正确。
]]
L.FAQ_Question_6 = "为什么战斗宠物显示的是[虚拟ID]而不是[物品ID]？"
L.FAQ_Question_6_p1 = [[
暴雪没有为魔兽世界中的战斗宠物分配物品ID。实际上，魔兽世界中的战斗宠物被分配了来自服务器的临时宠物ID。这个宠物ID不是唯一的，并会在服务器重启时改变。为了追踪战斗宠物，BagSync 生成了一个虚拟ID。虚拟ID由与战斗宠物关联的静态数字生成。使用虚拟ID使 BagSync 即使在服务器重启后也能追踪战斗宠物。
]]
L.FAQ_Question_7 = "什么是公会银行和邮件中的精确战斗宠物扫描？"
L.FAQ_Question_7_p1 = [[
暴雪不会在公会银行或邮件中使用正确的物品ID或物种ID存储战斗宠物。实际上，战斗宠物在公会银行和邮件中存储为 |cFF99CC33[宠物笼]|r，物品ID为 |cFF99CC3382800|r。这使得插件作者难以获取特定战斗宠物的数据。您可以在公会银行交易日志中自行查看，会注意到战斗宠物被存储为 |cFF99CC33[宠物笼]|r。如果您从公会银行链接一个，它也会显示为 |cFF99CC33[宠物笼]|r。为了解决这个问题，可以使用两种方法。第一种方法是将战斗宠物分配到提示框，然后从那里获取物种ID。这需要服务器响应魔兽客户端，如果公会银行中有大量战斗宠物，可能会导致严重卡顿。第二种方法使用战斗宠物的图标纹理来尝试查找物种ID。这有时不准确，因为某些战斗宠物共享相同的图标纹理。例如：毒黏怪与翡翠软泥怪共享相同的图标纹理。启用此选项将强制使用提示框扫描方法以尽可能精确，但这可能导致卡顿。|cFFDF2B2B在暴雪提供更多可用数据之前，无法解决此问题。|r
]]
L.FAQ_Question_8 = "秘密值错误与暴雪插件限制"
L.FAQ_Question_8_p1 = [[
暴雪新的 |cFFDF2B2B“秘密值”|r 系统旨在让插件 |cFF99CC33显示|r 某些战斗相关数据，但 |cFFDF2B2B不能安全地检查或计算|r 它们。在受污染的代码路径中，对这些值进行算术运算、比较甚至某些索引操作都会立即引发 Lua 错误。这些值还可以通过“秘密值/锚点”“感染”框架和提示框，因此 |cFF99CC33同一个提示框|r 稍后可能会开始返回秘密坐标，即使最初接触它的插件并未创建该秘密值。这意味着指向 BagSync 的堆栈跟踪 |cFFDF2B2B不|r 能证明 BagSync 引入了秘密值；它通常仅表示 BagSync 是下一个接触已受污染对象的插件。

这不是 BagSync 独有的问题。即使没有第三方插件，暴雪自己的 UI 也会抛出相同的“尝试对秘密值进行算术运算”错误（例如 MoneyFrame / GameTooltip）。其他插件正在积极发布针对由提示框和金钱框中的秘密值触发的 |cFF99CC33完全相同错误类|r 的紧急修复或防护措施。|cFFDF2B2B简而言之：这是一个广泛的平台问题，而非 BagSync 独有的漏洞|r。

我 |cFFDF2B2B已尽力|r 添加尽可能多的防护措施和防御性检查，以降低 BagSync 触发这些错误的几率，但暴雪已从设计上使秘密值在混合插件环境中 |cFFDF2B2B极难追踪和控制|r。这个系统主动阻止插件可靠地检查该值，甚至确认其 |cFF99CC33来源|r。这正是这些错误难以重现的原因，也是它们通常只在错误触发时才出现的原因。
]]
L.BagSyncInfoWindow = [[
默认情况下，BagSync 仅显示来自连服角色的提示框数据。（|cffff7d0a[连]|r）

连服是指已链接在一起的服务器。

完整列表请访问：
（|cFF99CC33 https://tinyurl.com/msncc7j6 |r）


|cFFfd5c63BagSync 默认不会显示您整个战网账号的数据。您需要启用此功能！|r
（|cff3587ff[战网]|r）

|cFF52D386如果您希望查看整个战网账号（|cff3587ff[战网]|r）下所有角色的数据，您需要在 BagSync 配置窗口的[战网通行证]下启用该选项。|r

该选项标记为：
]]
