local _, BSYC = ...
local L = BSYC:NewLocale("esMX")
if not L then return end

L.Yes = "Sí."
L.No = "No"
L.Realm = "Reino:"
L.TooltipCR_Tag = "CR"
L.TooltipBNET_Tag = "BN"
L.Tooltip_bag = "Bolsas"
L.Tooltip_bank = "Banco"
L.Tooltip_equip = "Equipado"
L.Tooltip_guild = "Hermandad"
L.Tooltip_mailbox = "Correo"
L.Tooltip_void = "Vacío"
L.Tooltip_reagents = "Reactivos"
L.Tooltip_auction = "Subasta"
L.Tooltip_warband = "Banda guerrera"
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
L.TooltipItemID = "[ItemID]:"
L.TooltipCurrencyID = "[CurrencyID]:"
L.TooltipFakeID = "[FakeID]:"
L.TooltipExpansion = "[Expansion]:"
L.TooltipItemType = "[ItemTypes]:"
L.TooltipDelimiter = ", "
L.TooltipRealmKey = "ClaveReino:"
L.TooltipDetailsInfo = "Resumen detallado del objeto."
L.DetailsBagID = "ID:"
L.DetailsSlot = "Ranura:"
L.DetailsTab = "Pestaña:"
L.DebugEnable = "Activar depuración"
L.DebugCache = "Desactivar caché"
L.DebugDumpOptions = "Volcar opciones |cff3587ff[DEBUG]|r"
L.DebugIterateUnits = "Iterar unidades |cff3587ff[DEBUG]|r"
L.DebugDBTotals = "Totales de BD |cff3587ff[DEBUG]|r"
L.DebugAddonList = "Lista de addons |cff3587ff[DEBUG]|r"
L.DebugExport = "Exportar"
L.DebugWarning = "|cFFDF2B2BAVISO:|R ¡La depuración de BagSync está activada! |cFFDF2B2B(CAUSARÁ LAG)|r"
L.Search = "Buscar"
L.Debug = "Depuración"
L.Reset = "Restablecer"
L.Clear = "Limpiar"
L.AdvancedSearch = "Búsqueda avanzada"
L.AdvancedSearchInformation = "* Utiliza la configuración BagSync |cffff7d0a[CR]|r y |cff3587ff[BNet]|r."
L.AdvancedLocationInformation = "* Seleccionar ninguno predeterminado para seleccionar TODO."
L.Units = "Unidades:"
L.Locations = "Lugares:"
L.Profiles = "Perfiles"
L.SortOrder = "Ordenar"
L.Professions = "Profesiones"
L.Currency = "Moneda"
L.Blacklist = "Lista negra"
L.Whitelist = "Lista blanca"
L.Recipes = "Recetas"
L.Details = "Detalles"
L.Gold = "Oro"
L.Close = "Cerrar"
L.FixDB = "FixDB"
L.Config = "Configuración"
L.DeleteWarning = "Seleccione un perfil para eliminar. ¡Esto es irreversible!"
L.Delete = "Suprimir"
L.SelectAll = "Seleccione todos"
L.FixDBComplete = "¡Se ha realizado un FixDB en BagSync! ¡La base de datos está optimizada!"
L.ResetDBInfo = "BagSync:\nAre ¿Seguro que quieres restablecer la base de datos? ¡Esto es irreversible! |r"
L.ON = "ACTIVADO"
L.OFF = "DESACTIVADO"
L.LeftClickSearch = "|cffddff00Left Click|r |cff00ff00= Search Window|r"
L.RightClickBagSyncMenu = "|cffddff00Right Click|r |cff00ff00= BagSync Menu|r"
L.ProfessionInformation = "|cffddff00Left Click|r |cff00ff00a Profession to view Recipes.|r"
L.ErrorUserNotFound = "BagSync: ¡No se encuentra el usuario de error!"
L.EnterItemID = "Ingrese un ItemID. (Use http://Wowhead.com/)"
L.AddGuild = "Añadir hermandad"
L.AddItemID = "Añadir ItemID"
L.PleaseRescan = "|cFF778899[Por favor, Rescan]|r"
L.UseFakeID = "Use [FakeID] para Battle Pets en lugar de [ItemID]."
L.ItemIDNotValid = "[%s] ItemID no válido ItemID o el servidor no respondió. ¡Inténtalo de nuevo!"
L.ItemIDRemoved = "[%s] ItemID eliminado"
L.ItemIDAdded = "[%s] ItemID añadido"
L.ItemIDExistBlacklist = "[%s] ItemID ya en la base de datos de lista negra."
L.ItemIDExistWhitelist = "[%s] ItemID ya en la base de datos de lista blanca."
L.GuildExist = "Hermandad [%s] ya está en la base de datos de lista negra."
L.GuildAdded = "Hermandad [%s] añadida"
L.GuildRemoved = "Hermandad [%s] eliminada"
L.BlackListRemove = "Quitar [%s] de la lista negra?"
L.WhiteListRemove = "Quitar [%s] de la lista blanca?"
L.BlackListErrorRemove = "Error eliminando de la lista negra."
L.WhiteListErrorRemove = "Error eliminando de la lista blanca."
L.ProfilesRemove = "Remove [%s][|cFF99CC33%s|r] profile from BagSync?"
L.ProfileBeenRemoved = "[%s][|cFF99CC33%s|r] perfil eliminado de BagSync!"
L.ProfessionHasRecipes = "Haga clic izquierdo para ver recetas."
L.ProfessionHasNoRecipes = "No tiene recetas que ver."
L.KeybindBlacklist = "Mostrar ventana de la lista negra."
L.KeybindWhitelist = "Mostrar ventana blanca."
L.KeybindCurrency = "Mostrar ventana de moneda."
L.KeybindGold = "Mostrar la punta de la herramienta Gold."
L.KeybindProfessions = "Mostrar la ventana Profesiones."
L.KeybindProfiles = "Mostrar la ventana Perfiles."
L.KeybindSearch = "Mostrar ventana de búsqueda."
L.ObsoleteWarning = "\n\nNota: Los elementos obsoletos continuarán mostrando como desaparecidos. Para reparar este problema, escanee sus caracteres de nuevo para eliminar los elementos obsoletos. \n(Bags, Bank, Reagent, Void, etc...)"
L.DatabaseReset = "Debido a los cambios en la base de datos. Su base de datos BagSync ha sido restablecida."
L.UnitDBAuctionReset = "Los datos de autación se han reajustado para todos los caracteres."
L.ScanGuildBankDone = "¡Escaneo del banco de hermandad completado!"
L.ScanGuildBankError = "Advertencia: escaneo del banco de hermandad incompleto."
L.DefaultColors = "Colores predeterminados"
-- ----THESE ARE FOR SLASH COMMANDS OPERATORS
L.SlashItemName = "[nombreobjeto]"
L.SlashSearch = "buscar"
L.SlashGold = "oro"
L.SlashMoney = "dinero"
L.SlashConfig = "config"
L.SlashCurrency = "moneda"
L.SlashFixDB = "fixdb"
L.SlashProfiles = "perfiles"
L.SlashProfessions = "profesiones"
L.SlashBlacklist = "listanegra"
L.SlashWhitelist = "listablanca"
L.SlashResetDB = "resetdb"
L.SlashDebug = "debug"
L.SlashResetPOS = "resetpos"
L.SlashSortOrder = "sortorder"
------------------------
-- ----THESE USE THE SLASH OPERATOR COMMANDS FOUND ABOVE
L.HelpSearchItemName = "Hace una búsqueda rápida de un artículo"
L.HelpSearchWindow = "Abre la ventana de búsqueda"
L.HelpGoldTooltip = "Muestra una punta de herramienta con la cantidad de oro en cada personaje."
L.HelpCurrencyWindow = "Abre la ventana de la moneda."
L.HelpProfilesWindow = "Abre la ventana de perfiles."
L.HelpFixDB = "Ejecuta la configuración de la base de datos (FixDB) en BagSync."
L.HelpResetDB = "Reinicia toda la base de datos BagSync."
L.HelpConfigWindow = "Abre la ventana de Config de BagSync"
L.HelpProfessionsWindow = "Abre la ventana de profesiones."
L.HelpBlacklistWindow = "Abre la ventana de la lista negra."
L.HelpWhitelistWindow = "Abre la ventana de la lista blanca."
L.HelpDebug = "Abre la ventana BagSync Debug."
L.HelpResetPOS = "Reinicie todas las posiciones de marco para cada módulo BagSync."
L.HelpSortOrder = "Orden de orden personalizado para caracteres y gremios."
------------------------
L.EnableBagSyncTooltip = "Activar tooltips de BagSync"
L.ShowOnModifier = "BagSync tooltip modifier key:"
L.ShowOnModifierDesc = "Mostrar BagSync Tooltip en la tecla de modificador."
L.ModValue_NONE = "Ninguno (Siempre Show)"
L.ModValue_ALT = "ALT"
L.ModValue_CTRL = "CTRL"
L.ModValue_SHIFT = "SHIFT"
L.EnableExtTooltip = "Mostrar datos del recuento de elementos en una herramienta externa."
L.EnableLoginVersionInfo = "Mostrar texto de la versión BagSync al iniciar sesión."
L.FocusSearchEditBox = "Enfoque el cuadro de búsqueda al abrir la ventana de búsqueda."
L.AlwaysShowAdvSearch = "Mostrar siempre la ventana de búsqueda avanzada Bagsync."
L.DisplayTotal = "Mostrar [Total] la cantidad."
L.DisplayGuildGoldInGoldWindow = "Mostrar los totales de oro de la [Hermandad] en la ventana de oro."
L.Display_GSC = "Mostrar |cFFFFD700Gold|r, |cFFC0C0C0Silver|r y |cFFB87333Copper|r en la ventana de oro."
L.DisplayMinimap = "Pantalla BagSync minimap botón."
L.DisplayFaction = "Mostrar elementos para ambas facciones (|cff3587ffAlliance|r/|cFFDF2B2BHorde|r)."
L.DisplayClassColor = "Mostrar colores de clase para nombres de personajes."
L.DisplayItemTotalsByClassColor = "Mostrar elementos totales por color de clase de personaje."
L.DisplayTooltipOnlySearch = "Mostrar BagSync tooltip |cFF99CC33(ONLY)|r en la ventana de búsqueda."
L.DisplayTooltipCurrencyData = "Mostrar datos de la herramienta BagSync en la ventana de Moneda Blizzard."
L.DisplayLineSeparator = "Mostrar separador de línea vacía."
L.DisplayCurrentCharacter = "Carácter actual"
L.DisplayCurrentCharacterOnly = "Mostrar datos de punta de herramienta para el personaje actual |cFFFFD700ONLY!|r |cFFDF2B2B(No recomendado)|r"
L.DisplayBlacklistCurrentCharOnly = "Mostrar los recuentos de elementos en la lista negra para el actual chracter |cFFFFD700ONLY!|r |cFFDF2B2B(No recomendado)|r"
L.DisplayCurrentRealmName = "Mostrar el |cFF4CBB17[Current Realm]|r del jugador."
L.DisplayCurrentRealmShortName = "Use un nombre corto para el |cFF4CBB17[Current Realm]|r."
L.DisplayCR = "Mostrar caracteres |cffff7d0a[Connected Realm]|r. |cffff7d0a[CR]|r"
L.DisplayBNET = "Mostrar toda Batalla. Personajes de cuenta neta. |cff3587ff[BNet]|r |cFFDF2B2B(No recomendado)|r"
L.DisplayItemID = "Mostrar ItemID en el campo de herramientas."
L.DisplayWhiteListOnly = "Mostrar los totales del elemento tooltip para artículos enlistadas únicamente."
L.DisplaySourceExpansion = "Ampliación de la fuente de visualización para elementos en el campo de herramientas. |cFF99CC33[Retail Only]|r"
L.DisplayItemTypes = "Mostrar las categorías [Tipo de tema tención Sub Tipo] en el campo de herramientas."
L.DisplayTooltipTags = "Etiquetas"
L.DisplayTooltipStorage = "Almacenamiento"
L.DisplayTooltipExtra = "Extra"
L.DisplaySortOrderHelp = "Ordenar ayuda"
L.DisplaySortOrderStatus = "Ordenar es actualmente: [%s]"
L.DisplayWhitelistHelp = "Whitelist Help"
L.DisplayWhitelistStatus = "Whitelist es actualmente: [%s]"
L.DisplayWhitelistHelpInfo = "Sólo puede introducir números de cómpidos en la base de datos de listas blancas. \n\nPara introducir mascotas de batalla por favor use el FakeID y no el ItemID, puede agarrar el FakeID habilitando la función de punta de herramientas de ItemID en BagSync config. \n\n|cFFDF2B2BEsto NO funcionará para la Ventana de Moneda. |r"
L.DisplayWhitelistHelpInfo2 = "\n\n\n\n|cFFFF7D0AADVERTENCIA: Esta función de lista blanca bloqueará que BagSync cuente |cFFFFFFFF--ALL--|r los objetos, excepto los de esta lista.|r\n|cFF09DBE0¡Es una lista negra inversa!|r"
L.DisplayTooltipAccountWide = "Cuenta completa"
L.DisplayAccountWideTagOpts = "|cFF99CC33Tag Options ( |cffff7d0a[CR]|r &amp; |cff3587ff[BNet]|r )|r"
L.DisplayGreenCheck = "Mostrar %s junto al nombre actual del personaje."
L.DisplayRealmIDTags = "Mostrar |cffff7d0a[CR]|r y |cff3587ff[BNet]|r realm identifiers."
L.DisplayRealmNames = "Mostrar nombres de reino."
L.DisplayRealmAstrick = "Mostrar [*] en lugar de nombres de reino para |cffff7d0a[CR]|r y |cff3587ff[BNet]|r."
L.DisplayShortRealmName = "Mostrar nombres de reino cortos para |cffff7d0a[CR]|r y |cff3587ff[BNet]|r."
L.DisplayFactionIcons = "Mostrar iconos de facción en el campo de herramientas."
L.DisplayGuildBankTabs = "Mostrar fichas bancarias de gremio [1,2,3, etc...] en punta de herramienta."
L.DisplayWarbandBankTabs = "Mostrar fichas de banco de banda de guerra [1,2,3, etc...] en punta de herramientas."
L.DisplayBankTabs = "Mostrar fichas bancarias [1,2,3, etc...] en el campo de herramientas."
L.DisplayEquipBagSlots = "Mostrar las ranuras de bolsas equipadas."
L.DisplayRaceIcons = "Mostrar iconos de raza de caracteres en el campo de herramientas."
L.DisplaySingleCharLocs = "Mostrar un solo personaje para ubicaciones de almacenamiento."
L.DisplayIconLocs = "Mostrar un icono para ubicaciones de almacenamiento."
L.DisplayAccurateBattlePets = "Permite mascotas de batalla precisas en el banco de hermandad y el buzón. |cFFDF2B2B(Puede causar lag)|r |cff3587ff[Ver FAQ de BagSync]|r"
L.DisplaySortCurrencyByExpansionFirst = "Ordenar la ventana de divisas BagSync por expansión primero en lugar de alfabéticamente."
L.DisplaySorting = "Clasificación de las herramientas"
L.DisplaySortInfo = "Predeterminado: Las puntas de la herramienta se ordenan alfabéticamente por Realm entonces Nombre del personaje."
L.SortMode = "Modo tipo"
L.SortMode_RealmCharacter = "Realm entonces Personaje (por defecto)"
L.SortMode_Character = "Cara"
L.SortMode_ClassCharacter = "Clase entonces carácter"
L.SortCurrentPlayerOnTop = "Ordenar por defecto y mostrar siempre el carácter actual en la parte superior."
L.SortTooltipByTotals = "Ordenar por totales y no alfabéticamente."
L.SortByCustomSortOrder = "Ordenar por pedido personalizado."
L.CustomSortInfo = "La lista utiliza un orden ascendente (1,2,3)"
L.CustomSortInfoWarn = "|cFF99CC33NOTE: ¡Usar números solo! Ejemplos: (-1,0,3,4,37,99,-45)|r"
L.DisplayShowUniqueItemsTotals = "La habilitación de esta opción permitirá añadir artículos únicos al recuento total de artículos, independientemente de las estadísticas de los artículos. |cFF99CC33(Recomendado)|r."
L.DisplayShowUniqueItemsTotals_2 = [[
Ciertos artículos como |cffff7d0a[Legendaries]|r pueden compartir el mismo nombre pero tienen diferentes estadísticas. Dado que estos artículos se tratan independientemente unos de otros, a veces no se contabilizan hacia el recuento total de los artículos. Habilitar esta opción hará caso omiso de las estadísticas únicas de los artículos y tratarlos todos iguales, siempre y cuando compartan el mismo nombre del artículo.

Disabling this option will display the item counts independently as item statistics will be taken into consideration. Los totales del artículo sólo mostrarán para cada personaje que comparta el mismo elemento único con las mismas estadísticas exactas. |cFFDF2B2B(No recomendado)|r
]]
L.DisplayShowUniqueItemsTotalsTitle = "Mostrar único elemento Tooltip Totales"
L.DisplayShowUniqueItemsEnableText = "Activar totales de objetos únicos."
L.ColorPrimary = "Color de punta de herramienta de BagSync primario."
L.ColorSecondary = "Bolsa secundariaDe color de punta de herramienta."
L.ColorTotal = "BagSync [Total] color de punta de herramienta."
L.ColorGuild = "Color del tooltip de BagSync [Hermandad]."
L.ColorWarband = "BagSync [Warband] color de las herramientas."
L.ColorCurrentRealm = "BagSync [Current Realm] color de las herramientas."
L.ColorCR = "BagSync [Connected Realm] color de las herramientas."
L.ColorBNET = "BagSync [Battle. Color de punta de herramienta neto."
L.ColorItemID = "BagSync [ItemID] color de las herramientas."
L.ColorExpansion = "BagSync [Expansion] color de las herramientas."
L.ColorItemTypes = "BagSync [ItemType] color de punta de herramienta."
L.ColorGuildTabs = "Color del tooltip de las pestañas de hermandad [1,2,3, etc...]."
L.ColorWarbandTabs = "Tabs Warband [1,2,3, etc...] color de punta de herramientas."
L.ColorBankTabs = "Banca Tabs [1,2,3, etc...] color de punta de herramientas."
L.ColorBagSlots = "Ranuras de bolsa de color = 1,2,3, etc..."
L.ConfigDisplay = "Visualización"
L.ConfigTooltipHeader = "Ajustes para la información de la herramienta BagSync mostrada."
L.ConfigColor = "Color"
L.ConfigColorHeader = "Ajustes de color para la información de la herramienta BagSync."
L.ConfigMain = "Main"
L.ConfigMainHeader = "Ajustes principales de BagSync."
L.ConfigKeybindings = "Keybindings"
L.ConfigKeybindingsHeader = "Ajustes de teclado para características de BagSync."
L.ConfigExternalTooltip = "Herramienta externa"
L.ConfigFont = "Fuente"
L.ConfigFontSize = "Tamaño de la fuente"
L.ConfigFontOutline = "Esquema"
L.ConfigFontOutline_NONE = "Ninguno"
L.ConfigFontOutline_OUTLINE = "Esquema"
L.ConfigFontOutline_THICKOUTLINE = "ThickOutline"
L.ConfigFontMonochrome = "Monocromo"
L.ConfigTracking = "Seguimiento"
L.ConfigTrackingHeader = "Ajustes de seguimiento para todas las bases de datos almacenadas de BagSync."
L.ConfigTrackingCaution = "Precaución"
L.ConfigTrackingModules = "Módulos"
L.ConfigTrackingInfo = [[
|cFFDF2B2BNOTE|r: Disabling a module will cause BagSync to stop tracking and storing the module to the database.

Los módulos discapacitados no se mostrarán en ninguna de las ventanas BagSync, comandos de barras, puntas de herramientas o botón de minimapa.
]]
L.TrackingModule_Bag = "Bolsas"
L.TrackingModule_Bank = "Banco"
L.TrackingModule_Reagents = "Reagent Bank"
L.TrackingModule_Equip = "Artículos equipados"
L.TrackingModule_Mailbox = "Mailbox"
L.TrackingModule_Void = "Void Bank"
L.TrackingModule_Auction = "Auction House"
L.TrackingModule_Guild = "Banco de hermandad"
L.TrackingModule_WarbandBank = "Warband Bank (WarBank)"
L.TrackingModule_Professions = "Profesiones / calificaciones"
L.TrackingModule_Currency = "Curency"
L.WarningItemSearch = "Advertencia: ¡No se registraron un total de [|cFFFFFFFF%s|r] artículos! \n\nBagSync sigue esperando que el servidor/cache responda. \n\nPresionar búsqueda o botón Refresh."
L.WarningCurrencyUpt = "Moneda de actualización de errores. Por favor, ingrese al personaje:"
L.WarningHeader = "¡Atención!"
L.SavedSearch = "Búsqueda guardada"
L.SavedSearch_Add = "Agregar búsqueda"
L.SavedSearch_Warn = "Debe escribir algo en el cuadro de búsqueda."
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
    "el",
    "la",
    "los",
    "las",
    "de",
    "del",
    "the",
}
---------------------------------------
--Localization Note:  Please be advised that the commands for the SearchHelp are english only, however the variables can be any language.  Example: class:<name of class in your locale>
--This includes name searches like name:<name in your locale>
---------------------------------------
L.SearchHelpHeader = "Buscar ayuda"
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
L.ConfigFAQ= "FAQ / Ayuda"
L.ConfigFAQHeader = "Preguntas frecuentes y sección de ayuda para BagSync."
L.FAQ_Question_1 = "Estoy experimentando golpes/estuttering/lagging con herramientas."
L.FAQ_Question_1_p1 = [[
Este problema normalmente ocurre cuando hay datos antiguos o corruptos en la base de datos, que BagSync no puede interpretar. El problema también puede ocurrir cuando hay una cantidad abrumadora de datos para que BagSync pase. Si usted tiene miles de elementos a través de múltiples caracteres, es un montón de datos para pasar dentro de un segundo. Esto puede llevar a su cliente tartamudeando un momento breve. Finalmente, otra causa para este problema es tener un ordenador extremadamente viejo. La computadora más vieja experimentará el acoplamiento/estutter mientras BagSync procesa miles de datos de elementos y caracteres. La computadora más reciente con CPU más rápido y la memoria no suelen tener este problema.

Para solucionar este problema, puede intentar restablecer la base de datos. Esto generalmente resuelve el problema. Utilice el siguiente comando slash. |cFF99CC33/bgs resetdb|r
Si esto no resuelve su problema, por favor envíe un ticket de emisión a GitHub for BagSync.
]]
L.FAQ_Question_2 = "No hay datos de elementos para mis otras cuentas WOW encontradas en una cuenta |cFFDF2B2Bsingle|r |cff3587ffBattle.net|r."
L.FAQ_Question_2_p1 = [[
Addon no tiene la capacidad de leer datos de otras cuentas WOW. Esto es porque no comparten la misma carpeta SavedVariable. Esto es una limitación construida dentro del cliente WOW de Blizzard. Por lo tanto, usted no podrá ver los datos de los elementos para múltiples cuentas WOW bajo un |cFFDF2B2Bsingle|r |cff3587ffBattle.net|r. BagSync sólo podrá leer datos de caracteres en varios reinos dentro de la misma cuenta WOW, no toda la cuenta Battle.net.

Hay una manera de conectar múltiples cuentas WOW, dentro de una cuenta |cFFDF2B2Bsingle|r |cff3587ffBattle.net|r, para que compartan la misma carpeta SavedVariables. Esto implica crear carpetas Symlink. No voy a prestar asistencia en esto. ¡Entonces no preguntes! Por favor visite la siguiente guía para más detalles. |cFF99CC33https://www.wowhead.com/guide=934|r
]]
L.FAQ_Question_3 = "Puede ver los datos del artículo de |cFFDF2B2Bmultiple|r |cff3587ffBattle.net|r ¿Cuentas?"
L.FAQ_Question_3_p1 = "No, no es posible. No voy a prestar asistencia en esto. ¡Entonces no preguntes!"
L.FAQ_Question_4 = "¿Puedo ver los datos del artículo de múltiples cuentas WOW |cFFDF2B2Bcurrently logged in|r?"
L.FAQ_Question_4_p1 = "Actualmente BagSync no admite la transmisión de datos entre múltiples registrados en cuentas WOW. Esto puede cambiar en el futuro."
L.FAQ_Question_5 = "¿Por qué recibo un mensaje de que el escaneo bancario de gremio es incompleto?"
L.FAQ_Question_5_p1 = [[
BagSync tiene que consultar el servidor para |cFF99CC33ALL|r su información bancaria. Se necesita tiempo para que el servidor transmita todos los datos. Para que BagSync pueda almacenar correctamente todos sus artículos, debe esperar hasta que la consulta del servidor esté completa. Cuando el proceso de escaneado esté completo, BagSync te notificará en el chat. Salir de la ventana Guild Bank antes de que se haga el proceso de escaneado, resultará en datos incorrectos que se almacenan para su Guild Bank.
]]
L.FAQ_Question_6 = "¿Por qué veo [FakeID] en lugar de [ItemID] para Battle Pets?"
L.FAQ_Question_6_p1 = [[
Blizzard no asigna a mascotas de combate de ItemID para WOW. En su lugar, Battle Pets en WOW se asigna un PetID temporal del servidor. Este PetID no es único y se cambiará cuando el servidor se reinicia. Para hacer un seguimiento de Battle Pets, BagSync genera un FakeID. Un FakeID se genera a partir de números estáticos asociados con la Batalla Pet. Utilizando un FakeID permite que BagSync rastree Battle Pets incluso a través de restauraciones del servidor.
]]
L.FAQ_Question_7 = "¿Qué es exactamente Battle Pet escaneando en Guild Bank & Mailbox?"
L.FAQ_Question_7_p1 = [[
Blizzard no almacena mascotas de batalla en el Banco de Culto o Mailbox con un ItemID o SpeciesID adecuado. De hecho, Battle Pets se almacenan en el Guild Bank y Mailbox como |cFF99CC33[Pet Cage]|r con un ItemID de |cFF99CC3382800|r. Esto hace difícil el acaparamiento de cualquier dato en relación a las mascotas de batalla específicas para los autores de addon. Usted puede ver por sí mismo en los registros de transacciones del Banco Guild, usted notará que Battle Pets se almacenan como |cFF99CC33[Pet Cage]|r. Si conecta uno de un banco de Guild también se mostrará como |cFF99CC33[Pet Cage]|r. Para superar este problema, hay dos métodos que se pueden utilizar. El primer método es asignar la Batalla Pet a una herramienta y luego agarrar el SpeciesID desde allí. Esto requiere que el servidor responda al cliente de WOW y puede potencialmente llevar a la carga masiva, especialmente si hay un montón de mascotas de batalla en el Banco de Culto. El segundo método utiliza el iconoTexto de la Batalla Pet para tratar de encontrar el SpeciesID. Esto es a veces inexacto como ciertas mascotas de batalla comparten el mismo iconoTextura. Ejemplo: Residuo tóxico comparte el mismo iconoTextura que Jade Oozeling. La habilitación de esta opción obligará al método de escaneo de punta de herramienta a ser lo más preciso posible, pero potencialmente puede causar retraso. |cFFDF2B2BNo hay manera alrededor de esto hasta que Blizzard nos da más datos con los que trabajar. |r
]]
L.BagSyncInfoWindow = [[
BagSync por defecto solo muestra datos de tooltip de caracteres en los reinos conectados. ( |cffff7d0a [CR]|r )

Realms conectados ( |cffff7d0a[CR]|r ) son servidores que se han unido.

Para una lista completa, visite:
(|cFF99CC33 https://tinyurl.com/msncc7j6 |r)


|cFFfd5c63BagSync no mostrará datos de toda su batalla. Cuenta neta por defecto. ¡Necesitarás habilitar esto! |r
( |cff3587ff [BNet]|r )

|cFF52D386Si desea ver todos sus caracteres en toda su cuenta de Battle.net ( |cff3587ff[BNet]|r ), necesita habilitar la opción en la ventana de configuración BagSync bajo [Account Wide]. |r

La opción se etiqueta como:
]]
