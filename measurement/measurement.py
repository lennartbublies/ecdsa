# Measure ECDSA-Algorithm on FPGA via serial connection
#
# Leander Schulz, inf102143@fh-wedel.de
import time
import serial
import csv
import os
import string
import binascii

import converter

# Number of measurements
MEASUREMENTS = 1000
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
# create converter
conv = converter.Converter()
# enable debug mode
DEBUG = 0

def generate_message(M=M):
    '''
        Generates a B byte long string
        with leading zeros if M is not byte aligned
    '''
    if DEBUG:
        return "00CD06203260EEE9549351BD29733E7D1E2ED49D88"
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

def generate_keys(M=M):
    '''
        Generate two keys r and s.
    '''
    if DEBUG:
        r = "DB17D5B2D39F28EA7E6C8180D92C88BED88A440B0A".encode("hex")
        s = "87F44EE928F398BCC1346737964D02C99D58C04543".encode("hex")
        return r, s
    r = generate_message()
    s = generate_message()
    return r, s

def read_uart(ser,length=1):
    """
    Reading string from uart
     
    Args:
        ser (serial.Serial):  handle to uart

    Return readed string
    """
    out = ''
    
    # Wait until all chars are read
    # while ser.inWaiting() > 0:
        # out += ser.read(1)
    for i in range(length):
        out += ser.read(1)
        
    # if DEBUG:    
        # print "OUT:" + str(out.encode('hex'))
    
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
    ser.write(mode + message + '\r\n')

    # read signature from uart (42bytes)
    res = read_uart(ser,42)
    
    end_time = time.time()
    
    r_tmp = res[:len(res)/2]
    s_tmp = res[len(res)/2:]
    r_hex = r_tmp.encode('hex')
    s_hex = s_tmp.encode('hex')

    r, s = conv.convert(r_hex,s_hex)

    # return (r.encode('hex'), s.encode('hex')), (end_time-start_time)
    return r, s, (end_time-start_time)

def measure_verify(ser, message, (r, s)):
    '''
    Send message to sign to device and measure time.
    
    Args:
        ser (serial.Serial):  handle to uart
        message (string): message to verify
        signature (string): signature of message

    Return verify result and elapsed time
    '''
    # set mode to 'verify'
    mode = "FF".decode('hex')
    
    start_time = time.time()

    # send data
    ser.write(mode + r + s + message + '\r\n')

    # Reading signature from uart
    res = read_uart(ser)

    end_time = time.time()

    return res.encode("hex"), end_time-start_time

 
if __name__ == "__main__":
    # configure serial connection
    ser = serial.Serial(port='COM1',baudrate=9600,bytesize=8,parity='N',stopbits=1)
    
    # csv file output
    csv_str = "ID|Message|R|S|sign_time|verify_time|result,\n"
    
    # 
    sign_time_array = []
    verify_time_array = []
    
    for i in range(0, MEASUREMENTS):
        # Generate random hash as message and sign it by device
        message = generate_message()
        if DEBUG:
            print ""
            print message + "\n"
        
        #(r,s), sign_time = measure_sign(ser, message)
        r, s, sign_time = measure_sign(ser, message)
        
        if DEBUG:
            print "R: " + str(r) + " (" + str(len(r)) + ")"
            print "S: " + s + " (" + str(len(s)) + ")"

        # Verify signature
        result, verify_time = measure_verify(ser, message, (r,s))
        
        if result == "00":
            result = "False"
        elif result == "11":
            result = "True"
        
        if DEBUG:
            print ""
            print "sign_time:" + str(sign_time)
            print "result:" + str(result)
            print "verify_time:" + str(verify_time)
        
        sign_time_array.append(sign_time)
        verify_time_array.append(verify_time)
        
        csv_str += str(i) + "|" + message + "|" + \
                    r + "|" + s + "|" + \
                    str(sign_time) + "|" + \
                    str(verify_time) + "|" + \
                    str(result) + ",\n" 
        

    # calculate results
    sign_time_avg = sum(sign_time_array) / len(sign_time_array)
    verify_time_avg = sum(verify_time_array) / len(verify_time_array)
    print "Measured " + str(MEASUREMENTS) + " sign/verify combinations"
    print "Average sign time: " + str(sign_time_avg)
    print "Average verify time: " + str(verify_time_avg)
    
    # write to file
    file = open(CSV_FILE,"w")
    file.write(csv_str)
    file.close
