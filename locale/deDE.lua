
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
L.Tooltip_warband = "Kriegsmeute"
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
L.TooltipTotal = "Total:"
L.TooltipGuildTabs = "T:"
L.TooltipBagSlot = "S:"
L.TooltipItemID = "[Gegenstands ID]:"
L.TooltipDebug = "[Debug]:"
L.TooltipCurrencyID = "[Währungs ID]:"
L.TooltipFakeID = "[FakeID]:"
L.TooltipExpansion = "[Erweiterung]:"
L.TooltipItemType = "[Gegenstands Typen]:"
L.TooltipDelimiter = ", "
L.TooltipRealmKey = "RealmKey:"
L.TooltipDetailsInfo = "Detaillierte Zusammenfassung des Gegenstands."
L.DetailsBagID = "Tasche:"
L.DetailsSlot = "Slot:"
L.DetailsTab = "Tab:"
L.Debug_DEBUG = "DEBUG"
L.Debug_INFO = "INFO"
L.Debug_TRACE = "PFAD"
L.Debug_WARN = "WARN"
L.Debug_FINE = "GUT"
L.Debug_SL1 = "SL1" --sublevel 1
L.Debug_SL2 = "SL2" --sublevel 2
L.Debug_SL3 = "SL3" --sublevel 3
L.DebugEnable = "Aktiviere Debug"
L.DebugCache = "Deaktiviere Cache"
L.DebugDumpOptions = "Dump Optionen |cff3587ff[DEBUG]|r"
L.DebugIterateUnits = "Einheiten iterieren |cff3587ff[DEBUG]|r"
L.DebugDBTotals = "DB Total |cff3587ff[DEBUG]|r"
L.DebugAddonList = "Addon Liste |cff3587ff[DEBUG]|r"
L.DebugExport = "Exportieren"
L.DebugWarning = "|cFFDF2B2BWARNING:|R BagSync Debug ist derzeit aktiviert! |cFFDF2B2B(WIRD LAGS AUSLÖSEN)|r"
L.Search = "Suche"
L.Debug = "Debug"
L.AdvSearchBtn = "Suche/Aktualisierung"
L.Reset = "Zurücksetzen"
L.Refresh = "Aktualisierung"
L.Clear = "Frei"
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
L.SelectAll = "Alles Auswählen"
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
L.EnterItemID = "Trage bitte eine Gegenstands ID ein. (Benutze wowhead.com)"
L.AddGuild = "Gilde einfügen"
L.AddItemID = "Gegenstands ID Einfügen"
L.RemoveItemID = "Entferne Gegenstands ID"
L.PleaseRescan = "|cFF778899[Please Rescan]|r"
L.UseFakeID = "Verwende [FakeID] für kampfhaustiere statt [Gegenstands ID]."
L.ItemIDNotFound = "[%s] Gegenstands ID nicht gefunden. Versuche es erneut!"
L.ItemIDNotValid = "[%s] Gegenstands ID ungültige Gegenstands ID oder der Server hat nicht geantwortet. Versuche es erneut!"
L.ItemIDRemoved = "[%s] Gegenstands ID entfernt"
L.ItemIDAdded = "[%s] Gegenstands ID hinzugefügt"
L.ItemIDExistBlacklist = "[%s] Gegenstands ID bereits in Blacklist Datenbank."
L.ItemIDExistWhitelist = "[%s] Gegenstands ID bereits in Whitelist Datenbank."
L.GuildExist = "Gilde [%s] bereits in Blacklist Datenbank."
L.GuildAdded = "Gilde [%s] hinzugefügt"
L.GuildRemoved = "Guilde [%s] entfernt"
L.BlackListRemove = "[%s] von der Blacklist entfernen?"
L.WhiteListRemove = "[%s] von der Whitelist entfernen?"
L.BlackListErrorRemove = "Fehler beim Löschen von der Blacklist."
L.WhiteListErrorRemove = "Fehler beim Löschen von der Whitelist."
L.ProfilesRemove = "Entferne [%s][|cFF99CC33%s|r] Profil von BagSync?"
L.ProfilesErrorRemove = "Fehler beim Löschen aus BagSync."
L.ProfileBeenRemoved = "[%s][|cFF99CC33%s|r] Profil entfert von BagSync!"
L.ProfessionsFailedRequest = "[%s] Serveranforderung fehlgeschlagen."
L.ProfessionHasRecipes = "Klicke mit der linken Maustaste, um Rezepte anzuzeigen."
L.ProfessionHasNoRecipes = "Hat keine Rezepte zum Anzeigen."
L.KeybindBlacklist = "Zeige Blacklist Fenster"
L.KeybindWhitelist = "zeige Whitelist Fenster."
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
L.HelpBlacklistWindow = "Öffnet das Blacklist Fenster"
L.HelpWhitelistWindow = "Öffnet das Whitelist Fenster"
L.HelpDebug = "Öffnet das BagSync Debug Fenster."
L.HelpResetPOS = "Setzt alle Fenster Positionen für jedes BagSync Modul zurück."
L.HelpSortOrder = "Benutzerdefinierte Sortierreihenfolge für Charaktere und Gilden."
------------------------
L.EnableBagSyncTooltip = "Aktiviere BagSync Tooltips"
L.ShowOnModifier = "BagSync Tooltip Modifikatortaste:"
L.ShowOnModifierDesc = "BagSync Tooltip auf Modifikatortaste anzeigen."
L.ModValue_NONE = "Nichts (Immer Anzeigen)"
L.ModValue_ALT = "ALT"
L.ModValue_CTRL = "CTRL"
L.ModValue_SHIFT = "SHIFT"
L.EnableExtTooltip = "Zeige Artikelzähldaten in einer externen QuickInfo an"
L.EnableLoginVersionInfo = "BagSync Versionsinfo bei der Anmeldung anzeigen"
L.FocusSearchEditBox = "Suchfeld beim Öffnen des Suchfensters fokussieren"
L.AlwaysShowAdvSearch = "Immer das erweiterte Suchfenster von Bagsync anzeigen."
L.DisplayTotal = "Anzeige des [Gesamt] Betrags."
L.DisplayGuildGoldInGoldWindow = "Zeige [Gilde] Goldsummen im Gold Fenster an"
L.Display_GSC = "zeige |cFFFFD700Gold|r, |cFFC0C0C0Silver|r und |cFFB87333Copper|r in dem Goldfenster."
L.DisplayMailbox = "Postfachgegenstände anzeigen"
L.DisplayAuctionHouse = "Auktionshausgegenstände anzeigen"
L.DisplayMinimap = "BagSync Minikartensymbol anzeigen"
L.DisplayFaction = "Gegenstände für beide Fraktionen anzeigen (|cff3587ffAllianz|r/|cFFDF2B2BHorde|r)"
L.DisplayClassColor = "Klassenfarben für Charaktere anzeigen"
L.DisplayItemTotalsByClassColor = "Gegenstände nach Charakterklassenfarbe anzeigen."
L.DisplayTooltipOnlySearch = "BagSync Tooltip |cFF99CC33(NUR)|r im Suchfenster anzeigen"
L.DisplayTooltipCurrencyData = "Zeige BagSync-Tooltip Daten im Blizzard Währungsfenster an."
L.DisplayLineSeparator = "Aktiviere eine leere Linie als Separator über der BagSync Tooltipanzeige"
L.DisplayCurrentCharacter = "Aktueller Charakter"
L.DisplayCurrentCharacterOnly = "BagSync Tooltip Daten |cFFFFD700NUR!|r für den aktuellen Charakter anzeigen |cFFDF2B2B (Nicht empfohlen)|r"
L.DisplayBlacklistCurrentCharOnly = "Zeigt die Anzahl der auf der schwarzen Liste stehenden Elemente |cFFFFD700NUR!|r für den aktuellen Charakter an |cFFDF2B2B (Nicht empfohlen)|r"
L.DisplayCurrentRealmName = "Zeigt den |cFF4CBB17[Aktuellen Realm]|r des Spielers an."
L.DisplayCurrentRealmShortName = "Verwenden Sie einen Kurznamen für |cFF4CBB17[Aktueller Realm]|r."
L.DisplayCR = "Aktiviere Gegenstände für |cffff7d0a[Verbundener Realm]|r Charaktere.  |cffff7d0a[CR]|r"
L.DisplayBNET = "Aktiviere Battle.net Account Charaktere. |cff3587ff[BNet]|r |cFFDF2B2B(Nicht empfohlen!)|r"
L.DisplayItemID = "Gegenstands ID im Tooltip anzeigen"
L.DisplaySourceDebugInfo = "Zeigt hilfreiche [Debug] Informationen im Tooltip an"
L.DisplayWhiteListOnly = "Gesamtsummen der Tooltip Gegenstände nur für Artikel auf der Whitelist anzeigen."
L.DisplaySourceExpansion = "Erweiterungsquelle für Artikel im Tooltip anzeigen. |cFF99CC33[Nur Retail]|r"
L.DisplayItemTypes = "Zeigt die Kategorien [Gegenstandstyp | Untertyp] im Tooltip an."
L.DisplayTooltipTags = "Tags"
L.DisplayTooltipStorage = "Lagerung"
L.DisplayTooltipExtra = "Extra"
L.DisplaySortOrderHelp = "Hilfe zur Sortierreihenfolge"
L.DisplaySortOrderStatus = "Sortierreihenfolge ist derzeit: [%s]"
L.DisplayWhitelistHelp = "Whitelist Hilfe"
L.DisplayWhitelistStatus = "Whitelist ist derzeit: [%s]"
L.DisplayWhitelistHelpInfo = "Du kannst nur Gegenstands ID Nummern in die Whitelist Datenbank eingeben. \n\nUm Kampfhaustiere einzugeben, verwende bitte die FakeID und nicht die Gegenstands ID. Du kannst die FakeID abrufen, indem Du die Gegenstands ID Tooltip Funktion in der BagSync Konfiguration aktivierst.\n\n|cFFDF2B2BDies wird NICHT für das Währungsfenster funktionieren.|r"
L.DisplayWhitelistHelpInfo2 = "\n\n\n\n|cFFFF7D0AWARNUNG: Diese Whitelist-Funktion blockiert |cFFFFFFFF--ALLE--|r Elemente, die nicht von BagSync gezählt werden, mit Ausnahme derer, die in dieser Liste gefunden werden.|r\n|cFF09DBE0Es ist eine umgekehrte Blacklist!|r"
L.DisplayTooltipAccountWide = "Accountweit"
L.DisplayAccountWideTagOpts = "|cFF99CC33Tag Optionen ( |cffff7d0a[CR]|r & |cff3587ff[BNet]|r )|r"
L.DisplayGreenCheck = "Zeige %s neben dem aktuellen Charakternamen an"
L.DisplayRealmIDTags = "Zeige |cffff7d0a[CR]|r- und |cff3587ff[BNet]|r-Realm ID`s an"
L.DisplayRealmNames = "Realname anzeigen."
L.DisplayRealmAstrick = "Zeige [*] anstelle von Realmnamen für |cffff7d0a[CR]|r und |cff3587ff[BNet]|r an"
L.DisplayShortRealmName = "Kurze Realmnamen für |cffff7d0a[CR]|r und |cff3587ff[BNet]|r anzeigen"
L.DisplayFactionIcons = "Fraktionssymbole im Tooltip anzeigen"
L.DisplayGuildBankTabs = "Gildenbank-Reiter [1,2,3, etc...] im Tooltip anzeigen."
L.DisplayWarbandBankTabs = "Zeigt die Tabs [1, 2, 3 usw.] der Kriegermeuten Bank im Tooltip an."
L.DisplayEquipBagSlots = "Zeigt die ausgerüsteten Taschenplätze <1,2,3, etc.> im Tooltip an."
L.DisplayRaceIcons = "Symbole der Charakterrasse im Tooltip anzeigen."
L.DisplaySingleCharLocs = "Zeige ein einzelnes Zeichen für Speicherorte an."
L.DisplayIconLocs = "Zeige ein Symbol für Speicherorte an."
L.DisplayGuildSeparately = "Zeige [Gilden-]Namen und Gegenstandssummen getrennt von den Charaktersummen an."
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
L.DisplayShowUniqueItemsEnableText = "Aktiviere einzigartige Gegenstandsummen"
L.ColorPrimary = "Primäre BagSync Tooltipfarbe"
L.ColorSecondary = "Sekundäre BagSync Tooltipfarbe"
L.ColorTotal = "BagSync [Total] Tooltipfarbe"
L.ColorGuild = "BagSync [Gilde] Tooltipfarbe"
L.ColorWarband = "BagSync [Kriegsmeuten] Tooltipfarbe."
L.ColorCurrentRealm = "BagSync [Aktueller Realm] Tooltipfarbe."
L.ColorCR = "BagSync [Verbundener Realm] Tooltipfarbe"
L.ColorBNET = "BagSync [Battle.Net] Tooltipfarbe"
L.ColorItemID = "BagSync [GegenstandsID] Tooltipfarbe"
L.ColorExpansion = "BagSync [Erweiterungen] Tooltipfarbe."
L.ColorItemTypes = "BagSync [Gegenstandstyp] Tooltipfarbe."
L.ColorGuildTabs = "Gilden Tabs [1,2,3, etc...] Tooltipfarbe."
L.ColorWarbandTabs = "Kriegsmeuten Tabs [1,2,3, etc...] Tooltipfarbe."
L.ColorBagSlots = "Taschen Slots <1,2,3, etc...> Tooltipfarbe."
L.ConfigHeader = "Einstellungen für verschiedene BagSync Funktionen."
L.ConfigDisplay = "Anzeige"
L.ConfigTooltipHeader = "Einstellungen für die angezeigten BagSync Tooltip Informationen."
L.ConfigColor = "Farbe"
L.ConfigColorHeader = "Farbeinstellungen für BagSync Tooltip Informationen"
L.ConfigMain = "Hauptkonfig"
L.ConfigMainHeader = "Haupteinstellungen von BagSync"
L.ConfigSearch = "Suche"
L.ConfigKeybindings = "Keybindings"
L.ConfigKeybindingsHeader = "Tastenbelegungseinstellungen für BagSync Funktionen."
L.ConfigExternalTooltip = "Externer Tooltip"
L.ConfigSearchHeader = "Einstellungen für das Suchfenster"
L.ConfigFont = "Schriftart"
L.ConfigFontSize = "Schriftart Größe"
L.ConfigFontOutline = "Outline"
L.ConfigFontOutline_NONE = "Nichts"
L.ConfigFontOutline_OUTLINE = "Outline"
L.ConfigFontOutline_THICKOUTLINE = "ThickOutline"
L.ConfigFontMonochrome = "Monochrome"
L.ConfigTracking = "Verfolgung"
L.ConfigTrackingHeader = "Verfolgungs Einstellungen für alle gespeicherten BagSync Datenbankstandorte."
L.ConfigTrackingCaution = "Achtung"
L.ConfigTrackingModules = "Module"
L.ConfigTrackingInfo = [[
|cFFDF2B2BNOTE|r: Wenn Du ein Modul deaktivierst, beendet BagSync die Verfolgung und Speicherung des Moduls in der Datenbank.

Deaktivierte Module werden in keinem der BagSync-Fenster, Schrägstrichbefehle, Tooltips oder Minikartenschaltflächen angezeigt.
]]
L.TrackingModule_Bag = "Taschen"
L.TrackingModule_Bank = "Bank"
L.TrackingModule_Reagents = "Reagenzienbank"
L.TrackingModule_Equip = "Ausgerüstete Gegenstände"
L.TrackingModule_Mailbox = "Mailbox"
L.TrackingModule_Void = "Leerenlager"
L.TrackingModule_Auction = "Auktionshaus"
L.TrackingModule_Guild = "Gildenbank"
L.TrackingModule_WarbandBank = "Kriegsmeuten Bank (WarBank)"
L.TrackingModule_Professions = "Berufe- / Handelsfertigkeiten"
L.TrackingModule_Currency = "Währungs Tokens"
L.WarningItemSearch = "WARNUNG: Insgesamt [|cFFFFFFFF%s|r] Elemente wurden nicht durchsucht!\n\nBagSync wartet immer noch auf die Antwort des Servers/Cache.\n\nDrücke die Schaltfläche Suchen oder Aktualisieren."
L.WarningUpdatedDB = "Du wurdest auf die neueste Datenbankversion aktualisiert! Du musst alle Deine Charaktere erneut scannen!|r"
L.WarningCurrencyUpt = "Fehler beim Aktualisieren der Währung. Bitte melde Dich mit dem Charakter an: "
L.WarningHeader = "Warnung!"
L.SavedSearch = "Gespeicherte Suche"
L.SavedSearch_Add = "Suche hinzufügen"
L.SavedSearch_Warn = "Du mußt etwas in das Suchfeld eingeben."
---------------------------------------
--Localization Note:  Please be advised that the commands for the SearchHelp are english only, however the variables can be any language.  Example: class:<name of class in your locale>
--This includes name searches like name:<name in your locale>
---------------------------------------
L.SearchHelpHeader = "Suchhilfe"
L.SearchHelp = [[
|cffff7d0aSuchoptionen|r:
|cFFDF2B2B(HINWEIS: Alle Befehle sind nur auf Englisch!)|r

|cFF99CC33Charakterelemente nach Standort|r:
@bag
@bank
@reagents
@equip
@mailbox
@void
@auction
@guild
@warband

|cffff7d0aAdvanced Search|r (|cFF99CC33commands|r | |cFFFFD580example|r):

|cff00ffff<item name>|r = |cFF99CC33n|r ; |cFF99CC33name|r | |cFFFFD580n:<text>|r ; |cFFFFD580name:<text>|r (n:ore ; name:ore)

|cff00ffff<item bind>|r = |cFF99CC33bind|r | |cFFFFD580bind:<type>|r ; types (boe, bop, bou, boq) i.e boe = bind on equip

|cff00ffff<quality>|r = |cFF99CC33q|r ; |cFF99CC33quality|r | |cFFFFD580q<op><text>|r ; |cFFFFD580q<op><digit>|r (q:rare ; q:>2 ; q:>=3)

|cff00ffff<ilvl>|r = |cFF99CC33l|r ; |cFF99CC33level|r ; |cFF99CC33lvl|r ; |cFF99CC33ilvl|r | |cFFFFD580ilvl<op><number>|r ; |cFFFFD580lvl<op><number>|r (lvl:>5 ; lvl:>=20)

|cff00ffff<required ilvl>|r = |cFF99CC33r|r ; |cFF99CC33req|r ; |cFF99CC33rl|r ; |cFF99CC33reql|r ; |cFF99CC33reqlvl|r | |cFFFFD580req<op><number>|r ; |cFFFFD580req<op><number>|r (req:>5 ; req:>=20)

|cff00ffff<type / slot>|r = |cFF99CC33t|r ; |cFF99CC33type|r ; |cFF99CC33slot|r | |cFFFFD580t:<text>|r (slot:head) ; (t:battlepet or t:petcage) (t:armor) (t:weapon)

|cff00ffff<tooltip>|r = |cFF99CC33tt|r ; |cFF99CC33tip|r ; |cFF99CC33tooltip|r | |cFFFFD580tt:<text>|r (tt:summon)

|cff00ffff<item set>|r = |cFF99CC33s|r ; |cFF99CC33set|r | |cFFFFD580s:<setname>|r (setname can be * for all sets)

|cff00ffff<expansion>|r = |cFF99CC33x|r ; |cFF99CC33xpac|r ; |cFF99CC33expansion|r | |cFFFFD580x:<expacID>|r ; |cFFFFD580x:<expansion name>|r ; |cFFFFD580xpac:<expansion name>|r (xpac:shadow)

|cff00ffff<keyword>|r = |cFF99CC33k|r ; |cFF99CC33key|r ; |cFF99CC33keyword|r | |cFFFFD580k:<keyword>|r (key:quest) (keywords: soulbound, bound, boe, bop, bou, boa, quest, unique, toy, reagent, crafting, naval, follower, follow, power, apperance)

|cff00ffff<class>|r = |cFF99CC33c|r ; |cFF99CC33class|r | |cFFFFD580c:<classname>|r ; |cFFFFD580class:<classname>|r (class:shaman)

|cffff7d0aOperators <op>|r:
|cFF99CC33:|r | |cFF99CC33=|r | |cFF99CC33==|r | |cFF99CC33!=|r | |cFF99CC33~=|r | |cFF99CC33<|r | |cFF99CC33>|r | |cFF99CC33<=|r | |cFF99CC33>=|r


|cffff7d0aBefehle Negieren|r:
Beispiel: |cFF99CC33!|r|cFFFFD580bind:boe|r (Kein BoE)
Beispiel: |cFF99CC33!|r|cFFFFD580bind:boe|r |cFF99CC33&&|r |cFFFFD580lvl:>20|r (kein BoE und Gegenstandsstufe größer als 20)

|cffff7d0aUnion-Suchen (und Suchvorgänge):|r
(Verwenden Sie das doppelte Und |cFF99CC33&&|r symbol)
Beispiel: |cFFFFD580bind:boe|r |cFF99CC33&&|r |cFFFFD580lvl:>20|r

|cffff7d0aSuchen (oder Suchvorgänge) überschneiden:|r
(Use the double pipe |cFF99CC33|||||r symbol)
Beispiel: |cFFFFD580bind:boe|r |cFF99CC33|||||r |cFFFFD580lvl:>20|r

|cffff7d0aKomplexes Suchbeispiel:|r
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


