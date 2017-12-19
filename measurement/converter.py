# Helper functions for conversion of test data to test on-board
import string

hexm = {'0000': '0',
        '0001': '1',
        '0010': '2',
        '0011': '3',
        '0100': '4',
        '0101': '5',
        '0110': '6',
        '0111': '7',
        '1000': '8',
        '1001': '9',
        '1010': 'A',
        '1011': 'B',
        '1100': 'C',
        '1101': 'D',
        '1110': 'E',
        '1111': 'F'}

def key2hex(key):
    '''
        Converts 163 bit string into hex
    '''
    old = "00000" + key
    out = ""
    if len(old)%4:
        print "Error: incompatible length " + str(len(old))
        return 0
    for i in range(len(old)/4):
        tmp = old[(i*4):((i+1)*4)]
        out += hexm[tmp]
    return out
    
def result_modification(key):
    '''
        Cut last 5 Bits and reverse byte-wise
    '''
    old = ""
    for i in range(len(key)/8):
        tmp = key[(i*8):((i+1)*8)]
        old += tmp.reverse()
    return old
    
    
tcase2_r = "0100000101101000100100010101101100010111110100010000010110011011001100000001000000101101100011111101110101000101000100111111101001110110010110101010001011111011011"
tcase2_s = "1011000011001010101100011101111111000001101011000000110100000000111010111101010011010000010000010000100101000100101100111100011011100001011010010100011011101011011"
tcase2_m = "1100110100100010100100010010101011000110110010110110111111110101011101111000010001110000011111011010011111011010001011001111000110101001110010101100100010001100011"

print key2hex(tcase2_r)
print key2hex(tcase2_s)
print key2hex(tcase2_m)
