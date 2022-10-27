
local L = LibStub("AceLocale-3.0"):NewLocale("BagSync", "frFR")
if not L then return end

--PLEASE LOOK AT enUS.lua for a complete localization list

--Really wish someone would do the french translation

L.Yes = "Oui"
L.No = "Non"
L.TooltipCrossRealmTag = "XR"
L.TooltipBattleNetTag = "BN"
L.TooltipBag = "Sacs :"
L.TooltipBank = "Banque :"
L.TooltipEquip = "Equipé :"
L.TooltipGuild = "Guilde :"
L.TooltipMail = "Courrier :"
L.TooltipReagent = "Composant :"
L.TooltipAuction = "Enchère : "
L.TooltipTotal = "Total :"
L.TooltipItemID = "[ItemID] :"
L.TooltipDebug = "[Debug] :"
L.TooltipCurrencyID = "[CurrencyID] :"
L.TooltipFakeID = "[FakeID] :"
L.TooltipDelimiter = ", "
L.TooltipRealmKey = "RealmKey :"
L.Search = "Rechercher"
L.AdvSearchBtn = "Rechercher/Actualiser"
L.Reset = "Réinitialiser"
L.Refresh = "Actualiser"
L.AdvancedSearch = "Recherche avancée"
L.AdvancedSearchInformation = "* Utilise les paramètres |cffff7d0a[XR]|r and |cff3587ff[BNet]|r de BagSync."
L.AdvancedLocationInformation = "* Selecting none defaults to selecting ALL."
L.AdvancedLocationInformation = "* Ne rien sélectionner revient à TOUT sélectionner."
L.Units = "Personnages :"
L.Locations = "Emplacements :"
L.Profiles = "Profils"
L.Professions = "Métiers"
L.Currency = "Monnaie"
L.Blacklist = "Liste noire"
L.Recipes = "Recettes"
L.Gold = "Or"
L.Close = "Fermer"
L.FixDB = "FixDB"
L.Config = "Config"
L.DeleteWarning = "Sélectionnez un profil à supprimer. REMARQUE : Cette opération est irréversible !"
L.Delete = "Supprimer"
L.Confirm = "Confirmer"
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
L.ItemIDNotFound = "L'ItemID [%s] est introuvable. Essayez encore !"
L.ItemIDNotValid = "L'ItemID [%s] est invalide ou le serveur n'a pas répondu. Essayez encore !"
L.ItemIDRemoved = "L'ItemID [%s] a été supprimé"
L.ItemIDAdded = "L'ItemID [%s] a été ajouté"
L.ItemIDExist = "L'ItemID [%s] est déjà dans la base de données de la liste noire."
L.GuildExist = "La guilde [%s] est déjà dans la base de données de la liste noire."
L.GuildAdded = "La guilde [%s] a été ajoutée"
L.GuildRemoved = "La guilde [%s] a été supprimée"
L.BlackListRemove = "Voulez-vous supprimer [%s] de la liste noire ?"
L.BlackListErrorRemove = "Erreur de suppression de la liste noire."
L.ProfilesRemove = "Voulez-vous supprimer le profil [%s][|cFF99CC33%s|r] de BagSync ?"
L.ProfilesErrorRemove = "Erreur de suppression de BagSync."
L.ProfileBeenRemoved = "Le profil [%s][|cFF99CC33%s|r] a été supprimé de BagSync !"
L.ProfessionsFailedRequest = "[%s] La requête du serveur a échoué."
L.ProfessionHasRecipes = "Clique gauche pour voir les recettes."
L.ProfessionHasNoRecipes = "Aucune recette."
L.KeybindBlacklist = "Afficher la fenêtre de la liste noire."
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
L.SlashResetDB = "resetdb"
------------------------
-- ----THESE USE THE SLASH OPERATOR COMMANDS FOUND ABOVE
L.HelpSearchItemName = "/bgs [itemname] - Effectue une recherche rapide d'un objet"
L.HelpSearchWindow = "/bgs search - Ouvre la fenêtre de recherche"
L.HelpGoldTooltip = "/bgs gold (or /bgs money) - Affiche une infobulle avec la quantité d'or sur chaque personnage."
L.HelpCurrencyWindow = "/bgs currency - Ouvre la fenêtre des monnaies."
L.HelpProfilesWindow = "/bgs profiles - Ouvre la fenêtre des profils."
L.HelpFixDB = "/bgs fixdb - Exécute la correction de la base de données (FixDB) sur BagSync."
L.HelpResetDB = "/bgs resetdb - Réinitialise intégralement la base de données BagSync."
L.HelpConfigWindow = "/bgs config - Ouvre la fenêtre de configuration de BagSync"
L.HelpProfessionsWindow = "/bgs professions - Ouvre la fenêtre des métiers."
L.HelpBlacklistWindow = "/bgs blacklist - Ouvre la fenêtre de la liste noire."
------------------------
L.EnableBagSyncTooltip = "Activer les infobulles de BagSync."
L.EnableExtTooltip = "Afficher les informations sur le nombre d'objets dans une infobulle externe."
L.EnableLoginVersionInfo = "Afficher la version de BagSync lors de la connexion."
L.FocusSearchEditBox = "Focalisation du champ de recherche lors de l'ouverture de la fenêtre de recherche."
L.DisplayTotal = "Afficher le montant [Total]."
L.DisplayGuildGoldInGoldTooltip = "Afficher les totaux d'or de [Guilde] dans l'infobulle de l'or."
L.DisplayGuildBank = "Afficher les objets de la banque de guilde. |cFF99CC33(Active l'analyse de la banque de guilde)|r"
L.DisplayMailbox = "Afficher les objets de la boîte aux lettres."
L.DisplayAuctionHouse = "Afficher les objets de la salle des ventes."
L.DisplayMinimap = "Afficher le bouton de minimap de BagSync."
L.DisplayFaction = "Afficher les objets des deux factions (Alliance/Horde)."
L.DisplayClassColor = "Afficher les couleurs de classes pour les personnages."
L.DisplayTooltipOnlySearch = "Afficher l'infobulle de BagSync |cFF99CC33(UNIQUEMENT)|r dans la fenêtre de recherche."
L.DisplayLineSeperator = "Afficher un séparateur de ligne vide."
L.DisplayCrossRealm = "Afficher les personnages inter-royaumes. |cffff7d0a[XR]|r"
L.DisplayBNET = "Afficher les caractères du compte Battle.Net. |cff3587ff[BNet]|r |cFFDF2B2B(Non recommandé)|r."
L.DisplayItemID = "Afficher l'ItemID de l'objet dans l'infobulle."
L.DisplaySourceDebugInfo = "Affichez des informations utiles [Debug] dans l'infobulle."
L.DisplayTooltipTags = "Étiquettes"
L.DisplayTooltipStorage = "Stockage"
L.DisplayTooltipExtra = "Extra"
L.DisplayTooltipAccountWide = "Account-Wide"
L.DisplayGreenCheck = "Afficher %s à côté du nom du personnage actuel."
L.DisplayRealmIDTags = "Afficher |cffff7d0a[XR]|r et les identifiants de royaume |cff3587ff[BNet]|r."
L.DisplayRealmNames = "Afficher les noms de royaumes."
L.DisplayRealmAstrick = "Afficher [*] à la place des noms de royaumes pour |cffff7d0a[XR]|r et |cff3587ff[BNet]|r."
L.DisplayShortRealmName = "Afficher les noms de royaumes courts pour |cffff7d0a[XR]|r et |cff3587ff[BNet]|r."
L.DisplayFactionIcons = "Afficher les icônes de faction dans l'infobulle."
L.DisplayGuildCurrentCharacter = "Afficher les objets de [Guilde] uniquement pour le personnage actuellement connecté."
L.DisplayGuildBankScanAlert = "Afficher la fenêtre d'alerte d'analyse de la banque de guilde."
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
L.ColorCrossRealm = "Couleur de l'infobulle de [Cross-Realms] de BagSync."
L.ColorBNET = "Couleur de l'infobulle de [Battle.Net] de BagSync."
L.ColorItemID = "Couleur de l'infobulle de [ItemID] de BagSync."
L.ConfigHeader = "Paramètres des différentes fonctions de BagSync."
L.ConfigDisplay = "Affichage"
L.ConfigTooltipHeader = "Paramètres des informations affichées dans l'infobulle de BagSync."
L.ConfigColor = "Couleur"
L.ConfigColorHeader = "Paramètres de couleur pour les informations de l'infobulle de BagSync."
L.ConfigMain = "Principal"
L.ConfigMainHeader = "Paramètres principaux de BagSync."
L.ConfigSearch = "Recherche"
L.ConfigSearchHeader = "Paramètres de la fenêtre de recherche"
L.WarningItemSearch = "ATTENTION : Un total de [|cFFFFFFFF%s|r] objets n'ont pas été recherchés !\n\nBagSync attend toujours la réponse du serveur/cache.\n\nAppuyez sur le bouton Rechercher ou Actualiser."
L.WarningUpdatedDB = "La base de données a été mise à jour dans sa dernière version ! Vous devez analyser à nouveau tous vos personnages !|r"
L.WarningHeader = "Attention !"
L.ConfigFAQ= "FAQ / Aide"
L.ConfigFAQHeader = "Foire aux questions et section d'aide pour BagSync."