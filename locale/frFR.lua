local _, BSYC = ...
local L = BSYC:NewLocale("frFR")
if not L then return end

--PLEASE LOOK AT enUS.lua for a complete localization list

--Special thanks to neun0eil from GitHub for the French Translation

L.Yes = "Oui"
L.No = "Non"
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
L.TooltipItemID = "[ItemID] :"
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
L.Reset = "Réinitialiser"
L.Clear = "Effacer"
L.SearchFilters = "Filtres de recherche"
L.SearchFiltersInformation = "* Utilise les paramètres |cffff7d0a[CR]|r et |cff3587ff[BNet]|r de BagSync."
L.SearchFiltersLocationInformation = "* Ne rien sélectionner revient à TOUT sélectionner."
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
L.SelectAll = "Tout sélectionner"
L.FixDBComplete = "Un FixDB a été effectué sur BagSync ! La base de données est maintenant optimisée !"
L.ResetDBInfo = "BagSync :\nÊtes-vous certain de vouloir réinitialiser la base de données ?\n|cFFDF2B2BNOTE : Ceci est irréversible !\r"
L.ON = "Marche"
L.OFF = "Arrêt"
L.LeftClickSearch = "|cffddff00Clic gauche|r |cff00ff00= Fenêtre de recherche|r"
L.RightClickBagSyncMenu = "|cffddff00Clic droit|r |cff00ff00= Menu de BagSync|r"
L.ProfessionInformation = "|cffddff00Clic gauche|r |cff00ff00sur un métier pour voir les recettes.|r"
L.ErrorUserNotFound = "BagSync : Utilisateur introuvable !"
L.EnterItemID = "Veuillez saisir un ItemID. (Utilisez https://www.wowhead.com/)"
L.AddGuild = "Ajouter une guilde"
L.AddItemID = "Ajouter un ItemID"
L.PleaseRescan = "|cFF778899[Veuillez rescanner]|r"
L.UseFakeID = "Utiliser [FakeID] pour les mascottes au lieu de [ItemID]."
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
L.ProfileBeenRemoved = "Le profil [%s][|cFF99CC33%s|r] a été supprimé de BagSync !"
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
L.ScanGuildBankDone = "Analyse de la banque de guilde terminé !"
L.ScanGuildBankError = "Avertissement : Analyse de la banque de guilde incomplète."
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
L.AlwaysShowSearchFilters = "Toujours afficher la fenêtre des filtres de recherche de Bagsync."
L.DisplayTotal = "Afficher le montant [Total]."
L.DisplayGuildGoldInGoldWindow = "Afficher les totaux d'or de [Guilde] dans l'infobulle de l'or."
L.Display_GSC = "Display |cFFFFD700Gold|r, |cFFC0C0C0Silver|r and |cFFB87333Copper|r in the Gold Window."
L.DisplayMinimap = "Afficher le bouton de minimap de BagSync."
L.EnableAddonCompartment = "Activer l'intégration au Compartiment d'addons de Blizzard."
L.ResetMinimapBtn = "Réinitialiser la position du bouton de la mini-carte."
L.AddonCompartmentReloadMsg = "Les changements du compartiment d’addons nécessitent un rechargement de l’interface. Utilisez /reload pour appliquer."
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
L.DisplayCR = "Afficher les personnages |cffff7d0a[Royaume connecté]|r. |cffff7d0a[CR]|r"
L.DisplayBNET = "Afficher les personnages du compte Battle.Net. |cff3587ff[BNet]|r |cFFDF2B2B(Non recommandé)|r."
L.DisplayItemID = "Afficher l'ItemID de l'objet dans l'infobulle."
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
L.DisplayBankTabs = "Afficher les onglets de banque [1,2,3, etc...] dans l'infobulle."
L.DisplayEquipBagSlots = "Display equipped bag slots <1,2,3, etc...> in tooltip."
L.DisplayRaceIcons = "Affichage des icônes de race des personnages dans l'infobulle."
L.DisplaySingleCharLocs = "Afficher un seul caractère pour les emplacements de stockage."
L.DisplayIconLocs = "Afficher une icône pour les emplacements de stockage."
L.DisplayAccurateBattlePets = "Enable accurate Battle Pets in Guild Bank & Mailbox. |cFFDF2B2B(May cause lag)|r |cff3587ff[See BagSync FAQ]|r"
L.DisplaySortCurrencyByExpansionFirst = "Trier la fenêtre des monnaies BagSync par extension d'abord plutôt qu'alphabétiquement."
L.DisplaySorting = "Tri des infobulles"
L.DisplaySortInfo = "Défaut : les infobulles sont classées par ordre alphabétique, par royaume puis par nom de personnage."
L.SortMode = "Mode de tri"
L.SortMode_RealmCharacter = "Royaume puis personnage (par défaut)"
L.SortMode_Character = "Personnage"
L.SortMode_ClassCharacter = "Classe puis personnage"
L.SortCurrentPlayerOnTop = "Trier par défaut et toujours afficher le personnage actuel en haut."
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
L.ColorCR = "Couleur de l'infobulle de [Royaume connecté] de BagSync."
L.ColorBNET = "Couleur de l'infobulle de [Battle.Net] de BagSync."
L.ColorItemID = "Couleur de l'infobulle de [ItemID] de BagSync."
L.ColorExpansion = "Couleur de l'infobulle de [Extension] de BagSync."
L.ColorItemTypes = "Couleur de l'infobulle de [ItemType] de BagSync."
L.ColorGuildTabs = "Couleur de l'infobulle des onglets de guilde [1,2,3, etc...] de BagSync."
L.ColorWarbandTabs = "Couleur de l'infobulle des onglets du bataillon [1,2,3, etc...] de BagSync."
L.ColorBankTabs = "Couleur de l'infobulle des onglets de banque [1,2,3, etc...] de BagSync."
L.ColorBagSlots = "Bag Slots <1,2,3, etc...> tooltip color."
L.ConfigDisplay = "Affichage"
L.ConfigTooltipHeader = "Paramètres des informations affichées dans l'infobulle de BagSync."
L.ConfigColor = "Couleur"
L.ConfigColorHeader = "Paramètres de couleur pour les informations de l'infobulle de BagSync."
L.ConfigCache = "Cache"
L.ConfigCacheHeader = "Paramètres du cache d’objets et de la limitation pour BagSync."
L.ConfigCacheHowTitle = "Comment Le Cache Fonctionne"
L.ConfigCacheHowText_1 = "Les infos d’objet ne sont pas entièrement disponibles à la connexion. Des API comme |cFFB19CD9GetItemInfo|r ou |cFFB19CD9C_Item.GetItemInfo|r renvoient nil (ou rien) tant que l’objet n’est pas mis en cache pour la session."
L.ConfigCacheHowText_2 = "BagSync demande les données manquantes par petits lots et attend que le client les reçoive (le même flux qui déclenche GET_ITEM_INFO_RECEIVED)."
L.ConfigCacheHowText_3 = "La limitation garde les performances stables pendant que le cache se remplit, afin que recherches et infobulles se complètent progressivement."
L.ConfigCacheRatesTitle = "Débits Actuels"
L.ConfigCacheSpeedTitle = "Vitesse Du Cache"
L.ConfigCacheSpeedLabel = "Limitation"
L.ConfigCacheSpeedHelp = "|cFFB19CD9Lent|r est le défaut et le meilleur pour les performances, mais les recherches prennent plus de temps pour tout mettre en cache.\n|cFFB19CD9Moyen|r est plus rapide, mais peut causer de petits pics à la connexion.\n|cFFB19CD9Rapide|r est le plus intense et peut causer des pics de lag à la connexion.\n|cFFFF4D4DDésactivé|r |cFFFF4D4Dn’est pas recommandé|r (|cFFFFFFFFBagSync utilisera |cFFB19CD9Rapide|r pendant que la fenêtre de recherche est ouverte et pendant les recherches.|r)"
L.CacheSpeedSlow = "Lent (Arrière‑plan + Rampe)"
L.CacheSpeedMedium = "Moyen"
L.CacheSpeedFast = "Rapide"
L.CacheSpeedDisabled = "Désactivé (Pas de cache en arrière‑plan)"
L.CacheSpeedRampIntro = "Le mode Lent augmente toutes les %d secondes."
L.CacheSpeedRampLine = "Étape %d : %d objets toutes les %.2fs (~%d par seconde)."
L.CacheSpeedSingleLine = "%d objets toutes les %.2fs (~%d par seconde)."
L.CacheSpeedDisabledSummary = "Le cache en arrière-plan est désactivé. À l’ouverture de BagSync, Rapide est utilisé, et les recherches sont aussi en Rapide."
L.ConfigMain = "Principal"
L.ConfigMainHeader = "Paramètres principaux de BagSync."
L.ConfigKeybindings = "Raccourcis clavier"
L.ConfigKeybindingsHeader = "Paramètres de raccourci pour les fonctionnalités de BagSync."
L.ConfigExternalTooltip = "Infobulle externe"
L.ConfigFont = "Police"
L.ConfigExtTooltipAnchor = "Position de GameTooltip"
L.ConfigExtTipPositionSettings = "Paramètres de position de l'infobulle externe"
L.ConfigExtTipCustomAnchorEnable = "Activer la position d'ancrage personnalisée"
L.ConfigExtTipCustomAnchorLocation = "Emplacement personnalisé"
L.ConfigExtTipCustomAnchorShow = "Afficher l'ancrage ExtTip"
L.ExtTipCustomAnchor_TopLeft = "Haut gauche"
L.ExtTipCustomAnchor_TopRight = "Haut droite"
L.ExtTipCustomAnchor_BottomLeft = "Bas gauche"
L.ExtTipCustomAnchor_BottomRight = "Bas droite"
L.ExtTipCustomAnchor_Center = "Centre"
L.ExtTipCustomAnchor_CenterTop = "Centre haut"
L.ExtTipCustomAnchor_CenterBottom = "Centre bas"
L.ExtTipCustomAnchor_UseAnchor = "Utiliser l'ancrage ExtTip"
L.ExtTipAnchorLabel = "Ancrage ExtTip de BagSync\\n\\n(Clic droit pour enregistrer la position)"
L.ConfigFontSize = "Taille de la police"
L.ConfigFontOutline = "Outline"
L.ConfigFontOutline_NONE = "Aucun"
L.ConfigFontOutline_OUTLINE = "Outline"
L.ConfigFontOutline_THICKOUTLINE = "ThickOutline"
L.ConfigFontMonochrome = "Monochrome"
L.ExtTooltipAnchor_Bottom = "Bas"
L.ExtTooltipAnchor_Left = "Gauche"
L.ExtTooltipAnchor_Right = "Droite"
L.ExtTipNoticeTitle = "Avis d'infobulle externe (ExtTip)"
L.ExtTipNoticeText = "|cFFFFFFFFLes |cFFFF0000Secret Values|r|cFFFFFFFF de Blizzard peuvent bloquer le positionnement d’ExtTip. BagSync ajoute des protections, mais si aucun tooltip sûr n’est trouvé, les totaux s’affichent dans le |cFFFF0000GameTooltip|r|cFFFFFFFF. Voir la FAQ « |cFFFF0000Secret Values|r|cFFFFFFFF » pour plus d’infos.|r"
L.ConfigTracking = "Tracking"
L.ConfigTrackingHeader = "Tracking settings for all stored BagSync database locations."
L.ConfigTrackingCaution = "Attention"
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
L.TrackingModule_Auction = "Hôtel des ventes"
L.TrackingModule_Guild = "Banque de guilde"
L.TrackingModule_WarbandBank = "Banque du Bataillon (WarBank)"
L.TrackingModule_Professions = "Métiers"
L.TrackingModule_Currency = "Monnaies / Jetons"
L.WarningItemSearch = "ATTENTION : Un total de [|cFFFFFFFF%s|r] objets n'ont pas été recherchés !\n\nBagSync attend toujours la réponse du serveur/cache.\n\nAppuyez sur le bouton Rechercher ou Actualiser."
L.CachingItemData = "Mise en cache des donnees d'objet... (%d restants)"
L.WarningCurrencyUpt = "Erreur lors de la mise à jour des monnaies. Veuillez vous connecter au personnage : "
L.WarningHeader = "Attention !"
L.SavedSearch = "Recherche sauvegardée !"
L.SavedSearch_Add = "Ajouter une recherche"
L.SavedSearch_Warn = "Vous devez saisir quelque chose dans le champ de recherche."
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
	"le",
	"la",
	"les",
	"de",
	"des",
	"du",
	"the",
}
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

