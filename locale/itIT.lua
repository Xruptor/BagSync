local _, BSYC = ...
local L = BSYC:NewLocale("itIT")
if not L then return end

L.Yes = "Sì."
L.No = "No."
L.Realm = "Reame:"
L.TooltipCR_Tag = "CR"
L.TooltipBNET_Tag = "BN"
L.Tooltip_bag = "Borse"
L.Tooltip_bank = "Banca"
L.Tooltip_equip = "Equipaggiamento"
L.Tooltip_guild = "Gilda"
L.Tooltip_mailbox = "Posta"
L.Tooltip_void = "Banca del Vuoto"
L.Tooltip_reagents = "Reagenti"
L.Tooltip_auction = "Asta"
L.Tooltip_warband = "Banda di guerra"
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
L.TooltipTotal = "Totale:"
L.TooltipTabs = "T:"
L.TooltipItemID = "[ItemID]:"
L.TooltipCurrencyID = "[CurrencyID]:"
L.TooltipFakeID = "[FakeID]"
L.TooltipExpansion = "[Espansione]:"
L.TooltipItemType = "[Types]:"
L.TooltipDelimiter = ", "
L.TooltipRealmKey = "RealmKey:"
L.TooltipDetailsInfo = "Riepilogo dettagliato dell'oggetto."
L.DetailsBagID = "ID:"
L.DetailsSlot = "Fessura:"
L.DetailsTab = "Scheda:"
L.DebugEnable = "Abilitare Debug"
L.DebugCache = "Disattivare Cache"
L.DebugDumpOptions = "Opzioni di dump |cff3587ff[DEBUG]|r"
L.DebugIterateUnits = "Unità Iterate |cff3587ff[DEBUG]|r"
L.DebugDBTotals = "DB Totale |cff3587ff[DEBUG]|r"
L.DebugAddonList = "Lista Addon |cff3587ff[DEBUG]|r"
L.DebugExport = "Esportazione"
L.DebugWarning = "|cFFDF2B2BATTENZIONE:|r Il debug di BagSync è attualmente abilitato! |cFFDF2B2B (CAUSERÀ LAG)|r"
L.Search = "Ricerca"
L.Debug = "Debug"
L.Reset = "Ripristino"
L.Clear = "Libero"
L.SearchFilters = "Filtri di ricerca"
L.SearchFiltersInformation = "* Utilizza BagSync |cffff7d0a[CR]|r e |cff3587ff[BNet]|r impostazioni."
L.SearchFiltersLocationInformation = "* Selezionando nessuna impostazione predefinita per selezionare TUTTE."
L.Units = "Unità:"
L.Locations = "Località:"
L.Profiles = "Profili"
L.SortOrder = "Ordinare"
L.Professions = "Professioni"
L.Currency = "Valuta"
L.Blacklist = "Lista nera"
L.Whitelist = "Whitelist"
L.Recipes = "Ricette"
L.Details = "Dettagli"
L.Gold = "Oro"
L.Close = "Chiudi"
L.FixDB = "Sistemazione"
L.Config = "Configurazione"
L.DeleteWarning = "Selezionare un profilo da eliminare. NOTA: Questo è irreversibile!"
L.Delete = "Cancella"
L.SelectAll = "Seleziona tutto"
L.FixDBComplete = "Un FixDB è stato eseguito su BagSync! Il database è ora ottimizzato!"
L.ResetDBInfo = "BagSync:\nAre sicuro di voler resettare il database? \n|cFFDF2B2BNOTE: Questo è irreversibile! |r"
L.ON = "ON"
L.OFF = "UFFICIO"
L.LeftClickSearch = "|cffddff00Left Click|r |cff00ff00= Finestra di ricerca|r"
L.RightClickBagSyncMenu = "|cffddff00Right Click|r |cff00ff00= BagSync Menu|r"
L.ProfessionInformation = "|cffddff00Left Click|r |cff00ff00a Professione per vedere le ricette.|r"
L.ErrorUserNotFound = "BagSync: Errore non trovato!"
L.EnterItemID = "Si prega di inserire un ItemID. (Usa http://Wowhead.com/)"
L.AddGuild = "Aggiungi Guild"
L.AddItemID = "Aggiungi articolo"
L.PleaseRescan = "|cFF778899 [Si prega di Rescan]|r"
L.UseFakeID = "Utilizzare [FakeID] per animali da battaglia invece di [ItemID]."
L.ItemIDNotValid = "[%s] ItemID non valido ItemID o il server non ha risposto. Riprova!"
L.ItemIDRemoved = "[%s] ItemID rimosso"
L.ItemIDAdded = "[%s] ItemID aggiunto"
L.ItemIDExistBlacklist = "[%s] ItemID già nel database della lista nera."
L.ItemIDExistWhitelist = "[%s] ItemID già nel database whitelist."
L.GuildExist = "Gilda [%s] già nel database della lista nera."
L.GuildAdded = "Gilda [%s] aggiunta"
L.GuildRemoved = "Gilda [%s] rimossa"
L.BlackListRemove = "Rimuovere [%s] dalla lista nera?"
L.WhiteListRemove = "Rimuovere [%s] dalla lista bianca?"
L.BlackListErrorRemove = "Cancellazione di errore dalla lista nera."
L.WhiteListErrorRemove = "Cancellazione di errore dalla whitelist."
L.ProfilesRemove = "Rimuovere il profilo [%s][|cFF99CC33%s|r] da BagSync?"
L.ProfileBeenRemoved = "[%s][|cFF99CC33%s|r] profilo cancellato da BagSync!"
L.ProfessionHasRecipes = "Clicca a sinistra per visualizzare le ricette."
L.ProfessionHasNoRecipes = "Non ha ricette da vedere."
L.KeybindBlacklist = "Mostra la finestra della lista nera."
L.KeybindWhitelist = "Mostra la finestra della Whitelist."
L.KeybindCurrency = "Mostra la finestra della valuta."
L.KeybindGold = "Mostra il tooltip Gold."
L.KeybindProfessions = "Mostra la finestra Professions."
L.KeybindProfiles = "Mostra profilo finestra."
L.KeybindSearch = "Mostra la finestra di ricerca."
L.ObsoleteWarning = "\n\nNota: Gli oggetti obsoleti continueranno a mostrare come manca. Per riparare questo problema, eseguire nuovamente la scansione dei caratteri al fine di rimuovere gli elementi obsoleti. \n(Borse, Banca, Reagente, Void, ecc...)"
L.DatabaseReset = "A causa delle modifiche del database. Il tuo database BagSync è stato resettato."
L.UnitDBAuctionReset = "I dati di asta sono stati ripristinati per tutti i caratteri."
L.ScanGuildBankDone = "Scansione della banca di gilda completata!"
L.ScanGuildBankError = "Attenzione: scansione della banca di gilda incompleta."
L.DefaultColors = "Colori predefiniti"
-- ----THESE ARE FOR SLASH COMMANDS OPERATORS
L.SlashItemName = "[itmname]"
L.SlashSearch = "ricerca"
L.SlashGold = "oro"
L.SlashMoney = "soldi"
L.SlashConfig = "config"
L.SlashCurrency = "moneta"
L.SlashFixDB = "fixdb"
L.SlashProfiles = "profili"
L.SlashProfessions = "professioni"
L.SlashBlacklist = "listanera"
L.SlashWhitelist = "listabianca"
L.SlashResetDB = "resetdb"
L.SlashDebug = "debug"
L.SlashResetPOS = "resetpos"
L.SlashSortOrder = "sortorder"
------------------------
-- ----THESE USE THE SLASH OPERATOR COMMANDS FOUND ABOVE
L.HelpSearchItemName = "Fa una ricerca rapida per un prodotto"
L.HelpSearchWindow = "Apre la finestra di ricerca"
L.HelpGoldTooltip = "Visualizza una punta di utensili con la quantità di oro su ogni personaggio."
L.HelpCurrencyWindow = "Apri la finestra di valuta."
L.HelpProfilesWindow = "Apri la finestra dei profili."
L.HelpFixDB = "Esegue la correzione del database (FixDB) su BagSync."
L.HelpResetDB = "Reimposta l'intero database BagSync."
L.HelpConfigWindow = "Apre la finestra Config BagSync"
L.HelpProfessionsWindow = "Apre la finestra professioni."
L.HelpBlacklistWindow = "Apri la finestra della lista nera."
L.HelpWhitelistWindow = "Apri la finestra della lista bianca."
L.HelpDebug = "Apre la finestra BagSync Debug."
L.HelpResetPOS = "Reimposta tutte le posizioni del telaio per ogni modulo BagSync."
L.HelpSortOrder = "Ordina per caratteri e corporazioni."
------------------------
L.EnableBagSyncTooltip = "Abilitare BagSync Tooltips"
L.ShowOnModifier = "BagSync tooltip modifier chiave:"
L.ShowOnModifierDesc = "Mostra BagSync Tooltip sulla chiave di modifica."
L.ModValue_NONE = "Nessuno (sempre Mostra)"
L.ModValue_ALT = "ALT"
L.ModValue_CTRL = "CTRL"
L.ModValue_SHIFT = "SHIFT"
L.EnableExtTooltip = "Visualizzare i dati di conteggio dell'elemento in un tooltip esterno."
L.EnableLoginVersionInfo = "Visualizza il testo della versione di BagSync al login."
L.FocusSearchEditBox = "Concentra la casella di ricerca quando si apre la finestra di ricerca."
L.AlwaysShowSearchFilters = "Mostra sempre la finestra dei filtri di ricerca di Bagsync."
L.DisplayTotal = "Visualizzazione [Totale] quantità."
L.DisplayGuildGoldInGoldWindow = "Mostra l'oro totale [Gilda] nella finestra dell'oro."
L.Display_GSC = "Visualizza |cFFFFD700Gold|r, |cFFC0C0C0Silver|r e |cFFB87333Copper|r nella finestra d'oro."
L.DisplayMinimap = "Mostra il pulsante della minimappa di BagSync."
L.DisplayFaction = "Visualizza articoli per entrambe le fazioni (|cff3587ffAlliance|r/|cFFDF2B2BHorde|r)."
L.DisplayClassColor = "Visualizza i colori della classe per i nomi dei personaggi."
L.DisplayItemTotalsByClassColor = "L'elemento di visualizzazione totale per colore di classe di carattere."
L.DisplayTooltipOnlySearch = "Visualizza BagSync tooltip |cFF99CC33 (ONLY)|r nella finestra di ricerca."
L.DisplayTooltipCurrencyData = "Visualizza i dati della tooltip BagSync nella finestra Valuta Blizzard."
L.DisplayLineSeparator = "Visualizza separatore di linea vuoto."
L.DisplayCurrentCharacter = "Carattere attuale"
L.DisplayCurrentCharacterOnly = "Visualizza i dati della tooltip BagSync per il carattere corrente |cFFFFD700ONLY!|r |cFFDF2B2B(Non consigliato)|r"
L.DisplayBlacklistCurrentCharOnly = "Visualizza il conteggio dell'elemento lista nera per l'attuale croato |cFFFFD700ONLY!|r |cFFDF2B2B(Non consigliato)|r"
L.DisplayCurrentRealmName = "Visualizza il |cFF4CBB17[Current Realm]|r del giocatore."
L.DisplayCurrentRealmShortName = "Utilizzare un nome breve per il |cFF4CBB17[Reame corrente]|r."
L.DisplayCR = "Visualizza caratteri |cffff7d0a[Connected Realm]|r. |cffff7d0a[CR]|r"
L.DisplayBNET = "Mostra tutta la battaglia. Personaggi di account netti. |cff3587ff[BNet]|r |cFFDF2B2B(non consigliato)|r"
L.DisplayItemID = "Mostra l'ItemID nel tooltip."
L.DisplayWhiteListOnly = "Visualizzare i totali dell'oggetto tooltip solo per gli articoli whitelist."
L.DisplaySourceExpansion = "Espansione di sorgente di visualizzazione per gli elementi in tooltip. |cFF99CC33[solo per la coda]|r"
L.DisplayItemTypes = "Visualizza le categorie [Tipo di file | Sub Type] in tooltip."
L.DisplayTooltipTags = "Tags"
L.DisplayTooltipStorage = "Stoccaggio"
L.DisplayTooltipExtra = "Extra"
L.DisplaySortOrderHelp = "Ordina aiuto"
L.DisplaySortOrderStatus = "Ordine è attualmente: [%s]"
L.DisplayWhitelistHelp = "Whitelist Aiuto"
L.DisplayWhitelistStatus = "Whitelist è attualmente: [%s]"
L.DisplayWhitelistHelpInfo = "È possibile inserire solo i numeri itemid nel database whitelist. \n\nTo input Battle Animali si prega di utilizzare il FakeID e non il ItemID, è possibile afferrare il FakeID abilitando la funzione di tooltip ItemID in BagSync config. \n\n|cFFDF2B2BQuesto NON funzionerà per la finestra di valuta. |r"
L.DisplayWhitelistHelpInfo2 = "\n\n\n\n|cFFFF7D0AATTENZIONE: Questa funzione whitelist blocca gli oggetti |cFFFFFFFF--ALL--|r dall'essere conteggiati da BagSync, eccetto quelli presenti in questa lista.|r\n|cFF09DBE0È una lista nera inversa!|r"
L.DisplayTooltipAccountWide = "Conto"
L.DisplayAccountWideTagOpts = "Opzioni |cFF99CC33Tag (|cffff7d0a[CR]|r & |cff3587ff[BNet]|r )|r"
L.DisplayGreenCheck = "Visualizza %s accanto al nome del carattere corrente."
L.DisplayRealmIDTags = "Visualizzare |cffff7d0a[CR]|r e |cff3587ff[BNet]|r identificatori reali."
L.DisplayRealmNames = "Visualizza i nomi dei reami."
L.DisplayRealmAstrick = "Visualizzazione [*] invece di nomi di realm per |cffff7d0a[CR]|r e |cff3587ff[BNet]|r."
L.DisplayShortRealmName = "Visualizzazione di nomi brevi realm per |cffff7d0a[CR]|r e |cff3587ff[BNet]|r."
L.DisplayFactionIcons = "Visualizza le icone della fazione nella punta degli strumenti."
L.DisplayGuildBankTabs = "Visualizzare schede bancarie gilda [1,2,3, ecc...] in tooltip."
L.DisplayWarbandBankTabs = "Visualizza le schede bancarie della banda di guerra [1,2,3, ecc...] in tooltip."
L.DisplayBankTabs = "Visualizza le schede bancarie [1,2,3, ecc...] in tooltip."
L.DisplayEquipBagSlots = "Visualizzare le fessure di borsa attrezzate <1,2,3, ecc...> in tooltip."
L.DisplayRaceIcons = "Visualizza le icone di gara dei personaggi in tooltip."
L.DisplaySingleCharLocs = "Visualizzare un singolo personaggio per le posizioni di archiviazione."
L.DisplayIconLocs = "Visualizzare un'icona per le posizioni di archiviazione."
L.DisplayAccurateBattlePets = "Abilita animali da battaglia accurati nella banca di gilda e nella cassetta postale. |cFFDF2B2B(Può causare lag)|r |cff3587ff[Vedi FAQ di BagSync]|r"
L.DisplaySortCurrencyByExpansionFirst = "Ordina la finestra BagSync Valuta per espansione prima piuttosto che in ordine alfabetico."
L.DisplaySorting = "Ordinazione di utensili"
L.DisplaySortInfo = "Default: Tooltips sono ordinati in ordine alfabetico da Realm poi il nome del carattere."
L.SortMode = "Modalità di selezione"
L.SortMode_RealmCharacter = "Realm then Character (default)"
L.SortMode_Character = "Carattere"
L.SortMode_ClassCharacter = "Classe poi Carattere"
L.SortCurrentPlayerOnTop = "Ordina per impostazione predefinita e visualizza sempre il carattere corrente in alto."
L.SortTooltipByTotals = "Ordina per totali e non alfabeticamente."
L.SortByCustomSortOrder = "Ordina per ordine personalizzato."
L.CustomSortInfo = "Elenco utilizza un ordine crescente (1,2,3)"
L.CustomSortInfoWarn = "|cFF99CC33NOTE: Utilizzare solo i numeri! Esempi: (-1,0,3,4,37,99,-45)|r"
L.DisplayShowUniqueItemsTotals = "Attivare questa opzione permetterà di aggiungere elementi unici al conteggio totale dell'elemento, indipendentemente dalle statistiche dell'elemento. |cFF99CC33(Consigliato)|r."
L.DisplayShowUniqueItemsTotals_2 = [[
Alcuni elementi come |cffff7d0a[Legendaries]|r possono condividere lo stesso nome ma hanno statistiche diverse. Poiché questi elementi sono trattati indipendentemente l'uno dall'altro, a volte non sono contati verso il conteggio totale dell'oggetto. Abilitare questa opzione sarà completamente ignorare le statistiche dell'elemento unico e trattarli tutti uguali, fino a quando condividono lo stesso nome dell'elemento.

Disabilitare questa opzione visualizzerà i conti dell'elemento in modo indipendente come le statistiche dell'oggetto saranno prese in considerazione. I totali dell'oggetto saranno visualizzati solo per ogni personaggio che condividono lo stesso elemento unico con le stesse statistiche. |cFFDF2B2B (non consigliato)|r
]]
L.DisplayShowUniqueItemsTotalsTitle = "Mostra unico articolo Tooltip Totals"
L.DisplayShowUniqueItemsEnableText = "Abilitare i totali dell'oggetto unico."
L.ColorPrimary = "Primario BagSync tooltip colore."
L.ColorSecondary = "Secondario BagSync tooltip colore."
L.ColorTotal = "BagSync [Totale] colore punta utensile."
L.ColorGuild = "BagSync [Guild] colore tooltip."
L.ColorWarband = "BagSync [Warband] colore punta utensile."
L.ColorCurrentRealm = "BagSync [Current Realm] colore punta utensile."
L.ColorCR = "BagSync [Connected Realm] colore tooltip."
L.ColorBNET = "BagSync [Battle. Net] colore tooltip."
L.ColorItemID = "BagSync [ItemID] colore tooltip."
L.ColorExpansion = "BagSync [Espansione] colore tooltip."
L.ColorItemTypes = "BagSync [ItemType] colore punta utensile."
L.ColorGuildTabs = "Coltello Tabs [1,2,3, ecc...] colore della punta degli strumenti."
L.ColorWarbandTabs = "Tab della fascia di calore [1,2,3, ecc...] colore della punta degli strumenti."
L.ColorBankTabs = "Tabs della banca [1,2,3, ecc...] colore della punta degli strumenti."
L.ColorBagSlots = "Bag Slot <1,2,3, ecc...> colore della punta dello strumento."
L.ConfigDisplay = "Visualizza"
L.ConfigTooltipHeader = "Impostazioni per le informazioni visualizzate sul tooltip BagSync."
L.ConfigColor = "Colore"
L.ConfigColorHeader = "Impostazioni di colore per le informazioni sul tooltip BagSync."
L.ConfigMain = "Principali"
L.ConfigMainHeader = "Impostazioni principali per BagSync."
L.ConfigKeybindings = "Keybindings"
L.ConfigKeybindingsHeader = "Impostazioni Keybind per funzioni BagSync."
L.ConfigExternalTooltip = "Tavoletta esterna"
L.ConfigFont = "Fonti"
L.ConfigFontSize = "Dimensione del carattere"
L.ConfigFontOutline = "Outline"
L.ConfigFontOutline_NONE = "Nessuno"
L.ConfigFontOutline_OUTLINE = "Outline"
L.ConfigFontOutline_THICKOUTLINE = "Traduzione:"
L.ConfigFontMonochrome = "Monocromatico"
L.ConfigTracking = "Monitoraggio"
L.ConfigTrackingHeader = "Impostazioni di monitoraggio per tutte le posizioni del database BagSync memorizzate."
L.ConfigTrackingCaution = "Attenzione"
L.ConfigTrackingModules = "Moduli"
L.ConfigTrackingInfo = [[
|cFFDF2B2BNOTE|r: Disabilitare un modulo causerà BagSync a smettere di tracciare e memorizzare il modulo nel database.

I moduli disabilitati non verranno visualizzati in nessuna delle finestre BagSync, comandi slash, tooltips o minip pulsante.
]]
L.TrackingModule_Bag = "Borse"
L.TrackingModule_Bank = "Banca"
L.TrackingModule_Reagents = "Reagente bancario"
L.TrackingModule_Equip = "Articoli attrezzati"
L.TrackingModule_Mailbox = "Mailbox"
L.TrackingModule_Void = "Banca Void"
L.TrackingModule_Auction = "Casa d'asta"
L.TrackingModule_Guild = "Banca di gilda"
L.TrackingModule_WarbandBank = "Warband Bank (WarBank)"
L.TrackingModule_Professions = "Professioni / Tradeskills"
L.TrackingModule_Currency = "Curiosità"
L.WarningItemSearch = "ATTENZIONE: Un totale di [|cFFFFFFFF%s|r] elementi non sono stati ricercati! \n\nBagSync sta ancora aspettando che il server/cache risponda. \n\nPress Cerca o Rifiuti pulsante."
L.WarningCurrencyUpt = "Aggiornamento della valuta. Si prega di effettuare il login al carattere:"
L.WarningHeader = "Attenzione!"
L.SavedSearch = "Ricerca salvata"
L.SavedSearch_Add = "Aggiungi ricerca"
L.SavedSearch_Warn = "Devi digitare qualcosa nella casella di ricerca."
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
    "il",
    "lo",
    "la",
    "i",
    "gli",
    "le",
    "di",
    "del",
    "della",
    "dei",
    "degli",
    "delle",
    "the",
}
---------------------------------------
--Localization Note:  Please be advised that the commands for the SearchHelp are english only, however the variables can be any language.  Example: class:<name of class in your locale>
--This includes name searches like name:<name in your locale>
---------------------------------------
L.SearchHelpHeader = "Cerca aiuto"
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
@warband

