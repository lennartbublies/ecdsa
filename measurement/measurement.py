import time
import serial
import csv

# Number of measurements
MEASUREMENTS = 1
CSV_FILE = "measurements.csv"

def read_uart(ser):
    """
    Reading string from uart
     
    Args:
        ser (serial.Serial):  handle to uart

    Return readed string
    """
		out = ''
        # Wait until all chars are readed
		while ser.inWaiting() > 0:
			out += ser.read(1)
		
        return out

def measure_sign(ser, message):
    """
    Send message to sign to device and measure time.
    
    Args:
        ser (serial.Serial):  handle to uart
        message (string): message to sign
    
    Return signature and elapsed time
    """
    mode = 0
    start_time = time.time()

    # Send data to device
    ser.write(mode + '\r\n')
    ser.write(message + '\r\n')

    # Reading signature from uart
    r = read_uart(ser)
    s = read_uart(ser)

    end_time = time.time()

    return (r, s), end_time-start_time

def measure_verify(ser, message, (r, s)):
    """
    Send message to sign to device and measure time.
    
    Args:
        ser (serial.Serial):  handle to uart
        message (string): message to verify
        signature (string): signature of message
    
    Return verify result and elapsed time
    """
    mode = 1
    start_time = time.time()

    ser.write(mode + '\r\n')
    ser.write(message + '\r\n')
    ser.write(r + '\r\n')
    ser.write(s + '\r\n')
    
    # Reading signature from uart
    res = read_uart(ser)
    
    end_time = time.time()
    
    return res, end_time-start_time
    
# Configure the serial connections
ser = serial.Serial(
	port='/dev/ttyUSB1',
	baudrate=9600,
	parity=serial.PARITY_ODD,
	stopbits=serial.STOPBITS_TWO,
	bytesize=serial.SEVENBITS
)

# Try to open UART connection
ser.open()
ser.isOpen():

for i in range(0, MEASUREMENTS):
    # -- SIGN -----------------------------------

    # Generate random hash as message and sign it by device
    message = ''.join(random.choice(string.ascii_uppercase + string.digits) for _ in range(N))
    (r,s), sign_time = measure_sign(ser, message)

    # Let's wait some time before verify
    time.sleep(1)

    # Verify signature
    result, verify_time = measure_verify(ser, message, (r,s))

    # Store results
    with open(CSV_FILE, 'wb') as csvfile:
        writer = csv.writer(csvfile, delimiter=' ', quotechar='|', quoting=csv.QUOTE_MINIMAL)
        writer.writerow([i, r, s, sign_time, result, verify_time])    
