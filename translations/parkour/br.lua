translations.br = {
	name = "br",

	-- Error messages
	corrupt_map = "<r>Mapa corrompido. Carregando outro.",
	corrupt_map_vanilla = "<r>[ERROR] <n>Não foi possível obter informações deste mapa.",
	corrupt_map_mouse_start = "<r>[ERROR] <n>O mapa requer um ponto de partida (spawn).",
	corrupt_map_needing_chair = "<r>[ERROR] <n>O mapa requer a poltrona final.",
	corrupt_map_missing_checkpoints = "<r>[ERROR] <n>O mapa requer ao menos um checkpoint (prego amarelo).",
	corrupt_data = "<r>Infelizmente seus dados corromperam e foram reiniciados.",
	min_players = "<r>Para que dados sejam salvos, ao menos 4 jogadores únicos devem estar na sala. <bl>[%s/%s]",
	tribe_house = "<r>Para que dados sejam salvos, você precisa jogar fora de um cafofo de tribo.",
	invalid_syntax = "<r>Sintaxe inválida.",
	user_not_in_room = "<r>O usuário <n2>%s</n2> não está na sala.",
	arg_must_be_id = "<r>O argumento deve ser um ID válido.",
	cant_update = "<r>Não foi possível atualizar o cargo do jogador. Tente novamente mais tarde.",
	cant_edit = "<r>Você não pode editar o cargo do jogador <n2>%s</n2>.",
	invalid_rank = "<r>Cargo inválido: <n2>%s",
	code_error = "<r>Um erro aconteceu: <bl>%s-%s-%s %s",
	panic_mode = "<r>Módulo entrando em Modo Pânico.",
	public_panic = "<r>Espere um momento enquanto um bot entra na sala e reinicia o módulo.",
	tribe_panic = "<r>Por favor, digite <n2>/module parkour</n2> para reiniciar o módulo.",
	emergency_mode = "<r>Começando desativação de emergência, novos jogadores não serão mais permitidos. Por favor, vá para outra sala #parkour.",
	bot_requested = "<r>O bot foi requisitado. Ele virá em poucos segundos.",
	stream_failure = "<r>Erro interno entre canais. Não foi possível transmitir dados.",
	maps_not_available = "<r>Submodo #parkour 'maps' só está disponível na sala <n2>*#parkour0maps</n2>.",
	version_mismatch = "<r>Versões do Bot (<d>%s</d>) e lua (<d>%s</d>) não são equivalentes. Não foi possível iniciar o sistema.",
	missing_bot = "<r>O bot sumiu. Aguarde um minuto ou mencione @Tocu#0018 no discord: <d>%s</d>",
	invalid_length = "<r>Sua mensagem deve ter algo entre 10 e 100 caracteres. Agora tem <n2>%s</n2> caracteres.",
	invalid_map = "<r>Mapa inválido.",
	map_does_not_exist = "<r>O mapa não existe ou não pôde ser carregado. Tente novamente mais tarde.",
	invalid_map_perm = "<r>O mapa não é nem P22, nem P41.",
	invalid_map_perm_specific = "<r>O mapa não é P%s.",
	cant_use_this_map = "<r>O mapa tem um pequeno bug e não pode ser usado.",
	invalid_map_p41 = "<r>O mapa é P41, mas não está na lista de mapas do módulo.",
	invalid_map_p22 = "<r>O mapa é P22, mas está na lista de mapas do módulo.",
	map_already_voting = "<r>o mapa já tem uma votação em aberto.",
	not_enough_permissions = "<r>Você não tem permissões suficientes para fazer isso.",
	already_depermed = "<r>O mapa já foi <i>deperm</i>.",
	already_permed = "<r>O mapa já está <i>perm</i>.",
	cant_perm_right_now = "<r>Não foi possível alterar a categoria deste mapa no momento. Tente novamente mais tarde.",
	already_killed = "<r>O jogador %s já está morto.",
	leaderboard_not_loaded = "<r>O ranking ainda não foi carregado. Aguarde um minuto.",

	-- Help window
	help = "Ajuda",
	staff = "Staff",
	rules = "Regras",
	contribute = "Contribuir",
	changelog = "Novidades",
	help_help = "<p align = 'center'><font size = '14'>Bem-vindo ao <T>#parkour!</T></font></p>\n<font size = '12'><p align='center'><J>Seu objetivo é chegar em todos os checkpoints até que você complete o mapa.</J></p>\n\n<N>• Aperte <O>O</O>, digite <O>!op</O> ou clique no <O>botão de configuração</O> para abrir o <T>menu de opções</T>.\n• Aperte <O>P</O> ou clique no <O>ícone de mão</O> no parte superior direita para abrir o <T>menu de poderes</T>.\n• Aperte <O>L</O> ou digite <O>!lb</O> parar abrir o <T>ranking</T>.\n• Aperte <O>M</O> ou a tecla <O>Delete</O> para <T>/mort</T>, você pode alterar as teclas no moenu de <J>Opções</J>.\n• Para saber mais sobre nossa <O>staff</O> e as <O>regras do parkour</O>, clique nas abas <T>Staff</T> e <T>Regras</T>, respectivamente.\n• Click <a href='event:discord'><o>here</o></a> to get the discord invite link and <a href='event:map_submission'><o>here</o></a> to get the map submission topic link.\n• Use <o>up</o> and <o>down</o> arrow keys when you need to scroll.\n\n<p align = 'center'><font size = '13'><T>Contribuições agora estão disponíveis! Para mais detalhes, clique na aba <O>Contribuir</O>!</T></font></p>",
	help_staff = "<p align = 'center'><font size = '13'><r>AVISO: A staff do Parkour não faz parte da staff do Transformice e não tem nenhum poder no jogo em si, apenas no módulo.</r>\nStaff do Parkour assegura que o módulo rode com problemas mínimos, e estão sempre disponíveis para dar assistência aos jogadores quando necessário.</font></p>\nVocê pode digitar <D>!staff</D> no chat para ver a lista de staff.\n\n<font color = '#E7342A'>Administradores:</font> São responsáveis por manter o módulo propriamente dito, atualizando-o e corrigindo bugs.\n\n<font color = '#843DA4'>Gerenciadores das Equipes:</font> Observam as equipes de Moderação e de Mapas, assegurando que todos estão fazendo um bom trabalho. Também são responsáveis por recrutar novos membros para a staff.\n\n<font color = '#FFAAAA'>Moderadores:</font> São responsáveis por aplicar as regras no módulo e punir aqueles que não as seguem.\n\n<font color = '#25C059'>Mappers:</font> São responsáveis por avaliar, adicionar e remover mapas do módulo para assegurar que você tenha uma jogatina divertida.",
	help_rules = "<font size = '13'><B><J>Todas as regras nos Termos e Condições de Uso do Transformice também se aplicam no #parkour</J></B></font>\n\nSe você encontrar algum jogador quebrando-as, cochiche com um moderador do #parkour no jogo. Se os moderadores não estiverem online, recomendamos que reporte em nosso servidor no Discord.\nAo reportar, por favor inclua a comunidade, o nome da sala e o nome do jogador.\n• Ex: en-#parkour10 Blank#3495 trolling\nEvidências, como prints, vídeos e gifs são úteis e apreciados, mas não necessários.\n\n<font size = '11'>• Uso de <font color = '#ef1111'>hacks, glitches ou bugs</font> são proibidos em salas #parkour\n• <font color = '#ef1111'>Farm VPN</font> será considerado um <B>abuso</B> e não é permitido. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nQualquer um pego quebrando as regras será banido imediatamente.</B></font></p>\n\n<font size = '12'>Transformice permite trollar. No entanto, <font color='#cc2222'><B>não permitiremos isso no parkour.</B></font></font>\n\n<p align = 'center'><J>Trollar é quando um jogador usa seus poderes de forma intencional para fazer com que os outros jogadores não terminem o mapa.</j></p>\n• Trollar por vingança <B>não é um motivo válido</B> e você ainda será punido.\n• Insistir em ajudar jogadores que estão tentando terminar o mapa sozinhos e se recusando a parar quando pedido também será considerado trollar.\n• <J>Se um jogador não quer ajuda e prefere completar o mapa sozinho, dê seu melhor para ajudar os outros jogadores</J>. No entanto, se outro jogador que precisa de ajuda estiver no mesmo checkpoint daquele que quer completar sozinho, você pode ajudar ambos sem receber punição.\n\nSe um jogador for pego trollando, serão punidos por um tempo determinado ou por algumas partidas. Note que trollar repetidamente irá fazer com que você receba punições gradativamente mais longas e/ou severas.",
	help_contribute = "<font size='14'>A equipe de gerenciamento do parkour ama código-fonte aberto, porque isso ajuda a comunidade. Você pode ver e modificar o código do módulo no github <a href='event:github'><u>(clicando aqui)</u></a>.\n\nNote que estamos mantendo o módulo de graça, então qualquer ajuda (seja código, report de bugs, sugestões) é bem-vinda. Também podemos receber doações, que podem ser feitas <a href='event:donate'><u>clicando aqui</u></a>. Qualquer valor é apreciado e será usado para melhorar o #parkour.",
	help_changelog = "<font size='13'><p align='center'><o>Version 2.1.0 - 27/04/2020</o></p>\n\n• Improved the help interface\n\t\t• Added a <o>News</o> button\n\t\t• Made it <t>wider</t>\n\t\t• Added <t>arrow key scroll</t>\n• Improved <t>sanctions</t> system.\n\t\t• Added an <t>anticheat system</t>.\n• Map review system has been changed.\n\t\t• Added <t>high</t> and <t>low</t> priority map rotations.\n• The <o>!staff</o> command only shows online members.\n• Internal changes and bugfixes so the game crashes less often.\n\t\t• A bug regarding <t>people not being able to complete the map</t> has been fixed.",

	-- Congratulation messages
	reached_level = "<d>Parabéns! Você atingiu o nível <vp>%s</vp>.",
	finished = "<d><o>%s</o> terminou o parkour em <vp>%s</vp> segundos, <fc>parabéns!",
	unlocked_power = "<ce><d>%s</d> desbloqueou o poder <vp>%s</vp>.",
	enjoy = "<d>Aproveite suas novas habilidades!",

	-- Information messages
	paused_events = "<cep><b>[Atenção!]</b> <n>O módulo está atingindo um estado crítico e está sendo pausado.",
	resumed_events = "<n2>O módulo está se normalizando.",
	welcome = "<n>Bem-vindo(a) ao <t>#parkour</t>!",
	type_help = "<pt>Recomendamos que você digite <d>!help</d> para informações úteis!",
	data_saved = "<vp>Dados salvos.",
	action_within_minute = "<vp>A ação será aplicada dentre um minuto.",
	rank_save = "<n2>Digite <d>!rank save</d> para salvar as mudanças.",
	module_update = "<r><b>[Atenção!]</b> <n>O módulo irá atualizar em <d>%02d:%02d</d>.",
	mapping_loaded = "<j>[INFO] <n>Sistema de mapas <t>(v%s)</t> carregado.",
	mapper_joined = "<j>[INFO] <n><ce>%s</ce> <n2>(%s)</n2> entrou na sala.",
	mapper_left = "<j>[INFO] <n><ce>%s</ce> <n2>(%s)</n2> saiu da sala.",
	mapper_loaded = "<j>[INFO] <n><ce>%s</ce> carregou este mapa.",
	starting_perm_change = "<j>[INFO] <n>Iniciando mudança de categoria...",
	got_map_info = "<j>[INFO] <n>Todas as informações do mapa foram coletadas. Tentando alterar categoria...",
	perm_changed = "<j>[INFO] <n>Categoria do mapa <ch>@%s</ch> alterada com sucesso, de <r>P%s</r> para <t>P%s</t>.",
	leaderboard_loaded = "<j>O ranking foi carregado. Aperte L para abri-lo.",
	kill_minutes = "<R>Seus poderes foram desativados por %s minutos.",
	kill_map = "<R>Seus poderes foram desativados até o próximo mapa.",

	-- Miscellaneous
	options = "<p align='center'><font size='20'>Opções do Parkour</font></p>\n\nUsar partículas para os checkpoints\n\nUsar o teclado <b>QWERTY</b> (desativar caso seja <b>AZERTY</b>)\n\nUsar a tecla <b>M</b> como <b>/mort</b> (desativar caso seja <b>DEL</b>)\n\nMostrar o delay do seu poder\n\nMostrar o botão de poderes\n\nMostrar o botão de ajuda\n\nMostrar mensagens de mapa completado",
	unknown = "Desconhecido",
	powers = "Poderes",
	press = "<vp>Aperte %s",
	click = "<vp>Use click",
	completed_maps = "<p align='center'><BV><B>Mapas completados: %s</B></p></BV>",
	leaderboard = "Ranking",
	position = "Posição",
	username = "Nome",
	community = "Comunidade",
	completed = "Mapas completados",
	not_permed = "não tem categoria",
	permed = "permed",
	points = "%d pontos",
	conversation_info = "<j>%s <bl>- @%s <vp>(%s, %s) %s\n<n><font size='10'>Iniciado por <d>%s</d>. Último comentário por <d>%s</d>. <d>%s</d> comentários, <d>%s</d> não lidos.",
	map_info = "<p align='center'>Código do mapa: <bl>@%s</bl> <g>|</g> Autor do mapa: <j>%s</j> <g>|</g> Status: <vp>%s, %s</vp> <g>|</g> Pontos: <vp>%s</vp>",
	permed_maps = "Mapas <i>permed</i>",
	ongoing_votations = "Votações em andamento",
	archived_votations = "Votações arquivadas",
	open = "Abrir",
	not_archived = "não arquivado",
	archived = "arquivado",
	delete = "<r><a href='event:%s'>[deletar]</a> ",
	see_restore = "<vp><a href='event:%s'>[ver]</a> <a href='event:%s'>[restaurar]</a> ",
	no_comments = "Sem comentários.",
	deleted_by = "<r>[Mensagem deletada por %s]",
	dearchive = "desarquivar", -- to dearchive
	archive = "arquivar", -- to archive
	deperm = "deperm", -- to deperm
	perm = "perm", -- to perm
	map_actions_staff = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Comentar</j></a> <g>|</g> Seu voto: %s <g>|</g> <vp><a href='event:%s'>[%s]</a> <a href='event:%s'>[%s]</a> <a href='event:%s'>[carregar]</a></p>",
	map_actions_user = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Comentar</j></a></p>",
	load_from_thread = "<p align='center'><a href='event:load_custom'>Carregar mapa</a></p>",
	write_comment = "Escreva seu comentário abaixo",
	write_map = "Escreva o código do mapa abaixo",

	-- Power names
	balloon = "Balão",
	masterBalloon = "Balão Mestre",
	bubble = "Bolha",
	fly = "Voar",
	snowball = "Bola de Neve",
	speed = "Velocidade",
	teleport = "Teleporte",
	smallbox = "Caixa Pequena",
	cloud = "Nuvem",
	rip = "Lápide",
	choco = "Choco-tábua",
}