|cffff7d0aFiltri di ricerca|r (|cFF99CC33commands|r | |cFFFFD580example|r):

|cff00ffff<item name>|r = |cFF99CC33n|r ; |cFF99CC33name|r | |cFFFFD580n:<text>|r ; |cFFFFD580name:<text>|r (n:ore ; name:ore)

|cff00ffff<item bind>|r = |cFF99CC33bind|r | |cFFFFD580bind:<type>|r ; types (boe, bop, bou, boq) i.e boe = bind on equip

|cff00ffff<quality>|r = |cFF99CC33q|r ; |cFF99CC33quality|r | |cFFFFD580q<op><text>|r ; |cFFFFD580q<op><digit>|r (q:rare ; q:>2 ; q:>=3)

|cff00ffff<ilvl>|r = |cFF99CC33l|r ; |cFF99CC33level|r ; |cFF99CC33lvl|r ; |cFF99CC33ilvl|r | |cFFFFD580ilvl<op><number>|r ; |cFFFFD580lvl<op><number>|r (lvl:>5 ; lvl:>=20)

|cff00ffff<required ilvl>|r = |cFF99CC33r|r ; |cFF99CC33req|r ; |cFF99CC33rl|r ; |cFF99CC33reql|r ; |cFF99CC33reqlvl|r | |cFFFFD580req<op><number>|r ; |cFFFFD580req<op><number>|r (req:>5 ; req:>=20)

