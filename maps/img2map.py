import sys
from PIL import Image

if len(sys.argv) == 1:
    print("gib arg pleas")
    sys.exit()

convtable = {
    " ": (255,255,255),
    "X": (0,0,0),
    "o": (255,0,0),
    "B": (255,255,0),
    "R": (0,0,255),
    "C": (0,128,255),
    "r": (0,255,255),
    "g": (0,255,0),
    "G": (128,255,0),
    "l": (255,128,0)
}

print("Converting {} ...".format(sys.argv[1]))

filename = sys.argv[1][:-3]
extension = sys.argv[1][-3:]

if extension == "png":
    outarr = []
    im = Image.open(sys.argv[1]).convert("RGB")
    imwidth, imheight = im.size
    for y in range(imheight):
        str = ""
        for x in range(imwidth):
            px = im.getpixel((x, y))
            for c, t in convtable.items():
                if px == t:
                    str += c
                    break
        outarr.append(str)

    with open(filename + "lua", "w") as outfile:
        outfile.write("return {\n")
        for s in outarr:
            outfile.write("    \"" + s + "\",\n")
        outfile.write("}")
        
elif extension == "txt":
    inarr = []
    with open(sys.argv[1], "r") as infile:
        inarr = infile.read().splitlines()
    imwidth, imheight = len(inarr[0]), len(inarr)
    im = Image.new('RGB', (imwidth, imheight), (255,255,255))
    px = im.load()
    for y in range(imheight):
        for x in range(imwidth):
            px[x, y] = convtable[inarr[y][x]]
    im.save(filename + "png")

print("Done!")