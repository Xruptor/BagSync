local _, BSYC = ...
local L = BSYC:NewLocale("ptBR")
if not L then return end

L.Yes = "Sim."
L.No = "Não"
L.Realm = "Reino:"
L.TooltipCR_Tag = "CR"
L.TooltipBNET_Tag = "BN"
L.Tooltip_bag = "Sacos"
L.Tooltip_bank = "Banco"
L.Tooltip_equip = "Equipado"
L.Tooltip_guild = "Guilda"
L.Tooltip_mailbox = "Correio"
L.Tooltip_void = "Vazio"
L.Tooltip_reagents = "Reagentes"
L.Tooltip_auction = "Leilão"
L.Tooltip_warband = "Banda de guerra"
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
L.TooltipItemID = "[Itemid]:"
L.TooltipCurrencyID = "[MoedaID]:"
L.TooltipFakeID = "[FakeID]:"
L.TooltipExpansion = "[Expansão]:"
L.TooltipItemType = "[ItemTipos]:"
L.TooltipDelimiter = ", "
L.TooltipRealmKey = "RealmKey:"
L.TooltipDetailsInfo = "Ponto resumo detalhado."
L.DetailsBagID = "ID:"
L.DetailsSlot = "Fenda:"
L.DetailsTab = "Página:"
L.DebugEnable = "Habilitar depuração"
L.DebugCache = "Desactivar a 'Cache'"
L.DebugDumpOptions = "Opções de dumping |cff3587ff[DEBUG]|r"
L.DebugIterateUnits = "Unidades Iteradas |cff3587ff[DEBUG]|r"
L.DebugDBTotals = "DB Total |cff3587ff[DEBUG]|r"
L.DebugAddonList = "Lista de anexos |cff3587ff[DEBUG]|r"
L.DebugExport = "Exportar"
L.DebugWarning = "|cFFDF2B2BAVISO:|R A depuração do BagSync está ativada! |cFFDF2B2B(VAI CAUSAR LAG)|r"
L.Search = "Pesquisar"
L.Debug = "Depurar"
L.Reset = "Reiniciar"
L.Clear = "Limpar"
L.AdvancedSearch = "Pesquisa Avançada"
L.AdvancedSearchInformation = "* Usa as configurações BagSync |cffff7d0a[CR]|r e |cff3587ff[BNet]|r."
L.AdvancedLocationInformation = "* Selecionar nenhum padrão para selecionar ALL."
L.Units = "Unidades:"
L.Locations = "Locais:"
L.Profiles = "Perfis"
L.SortOrder = "Ordenar Ordem"
L.Professions = "Profissãos"
L.Currency = "Moeda"
L.Blacklist = "Lista Negra"
L.Whitelist = "Lista Branca"
L.Recipes = "Receitas"
L.Details = "Detalhes"
L.Gold = "Ouro"
L.Close = "Fechar"
L.FixDB = "FixDB"
L.Config = "Configuração"
L.DeleteWarning = "Selecione um perfil para excluir. NOTA: Isto é irreversível!"
L.Delete = "Apagar"
L.SelectAll = "Seleccionar Tudo"
L.FixDBComplete = "Um FixDB foi realizado no BagSync! O banco de dados agora está otimizado!"
L.ResetDBInfo = "BagSync:\nTem certeza de que deseja redefinir o banco de dados? Isto é irreversível! |r"
L.ON = "ON"
L.OFF = "OFF"
L.LeftClickSearch = "|cffddff00Eft Click|r |cff00ff00= Search Window|r"
L.RightClickBagSyncMenu = "|cffddff00Right Click|r |cff00ff00= BagSync Menu|r"
L.ProfessionInformation = "|cffddff00Esquerdo Click|r |cff00ff00a Profissão para ver Receitas.|r"
L.ErrorUserNotFound = "BagSync: Usuário de erro não encontrado!"
L.EnterItemID = "Digite um ItemID. (Use http://Wowhead.com/)"
L.AddGuild = "Adicionar Guilda"
L.AddItemID = "Adicionar ItemID"
L.PleaseRescan = "|cFF778899[Por favor, refaça]|r"
L.UseFakeID = "Use [FakeID] para Battle Pets em vez de [ItemID]."
L.ItemIDNotValid = "[%s] ItemID não válido ItemID ou o servidor não respondeu. Tenta outra vez!"
L.ItemIDRemoved = "[%s] ItemID removido"
L.ItemIDAdded = "[%s] ItemID Adicionado"
L.ItemIDExistBlacklist = "[%s] ItemID já está na base de dados da lista negra."
L.ItemIDExistWhitelist = "[%s] ItemID já está na base de dados da lista branca."
L.GuildExist = "Guilda [%s] já está na base de dados da lista negra."
L.GuildAdded = "Guilda [%s] Adicionada"
L.GuildRemoved = "Guilda [%s] Removida"
L.BlackListRemove = "Remover [%s] da lista negra?"
L.WhiteListRemove = "Remover [%s] da lista branca?"
L.BlackListErrorRemove = "Erro ao apagar da lista negra."
L.WhiteListErrorRemove = "Erro ao excluir da lista branca."
L.ProfilesRemove = "Remover o perfil [%s] do BagSync?"
L.ProfileBeenRemoved = "[%s] [|cFF99CC33%s|r] perfil excluído do BagSync!"
L.ProfessionHasRecipes = "Clique com o botão esquerdo para ver as receitas."
L.ProfessionHasNoRecipes = "Não tem receitas para ver."
L.KeybindBlacklist = "Mostrar a janela da Lista Negra."
L.KeybindWhitelist = "Mostrar a janela da Lista Branca."
L.KeybindCurrency = "Mostrar a janela da moeda."
L.KeybindGold = "Mostrar dica de ferramentas de ouro."
L.KeybindProfessions = "Mostrar janela Professions."
L.KeybindProfiles = "Mostrar janela de Perfis."
L.KeybindSearch = "Mostrar janela de pesquisa."
L.ObsoleteWarning = "\n\nNota: Itens obsoletas continuarão a mostrar como faltando. Para reparar este problema, verifique seus caracteres novamente, a fim de remover itens obsoletos. \n(Bags, Bank, Reagent, Void, etc...)"
L.DatabaseReset = "Devido às alterações na base de dados. Seu banco de dados BagSync foi reiniciado."
L.UnitDBAuctionReset = "Os dados do leilão foram reiniciados para todos os caracteres."
L.ScanGuildBankDone = "Escaneamento do Banco da Guilda completo!"
L.ScanGuildBankError = "Aviso: escaneamento do Banco da Guilda incompleto."
L.DefaultColors = "Cores por Omissão"
-- ----THESE ARE FOR SLASH COMMANDS OPERATORS
L.SlashItemName = "[nome]"
L.SlashSearch = "procurar"
L.SlashGold = "ouro"
L.SlashMoney = "dinheiro"
L.SlashConfig = "configuração"
L.SlashCurrency = "moeda"
L.SlashFixDB = "fixdb"
L.SlashProfiles = "perfis"
L.SlashProfessions = "profissões"
L.SlashBlacklist = "listanegra"
L.SlashWhitelist = "listabranca"
L.SlashResetDB = "resetdb"
L.SlashDebug = "depuração"
L.SlashResetPOS = "resetpos"
L.SlashSortOrder = "sortord"
------------------------
-- ----THESE USE THE SLASH OPERATOR COMMANDS FOUND ABOVE
L.HelpSearchItemName = "Faz uma busca rápida por um item"
L.HelpSearchWindow = "Abre a janela de pesquisa"
L.HelpGoldTooltip = "Mostra uma dica com a quantidade de ouro em cada caractere."
L.HelpCurrencyWindow = "Abre a janela da moeda."
L.HelpProfilesWindow = "Abre a janela de perfis."
L.HelpFixDB = "Executa a correção do banco de dados (FixDB) no BagSync."
L.HelpResetDB = "Reinicia toda a base de dados BagSync."
L.HelpConfigWindow = "Abre a janela de configuração do BagSync"
L.HelpProfessionsWindow = "Abre a janela das profissões."
L.HelpBlacklistWindow = "Abre a janela da lista negra."
L.HelpWhitelistWindow = "Abre a janela da lista branca."
L.HelpDebug = "Abre a janela de depuração do BagSync."
L.HelpResetPOS = "Reinicia todas as posições do quadro para cada módulo BagSync."
L.HelpSortOrder = "Ordem de ordenação personalizada para caracteres e guilds."
------------------------
L.EnableBagSyncTooltip = "Activar as Dicas do BagSync"
L.ShowOnModifier = "Tecla modificadora de dicas BagSync:"
L.ShowOnModifierDesc = "Mostrar a dica do BagSync na tecla modificadora."
L.ModValue_NONE = "Nenhuma (Sempre Mostrar)"
L.ModValue_ALT = "ALT"
L.ModValue_CTRL = "CTRL"
L.ModValue_SHIFT = "SHIFT"
L.EnableExtTooltip = "Mostrar os dados de contagem de itens numa dica externa."
L.EnableLoginVersionInfo = "Mostrar o texto da versão BagSync no login."
L.FocusSearchEditBox = "Foque a caixa de pesquisa ao abrir a janela de pesquisa."
L.AlwaysShowAdvSearch = "Mostrar sempre a janela de Pesquisa Avançada Bagsync."
L.DisplayTotal = "Apresentar a quantidade [total]."
L.DisplayGuildGoldInGoldWindow = "Apresentar os totais de ouro da [Guilda] na Janela de Ouro."
L.Display_GSC = "|cFFFFD700Gold|r, |cFFC0C0C0Silver|r e |cFFB87333Copper|r na janela de ouro."
L.DisplayMinimap = "Mostrar o botão minimapa BagSync."
L.DisplayFaction = "Mostrar itens para ambas as facções (|cff3587ffAliance|r/|cFFDF2B2BHorde|r)."
L.DisplayClassColor = "Mostra as cores da classe para os nomes dos caracteres."
L.DisplayItemTotalsByClassColor = "Mostrar os totais do item pela cor da classe de caracteres."
L.DisplayTooltipOnlySearch = "Exibir a dica de ferramenta BagSync |cFF99CC33(ONLY)|r na janela de pesquisa."
L.DisplayTooltipCurrencyData = "Exibir dados de dicas do BagSync na janela Moeda da Blizzard."
L.DisplayLineSeparator = "Mostra o separador de linhas vazio."
L.DisplayCurrentCharacter = "Caracter atual"
L.DisplayCurrentCharacterOnly = "Mostrar os dados das dicas do BagSync para o caractere atual |cFFFFD700ONLY!|r |cFFDF2B2B(Não Recomendado)|r"
L.DisplayBlacklistCurrentCharOnly = "Mostrar as contagens de itens na lista negra para o atual chraracter |cFFFFD700ONLY!|r |cFFDF2B2B(Não Recomendado)|r"
L.DisplayCurrentRealmName = "Mostra o |cFF4CBB17[Reino atual]|r do jogador."
L.DisplayCurrentRealmShortName = "Use um nome curto para o |cFF4CBB17[Reino atual]|r."
L.DisplayCR = "Mostrar caracteres |cffff7d0a[Connected Realm]|r. |cffff7d0a[CR]|r"
L.DisplayBNET = "Mostra todos os combates. Personagens da conta líquida. |cff3587ff[BNet]|r |cFFDF2B2B(Não Recomendado)|r"
L.DisplayItemID = "Mostrar ItemID na dica."
L.DisplayWhiteListOnly = "Mostrar os totais de itens de dicas apenas para itens na lista branca."
L.DisplaySourceExpansion = "Mostrar a expansão da fonte para os itens na dica. |cFF99CC33[Somente Retail]|r"
L.DisplayItemTypes = "Exibe as categorias [Item Tipo □ Sub Tipo] na dica."
L.DisplayTooltipTags = "Etiquetas"
L.DisplayTooltipStorage = "Armazenamento"
L.DisplayTooltipExtra = "Extra"
L.DisplaySortOrderHelp = "Ordenar a Ajuda de Ordem"
L.DisplaySortOrderStatus = "Ordenar ordem é atualmente: [%s]"
L.DisplayWhitelistHelp = "Ajuda na Lista Branca"
L.DisplayWhitelistStatus = "A lista branca é atualmente: [%s]"
L.DisplayWhitelistHelpInfo = "Você só pode inserir números itemid na base de dados da lista branca. \n\nPara a entrada Battle Pets use o FakeID e não o ItemID, você pode pegar o FakeID habilitando o recurso de dicas do ItemID na configuração do BagSync. \n\n|cFFDF2B2BIsto não funcionará para a janela da moeda. |r"
L.DisplayWhitelistHelpInfo2 = "\n\n\n\n|cFFFF7D0AAVISO: Esta funcionalidade da lista branca irá bloquear que BagSync conte itens |cFFFFFFFF--ALL--|r, exceto os encontrados nesta lista.|r\n|cFF09DBE0É uma lista negra inversa!|r"
L.DisplayTooltipAccountWide = "Largura da Conta"
L.DisplayAccountWideTagOpts = "|cFF99CC33Tag Options (|cffff7d0a[CR]|r & |cff3587ff[BNet]|r)|r"
L.DisplayGreenCheck = "Mostra o %s ao lado do nome do caractere atual."
L.DisplayRealmIDTags = "Exibir identificadores de reino |cffff7d0a[CR]|r e |cff3587ff[BNet]|r."
L.DisplayRealmNames = "Mostra os nomes dos reinos."
L.DisplayRealmAstrick = "Mostrar [*] em vez de nomes de reinos para |cffff7d0a[CR]|r e |cff3587ff[BNet]|r."
L.DisplayShortRealmName = "Mostrar nomes de reinos curtos para |cffff7d0a[CR]|r e |cff3587ff[BNet]|r."
L.DisplayFactionIcons = "Mostrar ícones de facções na dica."
L.DisplayGuildBankTabs = "Mostrar as abas do banco de guild [1,2,3, etc...] na dica."
L.DisplayWarbandBankTabs = "Mostrar tabulações de banco de banda de guerra [1,2,3, etc...] na dica."
L.DisplayBankTabs = "Mostrar as abas do banco [1,2,3, etc...] na dica."
L.DisplayEquipBagSlots = "Exibe slots de saco equipados <1,2,3, etc...> na dica."
L.DisplayRaceIcons = "Mostrar ícones de corrida de caracteres na dica."
L.DisplaySingleCharLocs = "Mostra um único caracter para os locais de armazenamento."
L.DisplayIconLocs = "Mostra um ícone para os locais de armazenamento."
L.DisplayAccurateBattlePets = "Habilitar mascotes de batalha precisos no Banco da Guilda e Caixa de Correio. |cFFDF2B2B(Pode causar defasagem)|r |cff3587ff[Ver FAQ do BagSync]|r"
L.DisplaySortCurrencyByExpansionFirst = "Ordenar a janela BagSync Moeda por expansão primeiro em vez de alfabeticamente."
L.DisplaySorting = "Ordenação de Dicas"
L.DisplaySortInfo = "Por padrão: As dicas são ordenadas alfabeticamente pelo Realm e depois pelo Character."
L.SortMode = "Modo de ordenação"
L.SortMode_RealmCharacter = "Reale então Caracter (por omissão)"
L.SortMode_Character = "Caracter"
L.SortMode_ClassCharacter = "Classe então Caracter"
L.SortCurrentPlayerOnTop = "Ordenar por padrão e exibir sempre o caractere atual no topo."
L.SortTooltipByTotals = "Ordenar por totais e não alfabeticamente."
L.SortByCustomSortOrder = "Ordenar por ordem de ordenação personalizada."
L.CustomSortInfo = "Lista utiliza uma ordem ascendente (1,2,3)"
L.CustomSortInfoWarn = "Use apenas números! Exemplos: (-1,0,3,4,37,99,-45)|r"
L.DisplayShowUniqueItemsTotals = "Ativar esta opção permitirá adicionar itens únicos para a contagem total de itens, independentemente das estatísticas de itens. |cFF99CC33(Recomendado) |r."
L.DisplayShowUniqueItemsTotals_2 = [[
Alguns itens como |cffff7d0a[Legendaries]|r podem compartilhar o mesmo nome, mas têm estatísticas diferentes. Como esses itens são tratados independentemente um do outro, eles às vezes não são contados para a contagem total de itens. Se activar esta opção irá ignorar completamente as estatísticas de itens únicas e tratá- las da mesma forma, desde que partilhem o mesmo nome do item.

A desactivação desta opção irá mostrar as contagens do item independentemente, uma vez que as estatísticas do item serão tomadas em consideração. Os totais de itens só serão exibidos para cada caractere que compartilhe o mesmo item único com as mesmas estatísticas exatas. |cFFDF2B2B(Não Recomendado) |r
]]
L.DisplayShowUniqueItemsTotalsTitle = "Mostrar os Totais Únicos de Itens"
L.DisplayShowUniqueItemsEnableText = "Habilitar totais de itens únicos."
L.ColorPrimary = "Cor principal da dica do BagSync."
L.ColorSecondary = "Cor de dica secundária do BagSync."
L.ColorTotal = "Cor da dica do BagSync [Total]."
L.ColorGuild = "Cor do tooltip de BagSync [Guilda]."
L.ColorWarband = "Cor das dicas do BagSync [Warband]."
L.ColorCurrentRealm = "Cor das dicas do BagSync [Reino atual]."
L.ColorCR = "Cor da dica BagSync [Reino Conectado]."
L.ColorBNET = "BagSync [Battle. Cor da dica da rede]."
L.ColorItemID = "Cor das dicas do BagSync [ItemID]."
L.ColorExpansion = "Cor das dicas do BagSync [Expansão]."
L.ColorItemTypes = "Cor das dicas do BagSync [ItemType]."
L.ColorGuildTabs = "Cor do tooltip das páginas da Guilda [1,2,3, etc...]."
L.ColorWarbandTabs = "Páginas de Warband [1,2,3, etc...] cor da dica."
L.ColorBankTabs = "Páginas de banco [1,2,3, etc...] cor da dica."
L.ColorBagSlots = "Fendas de bolsa <1,2,3, etc...> cor da dica."
L.ConfigDisplay = "Visualização"
L.ConfigTooltipHeader = "Configurações para a informação exibida da dica BagSync."
L.ConfigColor = "Cor"
L.ConfigColorHeader = "Configurações de cor para informações de dicas do BagSync."
L.ConfigMain = "Principal"
L.ConfigMainHeader = "Configurações principais para BagSync."
L.ConfigKeybindings = "Combinações de teclas"
L.ConfigKeybindingsHeader = "Configurações do keybind para recursos do BagSync."
L.ConfigExternalTooltip = "Dicas externas"
L.ConfigFont = "Fonte"
L.ConfigFontSize = "Tamanho da Fonte"
L.ConfigFontOutline = "Contorno"
L.ConfigFontOutline_NONE = "Nenhum"
L.ConfigFontOutline_OUTLINE = "Contorno"
L.ConfigFontOutline_THICKOUTLINE = "Espesso Outline"
L.ConfigFontMonochrome = "Monocromático"
L.ConfigTracking = "Rastreamento"
L.ConfigTrackingHeader = "Configurações de rastreamento para todos os locais de banco de dados armazenados do BagSync."
L.ConfigTrackingCaution = "Atenção"
L.ConfigTrackingModules = "Módulos"
L.ConfigTrackingInfo = [[
|cFFDF2B2BNOTE|r: Desativar um módulo fará BagSync parar de rastrear e armazenar o módulo para o banco de dados.

Módulos desativados não serão exibidos em nenhuma das janelas BagSync, comandos de barra, dicas ou botão minimap.
]]
L.TrackingModule_Bag = "Sacos"
L.TrackingModule_Bank = "Banco"
L.TrackingModule_Reagents = "Banco de Reagentes"
L.TrackingModule_Equip = "Itens Equipados"
L.TrackingModule_Mailbox = "Caixa de Correio"
L.TrackingModule_Void = "Banco Vazio"
L.TrackingModule_Auction = "Leilão"
L.TrackingModule_Guild = "Banco da Guilda"
L.TrackingModule_WarbandBank = "Banco Warband (Banco de Guerra)"
L.TrackingModule_Professions = "Profissões / Competências comerciais"
L.TrackingModule_Currency = "Curência"
L.WarningItemSearch = "AVISO: Não foram pesquisados itens [|cFFFFFFFF%s|r]! \n\nBagSync ainda está esperando o servidor/cache responder. \n\nPress Buscar ou atualizar botão."
L.WarningCurrencyUpt = "Erro ao atualizar a moeda. Por favor, faça login no caracter:"
L.WarningHeader = "Aviso!"
L.SavedSearch = "Pesquisa Gravada"
L.SavedSearch_Add = "Adicionar pesquisa"
L.SavedSearch_Warn = "Você deve digitar algo na caixa de pesquisa."
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
    "o",
    "a",
    "os",
    "as",
    "de",
    "do",
    "da",
    "dos",
    "das",
    "the",
}
---------------------------------------
--Localization Note:  Please be advised that the commands for the SearchHelp are english only, however the variables can be any language.  Example: class:<name of class in your locale>
--This includes name searches like name:<name in your locale>
---------------------------------------
L.SearchHelpHeader = "Procurar Ajuda"
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
L.ConfigFAQ= "FAQ / Ajuda"
L.ConfigFAQHeader = "Perguntas frequentes e seção de ajuda para BagSync."
L.FAQ_Question_1 = "Estou experimentando engates/estuttering/lagging com dicas de ferramentas."
L.FAQ_Question_1_p1 = [[
Este problema normalmente acontece quando existem dados antigos ou corrompidos no banco de dados, que BagSync não pode interpretar. O problema também pode ocorrer quando há uma quantidade esmagadora de dados para BagSync passar. Se você tem milhares de itens em vários caracteres, isso é um monte de dados para passar dentro de um segundo. Isto pode levar o seu cliente a gaguejar por um breve momento. Finalmente, outra causa para este problema é ter um computador extremamente antigo. O computador mais antigo vai experimentar engates/tuttering como BagSync processa milhares de dados de itens e caracteres. O computador mais novo tem CPUs mais rápidas e a memória normalmente não tem esse problema.

Para corrigir este problema, você pode tentar redefinir o banco de dados. Isso geralmente resolve o problema. Use o seguinte comando de barra. |cFF99CC33/bgs resetdb|r
Se isso não resolver seu problema, arquive um ticket de problema no GitHub for BagSync.
]]
L.FAQ_Question_2 = "Nenhum item de dados para minhas outras contas WOW encontradas em uma conta |cFFDF2B2BsyNCTOK2Z |cff3587ffBattle.net|r."
L.FAQ_Question_2_p1 = [[
Addon não tem a capacidade de ler dados de outras contas WOW. Isso é porque eles não compartilham a mesma pasta SavedVariable. Esta é uma limitação construída dentro do cliente WOW da Blizzard. Portanto, você não será capaz de ver os dados do item para várias contas WOW sob um |cFFDF2B2B Single|r |cff3587ffBattle.net|r. BagSync só será capaz de ler dados de caracteres em vários reinos dentro da mesma conta WOW, não em toda a conta Battle.net.

Há uma maneira de conectar várias contas WOW, dentro de uma conta |cFFDF2B2Bsingle|r |cff3587ffBattle.net|r, para que eles compartilhem a mesma pasta SavedVariables. Isso envolve a criação de pastas Symlink. Não prestarei assistência nesta matéria. Não perguntes! Visite o seguinte guia para mais detalhes. |cFF99CC33https://www.wowhead.com/guide=934|r
]]
L.FAQ_Question_3 = "Você pode ver os dados do item de |cFFDF2B2Bmultiple|r |cff3587ffBattle.net|r Contas?"
L.FAQ_Question_3_p1 = "Não, não é possível. Não vou prestar assistência neste caso. Não perguntes!"
L.FAQ_Question_4 = "Posso ver os dados de itens de várias contas WOW |cFFDF2B2B atualmente logadas in|r?"
L.FAQ_Question_4_p1 = "Atualmente BagSync não suporta a transmissão de dados entre várias contas WOW logadas. Isto pode mudar no futuro."
L.FAQ_Question_5 = "Por que recebo uma mensagem de que a verificação do banco está incompleta?"
L.FAQ_Question_5_p1 = [[
BagSync tem que consultar o servidor para |cFF99CC33ALL|r suas informações do banco de guild. Leva tempo para o servidor transmitir todos os dados. Para BagSync armazenar corretamente todos os seus itens, você deve esperar até que a consulta do servidor esteja concluída. Quando o processo de digitalização estiver concluído, o BagSync irá notificá-lo no chat. Deixar a janela do Guild Bank antes que o processo de digitalização seja feito, resultará em dados incorretos sendo armazenados para o seu Guild Bank.
]]
L.FAQ_Question_6 = "Por que eu vejo [FakeID] em vez de [ItemID] para Battle Pets?"
L.FAQ_Question_6_p1 = [[
Blizzard não atribui ItemIDs para Battle Pets para WOW. Em vez disso, Battle Pets em WOW recebe um PetID temporário do servidor. Este PetID não é único e será alterado quando o servidor reiniciar. Para manter o controle de Battle Pets, BagSync gera um FakeID. Um FakeID é gerado a partir de números estáticos associados ao Battle Pet. Usar um FakeID permite que o BagSync rastreie o Battle Pets mesmo através de redefinições do servidor.
]]
L.FAQ_Question_7 = "O que é a digitalização precisa de Battle Pet no Guild Bank & Mailbox?"
L.FAQ_Question_7_p1 = [[
A Blizzard não armazena animais de estimação de batalha no Guild Bank ou Mailbox com um ItemID ou SpeciesID adequado. Na verdade, os animais de estimação de batalha são armazenados no Guild Bank e Mailbox como |cFF99CC33[Pet Cage]|r com um ItemID de |cFF99CC3382800|r. Isso torna difícil para os autores addon agarrar qualquer dado em relação a Battle Pets específicos. Você pode ver por si mesmo nos registros de transações do Guild Bank, você vai notar que os animais de estimação Battle são armazenados como |cFF99CC33[Pet Cage]|r. Se você ligar um de um Guild Bank, ele também será exibido como |cFF99CC33[Pet Cage]|r. Para superar este problema, existem dois métodos que podem ser usados. O primeiro método é atribuir o animal de estimação de batalha a uma dica e, em seguida, agarrar o SpeciesID de lá. Isso requer que o servidor responda ao cliente WOW e pode potencialmente levar a uma grande defasagem, especialmente se houver muitos animais de estimação de batalha no Guild Bank. O segundo método usa o ícone Texture of the Battle Pet para tentar encontrar o SpeciesID. Isso às vezes é impreciso, pois certos animais de guerra compartilham o mesmo ícone Textura. Exemplo: O Lixo Tóxico compartilha o mesmo íconeTextura como Jade Oozeling. Habilitar esta opção irá forçar o método de digitalização de dicas a ser o mais preciso possível, mas pode potencialmente causar lag. |cFFDF2B2BNão há como contornar isso até que a Blizzard nos dê mais dados para trabalhar. |r
]]
L.BagSyncInfoWindow = [[
BagSync por padrão só mostra dados de dicas de caracteres em reinos conectados. (|cffff7d0a[CR]|r)

Os Reinos Conectados (|cffff7d0a[CR]|r ) são servidores que foram conectados juntos.

Para uma lista completa, visite:
(|cFF99CC33 https://tinyurl.com/msncc7j6 |r)


|cFFfd5c63BagSync NÃO mostrará dados de toda a sua batalha. Conta líquida por padrão. Você vai precisar habilitar isso! |r
(|cff3587ff[BNet]|r)

|cFF52D386Se você gostaria de ver todos os seus caracteres em toda sua conta Battle.net ( |cff3587ff[BNet]|r ), você precisa ativar a opção na janela de configuração BagSync sob [Account Wide]. |r

A opção é marcada como:
]]
