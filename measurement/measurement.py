import time
import serial
import csv
import os
import string
import binascii

# Number of measurements
MEASUREMENTS = 1
# ECDSA Key Length
M = 163
# Output file path
CSV_FILE = "vhdl_measurements.csv"
# Bytes (B) and Byte-Alignment (A) of Key
if (M % 8) > 0:
    Aligned = False
    Bytes = (M/8)+1
else:
    Aligned = True
    Bytes = (M/8)

def generate_message(M=M):
    '''
        Generates a B byte long string
        with leading zeros if M is not byte aligned
    '''
    rand = binascii.b2a_hex(os.urandom(Bytes))
    rand = bin(int(rand,16))[2:].zfill(Bytes*8)
    if not Aligned:
        # fill leading bits with zero
        tmp = rand[:M]
        rand = tmp.zfill(Bytes*8)
    rand = '%08X' % int(rand, 2)
    while len(rand) < (2*Bytes):
        rand = "0" + rand
    return rand

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
    print "OUT:" + str(out.encode('hex'))
    return out

def measure_sign(ser, message):
    """
    Send message to sign to device and measure time.
    
    Args:
        ser (serial.Serial):  handle to uart
        message (string): message to sign

    Return signature and elapsed time
    """
    mode = '\0'
    start_time = time.time()

    # Send data to device
    #ser.write(mode)# + '\r\n')
    ser.write(mode + '\r\n')
    #ser.write(message)# + '\r\n')
    ser.write(message + '\r\n')
    #ser.flush()

    # Reading signature from uart
    r = read_uart(ser)
    s = read_uart(ser)

    end_time = time.time()

    return (r.encode('hex'), s.encode('hex')), (end_time-start_time)

def measure_verify(ser, message, (r, s)):
    """
    Send message to sign to device and measure time.
    
    Args:
        ser (serial.Serial):  handle to uart
        message (string): message to verify
        signature (string): signature of message

    Return verify result and elapsed time
    """
    mode = "FF".decode('hex')
    start_time = time.time()

    ser.write(mode + '\r\n')
    ser.write(r + '\r\n')
    ser.write(s + '\r\n')
    ser.write(message + '\r\n')

    # Reading signature from uart
    res = read_uart(ser)

    end_time = time.time()
    print res

    return res, end_time-start_time

# configure serial connection
ser = serial.Serial(port='COM1',baudrate=9600,bytesize=8,parity='N',stopbits=1)

for i in range(0, MEASUREMENTS):
    # Generate random hash as message and sign it by device
    message = generate_message()
    print message

    (r,s), sign_time = measure_sign(ser, message)

    print len(r)

    # wait before verify
    time.sleep(1)

    # Verify signature
    result, verify_time = measure_verify(ser, message, (r,s))

    print "r:" + str(r)
    print "s:" + str(s)
    print "sign_time:" + str(sign_time)
    print "result:" + str(result.encode('hex'))
    print "verify_time:" + str(verify_time)

    # save to csvfile
#    with open(CSV_FILE, 'wb') as csvfile:
#        writer = csv.writer(csvfile, delimiter=' ', quotechar='|', quoting=csv.QUOTE_MINIMAL)
#        #writer.writerow(["ID", "R", "S", "VTIME", "V", "VTIME"])
#        writer.writerow([i, r, s, sign_time, result, verify_time])
