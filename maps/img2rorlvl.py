import sys
import binascii
from PIL import Image

if len(sys.argv) != 2:
    print("gib arg pleas")
    sys.exit()

convtable = {
    # " ":
    (255,255,255): [],
    # "X":
    (0,0,0):       [0],
    # "o":
    (255,0,0):     [1],
    # "B":
    (255,255,0):   [3],
    # "R":
    (0,0,255):     [2, 1],
    # "C":
    (0,128,255):   [2, 0],
    # "r":
    (0,255,255):   [2],
    # "g":
    (0,255,0):     [1],
    # "G":
    (128,255,0):   [0],
    # "l":
    (255,128,0):   [5]
}

print("Converting {} ...".format(sys.argv[1]))

filename = sys.argv[1][:-4]
extension = sys.argv[1][-4:]

if extension == ".png":
    colarr = [[], [], [], [], [], [], []]
    im = Image.open(sys.argv[1]).convert("RGB")
    imwidth, imheight = im.size
    for y in range(imheight):
        for x in range(imwidth):
            px = im.getpixel((x, y))
            for c, t in convtable.items():
                if px == c:
                    for i in t:
                        colarr[i].append((x, y))
                    break

    with open(filename + ".rorlvl", "wb") as outfile:
        outfile.write(binascii.unhexlify("726F726C766C00000000000000302E312E31"))
        outfile.write(filename.encode("utf8"))
        outfile.write(binascii.unhexlify("000000000000000000007D0096000100"))
        count = 0
        for t in colarr:
            if len(t) > 0:
                count+=1
        outfile.write((count).to_bytes(1, byteorder='little', signed=False))
        outfile.write(binascii.unhexlify("00003A6E6F7468696E673A000000004C61796572203100416E6369656E742056616C6C6579000C0000000000"))
        for i in range(len(colarr)):
            t = colarr[i]
            count = len(t)
            if count > 0:
                outfile.write((i).to_bytes(1, byteorder='little', signed=False))
                outfile.write((count).to_bytes(4, byteorder='little', signed=False))
                for (x, y) in t:
                    outfile.write((x*2).to_bytes(2, byteorder='little', signed=True))
                    outfile.write((y*2).to_bytes(2, byteorder='little', signed=True))
print("Done!")