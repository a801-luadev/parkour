import subprocess
import signal
import time

while True:
	try:
		print("Launching bot...")
		process = subprocess.Popen(["python3.7", "run.py"], universal_newlines=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
		try:
			while True:
				line = process.stdout.readline()
				if not line:
					break

				print(line, end="")
				if "Restarting transformice bot" == line.rstrip():
					break
		except KeyboardInterrupt:
			break
		finally:
			print("Stopping with CTRL+C...")
			process.send_signal(signal.SIGINT)
			try:
				process.wait(timeout=10.0)
			except subprocess.TimeoutExpired:
				print("Can not stop the process with CTRL+C. Killing it.")
				process.kill()

			time.sleep(3.0)
	except:
		print("Could not launch bot.")
		time.sleep(15.0)