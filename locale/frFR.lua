local L = LibStub("AceLocale-3.0"):NewLocale("BagSync", "frFR")
if not L then return end

--PLEASE LOOK AT enUS.lua for a complete localization list

--Special thanks to neun0eil from GitHub for the French Translation

L.Yes = "Oui"
L.No = "Non"
L.Page = "Page"
L.Done = "Fait"
L.Realm = "Royaume:"
L.TooltipCR_Tag = "CR"
L.TooltipBNET_Tag = "BN"
L.Tooltip_bag = "Sacs"
L.Tooltip_bank = "Banque"
L.Tooltip_equip = "Equipé"
L.Tooltip_guild = "Guilde"
L.Tooltip_mailbox = "Courrier"
L.Tooltip_void = "Vide"
L.Tooltip_reagents = "Composant"
L.Tooltip_auction = "Enchère"
L.Tooltip_warband = "Bataillon"
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
L.TooltipTabs = "T:"
L.TooltipBagSlot = "S:"
L.TooltipItemID = "[ItemID] :"
L.TooltipDebug = "[Debug] :"
L.TooltipCurrencyID = "[CurrencyID] :"
L.TooltipFakeID = "[FakeID] :"
L.TooltipExpansion = "[Extension]:"
L.TooltipItemType = "[ItemType]:"
L.TooltipDelimiter = ", "
L.TooltipRealmKey = "RealmKey :"
L.TooltipDetailsInfo = "Résumé détaillé de l'objet"
L.DetailsBagID = "Sac:"
L.DetailsSlot = "Emplacement:"
L.DetailsTab = "Tab:"
L.Debug_DEBUG = "DEBUG"
L.Debug_INFO = "INFO"
L.Debug_TRACE = "TRACE"
L.Debug_WARN = "WARN"
L.Debug_FINE = "FINE"
L.Debug_SL1 = "SL1" --sublevel 1
L.Debug_SL2 = "SL2" --sublevel 2
L.Debug_SL3 = "SL3" --sublevel 3
L.DebugEnable = "Activer le Debug"
L.DebugCache = "Désactiver le Cache"
L.DebugDumpOptions = "Options de vidange |cff3587ff[DEBUG]|r"
L.DebugIterateUnits = "Unités itératives |cff3587ff[DEBUG]|r"
L.DebugDBTotals = "DB totale  |cff3587ff[DEBUG]|r"
L.DebugAddonList = "Liste d'addons |cff3587ff[DEBUG]|r"
L.DebugExport = "Export"
L.DebugWarning = "|cFFDF2B2BWARNING:|R BagSync Debug est actuellement activé ! |cFFDF2B2B(PROVOQUE DES LAG)|r"
L.Search = "Rechercher"
L.Debug = "Debug"
L.AdvSearchBtn = "Rechercher/Actualiser"
L.Reset = "Réinitialiser"
L.Refresh = "Actualiser"
L.Clear = "Effacer"
L.AdvancedSearch = "Recherche avancée"
L.AdvancedSearchInformation = "* Utilise les paramètres |cffff7d0a[CR]|r et |cff3587ff[BNet]|r de BagSync."
L.AdvancedLocationInformation = "* Ne rien sélectionner revient à TOUT sélectionner."
L.Units = "Personnages :"
L.Locations = "Emplacements :"
L.Profiles = "Profils"
L.SortOrder = "Ordre de tri"
L.Professions = "Métiers"
L.Currency = "Monnaie"
L.Blacklist = "Liste noire"
L.Whitelist = "Liste blanche"
L.Recipes = "Recettes"
L.Details = "Details"
L.Gold = "Or"
L.Close = "Fermer"
L.FixDB = "FixDB"
L.Config = "Config"
L.DeleteWarning = "Sélectionnez un profil à supprimer. REMARQUE : Cette opération est irréversible !"
L.Delete = "Supprimer"
L.Confirm = "Confirmer"
L.SelectAll = "Tout sélectionner"
L.FixDBComplete = "Un FixDB a été effectué sur BagSync ! La base de données est maintenant optimisée !"
L.ResetDBInfo = "BagSync :\nÊtes-vous certain de vouloir réinitialiser la base de données ?\n|cFFDF2B2BNOTE : Ceci est irréversible !\r"
L.ON = "Marche"
L.OFF = "Arrêt"
L.LeftClickSearch = "|cffddff00Clic gauche|r |cff00ff00= Fenêtre de recherche|r"
L.RightClickBagSyncMenu = "|cffddff00Clic droit|r |cff00ff00= Menu de BagSync|r"
L.ProfessionInformation = "|cffddff00Clic gauche|r |cff00ff00sur un métier pour voir les recettes.|r"
L.ClickViewProfession = "Cliquer pour voir le métier : "
L.ClickHere = "Cliquez ici"
L.ErrorUserNotFound = "BagSync : Utilisateur introuvable !"
L.EnterItemID = "Veuillez saisir un ItemID. (Utilisez https://www.wowhead.com/)"
L.AddGuild = "Ajouter une guilde"
L.AddItemID = "Ajouter un ItemID"
L.RemoveItemID = "Supprimer un ItemID"
L.PleaseRescan = "|cFF778899[Veuillez rescanner]|r"
L.UseFakeID = "Utiliser [FakeID] pour les mascottes au lieu de [ItemID]."
L.ItemIDNotFound = "L'ItemID [%s] est introuvable. Essayez encore !"
L.ItemIDNotValid = "L'ItemID [%s] est invalide ou le serveur n'a pas répondu. Essayez encore !"
L.ItemIDRemoved = "L'ItemID [%s] a été supprimé"
L.ItemIDAdded = "L'ItemID [%s] a été ajouté"
L.ItemIDExistBlacklist = "L'ItemID [%s] est déjà dans la base de données de la liste noire."
L.ItemIDExistWhitelist = "[%s] ItemID déjà dans la base de données de la liste blanche."
L.GuildExist = "La guilde [%s] est déjà dans la base de données de la liste noire."
L.GuildAdded = "La guilde [%s] a été ajoutée"
L.GuildRemoved = "La guilde [%s] a été supprimée"
L.BlackListRemove = "Voulez-vous supprimer [%s] de la liste noire ?"
L.WhiteListRemove = "Voulez-vous supprimer [%s] de la liste blanche ?"
L.BlackListErrorRemove = "Erreur de suppression de la liste noire."
L.WhiteListErrorRemove = "Erreur de suppression de la liste blanche."
L.ProfilesRemove = "Voulez-vous supprimer le profil [%s][|cFF99CC33%s|r] de BagSync ?"
L.ProfilesErrorRemove = "Erreur de suppression de BagSync."
L.ProfileBeenRemoved = "Le profil [%s][|cFF99CC33%s|r] a été supprimé de BagSync !"
L.ProfessionsFailedRequest = "[%s] La requête du serveur a échoué."
L.ProfessionHasRecipes = "Clique gauche pour voir les recettes."
L.ProfessionHasNoRecipes = "Aucune recette."
L.KeybindBlacklist = "Afficher la fenêtre de la liste noire."
L.KeybindWhitelist = "Afficher la fenêtre de la liste blanche."
L.KeybindCurrency = "Afficher la fenêtre des monnaies."
L.KeybindGold = "Afficher la fenêtre de l'or."
L.KeybindProfessions = "Afficher la fenêtre des métiers."
L.KeybindProfiles = "Afficher la fenêtre des profils."
L.KeybindSearch = "Afficher la fenêtre de recherche."
L.ObsoleteWarning = "\n\nRemarque : les objets obsolètes continueront d'apparaître comme manquants. Pour résoudre ce problème, scannez à nouveau vos personnages afin de supprimer les objets obsolètes.\n(Sacs, Banque, Composant, etc...)"
L.DatabaseReset = "En raison de changements dans la base de données. Votre base de données BagSync a été réinitialisée."
L.UnitDBAuctionReset = "Les données d'enchères ont été réinitialisées pour tous les personnages."
L.ScanGuildBankStart = "Demande d'informations sur la banque de guilde au serveur, veuillez patienter..."
L.ScanGuildBankDone = "Analyse de la banque de guilde terminé !"
L.ScanGuildBankError = "Avertissement : Analyse de la banque de guilde incomplète."
L.ScanGuildBankScanInfo = "Analyse de l'onglet de guilde (%s/%s)."
L.DefaultColors = "Couleurs par défaut"
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
L.HelpSearchItemName = "Effectue une recherche rapide d'un objet"
L.HelpSearchWindow = "Ouvre la fenêtre de recherche"
L.HelpGoldTooltip = "Affiche une infobulle avec la quantité d'or sur chaque personnage."
L.HelpCurrencyWindow = "Ouvre la fenêtre des monnaies."
L.HelpProfilesWindow = "Ouvre la fenêtre des profils."
L.HelpFixDB = "Exécute la correction de la base de données (FixDB) sur BagSync."
L.HelpResetDB = "Réinitialise intégralement la base de données BagSync."
L.HelpConfigWindow = "Ouvre la fenêtre de configuration de BagSync"
L.HelpProfessionsWindow = "Ouvre la fenêtre des métiers."
L.HelpBlacklistWindow = "Ouvre la fenêtre de la liste noire."
L.HelpWhitelistWindow = "Ouvre la fenêtre de la liste blanche."
L.HelpDebug = "Ouvre la fenêtre de débogage de BagSync."
L.HelpResetPOS = "Réinitialise toutes les positions de cadre pour chaque module BagSync."
L.HelpSortOrder = "Ordre de tri personnalisé pour les personnages et les guildes."
------------------------
L.EnableBagSyncTooltip = "Activer les infobulles de BagSync."
L.ShowOnModifier = "BagSync tooltip modifier key:"
L.ShowOnModifierDesc = "Show BagSync Tooltip on modifier key."
L.ModValue_NONE = "Jamais (toujours visible)"
L.ModValue_ALT = "ALT"
L.ModValue_CTRL = "CTRL"
L.ModValue_SHIFT = "MAJ"
L.EnableExtTooltip = "Afficher les informations sur le nombre d'objets dans une infobulle externe."
L.EnableLoginVersionInfo = "Afficher la version de BagSync lors de la connexion."
L.FocusSearchEditBox = "Focalisation du champ de recherche lors de l'ouverture de la fenêtre de recherche."
L.AlwaysShowAdvSearch = "Toujours afficher la fenêtre de recherche avancée de Bagsync."
L.DisplayTotal = "Afficher le montant [Total]."
L.DisplayGuildGoldInGoldWindow = "Afficher les totaux d'or de [Guilde] dans l'infobulle de l'or."
L.Display_GSC = "Display |cFFFFD700Gold|r, |cFFC0C0C0Silver|r and |cFFB87333Copper|r in the Gold Window."
L.DisplayMailbox = "Afficher les objets de la boîte aux lettres."
L.DisplayAuctionHouse = "Afficher les objets de la salle des ventes."
L.DisplayMinimap = "Afficher le bouton de minimap de BagSync."
L.DisplayFaction = "Afficher les objets des deux factions (|cff3587ffAlliance|r/|cFFDF2B2BHorde|r)."
L.DisplayClassColor = "Afficher les couleurs de classes pour les personnages."
L.DisplayItemTotalsByClassColor = "Afficher les totaux des objets en fonction de la couleur de la classe du personnage."
L.DisplayTooltipOnlySearch = "Afficher l'infobulle de BagSync |cFF99CC33(UNIQUEMENT)|r dans la fenêtre de recherche."
L.DisplayTooltipCurrencyData = "Display BagSync tooltip data in the Blizzard Currency window."
L.DisplayLineSeparator = "Afficher un séparateur de ligne vide."
L.DisplayCurrentCharacter = "Current Character"
L.DisplayCurrentCharacterOnly = "Display BagSync tooltip data for the current character |cFFFFD700ONLY!|r |cFFDF2B2B(Not Recommended)|r"
L.DisplayBlacklistCurrentCharOnly = "Display blacklisted item counts for the current chraracter |cFFFFD700ONLY!|r |cFFDF2B2B(Not Recommended)|r"
L.DisplayCurrentRealmName = "Display the |cFF4CBB17[Current Realm]|r of the player."
L.DisplayCurrentRealmShortName = "Use a short name for the |cFF4CBB17[Current Realm]|r."
L.DisplayCR = "Afficher les personnages |cffff7d0a[Connected Realm]|r. |cffff7d0a[CR]|r"
L.DisplayBNET = "Afficher les personnages du compte Battle.Net. |cff3587ff[BNet]|r |cFFDF2B2B(Non recommandé)|r."
L.DisplayItemID = "Afficher l'ItemID de l'objet dans l'infobulle."
L.DisplaySourceDebugInfo = "Afficher les informations de [Debug] dans l'infobulle."
L.DisplayWhiteListOnly = "Afficher les totaux des éléments de l'infobulle pour les éléments de la liste blanche uniquement."
L.DisplaySourceExpansion = "Afficher la source de l'extension pour les éléments dans l'infobulle. |cFF99CC33[Live seulement]|r"
L.DisplayItemTypes = "Afficher les catégories [Item Type | Sub Type] dans l'infobulle."
L.DisplayTooltipTags = "Étiquettes"
L.DisplayTooltipStorage = "Stockage"
L.DisplayTooltipExtra = "Extra"
L.DisplaySortOrderHelp = "Aide au tri"
L.DisplaySortOrderStatus = "L'ordre de tri est actuellement : [%s]"
L.DisplayWhitelistHelp = "Aide sur la liste blanche"
L.DisplayWhitelistStatus = "La liste blanche est actuellement : [%s]"
L.DisplayWhitelistHelpInfo = "Vous ne pouvez saisir que des numéros itemid dans la base de données de la liste blanche.. \n\nPour saisir des mascottes, merci d'utiliser FakeID et non ItemID, vous pouvez récupérer le FakeID en activant l'infobulle ItemID dans la configuration de BagSync..\n\n|cFFDF2B2BCela ne fonctionnera pas pour la fenêtre des monnaies.|r"
L.DisplayWhitelistHelpInfo2 = "\n\n\n\n|cFFFF7D0AWARNING: This whitelist feature will block |cFFFFFFFF--ALL--|r items from being counted by BagSync, except those found in this list.|r\n|cFF09DBE0It's a reverse blacklist!|r"
L.DisplayTooltipAccountWide = "Lié au compte"
L.DisplayAccountWideTagOpts = "|cFF99CC33Tag Options ( |cffff7d0a[CR]|r & |cff3587ff[BNet]|r )|r"
L.DisplayGreenCheck = "Afficher %s à côté du nom du personnage actuel."
L.DisplayRealmIDTags = "Afficher |cffff7d0a[CR]|r et les identifiants de royaume |cff3587ff[BNet]|r."
L.DisplayRealmNames = "Afficher les noms de royaumes."
L.DisplayRealmAstrick = "Afficher [*] à la place des noms de royaumes pour |cffff7d0a[CR]|r et |cff3587ff[BNet]|r."
L.DisplayShortRealmName = "Afficher les noms de royaumes courts pour |cffff7d0a[CR]|r et |cff3587ff[BNet]|r."
L.DisplayFactionIcons = "Afficher les icônes de faction dans l'infobulle."
L.DisplayGuildBankTabs = "Afficher [1,2,3, etc...] des onglets de la banque de guilde dans l'infobulle."
L.DisplayWarbandBankTabs = "Afficher [1,2,3, etc...] des onglets de la banque du bataillon dans l'infobulle."
L.DisplayEquipBagSlots = "Display equipped bag slots <1,2,3, etc...> in tooltip."
L.DisplayRaceIcons = "Affichage des icônes de race des personnages dans l'infobulle."
L.DisplaySingleCharLocs = "Afficher un seul caractère pour les emplacements de stockage."
L.DisplayIconLocs = "Afficher une icône pour les emplacements de stockage."
L.DisplayGuildSeparately = "Afficher les noms de [Guilde] et les totaux d'éléments séparément des totaux du personnage."
L.DisplayGuildCurrentCharacter = "Afficher les objets de [Guilde] uniquement pour le personnage actuellement connecté."
L.DisplayGuildBankScanAlert = "Afficher la fenêtre d'alerte d'analyse de la banque de guilde."
L.DisplayAccurateBattlePets = "Enable accurate Battle Pets in Guild Bank & Mailbox. |cFFDF2B2B(May cause lag)|r |cff3587ff[See BagSync FAQ]|r"
L.DisplaySorting = "Tri des infobulles"
L.DisplaySortInfo = "Défaut : les infobulles sont classées par ordre alphabétique, par royaume puis par nom de personnage."
L.SortTooltipByTotals = "Trier par total et non par ordre alphabétique."
L.SortByCustomSortOrder = "Trier par ordre personnalisé."
L.CustomSortInfo = "La liste utilise un ordre croissant (1,2,3)"
L.CustomSortInfoWarn = "|cFF99CC33NOTE: N'utilisez que des chiffres ! (-1,0,3,4)|r"
L.DisplayShowUniqueItemsTotals = "Si vous activez cette option, les objets uniques seront ajoutés au nombre total d'objets, quelles que soient leurs statistiques. |cFF99CC33(Recommandé)|r."
L.DisplayShowUniqueItemsTotals_2 = [[
Certains objets comme les |cffff7d0a[Légendaires]|r peuvent porter le même nom mais avoir des statistiques différentes. Comme ces objets sont traités indépendamment les uns des autres, ils ne sont parfois pas comptabilisés dans le nombre total d'objets. L'activation de cette option permet de ne pas tenir compte des statistiques uniques des objets et de les traiter tous de la même manière, tant qu'ils portent le même nom.

Si vous désactivez cette option, le nombre d'objets s'affichera indépendamment, car les statistiques des objets seront prises en compte. Les totaux des objets ne s'afficheront que pour chaque personnage qui partage le même objet unique avec exactement les mêmes statistiques. |cFFDF2B2B(Not Recommended)|r
]]
L.DisplayShowUniqueItemsTotalsTitle = "Afficher les totaux des objets uniques"
L.DisplayShowUniqueItemsEnableText = "Activer les totaux des objets uniques."
L.ColorPrimary = "Couleur primaire de l'infobulle de BagSync."
L.ColorSecondary = "Couleur secondaire de l'infobulle de BagSync."
L.ColorTotal = "Couleur de l'infobulle de [Total] de BagSync."
L.ColorGuild = "Couleur de l'infobulle de [Guild] de BagSync."
L.ColorWarband = "Couleur de l'infobulle de [Warband] de BagSync."
L.ColorCurrentRealm = "BagSync [Current Realm] tooltip color."
L.ColorCR = "Couleur de l'infobulle de [Connected Realm] de BagSync."
L.ColorBNET = "Couleur de l'infobulle de [Battle.Net] de BagSync."
L.ColorItemID = "Couleur de l'infobulle de [ItemID] de BagSync."
L.ColorExpansion = "Couleur de l'infobulle de [Extension] de BagSync."
L.ColorItemTypes = "Couleur de l'infobulle de [ItemType] de BagSync."
L.ColorGuildTabs = "Couleur de l'infobulle des onglets de guilde [1,2,3, etc...] de BagSync."
L.ColorWarbandTabs = "Couleur de l'infobulle des onglets du bataillon [1,2,3, etc...] de BagSync."
L.ColorBagSlots = "Bag Slots <1,2,3, etc...> tooltip color."
L.ConfigHeader = "Paramètres des différentes fonctions de BagSync."
L.ConfigDisplay = "Affichage"
L.ConfigTooltipHeader = "Paramètres des informations affichées dans l'infobulle de BagSync."
L.ConfigColor = "Couleur"
L.ConfigColorHeader = "Paramètres de couleur pour les informations de l'infobulle de BagSync."
L.ConfigMain = "Principal"
L.ConfigMainHeader = "Paramètres principaux de BagSync."
L.ConfigSearch = "Recherche"
L.ConfigKeybindings = "Raccourcis clavier"
L.ConfigKeybindingsHeader = "Paramètres de raccourci pour les fonctionnalités de BagSync."
L.ConfigExternalTooltip = "Infobulle externe"
L.ConfigSearchHeader = "Paramètres de la fenêtre de recherche"
L.ConfigFont = "Police"
L.ConfigFontSize = "Taille de la police"
L.ConfigFontOutline = "Outline"
L.ConfigFontOutline_NONE = "Aucun"
L.ConfigFontOutline_OUTLINE = "Outline"
L.ConfigFontOutline_THICKOUTLINE = "ThickOutline"
L.ConfigFontMonochrome = "Monochrome"
L.ConfigTracking = "Tracking"
L.ConfigTrackingHeader = "Tracking settings for all stored BagSync database locations."
L.ConfigTrackingCaution = "Caution"
L.ConfigTrackingModules = "Modules"
L.ConfigTrackingInfo = [[
|cFFDF2B2BNOTE|r: La désactivation d'un module entraîne l'arrêt du suivi et du stockage du module dans la base de données par BagSync.

Les modules désactivés ne s'afficheront pas dans les fenêtres BagSync, les commandes slash, les infobulles ou le bouton de la minimap.
]]
L.TrackingModule_Bag = "Sacs"
L.TrackingModule_Bank = "Banque"
L.TrackingModule_Reagents = "Banque de composants"
L.TrackingModule_Equip = "Objets équipés"
L.TrackingModule_Mailbox = "Boite aux lettres"
L.TrackingModule_Void = "Banque du vide"
L.TrackingModule_Auction = "Hôtel des vendes"
L.TrackingModule_Guild = "Banque de guilde"
L.TrackingModule_WarbandBank = "Banque du Bataillon (WarBank)"
L.TrackingModule_Professions = "Métiers"
L.TrackingModule_Currency = "Curency Tokens"
L.WarningItemSearch = "ATTENTION : Un total de [|cFFFFFFFF%s|r] objets n'ont pas été recherchés !\n\nBagSync attend toujours la réponse du serveur/cache.\n\nAppuyez sur le bouton Rechercher ou Actualiser."
L.WarningUpdatedDB = "La base de données a été mise à jour dans sa dernière version ! Vous devez analyser à nouveau tous vos personnages !|r"
L.WarningCurrencyUpt = "Error updating currency.  Please login to character: "
L.WarningHeader = "Attention !"
L.SavedSearch = "Recherche sauvegardée !"
L.SavedSearch_Add = "Ajouter une recherche"
L.SavedSearch_Warn = "Vous devez saisir quelque chose dans le champ de recherche."
---------------------------------------
--Localization Note:  Please be advised that the commands for the SearchHelp are english only, however the variables can be any language.  Example: class:<name of class in your locale>
--This includes name searches like name:<name in your locale>
---------------------------------------
L.SearchHelpHeader = "Aide à la recherche"
L.SearchHelp = [[
|cffff7d0aOptions de recherche|r:
|cFFDF2B2B(NOTE: Toutes les commandes doivent être en ANGLAIS)|r

|cFF99CC33Objet par localisation|r:
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
L.ConfigFAQ= "FAQ / Aide"
L.ConfigFAQHeader = "Foire aux questions et section d'aide pour BagSync."
L.FAQ_Question_1 = "I'm experiencing hitching/stuttering/lagging with tooltips."
L.FAQ_Question_1_p1 = [[
This issue normally happens when there is old or corrupt data in the database, which BagSync cannot interpret.  The problem can also occur when there is overwhelming amount of data for BagSync to go through.  If you have thousands of items across multiple characters, that's a lot of data to go through within a second.  This can lead to your client stuttering for a brief moment.  Finally, another cause for this problem is having an extremely old computer.  Older computer's will experience hitching/stuttering as BagSync processes thousands of item and character data.  Newer computer's with faster CPU's and memory don't typically have this issue.

In order to fix this problem, you can try resetting the database.  This usually resolves the problem.  Use the following slash command. |cFF99CC33/bgs resetdb|r
If this does not resolve your issue, please file an issue ticket on GitHub for BagSync.
]]
L.FAQ_Question_2 = "No item data for my other WOW accounts found in a |cFFDF2B2Bsingle|r |cff3587ffBattle.net|r account."
L.FAQ_Question_2_p1 = [[
Addon's do not have the ability to read data from other WOW accounts.  This is because they don't share the same SavedVariable folder.  This is a built in limitation within Blizzard's WOW Client.  Therefore, you will not be able to see item data for multiple WOW accounts under a |cFFDF2B2Bsingle|r |cff3587ffBattle.net|r.  BagSync will only be able to read character data across multiple realms within the same WOW Account, not the entire Battle.net account.

There is a way to connect multiple WOW Accounts, within a |cFFDF2B2Bsingle|r |cff3587ffBattle.net|r account, so that they share the same SavedVariables folder.  This involves creating Symlink folders.  I will not provide assistance on this.  So don't ask!  Please visit the following guide for more details.  |cFF99CC33https://www.wowhead.com/guide=934|r
]]
L.FAQ_Question_3 = "Can you view item data from |cFFDF2B2Bmultiple|r |cff3587ffBattle.net|r Accounts?"
L.FAQ_Question_3_p1 = "No, it's not possible.  I will not provide assistance in this.  So don't ask!"
L.FAQ_Question_4 = "Can I view item data from multiple WOW accounts |cFFDF2B2Bcurrently logged in|r?"
L.FAQ_Question_4_p1 = "Currently BagSync does not support transmitting data between multiple logged in WOW accounts.  This may change in the future."
L.FAQ_Question_5 = "Why do I get a message that guild bank scanning is incomplete?"
L.FAQ_Question_5_p1 = [[
BagSync has to query the server for |cFF99CC33ALL|r your guild bank information.  It takes time for the server to transmit all the data.  In order for BagSync to properly store all your items, you must wait until the server query is complete.  When the scanning process is complete, BagSync will notify you in chat.  Leaving the Guild Bank window before the scanning process is done, will result in incorrect data being stored for your Guild Bank.
]]
L.FAQ_Question_6 = "Why do I see [FakeID] instead of [ItemID] for Battle Pets?"
L.FAQ_Question_6_p1 = [[
Blizzard does not assign ItemID's to Battle Pets for WOW.  Instead, Battle Pets in WOW are assigned a temporary PetID from the server.  This PetID is not unique and will be changed when the server resets.  In order to keep track of Battle Pets, BagSync generates a FakeID.  A FakeID is generated from static numbers associated with the Battle Pet.  Using a FakeID allows BagSync to track Battle Pets even across server resets.
]]
L.FAQ_Question_7 = "What is accurate Battle Pet scanning in Guild Bank & Mailbox?"
L.FAQ_Question_7_p1 = [[
Blizzard does not store Battle Pets in the Guild Bank or Mailbox with a proper ItemID or SpeciesID.  In fact Battle Pets are stored in the Guild Bank and Mailbox as |cFF99CC33[Pet Cage]|r with an ItemID of |cFF99CC3382800|r.  This makes grabbing any data in regards to specific Battle Pets difficult for addon authors.  You can see for yourself in the Guild Bank transaction logs, you'll notice Battle Pets are stored as |cFF99CC33[Pet Cage]|r.  If you link one from a Guild Bank it will also be displayed as |cFF99CC33[Pet Cage]|r.  In order to get by this problem, there are two methods that can be used.  The first method is assigning the Battle Pet to a tooltip and then grabbing the SpeciesID from there.  This requires the server to respond to the WOW client and can potentially lead to massive lag, especially if there is a lot of Battle Pets in the Guild Bank.  The second method uses the iconTexture of the Battle Pet to try to find the SpeciesID.  This is sometimes inaccurate as certain Battle Pets share the same iconTexture.  Example:  Toxic Wasteling shares the same iconTexture as Jade Oozeling.  Enabling this option will force the tooltip scanning method to be as accurate as possible, but it can potentially cause lag.  |cFFDF2B2BThere is no way around this until Blizzard gives us more data to work with.|r
]]
