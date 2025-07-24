
local L = LibStub("AceLocale-3.0"):NewLocale("BagSync", "ruRU")
if not L then return end
-- Translator ZamestoTV
L.Yes = "Да"
L.No = "Нет"
L.Page = "Страница"
L.Done = "Готово"
L.Realm = "Сервер:"
L.TooltipCR_Tag = "CR"
L.TooltipBNET_Tag = "BN"
L.Tooltip_bag = "Сумки"
L.Tooltip_bank = "Банк"
L.Tooltip_equip = "Экипировка"
L.Tooltip_guild = "Гильдия"
L.Tooltip_mailbox = "Почта"
L.Tooltip_void = "Хранилище"
L.Tooltip_reagents = "Реагенты"
L.Tooltip_auction = "Аукцион"
L.Tooltip_warband = "Отряд"
L.TooltipSmall_bag = "С"
L.TooltipSmall_bank = "Б"
L.TooltipSmall_reagents = "Р"
L.TooltipSmall_equip = "Э"
L.TooltipSmall_guild = "Г"
L.TooltipSmall_mailbox = "П"
L.TooltipSmall_void = "Х"
L.TooltipSmall_auction = "А"
L.TooltipSmall_warband = "О"
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
L.TooltipTotal = "Итого:"
L.TooltipGuildTabs = "В:"
L.TooltipBagSlot = "Сл:"
L.TooltipItemID = "[ItemID]:"
L.TooltipDebug = "[Отладка]:"
L.TooltipCurrencyID = "[CurrencyID]:"
L.TooltipFakeID = "[FakeID]:"
L.TooltipExpansion = "[Расширение]:"
L.TooltipItemType = "[Типы предметов]:"
L.TooltipDelimiter = ", "
L.TooltipRealmKey = "Ключ сервера:"
L.TooltipDetailsInfo = "Подробная сводка по предмету."
L.DetailsBagID = "ID:"
L.DetailsSlot = "Слот:"
L.DetailsTab = "Вкладка:"
L.Debug_DEBUG = "ОТЛАДКА"
L.Debug_INFO = "ИНФО"
L.Debug_TRACE = "ТРАССИРОВКА"
L.Debug_WARN = "ПРЕДУПРЕЖДЕНИЕ"
L.Debug_FINE = "ТОЧНО"
L.Debug_SL1 = "SL1" --sublevel 1
L.Debug_SL2 = "SL2" --sublevel 2
L.Debug_SL3 = "SL3" --sublevel 3
L.DebugEnable = "Включить отладку"
L.DebugCache = "Отключить кэш"
L.DebugDumpOptions = "Сброс опций |cff3587ff[ОТЛАДКА]|r"
L.DebugIterateUnits = "Итерация юнитов |cff3587ff[ОТЛАДКА]|r"
L.DebugDBTotals = "Итоги БД |cff3587ff[ОТЛАДКА]|r"
L.DebugAddonList = "Список аддонов |cff3587ff[ОТЛАДКА]|r"
L.DebugExport = "Экспорт"
L.DebugWarning = "|cFFDF2B2BПРЕДУПРЕЖДЕНИЕ:|R Отладка BagSync включена! |cFFDF2B2B(МОЖЕТ ВЫЗВАТЬ ЛАГИ)|r"
L.Search = "Поиск"
L.Debug = "Отладка"
L.AdvSearchBtn = "Поиск/Обновить"
L.Reset = "Сброс"
L.Refresh = "Обновить"
L.Clear = "Очистить"
L.AdvancedSearch = "Расширенный поиск"
L.AdvancedSearchInformation = "* Использует настройки BagSync |cffff7d0a[CR]|r и |cff3587ff[BNet]|r."
L.AdvancedLocationInformation = "* Если ничего не выбрано, выбирается ВСЕ."
L.Units = "Юниты:"
L.Locations = "Местоположения:"
L.Profiles = "Профили"
L.SortOrder = "Порядок сортировки"
L.Professions = "Профессии"
L.Currency = "Валюта"
L.Blacklist = "Черный список"
L.Whitelist = "Белый список"
L.Recipes = "Рецепты"
L.Details = "Детали"
L.Gold = "Золото"
L.Close = "Закрыть"
L.FixDB = "Исправить БД"
L.Config = "Конфигурация"
L.DeleteWarning = "Выберите профиль для удаления. ВНИМАНИЕ: Это необратимо!"
L.Delete = "Удалить"
L.Confirm = "Подтвердить"
L.SelectAll = "Выбрать все"
L.FixDBComplete = "Исправление БД для BagSync выполнено! База данных теперь оптимизирована!"
L.ResetDBInfo = "BagSync:\nВы уверены, что хотите сбросить базу данных?\n|cFFDF2B2BВНИМАНИЕ: Это необратимо!|r"
L.ON = "ВКЛ"
L.OFF = "ВЫКЛ"
L.LeftClickSearch = "|cffddff00Левый клик|r |cff00ff00= Окно поиска|r"
L.RightClickBagSyncMenu = "|cffddff00Правый клик|r |cff00ff00= Меню BagSync|r"
L.ProfessionInformation = "|cffddff00Левый клик|r |cff00ff00на профессии для просмотра рецептов.|r"
L.ClickViewProfession = "Кликните для просмотра профессии: "
L.ClickHere = "Кликните здесь"
L.ErrorUserNotFound = "BagSync: Пользователь не найден!"
L.EnterItemID = "Пожалуйста, введите ItemID. (Используйте http://Wowhead.com/)"
L.AddGuild = "Добавить гильдию"
L.AddItemID = "Добавить ItemID"
L.RemoveItemID = "Удалить ItemID"
L.PleaseRescan = "|cFF778899[Пожалуйста, пересканируйте]|r"
L.UseFakeID = "Использовать [FakeID] для боевых питомцев вместо [ItemID]."
L.ItemIDNotFound = "[%s] ItemID не найден. Попробуйте снова!"
L.ItemIDNotValid = "[%s] ItemID не является действительным или сервер не ответил. Попробуйте снова!"
L.ItemIDRemoved = "[%s] ItemID удален"
L.ItemIDAdded = "[%s] ItemID добавлен"
L.ItemIDExistBlacklist = "[%s] ItemID уже в базе черного списка."
L.ItemIDExistWhitelist = "[%s] ItemID уже в базе белого списка."
L.GuildExist = "Гильдия [%s] уже в базе черного списка."
L.GuildAdded = "Гильдия [%s] добавлена"
L.GuildRemoved = "Гильдия [%s] удалена"
L.BlackListRemove = "Удалить [%s] из черного списка?"
L.WhiteListRemove = "Удалить [%s] из белого списка?"
L.BlackListErrorRemove = "Ошибка удаления из черного списка."
L.WhiteListErrorRemove = "Ошибка удаления из белого списка."
L.ProfilesRemove = "Удалить профиль [%s][|cFF99CC33%s|r] из BagSync?"
L.ProfilesErrorRemove = "Ошибка удаления из BagSync."
L.ProfileBeenRemoved = "Профиль [%s][|cFF99CC33%s|r] удален из BagSync!"
L.ProfessionsFailedRequest = "[%s] Запрос к серверу не удался."
L.ProfessionHasRecipes = "Левый клик для просмотра рецептов."
L.ProfessionHasNoRecipes = "Нет рецептов для просмотра."
L.KeybindBlacklist = "Показать окно черного списка."
L.KeybindWhitelist = "Показать окно белого списка."
L.KeybindCurrency = "Показать окно валюты."
L.KeybindGold = "Показать всплывающую подсказку с золотом."
L.KeybindProfessions = "Показать окно профессий."
L.KeybindProfiles = "Показать окно профилей."
L.KeybindSearch = "Показать окно поиска."
L.ObsoleteWarning = "\n\nПримечание: Устаревшие предметы будут отображаться как отсутствующие. Чтобы исправить эту проблему, повторно просканируйте ваших персонажей, чтобы удалить устаревшие предметы.\n(Сумки, Банк, Реагенты, Хранилище и т.д.)"
L.DatabaseReset = "Из-за изменений в базе данных ваша база BagSync была сброшена."
L.UnitDBAuctionReset = "Данные аукциона были сброшены для всех персонажей."
L.ScanGuildBankStart = "Запрос информации о банковской гильдии с сервера, пожалуйста, подождите..."
L.ScanGuildBankDone = "Сканирование банка гильдии завершено!"
L.ScanGuildBankError = "Предупреждение: Сканирование банка гильдии не завершено."
L.ScanGuildBankScanInfo = "Сканирование вкладки гильдии (%s/%s)."
L.DefaultColors = "Цвета по умолчанию"
-- ----THESE ARE FOR SLASH COMMANDS OPERATORS
L.SlashItemName = "[itemname]"
L.SlashSearch = "search"
L.SlashGold = "gold"
L.SlashMoney = "money"
L.SlashConfig = "config"
L.SlashCurrency = "currency"
L.SlashFixDB = "fixdb"
L.SlashProfiles = "profiles"
L.SlashProfessions = "professions"
L.SlashBlacklist = "blacklist"
L.SlashWhitelist = "whitelist"
L.SlashResetDB = "resetdb"
L.SlashDebug = "debug"
L.SlashResetPOS = "resetpos"
L.SlashSortOrder = "sortorder"
------------------------
-- ----THESE USE THE SLASH OPERATOR COMMANDS FOUND ABOVE
L.HelpSearchItemName = "Выполняет быстрый поиск предмета"
L.HelpSearchWindow = "Открывает окно поиска"
L.HelpGoldTooltip = "Отображает всплывающую подсказку с количеством золота у каждого персонажа."
L.HelpCurrencyWindow = "Открывает окно валюты."
L.HelpProfilesWindow = "Открывает окно профилей."
L.HelpFixDB = "Запускает исправление базы данных (FixDB) для BagSync."
L.HelpResetDB = "Сбрасывает всю базу данных BagSync."
L.HelpConfigWindow = "Открывает окно конфигурации BagSync"
L.HelpProfessionsWindow = "Открывает окно профессий."
L.HelpBlacklistWindow = "Открывает окно черного списка."
L.HelpWhitelistWindow = "Открывает окно белого списка."
L.HelpDebug = "Открывает окно отладки BagSync."
L.HelpResetPOS = "Сбрасывает позиции всех фреймов для каждого модуля BagSync."
L.HelpSortOrder = "Пользовательский порядок сортировки для персонажей и гильдий."
------------------------
L.EnableBagSyncTooltip = "Включить всплывающие подсказки BagSync"
L.ShowOnModifier = "Клавиша-модификатор для всплывающих подсказок BagSync:"
L.ShowOnModifierDesc = "Показывать всплывающую подсказку BagSync при использовании клавиши-модификатора."
L.ModValue_NONE = "Нет (Всегда показывать)"
L.ModValue_ALT = "ALT"
L.ModValue_CTRL = "CTRL"
L.ModValue_SHIFT = "SHIFT"
L.EnableExtTooltip = "Отображать данные о количестве предметов во внешней всплывающей подсказке."
L.EnableLoginVersionInfo = "Отображать текст версии BagSync при входе в игру."
L.FocusSearchEditBox = "Фокусировать поле поиска при открытии окна поиска."
L.AlwaysShowAdvSearch = "Всегда показывать окно расширенного поиска BagSync."
L.DisplayTotal = "Отображать общее количество [Итого]."
L.DisplayGuildGoldInGoldWindow = "Отображать общее количество золота [Гильдия] в окне золота."
L.Display_GSC = "Отображать |cFFFFD700Золото|r, |cFFC0C0C0Серебро|r и |cFFB87333Медь|r в окне золота."
L.DisplayMailbox = "Отображать предметы в почтовом ящике."
L.DisplayAuctionHouse = "Отображать предметы аукционного дома."
L.DisplayMinimap = "Отображать кнопку миникарты BagSync."
L.DisplayFaction = "Отображать предметы для обеих фракций (|cff3587ffАльянс|r/|cFFDF2B2BОрда|r)."
L.DisplayClassColor = "Отображать цвета классов для имен персонажей."
L.DisplayItemTotalsByClassColor = "Отображать общее количество предметов по цвету класса персонажа."
L.DisplayTooltipOnlySearch = "Отображать всплывающую подсказку BagSync |cFF99CC33(ТОЛЬКО)|r в окне поиска."
L.DisplayTooltipCurrencyData = "Отображать данные всплывающей подсказки BagSync в окне валюты Blizzard."
L.DisplayLineSeparator = "Отображать пустую строку-разделитель."
L.DisplayCurrentCharacter = "Текущий персонаж"
L.DisplayCurrentCharacterOnly = "Отображать данные всплывающей подсказки BagSync только для текущего персонажа |cFFFFD700ТОЛЬКО!|r |cFFDF2B2B(Не рекомендуется)|r"
L.DisplayBlacklistCurrentCharOnly = "Отображать количество предметов из черного списка только для текущего персонажа |cFFFFD700ТОЛЬКО!|r |cFFDF2B2B(Не рекомендуется)|r"
L.DisplayCurrentRealmName = "Отображать |cFF4CBB17[Текущий сервер]|r игрока."
L.DisplayCurrentRealmShortName = "Использовать короткое имя для |cFF4CBB17[Текущего сервера]|r."
L.DisplayCR = "Отображать персонажей |cffff7d0a[Связанного сервера]|r. |cffff7d0a[CR]|r"
L.DisplayBNET = "Отображать всех персонажей учетной записи Battle.Net. |cff3587ff[BNet]|r |cFFDF2B2B(Не рекомендуется)|r"
L.DisplayItemID = "Отображать ItemID во всплывающей подсказке."
L.DisplaySourceDebugInfo = "Отображать полезную информацию [Отладка] во всплывающей подсказке."
L.DisplayWhiteListOnly = "Отображать общее количество предметов во всплывающей подсказке только для элементов белого списка."
L.DisplaySourceExpansion = "Отображать расширение источника для предметов во всплывающей подсказке. |cFF99CC33[Только для Retail]|r"
L.DisplayItemTypes = "Отображать категории [Тип предмета | Подтип] во всплывающей подсказке."
L.DisplayTooltipTags = "Теги"
L.DisplayTooltipStorage = "Хранилище"
L.DisplayTooltipExtra = "Дополнительно"
L.DisplaySortOrderHelp = "Помощь по порядку сортировки"
L.DisplaySortOrderStatus = "Порядок сортировки сейчас: [%s]"
L.DisplayWhitelistHelp = "Помощь по белому списку"
L.DisplayWhitelistStatus = "Белый список сейчас: [%s]"
L.DisplayWhitelistHelpInfo = "В базу белого списка можно вводить только номера ItemID. \n\nДля ввода боевых питомцев используйте FakeID, а не ItemID, вы можете получить FakeID, включив функцию отображения ItemID в настройках BagSync.\n\n|cFFDF2B2BЭто НЕ будет работать для окна валюты.|r"
L.DisplayWhitelistHelpInfo2 = "\n\n\n\n|cFFFF7D0AПРЕДУПРЕЖДЕНИЕ: Эта функция белого списка заблокирует подсчет |cFFFFFFFF--ВСЕХ--|r предметов BagSync, кроме тех, что находятся в этом списке.|r\n|cFF09DBE0Это обратный черный список!|r"
L.DisplayTooltipAccountWide = "По всей учетной записи"
L.DisplayAccountWideTagOpts = "|cFF99CC33Настройки тегов ( |cffff7d0a[CR]|r & |cff3587ff[BNet]|r )|r"
L.DisplayGreenCheck = "Отображать %s рядом с именем текущего персонажа."
L.DisplayRealmIDTags = "Отображать идентификаторы серверов |cffff7d0a[CR]|r и |cff3587ff[BNet]|r."
L.DisplayRealmNames = "Отображать имена серверов."
L.DisplayRealmAstrick = "Отображать [*] вместо имен серверов для |cffff7d0a[CR]|r и |cff3587ff[BNet]|r."
L.DisplayShortRealmName = "Отображать короткие имена серверов для |cffff7d0a[CR]|r и |cff3587ff[BNet]|r."
L.DisplayFactionIcons = "Отображать иконки фракций во всплывающей подсказке."
L.DisplayGuildBankTabs = "Отображать вкладки банка гильдии [1,2,3, и т.д.] во всплывающей подсказке."
L.DisplayWarbandBankTabs = "Отображать вкладки банка отряда [1,2,3, и т.д.] во всплывающей подсказке."
L.DisplayEquipBagSlots = "Отображать слоты экипированных сумок <1,2,3, и т.д.> во всплывающей подсказке."
L.DisplayRaceIcons = "Отображать иконки рас персонажей во всплывающей подсказке."
L.DisplaySingleCharLocs = "Отображать один символ для мест хранения."
L.DisplayIconLocs = "Отображать иконку для мест хранения."
L.DisplayGuildSeparately = "Отображать имена [Гильдия] и общее количество предметов отдельно от итогов персонажей."
L.DisplayGuildCurrentCharacter = "Отображать предметы [Гильдия] только для текущего вошедшего персонажа."
L.DisplayGuildBankScanAlert = "Отображать окно предупреждения о сканировании банка гильдии."
L.DisplayAccurateBattlePets = "Включить точное отслеживание боевых питомцев в банке гильдии и почте. |cFFDF2B2B(Может вызвать лаги)|r |cff3587ff[См. FAQ BagSync]|r"
L.DisplaySortCurrencyByExpansionFirst = "Сортировать окно валюты BagSync сначала по расширению, а не по алфавиту."
L.DisplaySorting = "Сортировка всплывающих подсказок"
L.DisplaySortInfo = "По умолчанию: Всплывающие подсказки сортируются по алфавиту по серверу, затем по имени персонажа."
L.SortCurrentPlayerOnTop = "Сортировать по умолчанию и всегда отображать текущего персонажа сверху."
L.SortTooltipByTotals = "Сортировать по общему количеству, а не по алфавиту."
L.SortByCustomSortOrder = "Сортировать по пользовательскому порядку сортировки."
L.CustomSortInfo = "Список использует порядок по возрастанию (1,2,3)"
L.CustomSortInfoWarn = "|cFF99CC33ПРИМЕЧАНИЕ: Используйте только числа! Примеры: (-1,0,3,4,37,99,-45)|r"
L.DisplayShowUniqueItemsTotals = "Включение этой опции позволит добавлять уникальные предметы к общему количеству предметов, независимо от их характеристик. |cFF99CC33(Рекомендуется)|r."
L.DisplayShowUniqueItemsTotals_2 = [[
Некоторые предметы, такие как |cffff7d0a[Легендарные]|r, могут иметь одинаковое название, но разные характеристики. Поскольку эти предметы считаются независимыми друг от друга, они иногда не учитываются в общем количестве предметов. Включение этой опции полностью игнорирует уникальные характеристики предметов и рассматривает их как одинаковые, если у них совпадает название предмета.

Отключение этой опции будет отображать количество предметов независимо, так как будут учитываться характеристики предметов. Общее количество предметов будет отображаться только для каждого персонажа, у которого есть одинаковый уникальный предмет с точно такими же характеристиками. |cFFDF2B2B(Не рекомендуется)|r
]]
L.DisplayShowUniqueItemsTotalsTitle = "Показать общее количество уникальных предметов во всплывающей подсказке"
L.DisplayShowUniqueItemsEnableText = "Включить общее количество уникальных предметов."
L.ColorPrimary = "Основной цвет всплывающей подсказки BagSync."
L.ColorSecondary = "Вторичный цвет всплывающей подсказки BagSync."
L.ColorTotal = "Цвет [Итого] всплывающей подсказки BagSync."
L.ColorGuild = "Цвет [Гильдия] всплывающей подсказки BagSync."
L.ColorWarband = "Цвет [Отряд] всплывающей подсказки BagSync."
L.ColorCurrentRealm = "Цвет [Текущий сервер] всплывающей подсказки BagSync."
L.ColorCR = "Цвет [Связанный сервер] всплывающей подсказки BagSync."
L.ColorBNET = "Цвет [Battle.Net] всплывающей подсказки BagSync."
L.ColorItemID = "Цвет [ItemID] всплывающей подсказки BagSync."
L.ColorExpansion = "Цвет [Расширение] всплывающей подсказки BagSync."
L.ColorItemTypes = "Цвет [Тип предмета] всплывающей подсказки BagSync."
L.ColorGuildTabs = "Цвет вкладок гильдии [1,2,3, и т.д.] всплывающей подсказки."
L.ColorWarbandTabs = "Цвет вкладок отряда [1,2,3, и т.д.] всплывающей подсказки."
L.ColorBagSlots = "Цвет слотов сумок <1,2,3, и т.д.> всплывающей подсказки."
L.ConfigHeader = "Настройки для различных функций BagSync."
L.ConfigDisplay = "Отображение"
L.ConfigTooltipHeader = "Настройки для отображаемой информации всплывающей подсказки BagSync."
L.ConfigColor = "Цвет"
L.ConfigColorHeader = "Настройки цвета для информации всплывающей подсказки BagSync."
L.ConfigMain = "Основные"
L.ConfigMainHeader = "Основные настройки для BagSync."
L.ConfigSearch = "Поиск"
L.ConfigKeybindings = "Горячие клавиши"
L.ConfigKeybindingsHeader = "Настройки горячих клавиш для функций BagSync."
L.ConfigExternalTooltip = "Внешняя всплывающая подсказка"
L.ConfigSearchHeader = "Настройки для окна поиска"
L.ConfigFont = "Шрифт"
L.ConfigFontSize = "Размер шрифта"
L.ConfigFontOutline = "Контур"
L.ConfigFontOutline_NONE = "Нет"
L.ConfigFontOutline_OUTLINE = "Контур"
L.ConfigFontOutline_THICKOUTLINE = "Толстый контур"
L.ConfigFontMonochrome = "Монохромный"
L.ConfigTracking = "Отслеживание"
L.ConfigTrackingHeader = "Настройки отслеживания для всех сохраненных местоположений базы данных BagSync."
L.ConfigTrackingCaution = "Предупреждение"
L.ConfigTrackingModules = "Модули"
L.ConfigTrackingInfo = [[
|cFFDF2B2BПРИМЕЧАНИЕ|r: Отключение модуля заставит BagSync прекратить отслеживание и сохранение данных этого модуля в базе данных.

Отключенные модули не будут отображаться ни в одном из окон BagSync, командах, всплывающих подсказках или кнопке миникарты.
]]
L.TrackingModule_Bag = "Сумки"
L.TrackingModule_Bank = "Банк"
L.TrackingModule_Reagents = "Банк реагентов"
L.TrackingModule_Equip = "Экипированные предметы"
L.TrackingModule_Mailbox = "Почтовый ящик"
L.TrackingModule_Void = "Хранилище"
L.TrackingModule_Auction = "Аукционный дом"
L.TrackingModule_Guild = "Банк гильдии"
L.TrackingModule_WarbandBank = "Банк отряда (WarBank)"
L.TrackingModule_Professions = "Профессии / Ремесла"
L.TrackingModule_Currency = "Валюта"
L.WarningItemSearch = "ПРЕДУПРЕЖДЕНИЕ: Всего [|cFFFFFFFF%s|r] предметов не были найдены!\n\nBagSync все еще ожидает ответа от сервера/кэша.\n\nНажмите кнопку Поиск или Обновить."
L.WarningUpdatedDB = "Вы обновлены до последней версии базы данных! Вам нужно повторно просканировать всех ваших персонажей!|r"
L.WarningCurrencyUpt = "Ошибка обновления валюты. Пожалуйста, войдите персонажем: "
L.WarningHeader = "Предупреждение!"
L.SavedSearch = "Сохраненный поиск"
L.SavedSearch_Add = "Добавить поиск"
L.SavedSearch_Warn = "Вы должны ввести что-то в поле поиска."
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
L.SearchHelpHeader = "Помощь по поиску"
L.SearchHelp = [[
|cffff7d0aОпции поиска|r:
|cFFDF2B2B(ПРИМЕЧАНИЕ: Все команды только на английском!)|r

|cFF99CC33Предметы персонажа по местоположению|r:
@bag
@bank
@reagents
@equip
@mailbox
@void
@auction
@guild
@warband

|cffff7d0aРасширенный поиск|r (|cFF99CC33команды|r | |cFFFFD580пример|r):

|cff00ffff<имя предмета>|r = |cFF99CC33n|r ; |cFF99CC33name|r | |cFFFFD580n:<текст>|r ; |cFFFFD580name:<текст>|r (n:руда ; name:руда)

|cff00ffff<привязка предмета>|r = |cFF99CC33bind|r | |cFFFFD580bind:<тип>|r ; типы (boe, bop, bou, boq) например boe = привязка при экипировке

|cff00ffff<качество>|r = |cFF99CC33q|r ; |cFF99CC33quality|r | |cFFFFD580q<оп><текст>|r ; |cFFFFD580q<оп><цифра>|r (q:редкий ; q:>2 ; q:>=3)

|cff00ffff<ilvl>|r = |cFF99CC33l|r ; |cFF99CC33level|r ; |cFF99CC33lvl|r ; |cFF99CC33ilvl|r | |cFFFFD580ilvl<оп><число>|r ; |cFFFFD580lvl<оп><число>|r (lvl:>5 ; lvl:>=20)

|cff00ffff<требуемый ilvl>|r = |cFF99CC33r|r ; |cFF99CC33req|r ; |cFF99CC33rl|r ; |cFF99CC33reql|r ; |cFF99CC33reqlvl|r | |cFFFFD580req<оп><число>|r ; |cFFFFD580req<оп><число>|r (req:>5 ; req:>=20)

|cff00ffff<тип / слот>|r = |cFF99CC33t|r ; |cFF99CC33type|r ; |cFF99CC33slot|r | |cFFFFD580t:<текст>|r (slot:голова) ; (t:боевойпитомец или t:клетка) (t:броня) (t:оружие)

|cff00ffff<всплывающая подсказка>|r = |cFF99CC33tt|r ; |cFF99CC33tip|r ; |cFF99CC33tooltip|r | |cFFFFD580tt:<текст>|r (tt:призыв)

|cff00ffff<набор предметов>|r = |cFF99CC33s|r ; |cFF99CC33set|r | |cFFFFD580s:<имя_набора>|r (имя_набора может быть * для всех наборов)

|cff00ffff<расширение>|r = |cFF99CC33x|r ; |cFF99CC33xpac|r ; |cFF99CC33expansion|r | |cFFFFD580x:<ID_расширения>|r ; |cFFFFD580x:<имя_расширения>|r ; |cFFFFD580xpac:<имя_расширения>|r (xpac:тень)

|cff00ffff<ключевое слово>|r = |cFF99CC33k|r ; |cFF99CC33key|r ; |cFF99CC33keyword|r | |cFFFFD580k:<ключевое_слово>|r (key:квест) (ключевые слова: привязанный, boe, bop, bou, boa, квест, уникальный, игрушка, реагент, ремесло, naval, последователь, следовать, сила, внешнийвид)

|cff00ffff<класс>|r = |cFF99CC33c|r ; |cFF99CC33class|r | |cFFFFD580c:<имя_класса>|r ; |cFFFFD580class:<имя_класса>|r (class:шаман)

|cffff7d0aОператоры <op>|r:
|cFF99CC33:|r | |cFF99CC33=|r | |cFF99CC33==|r | |cFF99CC33!=|r | |cFF99CC33~=|r | |cFF99CC33<|r | |cFF99CC33>|r | |cFF99CC33<=|r | |cFF99CC33>=|r


|cffff7d0aОтрицательные команды|r:
Пример: |cFF99CC33!|r|cFFFFD580bind:boe|r (не boe)
Пример: |cFF99CC33!|r|cFFFFD580bind:boe|r |cFF99CC33&&|r |cFFFFD580lvl:>20|r (не boe и уровень предмета больше 20)

|cffff7d0aОбъединенные поиски (и поиски):|r
(Используйте двойной амперсанд |cFF99CC33&&|r)
Пример: |cFFFFD580bind:boe|r |cFF99CC33&&|r |cFFFFD580lvl:>20|r

|cffff7d0aПересекающиеся поиски (или поиски):|r
(Используйте двойную вертикальную черту |cFF99CC33|||||r)
Пример: |cFFFFD580bind:boe|r |cFF99CC33|||||r |cFFFFD580lvl:>20|r

|cffff7d0aПример сложного поиска:|r
(привязка при экипировке, уровень точно 20 с словом 'robe' в названии)
|cFFFFD580bind:boe|r |cFF99CC33&&|r |cFFFFD580lvl:20|r |cFF99CC33&&|r |cFFFFD580name:robe|r

]]
L.ConfigFAQ= "ЧаВО / Помощь"
L.ConfigFAQHeader = "Часто задаваемые вопросы и раздел помощи для BagSync."
L.FAQ_Question_1 = "Я испытываю заикания/зависания/лаги с всплывающими подсказками."
L.FAQ_Question_1_p1 = [[
Эта проблема обычно возникает, когда в базе данных есть старые или поврежденные данные, которые BagSync не может интерпретировать. Проблема также может возникать при большом количестве данных, которые BagSync должен обработать. Если у вас тысячи предметов на нескольких персонажах, это большой объем данных для обработки за секунду. Это может привести к кратковременному заиканию клиента. Наконец, еще одной причиной этой проблемы может быть использование очень старого компьютера. На старых компьютерах будут наблюдаться заикания/зависания, так как BagSync обрабатывает тысячи данных о предметах и персонажах. Новые компьютеры с более быстрыми процессорами и памятью обычно не сталкиваются с этой проблемой.

Чтобы исправить эту проблему, вы можете попробовать сбросить базу данных. Это обычно решает проблему. Используйте следующую команду: |cFF99CC33/bgs resetdb|r
Если это не решает вашу проблему, пожалуйста, создайте тикет на GitHub для BagSync.
]]
L.FAQ_Question_2 = "Нет данных о предметах для других учетных записей WOW в |cFFDF2B2Bодной|r |cff3587ffBattle.net|r учетной записи."
L.FAQ_Question_2_p1 = [[
Аддоны не имеют возможности читать данные с других учетных записей WOW. Это связано с тем, что они не используют одну и ту же папку SavedVariables. Это встроенное ограничение в клиенте Blizzard WOW. Поэтому вы не сможете видеть данные о предметах для нескольких учетных записей WOW в |cFFDF2B2Bодной|r |cff3587ffBattle.net|r. BagSync сможет читать данные персонажей только на нескольких серверах в пределах одной учетной записи WOW, а не всей учетной записи Battle.net.

Существует способ связать несколько учетных записей WOW в |cFFDF2B2Bодной|r |cff3587ffBattle.net|r учетной записи, чтобы они использовали одну и ту же папку SavedVariables. Это включает создание символических ссылок (Symlink). Я не буду предоставлять помощь по этому вопросу. Поэтому не спрашивайте! Пожалуйста, посетите следующее руководство для получения дополнительной информации: |cFF99CC33https://www.wowhead.com/guide=934|r
]]
L.FAQ_Question_3 = "Можно ли просматривать данные о предметах с |cFFDF2B2Bнескольких|r |cff3587ffBattle.net|r учетных записей?"
L.FAQ_Question_3_p1 = "Нет, это невозможно. Я не буду предоставлять помощь по этому вопросу. Поэтому не спрашивайте!"
L.FAQ_Question_4 = "Можно ли просматривать данные о предметах с нескольких учетных записей WOW, |cFFDF2B2Bв настоящее время вошедших в игру|r?"
L.FAQ_Question_4_p1 = "В настоящее время BagSync не поддерживает передачу данных между несколькими вошедшими учетными записями WOW. Это может измениться в будущем."
L.FAQ_Question_5 = "Почему я получаю сообщение о том, что сканирование банка гильдии не завершено?"
L.FAQ_Question_5_p1 = [[
BagSync должен запросить у сервера |cFF99CC33ВСЮ|r информацию о вашем банке гильдии. Передача всех данных с сервера занимает время. Чтобы BagSync правильно сохранил все ваши предметы, вы должны дождаться завершения запроса к серверу. Когда процесс сканирования завершен, BagSync уведомит вас в чате. Если вы закроете окно банка гильдии до завершения процесса сканирования, это приведет к сохранению неверных данных для вашего банка гильдии.
]]
L.FAQ_Question_6 = "Почему я вижу [FakeID] вместо [ItemID] для боевых питомцев?"
L.FAQ_Question_6_p1 = [[
Blizzard не присваивает ItemID боевым питомцам в WOW. Вместо этого боевые питомцы в WOW получают временный PetID от сервера. Этот PetID не является уникальным и будет изменен при сбросе сервера. Чтобы отслеживать боевых питомцев, BagSync генерирует FakeID. FakeID создается на основе статичных чисел, связанных с боевым питомцем. Использование FakeID позволяет BagSync отслеживать боевых питомцев даже после сброса сервера.
]]
L.FAQ_Question_7 = "Что такое точное сканирование боевых питомцев в банке гильдии и почте?"
L.FAQ_Question_7_p1 = [[
Blizzard не сохраняет боевых питомцев в банке гильдии или почте с правильным ItemID или SpeciesID. На самом деле боевые питомцы хранятся в банке гильдии и почте как |cFF99CC33[Клетка для питомца]|r с ItemID |cFF99CC3382800|r. Это затрудняет получение данных о конкретных боевых питомцах для авторов аддонов. Вы можете сами убедиться в этом в журналах транзакций банка гильдии, где боевые питомцы отображаются как |cFF99CC33[Клетка для питомца]|r. Если вы свяжете одного из банка гильдии, он также будет отображаться как |cFF99CC33[Клетка для питомца]|r. Чтобы обойти эту проблему, можно использовать два метода. Первый метод заключается в привязке боевого питомца к всплывающей подсказке и получении SpeciesID оттуда. Это требует ответа сервера клиенту WOW и может привести к значительным лагам, особенно если в банке гильдии много боевых питомцев. Второй метод использует iconTexture боевого питомца для попытки найти SpeciesID. Это иногда неточно, так как некоторые боевые питомцы имеют одинаковый iconTexture. Например: Токсичный Отросток имеет тот же iconTexture, что и Нефритовый Слизнюк. Включение этой опции заставит использовать метод сканирования всплывающей подсказки для максимальной точности, но это может вызвать лаги. |cFFDF2B2BЭтого нельзя избежать, пока Blizzard не предоставит больше данных для работы.|r
]]
L.BagSyncInfoWindow = [[
BagSync по умолчанию показывает данные всплывающих подсказок только для персонажей на связанных серверах. ( |cffff7d0a[CR]|r )

Связанные серверы ( |cffff7d0a[CR]|r ) — это серверы, которые были объединены.

Для полного списка, пожалуйста, посетите:
(|cFF99CC33 https://tinyurl.com/msncc7j6 |r)


|cFFfd5c63BagSync НЕ будет показывать данные со всей вашей учетной записи Battle.Net по умолчанию. Вам нужно включить эту опцию!|r
( |cff3587ff[BNet]|r )

|cFF52D386Если вы хотите видеть всех своих персонажей по всей учетной записи Battle.net ( |cff3587ff[BNet]|r ), вам нужно включить опцию в окне конфигурации BagSync в разделе [По всей учетной записи].|r

Опция называется:
]]
