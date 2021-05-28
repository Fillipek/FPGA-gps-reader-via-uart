import pyftdi.serialext
import os

def cls():
    os.system('cls' if os.name=='nt' else 'clear')

brate = 115200
url='ftdi://ftdi:232:AQ00RVND/1'
port = pyftdi.serialext.serial_for_url(url, baudrate=brate, bytesize=8, stopbits=1, parity='N', xonxoff=False, rtscts=False)

class CurrentData:
	def __init__(self) -> None:
		self.UTCTime = ''
		self.Latitude = ''

	def __str__(self) -> str:
		return f'UTCTime: {self.UTCTime}\nLatitude: {self.Latitude}'

current_data = CurrentData()

def update_GPGGA_data(data):
	'''
	GPS Fixed Data: Time, Position and fix related data.
	'''
	# returned = f'UTCTime: {data[1]}\n'
	# returned += f'Latitude: {data[2]}\n'
	# returned += f'N/S Indicator: {data[3]}\n'
	# returned += f'Longitude: {data[4]}\n'
	# returned += f'E/W Indicator: {data[5]}\n'
	# returned += f'Position Fix Indicator: {data[6]}\n'
	# returned += f'Satellites Used: {data[7]}\n'
	# returned += f'HDOP: {data[8]}\n'
	# returned += f'MSLAltitude: {data[9]} meters\n'
	# returned += f'Units: {data[10]} meters\n'
	# returned += f'Geoidal Separation: {data[11]} meters\n'
	# returned += f'Units: {data[12]} meters\n'
	# returned += f'Age of Diff. Corr.: {data[13]} seconds\n'
	# returned += f'Checksum: {data[14]}\n'

	# return returned

	current_data.UTCTime = data[1]
	current_data.Latitude = data[2]
	
def print_GPRMC(data):
	'''
	GPS Minimum Navigation Information.
	'''
	hours = data[1][:2]
	minutes = data[1][2:4]
	seconds = data[1][4:6]
	print(f'Time: {hours}:{minutes}:{seconds}')
	print(f'Position: {data[3]} {data[4]}, {data[5]} {data[6]}')

def decode_and_print_gps(sentence: str) -> None:
	data = sentence.split(',')
	sentence_type = data[0]
	string_data = ''
	if sentence_type == '$GPGGA':
		update_GPGGA_data(data)
	elif sentence_type == '$GPGSA':
		pass
	elif sentence_type == '$GPGSV':
		pass
	elif sentence_type == '$GPRMC':
		pass
		#print_GPRMC(data)
	elif sentence_type == '$GPVTG':
		pass
	cls()
	print(string_data, end='')

print('Receiving at', brate)
sentence = ''

while True:
	byte = port.read(1)
	letter = byte.decode('utf-8')
	if letter == '$':
		sentence = '$'
	elif letter == '\n':
		sentence += letter
		decode_and_print_gps(sentence)
	else:
		sentence += letter
