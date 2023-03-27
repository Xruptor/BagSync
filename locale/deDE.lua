
local L = LibStub("AceLocale-3.0"):NewLocale("BagSync", "deDE")
if not L then return end

--special thanks to Dlarge, GrimPala from wowinterface.com

L.Yes = "Ja"
L.No = "Nein"
L.Page = "Seite"
L.Done = "Fertig"
L.Realm = "Realm:"
L.TooltipCR_Tag = "CR"
L.TooltipBNET_Tag = "BN"
L.Tooltip_bag = "Taschen"
L.Tooltip_bank = "Bank"
L.Tooltip_equip = "Angelegt"
L.Tooltip_guild = "Gilde"
L.Tooltip_mailbox = "Post"
L.Tooltip_void = "Leerenlager"
L.Tooltip_reagents = "Materiallager"
L.Tooltip_auction = "AH"
L.TooltipSmall_bag = "P"
L.TooltipSmall_bank = "B"
L.TooltipSmall_reagents = "R"
L.TooltipSmall_equip = "E"
L.TooltipSmall_guild = "G"
L.TooltipSmall_mailbox = "M"
L.TooltipSmall_void = "V"
L.TooltipSmall_auction = "A"
--do not touch these unless requiring a new image for a specific localization
L.TooltipIcon_bag = [[|TInterface\AddOns\BagSync\media\bag:13:13|t]]
L.TooltipIcon_bank = [[|TInterface\AddOns\BagSync\media\bank:13:13|t]]
L.TooltipIcon_reagents = [[|TInterface\AddOns\BagSync\media\reagents:13:13|t]]
L.TooltipIcon_equip = [[|TInterface\AddOns\BagSync\media\equip:13:13|t]]
L.TooltipIcon_guild = [[|TInterface\AddOns\BagSync\media\guild:13:13|t]]
L.TooltipIcon_mailbox = [[|TInterface\AddOns\BagSync\media\mailbox:13:13|t]]
L.TooltipIcon_void = [[|TInterface\AddOns\BagSync\media\void:13:13|t]]
L.TooltipIcon_auction = [[|TInterface\AddOns\BagSync\media\auction:13:13|t]]
L.TooltipTotal = "Total:"
L.TooltipGuildTabs = "T:"
L.TooltipItemID = "[ItemID]:"
L.TooltipDebug = "[Debug]:"
L.TooltipCurrencyID = "[WährungsID]:"
L.TooltipFakeID = "[FakeID]:"
L.TooltipExpansion = "[Expansion]:"
L.TooltipItemType = "[ItemTypes]:"
L.TooltipDelimiter = ", "
L.TooltipRealmKey = "RealmKey:"
L.TooltipDetailsInfo = "Item detailed summary."
L.DetailsBagID = "Bag:"
L.DetailsSlot = "Slot:"
L.DetailsTab = "Tab:"
L.Debug_DEBUG = "DEBUG"
L.Debug_INFO = "INFO"
L.Debug_TRACE = "TRACE"
L.Debug_WARN = "WARN"
L.Debug_FINE = "FINE"
L.Debug_SL1 = "SL1" --sublevel 1
L.Debug_SL2 = "SL2" --sublevel 2
L.Debug_SL3 = "SL3" --sublevel 3
L.DebugEnable = "Enable Debug"
L.DebugCache = "Disable Cache"
L.DebugDumpOptions = "Dump Options |cff3587ff[DEBUG]|r"
L.DebugIterateUnits = "Iterate Units |cff3587ff[DEBUG]|r"
L.DebugDBTotals = "DB Totals |cff3587ff[DEBUG]|r"
L.DebugAddonList = "Addon List |cff3587ff[DEBUG]|r"
L.DebugExport = "Export"
L.DebugWarning = "|cFFDF2B2BWARNING:|R BagSync Debug is currently enabled! |cFFDF2B2B(WILL CAUSE LAG)|r"
L.Search = "Suche"
L.Debug = "Debug"
L.AdvSearchBtn = "Suche/Aktualisierung"
L.Reset = "Zurücksetzen"
L.Refresh = "Aktualisierung"
L.Clear = "Clear"
L.AdvancedSearch = "Erweiterte Suche"
L.AdvancedSearchInformation = "* Benutze BagSync |cffff7d0a[CR]|r und |cff3587ff[BNet]|r Einstellungen."
L.AdvancedLocationInformation = "* Wenn Du keine auswählst, wird standardmäßig ALLE ausgewählt."
L.Units = "Einheiten:"
L.Locations = "Standort:"
L.Profiles = "Profile"
L.SortOrder = "Benutzerdefinierte Sortierreihenfolge"
L.Professions = "Berufe"
L.Currency = "Währung"
L.Blacklist = "Blacklist"
L.Whitelist = "Whitelist"
L.Recipes = "Rezepte"
L.Details = "Details"
L.Gold = "Gold"
L.Close = "Schließen"
L.FixDB = "FixDB"
L.Config = "Einstellungen"
L.DeleteWarning = "Wähle ein Profil zum löschen aus. INFO: Dies ist nicht umkehrbar!"
L.Delete = "Löschen"
L.Confirm = "Bestätigen"
L.SelectAll = "Select All"
L.FixDBComplete = "Die Funktion FixDB wurde ausgeführt! Die Datenbank wurde optimiert!"
L.ResetDBInfo = "BaySync:\nBist Du sicher, dass Du die Datenbank zurücksetzen möchtest?\nin|cFFDF2B2B HINWEIS: Dies kann nicht rückgängig gemacht werden!|r"
L.ON = "An"
L.OFF = "Aus"
L.LeftClickSearch = "|cffddff00Links Klick|r |cff00ff00= Suchen|r"
L.RightClickBagSyncMenu = "|cffddff00Rechts Klick|r |cff00ff00= BagSync Menu|r"
L.ProfessionInformation = "|cffddff00Links Klick|r |cff00ff00a Beruf zum Anzeigen von Rezepten.|r"
L.ClickViewProfession = "Klicke hier, um den Beruf anzuzeigen: "
L.ClickHere = "Klicke hier"
L.ErrorUserNotFound = "BagSync: Fehler, Benutzer nicht gefunden!"
L.EnterItemID = "Trage bitte eine ItemID ein. (Benutze wowhead.com)"
L.AddGuild = "Gilde einfügen"
L.AddItemID = "ItemID Einfügen"
L.RemoveItemID = "Entferne ItemID"
L.ItemIDNotFound = "[%s] ItemID nicht gefunden. Versuche es erneut!"
L.ItemIDNotValid = "[%s] ItemID ungültige ItemID oder der Server hat nicht geantwortet. Versuche es erneut!"
L.ItemIDRemoved = "[%s] ItemID entfernt"
L.ItemIDAdded = "[%s] ItemID hinzugefügt"
L.ItemIDExistBlacklist = "[%s] ItemID bereits in Blacklist Datenbank."
L.GuildExist = "Gilde [%s] bereits in Blacklist Datenbank."
L.GuildAdded = "Gilde [%s] hinzugefügt"
L.GuildRemoved = "Guilde [%s] entfernt"
L.BlackListRemove = "[%s] von der Blacklist entfernen?"
L.WhiteListRemove = "Remove [%s] from the whitelist?"
L.BlackListErrorRemove = "Fehler beim Löschen von der Blacklist."
L.WhiteListErrorRemove = "Error deleting from whitelist."
L.ProfilesRemove = "Entferne [%s][|cFF99CC33%s|r] Profil von BagSync?"
L.ProfilesErrorRemove = "Fehler beim Löschen aus BagSync."
L.ProfileBeenRemoved = "[%s][|cFF99CC33%s|r] Profil entfert von BagSync!"
L.ProfessionsFailedRequest = "[%s] Serveranforderung fehlgeschlagen."
L.ProfessionHasRecipes = "Klicke mit der linken Maustaste, um Rezepte anzuzeigen."
L.ProfessionHasNoRecipes = "Hat keine Rezepte zum Anzeigen."
L.KeybindBlacklist = "Zeige Schwarze Liste Fenster"
L.KeybindWhitelist = "Show Whitelist window."
L.KeybindCurrency = "Zeige Währungsfenster"
L.KeybindGold = "Zeige Gold Tooltip"
L.KeybindProfessions = "Zeige Berufefenster"
L.KeybindProfiles = "Zeige Profilfenster"
L.KeybindSearch = "Zeige Suchfenster"
L.ObsoleteWarning = "\n\nNotiz: Veraltete Artikel werden weiterhin als fehlend angezeigt. Um dieses Problem zu beheben, scanne Deine Charaktere erneut, um veraltete Gegenstände zu entfernen.\n(Taschen, Bank, Reagenzien, Leerenlager, etc...)"
L.DatabaseReset = "Aufgrund von Änderungen in der Datenbank. Deine BagSync Datenbank wurde zurückgesetzt."
L.UnitDBAuctionReset = "Die Auktionsdaten wurden für alle Charaktere zurückgesetzt."
L.ScanGuildBankStart = "Abfrage des Servers für Informationen zur Gildenbank, bitte warten....."
L.ScanGuildBankDone = "Gildenbank Scan abgeschlossen!"
L.ScanGuildBankError = "Warnung: Das Scannen der Gildenbank ist unvollständig."
L.ScanGuildBankScanInfo = "Scanne Gildentab (%s/%s)."
L.DefaultColors = "Standard Farben"
-- ----THESE ARE FOR SLASH COMMANDS OPERATORS
L.SlashItemName = "[gegenstandsname]"
L.SlashSearch = "suche"
L.SlashGold = "gold"
L.SlashMoney = "geld"
L.SlashConfig = "einstellungen"
L.SlashCurrency = "währung"
L.SlashFixDB = "fixdb"
L.SlashProfiles = "profile"
L.SlashProfessions = "berufe"
L.SlashBlacklist = "blacklist"
L.SlashWhitelist = "whitelist"
L.SlashResetDB = "resetdb"
L.SlashDebug = "debug"
L.SlashResetPOS = "resetpos"
L.SlashSortOrder = "sortorder"
------------------------
-- ----THESE USE THE SLASH OPERATOR COMMANDS FOUND ABOVE
L.HelpSearchItemName = "Nach einem Item suchen"
L.HelpSearchWindow = "Öffnet das Suchfenster"
L.HelpGoldTooltip = "Zeigt einen Tooltip mit dem Gold eines jeden Charakters"
L.HelpCurrencyWindow = "Öffnet das Währungsfenster"
L.HelpProfilesWindow = "Öffnet das Profilfenster"
L.HelpFixDB = "Führt eine Reparatur der Datenbank (FixDB) aus"
L.HelpResetDB = "Setzt die gesamte BagSync Datenbank zurück"
L.HelpConfigWindow = "Öffnet die Einstellungen für BagSync"
L.HelpProfessionsWindow = "Öffnet das Berufefenster"
L.HelpBlacklistWindow = "Öffnet das Schwarze Liste Fenster"
L.HelpDebug = "Opens the BagSync Debug window."
L.HelpResetPOS = "Resets all frame positions for each BagSync module."
L.HelpSortOrder = "Custom Sort Order for characters and guilds."
------------------------
L.EnableBagSyncTooltip = "Aktiviere BagSync Tooltips"
L.ShowOnModifier = "BagSync tooltip modifier key:"
L.ShowOnModifierDesc = "Show BagSync Tooltip on modifier key."
L.ModValue_NONE = "None (Always Show)"
L.ModValue_ALT = "ALT"
L.ModValue_CTRL = "CTRL"
L.ModValue_SHIFT = "SHIFT"
L.EnableExtTooltip = "Zeige Artikelzähldaten in einer externen QuickInfo an"
L.EnableLoginVersionInfo = "BagSync Versionsinfo bei der Anmeldung anzeigen"
L.FocusSearchEditBox = "Suchfeld beim Öffnen des Suchfensters fokussieren"
L.AlwaysShowAdvSearch = "Always show the Bagsync Advanced Search window."
L.DisplayTotal = "Anzeige des [Gesamt] Betrags."
L.DisplayGuildGoldInGoldWindow = "Zeige [Gilde] Goldsummen im Gold Window an"
L.DisplayGuildBank = "Gildenbankgegenstände anzeigen. |cFF99CC33(Aktiviert das Scannen von Gildenbanken)|r"
L.DisplayMailbox = "Postfachgegenstände anzeigen"
L.DisplayAuctionHouse = "Auktionshausgegenstände anzeigen"
L.DisplayMinimap = "BagSync Minikartensymbol anzeigen"
L.DisplayFaction = "Gegenstände für beide Fraktionen anzeigen (|cff3587ffAllianz|r/|cFFDF2B2BHorde|r)"
L.DisplayClassColor = "Klassenfarben für Charaktere anzeigen"
L.DisplayItemTotalsByClassColor = "Display item totals by character class color."
L.DisplayTooltipOnlySearch = "BagSync Tooltip |cFF99CC33(NUR)|r im Suchfenster anzeigen"
L.DisplayLineSeparator = "Aktiviere eine leere Linie als Separator über der BagSync Tooltipanzeige"
L.DisplayCR = "Aktiviere Gegenstände für |cffff7d0a[Connected Realm]|r Charaktere.  |cffff7d0a[CR]|r"
L.DisplayBNET = "Aktiviere Battle.net Account Charaktere. |cff3587ff[BNet]|r |cFFDF2B2B(Nicht empfohlen!)|r"
L.DisplayItemID = "ItemID im Tooltip anzeigen"
L.DisplaySourceDebugInfo = "Zeigt hilfreiche [Debug] Informationen im Tooltip an"
L.DisplayWhiteListOnly = "Display tooltip item totals for whitelisted items only."
L.DisplaySourceExpansion = "Display source expansion for items in tooltip. |cFF99CC33[Retail Only]|r"
L.DisplayItemTypes = "Display the [Item Type | Sub Type] categories in tooltip."
L.DisplayTooltipTags = "Tags"
L.DisplayTooltipStorage = "Lagerung"
L.DisplayTooltipExtra = "Extra"
L.DisplaySortOrderHelp = "Sort Order Help"
L.DisplaySortOrderStatus = "Sort Order is currently: [%s]"
L.DisplayWhitelistHelp = "Whitelist Help"
L.DisplayWhitelistStatus = "Whitelist is currently: [%s]"
L.DisplayWhitelistHelpInfo = "You can only input itemid numbers into the whitelist database. \n\nTo input Battle Pets please use the FakeID and not the ItemID, you can grab the FakeID by enabling ItemID tooltip feature in BagSync config.\n\n|cFFDF2B2BThis will NOT work for the Currency Window.|r"
L.DisplayTooltipAccountWide = "Accountweit"
L.DisplayAccountWideTagOpts = "|cFF99CC33Tag Optionen ( |cffff7d0a[CR]|r & |cff3587ff[BNet]|r )|r"
L.DisplayGreenCheck = "Zeige %s neben dem aktuellen Charakternamen an"
L.DisplayRealmIDTags = "Zeige |cffff7d0a[CR]|r- und |cff3587ff[BNet]|r-Realm ID`s an"
L.DisplayRealmNames = "Realname anzeigen."
L.DisplayRealmAstrick = "Zeige [*] anstelle von Realmnamen für |cffff7d0a[CR]|r und |cff3587ff[BNet]|r an"
L.DisplayShortRealmName = "Kurze Realmnamen für |cffff7d0a[CR]|r und |cff3587ff[BNet]|r anzeigen"
L.DisplayFactionIcons = "Fraktionssymbole im Tooltip anzeigen"
L.DisplayGuildBankTabs = "Display guild bank tabs [1,2,3, etc...] in tooltip."
L.DisplayRaceIcons = "Display character race icons in tooltip."
L.DisplaySingleCharLocs = "Display a single character for storage locations."
L.DisplayIconLocs = "Display a icon for storage locations."
L.DisplayGuildSeparately = "Display [Guild] names and item totals separately from character totals."
L.DisplayGuildCurrentCharacter = "Zeige [Gilden] Gegenstände nur für den aktuell eingeloggten Charakter"
L.DisplayGuildBankScanAlert = "Zeigt das Scan Warnfenster der Gildenbank an"
L.DisplayAccurateBattlePets = "Genaue Kampfhaustiere in der Gildenbank und Mailbox aktivieren. |cFFDF2B2B(Kann zu Verzögerungen führen)|r |cff3587ff[Siehe BagSync FAQ]|r"
L.DisplaySorting = "Tooltip Sortierung"
L.DisplaySortInfo = "Standard: Tooltips werden alphabetisch nach Realm und dann nach Charakternamen sortiert."
L.SortTooltipByTotals = "Sortiere die BagSync Tooltips nach Summen und nicht alphabetisch."
L.SortByCustomSortOrder = "Sortieren nach benutzerdefinierter Sortierreihenfolge."
L.CustomSortInfo = "Liste verwendet eine aufsteigende Reihenfolge (1,2,3)"
L.CustomSortInfoWarn = "|cFF99CC33NOTE: Nur Zahlen benutzen! (-1,0,3,4)|r"
L.DisplayShowUniqueItemsTotals = "Wenn Du diese Option aktivierst, können einzigartige Gegenstände zur Gesamtzahl der Gegenstände hinzugefügt werden, unabhängig von den Gegenstandsstatistiken. |cFF99CC33(Empfohlen)|r."
L.DisplayShowUniqueItemsTotals_2 = [[
Bestimmte Gegenstände wie |cffff7d0a[Legendäre]|r können den gleichen Namen haben, aber unterschiedliche Werte haben. Da diese Artikel unabhängig voneinander behandelt werden, werden sie manchmal nicht auf die Gesamtanzahl der Artikel angerechnet. Wenn Sie diese Option aktivieren, werden die einzigartigen Gegenstandsstatistiken vollständig ignoriert und alle gleich behandelt, solange sie denselben Gegenstandsnamen haben.

Wenn Du diese Option deaktivierst, werden die Artikelanzahlen unabhängig angezeigt, da die Artikelstatistiken berücksichtigt werden. Gegenstandssummen werden nur für jeden Charakter angezeigt, der denselben einzigartigen Gegenstand mit exakt denselben Werten hat. |cFFDF2B2B(Nicht empfohlen)|r
]]
L.DisplayShowUniqueItemsTotalsTitle = "QuickInfo Gesamtsummen für einzigartige Gegenstände anzeigen"
L.DisplayShowUniqueItemsEnableText = "Aktiviere einzigartige Artikelsummen"
L.ColorPrimary = "Primäre BagSync Tooltipfarbe"
L.ColorSecondary = "Sekundäre BagSync Tooltipfarbe"
L.ColorTotal = "BagSync [Total] Tooltipfarbe"
L.ColorGuild = "BagSync [Gilde] Tooltipfarbe"
L.ColorCR = "BagSync [Connected Realm] Tooltipfarbe"
L.ColorBNET = "BagSync [Battle.Net] Tooltipfarbe"
L.ColorItemID = "BagSync [ItemID] Tooltipfarbe"
L.ColorExpansion = "BagSync [Expansion] tooltip color."
L.ColorItemTypes = "BagSync [ItemType] tooltip color."
L.ColorGuildTabs = "Guild Tabs [1,2,3, etc...] tooltip color."
L.ConfigHeader = "Einstellungen für verschiedene BagSync Funktionen."
L.ConfigDisplay = "Display"
L.ConfigTooltipHeader = "Einstellungen für die angezeigten BagSync Tooltip Informationen."
L.ConfigColor = "Farbe"
L.ConfigColorHeader = "Farbeinstellungen für BagSync Tooltip Informationen"
L.ConfigMain = "Hauptkonfig"
L.ConfigMainHeader = "Haupteinstellungen von BagSync"
L.ConfigSearch = "Suche"
L.ConfigKeybindings = "Keybindings"
L.ConfigKeybindingsHeader = "Keybind settings for BagSync features."
L.ConfigExternalTooltip = "External Tooltip"
L.ConfigSearchHeader = "Settings for the search window"
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
L.WarningItemSearch = "WARNING: A total of [|cFFFFFFFF%s|r] items were not searched!\n\nBagSync is still waiting for the server/cache to respond.\n\nPress Search or Refresh button."
L.WarningUpdatedDB = "You have been updated to latest database version!  You will need to rescan all your characters again!|r"
L.WarningHeader = "Warning!"
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
L.ConfigFAQ= "FAQ / Hilfe"
L.ConfigFAQHeader = "Häufig gestellte Fragen und Hilfebereich für BagSync."
L.FAQ_Question_1 = "Ich erlebe Ruckeln/Stottern/Verzögerungen bei Tooltips."
L.FAQ_Question_1_p1 = [[
Dieses Problem tritt normalerweise auf, wenn alte oder beschädigte Daten in der Datenbank vorhanden sind, die BagSync nicht interpretieren kann. Das Problem kann auch auftreten, wenn BagSync eine überwältigende Datenmenge verarbeiten muss. Wenn Sie Tausende von Elementen über mehrere Charaktere hinweg haben, müssen Sie innerhalb einer Sekunde eine Menge Daten durchgehen. Dies kann dazu führen, dass Ihr Kunde für einen kurzen Moment stottert. Schließlich ist ein extrem alter Computer eine weitere Ursache für dieses Problem. Bei älteren Computern kommt es zu Ruckeln/Stottern, da BagSync Tausende von Artikel- und Charakterdaten verarbeitet. Neuere Computer mit schnelleren CPUs und Arbeitsspeicher haben dieses Problem normalerweise nicht.

Um dieses Problem zu beheben, kannst Du versuchen, die Datenbank zurückzusetzen. Dies behebt normalerweise das Problem. Verwende den folgenden Slash-Befehl. |cFF99CC33/bgs resetdb|r
Wenn dies Dein Problem nicht löst, reiche bitte ein Problemticket auf GitHub für BagSync ein.
]]
L.FAQ_Question_2 = "Keine Gegenstandsdaten für meine anderen WOW-Konten in einem |cFFDF2B2Bsingle|r |cff3587ffBattle.net|r-Konto gefunden."
L.FAQ_Question_2_p1 = [[
Addons haben nicht die Fähigkeit, Daten von anderen WOW-Konten zu lesen. Dies liegt daran, dass sie nicht denselben SavedVariable-Ordner gemeinsam nutzen. Dies ist eine eingebaute Einschränkung im WOW-Client von Blizzard. Daher können Sie Artikeldaten für mehrere WOW-Konten unter einem |cFFDF2B2Bsingle|r |cff3587ffBattle.net|r nicht sehen. BagSync kann nur Charakterdaten über mehrere Realms innerhalb desselben WOW-Kontos lesen, nicht das gesamte Battle.net-Konto.

Es gibt eine Möglichkeit, mehrere WOW-Konten innerhalb eines |cFFDF2B2Bsingle|r |cff3587ffBattle.net|r-Kontos zu verbinden, sodass sie denselben SavedVariables-Ordner teilen. Dazu gehört das Erstellen von Symlink-Ordnern. Ich werde diesbezüglich keine Hilfe leisten. Also frag nicht! Weitere Informationen findest Du in der folgenden Anleitung. |cFF99CC33https://www.wowhead.com/guide=934|r
]]
L.FAQ_Question_3 = "Kannst Du Gegenstandsdaten von |cFFDF2B2Bmehreren|r |cff3587ffBattle.net|r Accounts anzeigen?"
L.FAQ_Question_3_p1 = "Nein, das ist nicht möglich. Ich werde dabei keine Hilfe leisten."
L.FAQ_Question_4 = "Kann ich Artikeldaten von mehreren WOW-Konten anzeigen, |cFFDF2B2Bderzeit eingeloggt|r?"
L.FAQ_Question_4_p1 = "Derzeit unterstützt BagSync die Übertragung von Daten zwischen mehreren angemeldeten WOW-Konten nicht. Dies kann sich in Zukunft ändern."
L.FAQ_Question_5 = "Warum erhalte ich eine Meldung, dass das Scannen der Gildenbank unvollständig ist?"
L.FAQ_Question_5_p1 = [[
BagSync muss den Server nach |cFF99CC33ALL|r deiner Gildenbankdaten abfragen. Es dauert einige Zeit, bis der Server alle Daten übertragen hat. Damit BagSync alle Ihre Artikel ordnungsgemäß speichern kann, müssen Sie warten, bis die Serverabfrage abgeschlossen ist. Wenn der Scanvorgang abgeschlossen ist, benachrichtigt BagSync Sie im Chat. Wenn Sie das Gildenbank-Fenster verlassen, bevor der Scanvorgang abgeschlossen ist, werden falsche Daten für Ihre Gildenbank gespeichert.
]]
L.FAQ_Question_6 = "Warum sehe ich [FakeID] anstelle von [ItemID] für Kampfhaustiere?"
L.FAQ_Question_6_p1 = [[
Blizzard weist Kampfhaustieren keine ItemIDs für WOW zu. Stattdessen wird Battle Pets in WOW eine temporäre PetID vom Server zugewiesen. Diese PetID ist nicht eindeutig und wird geändert, wenn der Server zurückgesetzt wird. Um Battle Pets im Auge zu behalten, generiert BagSync eine FakeID. Eine FakeID wird aus statischen Nummern generiert, die dem Battle Pet zugeordnet sind. Die Verwendung einer FakeID ermöglicht es BagSync, Battle Pets sogar über Server-Resets hinweg zu verfolgen.
]]
L.FAQ_Question_7 = "Was ist ein genaues Scannen von Kampfhaustieren in Gildenbank und Postfach?"
L.FAQ_Question_7_p1 = [[
Blizzard speichert Kampfhaustiere nicht mit einer korrekten ItemID oder SpeciesID in der Gildenbank oder Mailbox. Tatsächlich werden Kampfhaustiere in der Gildenbank und im Postfach als |cFF99CC33[Haustierkäfig]|r mit der ItemID |cFF99CC3382800|r gespeichert. Dies macht es für Addon-Entwickler schwierig, Daten zu bestimmten Kampfhaustieren zu erhalten. Dies zeigt sich auch im Log der Gildenbank, dort werden Kaupfhaustiere als |cFF99CC33[Haustierkäfig]|r angezeigt. Auch beim Verlinken aus der Gildenbank werden sie als |cFF99CC33[Haustierkäfig]|r angezeigt. Um dieses Problem zu umgehen, gibt es zwei Methoden. Die erste Methode besteht darin, das Kampfhaustier einem Tooltip zuzuweisen und dann die SpeciesID von dort zu holen. Dafür muss der Server auf den WoW-Client antworten. Das kann zu massiven Lags führen, insbesondere wenn sich viele Kampfhaustiere in der Gildenbank befinden. Die zweite Methode verwendet die Symboltextur des Kampfhaustiers, um die SpeciesID herauszufinden. Dies ist manchmal ungenau, da manche Kampfhaustiere die gleiche Symboltextur haben. Beispiel: Giftmüllschleimling verwendet die gleiche Symboltextur wie Jadeschlammling. Aktivieren dieser Option erzwingt die Tooltip-Scanmethode für möglichst genaue Ergebnisse, kann aber Lags verursachen. |cFFDF2B2BDaran führt kein Weg vorbei, bis Blizzard uns mehr Daten zum Arbeiten gibt.|r
]]