|cff00ffff<type / slot>|r = |cFF99CC33t|r ; |cFF99CC33type|r ; |cFF99CC33slot|r | |cFFFFD580t:<text>|r (slot:head) ; (t:battlepet or t:petcage) (t:armor) (t:weapon)

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
L.ConfigFAQ= "FAQ / Aiuto"
L.ConfigFAQHeader = "Domande frequenti e assistenza per BagSync."
L.FAQ_Question_1 = "Sto sperimentando hitching/stuttering/lagging con tooltips."
L.FAQ_Question_1_p1 = [[
Questo problema avviene normalmente quando ci sono dati vecchi o corrotti nel database, che BagSync non può interpretare. Il problema può verificarsi anche quando c'è una quantità schiacciante di dati per BagSync di passare attraverso. Se si dispone di migliaia di elementi in più caratteri, è un sacco di dati da passare entro un secondo. Questo può portare al vostro cliente stuttering per un breve momento. Infine, un'altra causa per questo problema sta avendo un computer estremamente vecchio. Il computer più vecchio sperimenterà hitching/stuttering come BagSync elabora migliaia di dati dell'elemento e del carattere. Il computer più recente con CPU più veloce e la memoria di solito non hanno questo problema.

Per risolvere questo problema, è possibile provare a ripristinare il database. Questo di solito risolve il problema. Utilizzare il seguente comando slash. |cFF99CC33/bgs resettatob|r
Se questo non risolve il problema, si prega di presentare un biglietto di emissione su GitHub per BagSync.
]]
L.FAQ_Question_2 = "Nessun dato prodotto per i miei altri account WOW trovato in un account |cFFDF2B2Bsingle|r |cff3587ffBattle.net|r."
L.FAQ_Question_2_p1 = [[
Addon non ha la capacità di leggere i dati da altri account WOW. Questo perché non condividono la stessa cartella SavedVariable. Questa è una limitazione costruita all'interno del client WOW di Blizzard. Pertanto, non sarà in grado di vedere i dati dell'elemento per più account WOW sotto un |cFFDF2B2Bsingle|r |cff3587ffBattle.net|r. BagSync sarà in grado di leggere solo i dati dei personaggi attraverso regni multipli all'interno dello stesso account WOW, non l'intero account Battle.net.

C'è un modo per collegare più account WOW, all'interno di un account |cFFDF2B2Bsingle|r |cff3587ffBattle.net|r, in modo che condividono la stessa cartella SavedVariables. Ciò comporta la creazione di cartelle Symlink. Non fornirò assistenza. Quindi non chiedetelo! Per maggiori dettagli visita la seguente guida. |cFF99CC33https://www.wowhead.com/guide=934|r
]]
L.FAQ_Question_3 = "È possibile visualizzare i dati dell'articolo da |cFFDF2B2Bmultiple|r |cff3587ffBattle.net|r Conti?"
L.FAQ_Question_3_p1 = "No, non e' possibile. Non fornirò assistenza in questo. Quindi non chiedetelo!"
L.FAQ_Question_4 = "Posso visualizzare i dati dell'elemento da più account WOW |cFFDF2B2B attualmente registrati in|r?"
L.FAQ_Question_4_p1 = "Attualmente BagSync non supporta la trasmissione dei dati tra più account WOW registrati. Questo può cambiare in futuro."
L.FAQ_Question_5 = "Perché ricevo un messaggio che la scansione bancaria della gilda è incompleta?"
L.FAQ_Question_5_p1 = [[
BagSync deve query il server per |cFF99CC33ALL|r le informazioni bancarie della gilda. Ci vuole tempo per il server per trasmettere tutti i dati. Affinché BagSync riporti correttamente tutti i tuoi elementi, devi aspettare che la query del server sia completa. Quando il processo di scansione è completo, BagSync ti avviserà in chat. Lasciando la finestra Guild Bank prima che il processo di scansione sia fatto, si tradurrà in dati errati che vengono memorizzati per la vostra Guild Bank.
]]
L.FAQ_Question_6 = "Perché vedo [FakeID] invece di [ItemID] per gli animali da battaglia?"
L.FAQ_Question_6_p1 = [[
Blizzard non assegna a ItemID's a Battle Pets for WOW. Invece, gli animali da battaglia in WOW sono assegnati un PetID temporaneo dal server. Questo PetID non è unico e verrà modificato quando il server si resetta. Per tenere traccia degli animali da battaglia, BagSync genera un FakeID. Un FakeID viene generato da numeri statici associati alla Battle Pet. Utilizzando un FakeID consente a BagSync di monitorare gli animali da battaglia anche attraverso i reset del server.
]]
L.FAQ_Question_7 = "Cos'è la scansione accurata Battle Pet in Guild Bank & Mailbox?"
L.FAQ_Question_7_p1 = [[
Blizzard non memorizza gli animali da battaglia nella Guild Bank o Mailbox con un corretto ItemID o SpeciesID. Infatti, gli animali da battaglia sono memorizzati nella Banca di Gilda e Mailbox come |cFF99CC33[Cage]|r con un ItemID di |cFF99CC3382800|r. Ciò rende difficile afferrare qualsiasi dato in relazione a specifici animali da battaglia per gli autori di addon. Puoi vedere per te nei registri delle transazioni di Guild Bank, noterai che gli animali da battaglia sono memorizzati come |cFF99CC33[Cage]|r. Se si collega uno da un Guild Bank verrà visualizzato anche come |cFF99CC33[Pet Cage]|r. Per ottenere da questo problema, ci sono due metodi che possono essere utilizzati. Il primo metodo sta assegnando il Battle Pet a un tooltip e poi afferrando la SpeciesID da lì. Ciò richiede al server di rispondere al client WOW e può potenzialmente portare a un enorme ritardo, soprattutto se c'è un sacco di animali da battaglia nella Guild Bank. Il secondo metodo utilizza l'iconaTesoro della Battaglia Pet per cercare di trovare la SpeciesID. Questo a volte è impreciso come alcuni animali da battaglia condividono la stessa iconTexture. Esempio: Toxic Wasteling condivide la stessa iconaTexture di Jade Oozeling. Attivare questa opzione costringerà il metodo di scansione tooltip ad essere il più accurato possibile, ma può potenzialmente causare ritardo. |cFFDF2B2BNon c'è modo in giro fino a quando Blizzard ci dà più dati per lavorare con. |r
]]
L.BagSyncInfoWindow = [[
BagSync per impostazione predefinita mostra solo i dati di tooltip da caratteri su regni collegati. (|cffff7d0a[CR]|r )

I Realm collegati (|cffff7d0a[CR]|r ) sono server collegati tra loro.

Per un elenco completo, visitare:
(|cFF99CC33 https://tinyurl.com/msncc7j6 |r)


|cFFfd5c63BagSync NON mostrerà i dati dall'intera battaglia. account Net per impostazione predefinita. Dovrete abilitare questo! |r
(|cff3587ff[BNet]|r )

|cFF52D386If ti piacerebbe vedere tutti i tuoi personaggi attraverso l'intero account Battle.net (|cff3587ff[BNet]|r ), è necessario abilitare l'opzione nella finestra di configurazione BagSync sotto [Account Wide]. |r

L'opzione è etichettata come:
]]
