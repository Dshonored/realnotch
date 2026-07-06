from PIL import Image, ImageDraw
import os, math

ROOT = "/Users/alexanderbonal/realnotch"
LAYERS = f"{ROOT}/design/icon/layers"
ASSET  = f"{ROOT}/RealNotch/Assets.xcassets/AppIcon.appiconset"
os.makedirs(LAYERS, exist_ok=True)
os.makedirs(ASSET, exist_ok=True)

S = 1024
ACCENT = (10, 132, 255, 255)   # #0A84FF

def lerp(a, b, t): return tuple(int(a[i] + (b[i]-a[i])*t) for i in range(len(a)))

def background():
    # graphite radial gradient, light source upper-left
    img = Image.new("RGB", (S, S))
    px = img.load()
    c_hi, c_mid, c_lo = (52,52,62), (23,23,30), (10,10,13)
    cx, cy = S*0.30, S*0.22
    maxd = math.hypot(S, S)
    for y in range(S):
        for x in range(0, S, 1):
            d = math.hypot(x-cx, y-cy)/maxd  # 0..~1
            if d < 0.5:
                col = lerp(c_hi, c_mid, d/0.5)
            else:
                col = lerp(c_mid, c_lo, min(1,(d-0.5)/0.5))
            px[x, y] = col
    return img.convert("RGBA")

# notch geometry, shared so the hairline can hug its bottom edge
NW = int(S*0.44); NX0 = (S-NW)//2; NX1 = NX0+NW
NY0 = int(S*0.30); NH = int(S*0.235); NY1 = NY0+NH   # centered group, still top-ish

def notch_layer():
    img = Image.new("RGBA", (S, S), (0,0,0,0))
    d = ImageDraw.Draw(img)
    r = int(NW*0.30)
    d.rounded_rectangle([NX0,NY0,NX1,NY1], radius=r, fill=(8,8,12,255))
    d.rectangle([NX0, NY0, NX1, NY0+r], fill=(8,8,12,255))  # square top corners
    return img

def hairline_layer():
    # a tight accent sill just below the notch — reads as one mark, not a face
    img = Image.new("RGBA", (S, S), (0,0,0,0))
    d = ImageDraw.Draw(img)
    w = int(S*0.20); x0=(S-w)//2; x1=x0+w
    y = NY1 + int(S*0.045); h = int(S*0.026)
    d.rounded_rectangle([x0,y,x1,y+h], radius=h//2, fill=ACCENT)
    return img

print("rendering background…")
bg = background()
notch = notch_layer()
hair = hairline_layer()

bg.save(f"{LAYERS}/background.png")
notch.save(f"{LAYERS}/notch.png")
hair.save(f"{LAYERS}/hairline.png")

master = bg.copy()
master.alpha_composite(notch)
master.alpha_composite(hair)
master.save(f"{ROOT}/design/icon/icon-1024.png")

# macOS iconset sizes
sizes = [16,32,64,128,256,512,1024]
for s in sizes:
    master.resize((s,s), Image.LANCZOS).save(f"{ASSET}/icon_{s}.png")

# menu-bar template glyph (black notch silhouette, transparent) at 1x/2x/3x
def menubar(scale):
    w, h = 22*scale, 14*scale
    img = Image.new("RGBA",(w,h),(0,0,0,0))
    d = ImageDraw.Draw(img)
    r = int(w*0.30)
    d.rounded_rectangle([0,0,w-1,h-1], radius=r, fill=(0,0,0,255))
    d.rectangle([0,0,w-1,r], fill=(0,0,0,255))
    return img
os.makedirs(f"{ROOT}/design/icon/menubar", exist_ok=True)
for sc in (1,2,3):
    menubar(sc).save(f"{ROOT}/design/icon/menubar/notch{'' if sc==1 else '@'+str(sc)+'x'}.png")

print("done")
