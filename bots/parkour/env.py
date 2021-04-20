import os


class env:
	proxy_token = os.getenv("PROXY_TOKEN")
	proxy_ip = os.getenv("PROXY_IP")
	proxy_port = os.getenv("PROXY_PORT")

	password = os.getenv("PARKOUR_PASSWORD")
	heroku_token = os.getenv("HEROKU_TOKEN")

	class webhooks:
		mod_chat = os.getenv("MOD_CHAT_WEBHOOK")
		mod_chat_announcement = os.getenv("MOD_CHAT_ANNOUNCEMENT_WEBHOOK")
		mapper_chat = os.getenv("MAPPER_CHAT_WEBHOOK")
		mapper_chat_announcement = os.getenv("MAPPER_CHAT_ANNOUNCEMENT_WEBHOOK")

		weekly_record = os.getenv("WEEKLY_RECORD_WEBHOOK")

		game_logs = os.getenv("GAME_LOGS_WEBHOOK")
		suspects = os.getenv("SUSPECT_WEBHOOK")
		suspects2 = os.getenv("SUSPECT2_WEBHOOK")
		sanctions = os.getenv("SANCTIONS_WEBHOOK")
		ranks = os.getenv("RANKS_WEBHOOK")
		join = os.getenv("JOIN_WEBHOOK")
		private = os.getenv("BOT_CRASH_WEBHOOK")
		default = os.getenv("DEFAULT_WEBHOOK")

		records = os.getenv("RECORDS_WEBHOOK")
		parkour_records = os.getenv("PARKOUR_RECORDS_WEBHOOK")
		record_badges = os.getenv("RECORD_BADGES_WEBHOOK")
		record_suspects = os.getenv("RECORD_SUSPECTS")

		suspects_norecord = os.getenv("SUSPECTS_NORECORD_WEBHOOK")
		game_victory = os.getenv("GAME_VICTORY_WEBHOOK")
		game_title = os.getenv("GAME_TITLE")

		commands = os.getenv("COMMAND_LOG_WEBHOOK")

		tribe = os.getenv("TRIBE_WEBHOOK")

	report_channel = 773630094257815572