|cffff7d0aFiltres de recherche|r (|cFF99CC33commands|r | |cFFFFD580example|r):

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
L.ConfigFAQ= "FAQ / Aide"
L.ConfigFAQHeader = "Foire aux questions et section d'aide pour BagSync."
L.FAQ_Question_1 = "Je subis des saccades/micro-freezes/ralentissements avec les infobulles."
L.FAQ_Question_1_p1 = [[
Ce problème survient généralement lorsqu'il y a des données anciennes ou corrompues dans la base de données, que BagSync ne peut pas interpréter. Il peut aussi se produire lorsqu'il y a une quantité énorme de données à traiter. Si vous avez des milliers d'objets sur plusieurs personnages, cela représente beaucoup d'informations à parcourir en une seconde, ce qui peut provoquer un bref ralentissement du client. Enfin, un ordinateur très ancien peut aussi être à l'origine de ce comportement : les machines plus anciennes subissent des saccades lorsque BagSync traite des milliers d'objets et de données de personnages. Les ordinateurs plus récents, avec des CPU et de la mémoire plus rapides, n'ont généralement pas ce problème.

Pour résoudre ce problème, vous pouvez essayer de réinitialiser la base de données. Cela corrige généralement le souci. Utilisez la commande suivante : |cFF99CC33/bgs resetdb|r
Si cela ne résout pas votre problème, veuillez ouvrir un ticket sur GitHub pour BagSync.
]]
L.FAQ_Question_2 = "Aucune donnée d'objet pour mes autres comptes WoW dans un |cFFDF2B2Bseul|r compte |cff3587ffBattle.net|r."
L.FAQ_Question_2_p1 = [[
Les addons ne peuvent pas lire les données d'autres comptes WoW, car ils ne partagent pas le même dossier SavedVariables. C'est une limitation intégrée au client WoW de Blizzard. Par conséquent, vous ne pourrez pas voir les données d'objets de plusieurs comptes WoW au sein d'un |cFFDF2B2Bseul|r compte |cff3587ffBattle.net|r. BagSync ne peut lire que les données de personnages sur plusieurs royaumes au sein d'un même compte WoW, pas l'ensemble du compte Battle.net.

Il existe un moyen de faire en sorte que plusieurs comptes WoW, au sein d'un |cFFDF2B2Bseul|r compte |cff3587ffBattle.net|r, partagent le même dossier SavedVariables : cela implique de créer des dossiers de type symlink. Je ne fournirai pas d'assistance pour cela, donc ne demandez pas ! Pour plus de détails, consultez le guide suivant : |cFF99CC33https://www.wowhead.com/guide=934|r
]]
L.FAQ_Question_3 = "Peut-on voir les données d'objets de |cFFDF2B2Bplusieurs|r comptes |cff3587ffBattle.net|r ?"
L.FAQ_Question_3_p1 = "Non, ce n'est pas possible. Je ne fournirai pas d'assistance à ce sujet, donc ne demandez pas !"
L.FAQ_Question_4 = "Puis-je voir les données d'objets de plusieurs comptes WoW |cFFDF2B2Bactuellement connectés|r ?"
L.FAQ_Question_4_p1 = "Actuellement, BagSync ne prend pas en charge la transmission de données entre plusieurs comptes WoW connectés simultanément. Cela pourrait changer à l'avenir."
L.FAQ_Question_5 = "Pourquoi ai-je un message indiquant que l'analyse de la banque de guilde est incomplète ?"
L.FAQ_Question_5_p1 = [[
BagSync doit interroger le serveur pour récupérer |cFF99CC33TOUTES|r les informations de votre banque de guilde. Le serveur met du temps à transmettre l'ensemble des données. Pour que BagSync stocke correctement tous vos objets, vous devez attendre la fin de cette requête. Lorsque le scan est terminé, BagSync vous en informera dans le chat. Si vous quittez la fenêtre de banque de guilde avant la fin du scan, des données incorrectes seront enregistrées pour votre banque de guilde.
]]
L.FAQ_Question_6 = "Pourquoi vois-je [FakeID] au lieu de [ItemID] pour les mascottes de combat ?"
L.FAQ_Question_6_p1 = [[
Blizzard n'assigne pas d'ItemID aux mascottes de combat dans WoW. À la place, les mascottes de combat reçoivent un PetID temporaire fourni par le serveur. Ce PetID n'est pas unique et change lors des redémarrages du serveur. Pour pouvoir suivre les mascottes de combat, BagSync génère un FakeID. Un FakeID est construit à partir de nombres statiques associés à la mascotte. L'utilisation d'un FakeID permet à BagSync de suivre les mascottes de combat même après des redémarrages du serveur.
]]
L.FAQ_Question_7 = "Qu'est-ce que l'analyse précise des mascottes de combat dans la banque de guilde et la boîte aux lettres ?"
L.FAQ_Question_7_p1 = [[
Blizzard ne stocke pas les mascottes de combat dans la banque de guilde ou la boîte aux lettres avec un ItemID ou un SpeciesID correct. En réalité, elles sont enregistrées dans la banque de guilde et la boîte aux lettres comme |cFF99CC33[Pet Cage]|r avec un ItemID de |cFF99CC3382800|r. Cela rend la récupération de données sur des mascottes spécifiques difficile pour les auteurs d'addons. Vous pouvez le constater dans les journaux de transactions de la banque de guilde : les mascottes y apparaissent comme |cFF99CC33[Pet Cage]|r. Si vous en liez une depuis la banque de guilde, elle s'affichera également comme |cFF99CC33[Pet Cage]|r.

Pour contourner ce problème, deux méthodes peuvent être utilisées. La première consiste à attribuer la mascotte de combat à une infobulle puis à récupérer le SpeciesID depuis celle-ci. Cela nécessite que le serveur réponde au client WoW et peut entraîner d'importants ralentissements, surtout s'il y a beaucoup de mascottes dans la banque de guilde. La seconde méthode utilise l'iconTexture de la mascotte pour tenter de trouver le SpeciesID. Cela peut parfois être imprécis, car certaines mascottes partagent la même iconTexture. Exemple : Toxic Wasteling partage la même iconTexture que Jade Oozeling. Activer cette option forcera la méthode de scan des infobulles à être aussi précise que possible, mais peut provoquer du lag. |cFFDF2B2BIl n'y a pas de solution parfaite tant que Blizzard ne nous donne pas plus de données à exploiter.|r
]]
L.FAQ_Question_8 = "Erreurs de valeurs secrètes et restrictions des addons Blizzard"
L.FAQ_Question_8_p1 = [[
Le nouveau système de |cFFDF2B2B« valeurs secrètes »|r de Blizzard est conçu pour que les addons puissent |cFF99CC33afficher|r certaines données liées au combat, mais |cFFDF2B2Bne puissent pas les inspecter ni effectuer des calculs dessus en toute sécurité|r. Dans des chemins de code contaminés, les opérations arithmétiques, les comparaisons, et même certains indexages de ces valeurs provoquent immédiatement des erreurs Lua. Ces valeurs peuvent aussi « infecter » des frames et des infobulles via des aspects/ancrages secrets, de sorte que |cFF99CC33la même infobulle|r peut ensuite renvoyer des coordonnées secrètes — même si l'addon qui l'a touchée n'a pas créé la valeur secrète au départ. Cela signifie qu'une trace de pile pointant BagSync ne |cFFDF2B2Bprouve pas|r que BagSync a introduit la valeur secrète ; cela veut souvent juste dire que BagSync a été le prochain addon à toucher l'objet déjà contaminé.

Ce n'est pas un problème propre à BagSync. L'interface Blizzard elle-même renvoie les mêmes erreurs « attempt to perform arithmetic on a secret value » (ex. MoneyFrame / GameTooltip) même sans addons tiers. D'autres addons publient déjà des correctifs d'urgence ou des garde-fous pour la |cFF99CC33même classe d'erreur exacte|r déclenchée par les valeurs secrètes dans les infobulles et money frames. |cFFDF2B2BEn bref : c'est un problème de plateforme, pas un bug unique à BagSync|r.

J'|cFFDF2B2Bai essayé|r d'ajouter autant de protections et de vérifications défensives que possible pour réduire les risques que BagSync déclenche ces erreurs, mais Blizzard a rendu les valeurs secrètes |cFFDF2B2Bincroyablement difficiles à tracer et à contrôler|r dans un environnement multi-addons — par conception. Ce système empêche activement les addons d'inspecter la valeur de façon fiable ou même de confirmer |cFF99CC33où|r elle a pris naissance. C'est précisément pourquoi ces erreurs sont difficiles à reproduire et pourquoi elles n'apparaissent souvent qu'au moment où l'erreur se produit.
]]

L.BagSyncInfoWindow = [[
BagSync, par défaut, n'affiche dans les infobulles que les données des personnages sur les royaumes connectés. ( |cffff7d0a[CR]|r )

Les royaumes connectés ( |cffff7d0a[CR]|r ) sont des serveurs qui ont été liés entre eux.

Pour une liste complète, veuillez consulter :
(|cFF99CC33 https://tinyurl.com/msncc7j6 |r)


|cFFfd5c63BagSync n'affichera PAS, par défaut, les données de l'ensemble de votre compte Battle.Net. Vous devez l'activer !|r
( |cff3587ff[BNet]|r )

|cFF52D386Si vous souhaitez voir tous vos personnages sur l'ensemble de votre compte Battle.net ( |cff3587ff[BNet]|r ), vous devez activer l'option dans la fenêtre de configuration BagSync, sous [Account Wide].|r

L'option s'appelle :
]]
