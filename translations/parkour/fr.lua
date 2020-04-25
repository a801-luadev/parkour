translations.fr = {
	name = "fr",

	-- Error messages
	corrupt_map = "<r>Carte non opérationelle. Chargement d'une autre.",
	corrupt_map_vanilla = "<r>[ERROR] <n>Impossible de récolter les information de cette carte.",
	corrupt_map_mouse_start = "<r>[ERROR] <n>Cette carte a besoin d'un point d'apparition (pour les souris).",
	corrupt_map_needing_chair = "<r>[ERROR] <n>La carte a besoin d'une chaise de fin (point final).",
	corrupt_map_missing_checkpoints = "<r>[ERROR] <n>La carte a besoin d'au moins d'un point de sauvegarde (étoiles jaunes).",
	corrupt_data = "<r>Malheureusment, vos donnés ont été corrompues et ont été effacé.",
	min_players = "<r>Pour sauvegarder vos donnés, il doit y avoir au moins 4 souris dans le salon. <bl>[%s/%s]",
	tribe_house = "<r>Les données ne sont pas sauvées dans les maisons de tribus..",
	invalid_syntax = "<r>Syntaxe invalide.",
	user_not_in_room = "<r>Le joueur <n2>%s</n2> n'est pas dans le salon.",
	arg_must_be_id = "<r>L'argument doit Être un ID valide.",
	cant_update = "<r>Impossible de mettre à jour les rangs des joueurs pour l'instant. Essayer plus tard.",
	cant_edit = "<r>Vous ne pouvez pas modifier le rang de <n2>%s's</n2>.",
	invalid_rank = "<r>Rang invalide: <n2>%s",
	code_error = "<r>Une erreur est survenue: <bl>%s-%s-%s %s",
	panic_mode = "<r>Module est maintenant en mode panique.",
	public_panic = "<r>Merci d'attendre jusqu'à ce que le robot arrive et redémarre le serveur.",
	tribe_panic = "<r>Veuillez ecrire <n2>/module parkour</n2> pour redémarrer le module.",
	emergency_mode = "<r>Mise en place du bloquage d'urgence, aucun nouveau joueur ne peut rejoindre. Merci d'aller dans un autre salon de #parkour.",
	bot_requested = "<r>Le robot à été solicité, il devrait arrivé dans un moment.",
	stream_failure = "<r>Echec de la chaine de stream interne. Impossible de transmettre les données.",
	maps_not_available = "<r>#parkour's 'maps' est seulement disponible dans <n2>*#parkour0maps</n2>.",
	version_mismatch = "<r>Le robot (<d>%s</d>) et Lua(<d>%s</d>) ne marche pas ensemble. Impossible de démarrer le système.",
	missing_bot = "<r>Robot absent. Attendez jusqu'à ce que le robot arrive ou mentionnez @Tocu#0018 sur Discord: <d>%s</d>",
	invalid_length = "<r>Votre message doit obligatoirement avoir entre 10 et 100 caractères. Il a seulement <n2>%s</n2> characters.",
	invalid_map = "<r>Carte invalide.",
	map_does_not_exist = "<r>Cette carte n'existe pas ou ne peut pas Être chargé. Essayez plus tard.",
	invalid_map_perm = "<r>Cette carte n'est pas P22 ou P41.",
	invalid_map_perm_specific = "<r>La carte n'est pas P%s.",
	cant_use_this_map = "<r>Cette carte a un bug et ne peut pas Être utilisée.",
	invalid_map_p41 = "<r>Cette carte est en P41, mais n'est pas dans la liste des cartes de ce module.",
	invalid_map_p22 = "<r>Cette carte est en P22, mais n'est pas dans la liste des cartes de ce module.",
	map_already_voting = "<r>Cette garde a déjà un vote en cours.",
	not_enough_permissions = "<r>Vous n'avez pas assez de permissions pour faire ça.",
	already_depermed = "<r>Cette carte est déjà non-permanente.",
	already_permed = "<r>Cette carte est déjà permanente.",
	cant_perm_right_now = "<r>Impossible de changer les permissions de cette carte maintenant. Essayez plus tard.",
	already_killed = "<r>Le joueur %s a déjà été tué.",
	leaderboard_not_loaded = "<r>Le tableau des scores n'a pas été cahrgé encore. Attendez une minute.",

	-- Help window
	help = "Aide",
	staff = "Staff",
	rules = "Règles",
	contribute = "Contribuer",
	changelog = "Changements",
	help_help = "<p align = 'center'><font size = '14'>Bienvenue à <T>#parkour!</T></font></p>\n<font size = '12'><p align='center'><J>Votre but est de parcourir tous les points de sauvegarde pour finir la carte.</J></p>\n\n<N>• Press <O>O</O>, type <O>!op</O> ou cliquez le <O>configuration button</O> pour ouvrir le <T>options menu</T>.\n• Press <O>P</O> ou cliquez le <O>hand icon</O> en haut à droite pour ouvrir <T>powers menu</T>.\n• Press <O>L</O> ou écrivez <O>!lb</O> pour ouvrir le <T>leaderboard</T>.\n• Appuyez sur <O>M</O> ou la touche <O>Delete</O> pour <T>/mort</T>, vous pouvez personnaliser les touches dans le menu <J>Options</J>\n• Pour savoir plus à propso de notre <O>Staff</O> et des <O>Règles de parkour</O>, cliquez sur les pages respectives du <T>Staff</T> et des <T>Règles</T>.\n• Cliquez sur <a href='event:discord'><o>here</o></a> pour avoir le lien d'invitation pour le discord et <a href='event:map_submission'><o>here</o></a> pour avoir le lien pour proposer ses cartes.\n• Utilisez les flèches d'<o>en haut</o> et d'<o>en bas</o> quand vous avez besoin de scroller.\n\n<p align = 'center'><font size = '13'><T>Les contributions sont maintenant ouvertes ! pour plus d'informations, cliquez sur la page <O>Contribute</O> </T></font></p>",
	help_staff = "<p align = 'center'><font size = '13'><r>INFORMATION: Le Staff de Parkour ne sont pas Staff de Transformice, ils n'ont aucun pouvoir sur le jeu soit-meme, seulement dans ce module.</r>\nLe Staff de Parkour s'assure que le module marche bien avec des issues minimales et sont toujours disponibles pour aider les joueurs.</font></p>\nVous pouvez écrire <D>!staff</D> dans le chat pour voir la liste du Staff.\n\n<font color = '#E7342A'>Administrateurs:</font> Ils sont responsables de maintenir le module soit-meme en ajoutant des mise à jours et en réparant les bugs.\n\n<font color = '#843DA4'>Manageurs des équipes:</font> Ils surveillent les modérateurs et les créateurs de cartes, surveillant s'ils font bien leur travail. Ils sont aussi responsable du recrutement de nouveau membre du Staff.\n\n<font color = '#FFAAAA'>Modérateurs:</font> Ils font respecter les règles du module et punissent ceux qui les enfreignent.\n\n<font color = '#25C059'>Mappers:</font> Ils sont aussi responsables de vérifier, d'ajouter et de supprimer des cartes dans le module pour rendre vos parties meilleures.",
	help_rules = "<font size = '13'><B><J>All Les Regles de Termes et de Conditions de Transformice s'appliquent aussi dans #parkour</J></B></font>\n\nSi vous surprenez un joueur enfreignant les règles, chuchotez à un modérateur du module #parkour connecté. Si aucun modérateur n'est en ligne, reportez le dans le serveur Discord.\nPour tous reports, inclusez : le serveur, le nom du salon, et le nom du joueur.\n• Ex: en-#parkour10 Blank#3495 trolling\nDes preuves, comme des captures d'écran, des vidéos et des GIFs aident et sont appréciés, mais pas nécessaires.\n\n<font size = '11'>• Aucun <font color = '#ef1111'> piratage, aucune corruption ou bugs</font> utilisés/abusés dans les salons #parkour\n• <font color = '#ef1111'>VPN farming</font> seront considérés comme <B>une violation</B> et ne sont pas autorisés. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nN'importe qui surprit en train d'enfreindre ces règles sera banni.</B></font></p>\n\n<font size = '12'>Transformice autorise le concept du troll. Mais, <font color='#cc2222'><B>wenous ne l'autorisons pas dans #parkour.</B></font></font>\n\n<p align = 'center'><J>Quelqu'un troll si il empeche, grace à ses pouvoirs, de laisser les autres joueurs finir la carte.</j></p>\n• Le troll en revanche d'un autre troll<B>n'est pas une raison valable</B> et vous serez quand meme puni.\n• Aider un joueur qui a dit qu'il voulait faire la carte seule est aussi considéré comme du trolling.\n• <J>Si un joueur veut réaliser la carte sans aide, merci de le laisser libre de son choix et d'aider les autres joueurs</J>. Si un autre joueur a besoin d'aide au meme point de sauvegarde que celui-ci, vous pouvez aider les deux.\n\nSi un joueur est surpris en train de troller, il sera punis par sois un certains temps ou attendre un certain temps de cartes parkour sans pouvoir les jouer. Notez que du troll répétitif peut amener à des sanctions de plus en plus sévères.",
	help_contribute = "<font size='14'>\n<p align='center'>L'équipe de management de parkour adore partager les codes de source car <t>cela aide la communauté</t>. vous pouvez <o>voir</o> et<o>modifier</o> les codes de sources sur <o><u><a href='event:github'>GitHub</a></u></o>.\n\nEntretenir le module est <t>strictement volontaire</t>, donc n'importe quelle aide à propos des <t>codes</t>, <t>des reports de bugs</t>, <t>des suggestions</t> et <t>la création de cartes</t> est toujours <u>la bienvenue et apprécié</u>.\nVous pouvez <vp>reporter des bugs</vp> et <vp>faire des suggestions</vp> dans <o><u><a href='event:discord'>Discord</a></u></o> and/or <o><u><a href='event:github'>GitHub</a></u></o>.\nVous pouvez <vp>proposer des cartes</vp> dans notre <o><u><a href='event:map_submission'>Forum Thread</a></u></o>.\n\nEntretenir le parkour n'est pas cher, mais ce n'est pas non plus gratuit. Nous adoriions si vous nous aidez en <t>faisant un don</t> <o><u><a href='event:donate'>ici</a></u></o>.\n<u>Toutes les donations iront directement dans l'amélioration du module.</u></p>",
	help_changelog = "<font size='13'><p align='center'><o>Version 2.1.0 - 27/04/2020</o></p>\n\n• Amélioration de l'interface d'aide.\n\t\t• Ajout d'un nouveau boutton de <o>nouvelles</o> .\n\t\t• Rendu <t>plus large</t>.\n\t\t• Ajout de <t>flèche de scroll</t>.\n• IAmélioration du système de <t>sanctions</t>.\n\t\t• Ajout d'un <t>système d'anti-triche</t>.\n• Changement du système de vérification de cartes.\n\t\t• Ajout de  rotation <t>en haut</t> et  <t>en bas</t> des cartes.\n• La commande <o>!staff</o> montre seulement le Staff en ligne.\n• Changements internes et réparations de bugs pour faire en sorte que le module crash moins.\n\t\t• Le bug à propos des <t>personnes ne pouvant pas terminer la carte</t> a été réparé.",

	-- Congratulation messages
	reached_level = "<d>Bravo! Vous avez atteint le niveau <vp>%s</vp>.",
	finished = "<d><o>%s</o> a finis le parcour en <vp>%s</vp> secondes, <fc>congratulations!",
	unlocked_power = "<ce><d>%s</d> a débloqué le pouvoir <vp>%s</vp>.",
	enjoy = "<d>Profite de tes nouvelles compétences!",

	-- Information messages
	paused_events = "<cep><b>[Attention!]</b> <n>Le module a atteint sa limite critique et est en pause.",
	resumed_events = "<n2>Le module n'est plus en pause.",
	welcome = "<n>Bienvenue à <t>#parkour</t>!",
	type_help = "<pt>Nous vous recommandons d'utiliser la commande <d>!help</d> pour voir des informations utiles !",
	data_saved = "<vp>Données enregistrées.",
	action_within_minute = "<vp>Cette action sera réalisée dans quelque minutes.",
	rank_save = "<n2>Ecrivez <d>!rank save</d> pour appliquer les changements.",
	module_update = "<r><b>[Attention!]</b> <n>Le module va se réinitialiser dans<d>%02d:%02d</d>.",
	mapping_loaded = "<j>[INFO] <n>Système de carte<t>(v%s)</t> chargé.",
	mapper_joined = "<j>[INFO] <n><ce>%s</ce> <n2>(%s)</n2> a rejoinds le salon.",
	mapper_left = "<j>[INFO] <n><ce>%s</ce> <n2>(%s)</n2> a quitté le salon.",
	mapper_loaded = "<j>[INFO] <n><ce>%s</ce> a chargé la carte.",
	starting_perm_change = "<j>[INFO] <n>Commencement du changement de permissions...",
	got_map_info = "<j>[INFO] <n>Informations de la carte récupérées. Essaie de changement de permissions...",
	perm_changed = "<j>[INFO] <n>Réussite du changement de permission de la carte<ch>@%s</ch> from <r>P%s</r> to <t>P%s</t>.",
	leaderboard_loaded = "<j>Le tableau des scores a été chargé. Appuyer sur L pour l'ouvrir.",
	kill_minutes = "<R>Vos pouvoirs ont été désactivés pour %s minutes.",
	kill_map = "<R>Vos pouvoirs ont été désactivés jusqu'à la prochaine carte.",

	-- Miscellaneous
	options = "<p align='center'><font size='20'>Options de Parkour</font></p>\n\nUtilisez les particules comme points de sauvegarde\n\nUtilisez le clavier <b>QWERTY</b> (désactivez si votre clavier et en <b>AZERTY</b>)\n\nUtilisez <b>M</b> touche chaude pour <b>/mort</b> (désactivez pour <b>DEL</b>)\n\nMontre le cooldown de vos compétences\n\nMontre les boutons pour utiiser les compétences\n\nMontre le bouton d'aide\n\nMontre les annonces des cartes achevées",
	unknown = "Inconnu",
	powers = "Pouvoirs",
	press = "<vp>Appuyer sur %s",
	click = "<vp>Clique gauche",
	completed_maps = "<p align='center'><BV><B>Cartes complétées: %s</B></p></BV>",
	leaderboard = "Tableau des scores",
	position = "Position",
	username = "Pseudo",
	community = "Communauté",
	completed = "Cartes complétées",
	not_permed = "sans permissions",
	permed = "avec des permissions",
	points = "%d points",
	conversation_info = "<j>%s <bl>- @%s <vp>(%s, %s) %s\n<n><font size='10'>Started by <d>%s</d>. Dernier commentaire par <d>%s</d>. <d>%s</d> commentaire(s), <d>%s</d> non-lu(s).",
	map_info = "<p align='center'>Code de la carte: <bl>@%s</bl> <g>|</g> Auteur de la carte: <j>%s</j> <g>|</g> Status: <vp>%s, %s</vp> <g>|</g> Points: <vp>%s</vp>",
	permed_maps = "Maps ayant des permissions",
	ongoing_votations = "Votes en cours",
	archived_votations = "Votes archivés",
	open = "Ouvrir",
	not_archived = "non-archivée",
	archived = "archivée",
	delete = "<r><a href='event:%s'>[supprimer]</a> ",
	see_restore = "<vp><a href='event:%s'>[voir]</a> <a href='event:%s'>[restaurer]</a> ",
	no_comments = "Pas de commentaires.",
	deleted_by = "<r>[Message supprimé par %s]",
	dearchive = "inarchiver", -- pour ne plus l'archiver
	archive = "archive", -- pour archiver
	deperm = "enlever les permissions", -- pour enlever les permissions
	perm = "permissions", -- pour ajouter des permissions
	map_actions_staff = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Commentaire</j></a> <g>|</g> Votre  vote: %s <g>|</g> <vp><a href='event:%s'>[%s]</a> <a href='event:%s'>[%s]</a> <a href='event:%s'>[chargement]</a></p>",
	map_actions_user = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Commentaire</j></a></p>",
	load_from_thread = "<p align='center'><a href='event:load_custom'>Charger une carte personalisée</a></p>",
	write_comment = "Ecrivez votre commentaire en-dessous",
	write_map = "Ecrivez les codes de la carte en-dessous",

	-- Power names
	balloon = "Ballon",
	masterBalloon = "Maitre Ballon",
	bubble = "Bulle",
	fly = "Voler",
	snowball = "Boule de neige",
	speed = "Vitesse",
	teleport = "Teleportation",
	smallbox = "Petite boite",
	cloud = "Nuage",
	rip = "Tombe",
	choco = "Planche de chocolat",
}
