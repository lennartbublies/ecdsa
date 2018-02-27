# Helper functions for conversion of test data to test on-board
import string

        
class Converter:
    def __init__(self):
        # dictionaries for fast lookups
        self.hexd = {'0000': '0','0001': '1','0010': '2','0011': '3',
                     '0100': '4','0101': '5','0110': '6','0111': '7',
                     '1000': '8','1001': '9','1010': 'A','1011': 'B',
                     '1100': 'C','1101': 'D','1110': 'E','1111': 'F'}
        self.bind = {'0': '0000','1': '0001','2': '0010','3': '0011',
                     '4': '0100','5': '0101','6': '0110','7': '0111',
                     '8': '1000','9': '1001','A': '1010','B': '1011',
                     'C': '1100','D': '1101','E': '1110','F': '1111',
                     'a': '1010','b': '1011','c': '1100','d': '1101',
                     'e': '1110','f': '1111'}

    def binstr2hex(self,key,padding=False):
        '''
            Converts bit string into hex
        '''
        old = "" + key
        if padding:
            old = "00000" + key
        out = ""
        if len(old)%4:
            print "Error: incompatible length " + str(len(old))
            return 0
        for i in range(len(old)/4):
            tmp = old[(i*4):((i+1)*4)]
            out += self.hexd[tmp]
        return out
        
    def hex2binstr(self,hex):
        '''
            Converts hex string to bin string.
        '''
        bin = ""
        for i in range(len(hex)):
            if hex[i] in "0123456789ABCDEFabcdef":
                bin += self.bind[hex[i]]
        return bin

    def format_hex(str):
        ''' 
            Delete non-hex characters, e.g. spaces
        '''
        out = ""
        for i in range(len(str)):
            if str[i] in "0123456789ABCDEF":
                out += str[i]
        return out
        
    def extract_and_format(self,tx):
        '''
            Extracts and transform tx data into key
            Input: "00000..000000XXXXX000"
        '''
        # chunk into array of bytes
        binbyte = []
        bytes = len(tx)/8
        for i in range(bytes):
            binbyte.append(tx[i*8:i*8+8]) 
        # reverse bytes byte-wise
        for i in range(bytes):
            binbyte[i] = binbyte[i][::-1]
        # "mask" last byte
        binbyte[bytes-1] = "00000" + binbyte[bytes-1][4:7]
        # reverse array byte-wise and build output string
        out_bit_str = ""
        #for i in xrange(bytes-1,0,-1):
        for i in range(bytes-1,-1,-1):
            out_bit_str += str(binbyte[i])
        return out_bit_str

    def convert(self,r,s):
        '''
            takes hex input and return converted result
        '''
        # r_bin = self.extract_and_format(self.hex2binstr(r))
        # s_bin = self.extract_and_format(self.hex2binstr(s))
        # return self.binstr2hex(r), self.binstr2hex(s)
        # print r
        r_binstr = self.hex2binstr(r)
        s_binstr = self.hex2binstr(s)
        # print r_binstr
        r_formatted = self.extract_and_format(r_binstr)
        s_formatted = self.extract_and_format(s_binstr)
        # print r_formatted
        r_new = self.binstr2hex(r_formatted)
        s_new = self.binstr2hex(s_formatted)
        # print r_new
        return r_new, s_new
        
    # def result_modification(key):
        # '''
            # Cut last 5 Bits and reverse byte-wise
        # '''
        # old = ""
        # for i in range(len(key)/8):
            # tmp = key[(i*8):((i+1)*8)]
            # old += tmp.reverse()
        # return old
 
# hex1 = "DB 17 D5 B2 D3 9F 28 EA 7E 6C 81 80 D9 2C 88 BE D8 8A 44 0B 0A 87 F4 4E E9 28 F3 98 BC C1 34 67 37 96 4D 02 C9 9D 58 C0 45 43" 
# hexi = "d88a440b0a7c1641d9459430e6b97ac5c1f9167909de389a303600"

# conv = Converter()
# r, s = conv.convert(hexi, hexi)

#tcase2_r = "010000010110100010010001010110110001011111010001000001011001101100110000000100000010110110001111110111010100010100010011111110100111011001011010101000101111101101101010"
#tcase2_s = "1011000011001010101100011101111111000001101011000000110100000000111010111101010011010000010000010000100101000100101100111100011011100001011010010100011011101011011"
#tcase2_m = "1100110100100010100100010010101011000110110010110110111111110101011101111000010001110000011111011010011111011010001011001111000110101001110010101100100010001100011"

#print extract_and_format(tcase2_r)
#print key2hex(tcase2_r)
#print key2hex(tcase2_s)
#print key2hex(tcase2_m)
