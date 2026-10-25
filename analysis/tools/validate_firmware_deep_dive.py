"""Check independent artifact integrity and bounds for offline firmware research."""
from pathlib import Path
import hashlib,json,struct,zipfile
from PIL import Image
R=Path(__file__).resolve().parents[2];F=R/'analysis/firmware/colorfit-pulse-2';O=F/'deep-dive';errors=[];checks=[]
def check(ok,label):
 (checks if ok else errors).append(label)
b=(F/'extracted-891d18c1ed86/a.bin').read_bytes();B=0x1023000
check(hashlib.sha256(b).hexdigest()=='02f3c2637766116c44918b4214c2e872a26f54416037b4fe74d35a28a13c06fd','a.bin matches recovered artifact SHA-256')
with zipfile.ZipFile(F/'ColorFitPulse2V26diffa.zip') as z:
 check(z.namelist()==['a.bin'] and z.testzip() is None and z.read('a.bin')==b,'ZIP CRC, sole member and extracted binary match')
check(struct.unpack_from('<2I',b)==(0x840000,0x1023389),'vector mapping agrees with inferred image base')
check(struct.unpack_from('<I',b,len(b)-44)[0]==len(b)-48,'footer image-length field agrees with footer boundary')
rows=json.loads((O/'screen-registry.json').read_text());check(len(rows)==40 and len({x['screen_id'] for x in rows})==40,'40 distinct recovered screen IDs')
for row in rows:
 o=int(row['stub'],16)-B
 check(struct.unpack_from('<H',b,o)[0]==0xb510 and struct.unpack_from('<H',b,o+16)[0]==0x6081 and struct.unpack_from('<H',b,o+20)[0]==0x60c1,f'screen {row["screen_id"]}: raw registration stores remain present')
 for role in ('create','destroy'):
  a=int(row[role],16);ptr=int(row[role+'_thumb_pointer'],16)
  check(B<=a<B+len(b)-48 and a%2==0 and ptr==a|1,f'screen {row["screen_id"]}: {role} pointer alignment and image bounds')
tasks=json.loads((O/'task-descriptors.json').read_text());check(len(tasks)==9,'nine task descriptors')
for t in tasks:
 entry,name,stack,priority=struct.unpack_from('<4I',b,int(t['descriptor'],16)-B);n=name-B
 check(B<=entry-1<B+len(b) and entry&1 and 0<=n<len(b) and b[n:b.index(b'\0',n)].decode()==t['name'] and stack==t['stack_depth_argument'] and priority==t['priority_argument'],t['name']+': descriptor matches raw bytes')
w=(R/'analysis/device-cache/watchface.zip').read_bytes();d=json.loads((O/'watchface/structure.json').read_text());check(hashlib.sha256(w).hexdigest()==d['sha256']=='e414233eb7ce8559f393b724f27298683091372a7a0aaef97bf83a77c8cc3bb0','cached watchface input hash')
check(d['data_offset']+d['data_length']==len(w) and d['index_length']==4+16*51 and len(d['images'])==51,'watchface section lengths and record count agree')
for im in d['images']:
 start=im['file_offset'];size=im.get('raw_bytes',im.get('encoded_length'))
 check(0<=start<=start+size<=len(w),f'image {im["id"]}: payload range inside input')
 if im['format']==0:
  check(size==im['width']*im['height']*2,f'image {im["id"]}: RGB565 byte count matches dimensions')
  png=Image.open(O/'watchface'/f'image-{im["id"]:02d}-rgb565-big.png');check(png.size==(im['width'],im['height']),f'image {im["id"]}: decoded PNG dimensions')
  for x,y in ((0,0),(im['width']//2,im['height']//2),(im['width']-1,im['height']-1)):
   v=int.from_bytes(w[start+2*(y*im['width']+x):start+2*(y*im['width']+x)+2],'big');rgb=(((v>>11)&31)*255//31,((v>>5)&63)*255//63,(v&31)*255//31)
   check(png.getpixel((x,y))==rgb,f'image {im["id"]}: pixel {x},{y} agrees with source RGB565')
for src,dst in [('image-00-rgb565-big.png','cached-background.png'),('image-01-rgb565-big.png','cached-preview.png')]:
 check((O/'watchface'/src).read_bytes()==(R/'docs/firmware/assets'/dst).read_bytes(),dst+': documentation image matches decoded artifact')
report=dict(status='pass' if not errors else 'fail',checks_passed=len(checks),errors=errors,notes=['Structural validation does not establish live device behavior, signatures, compatibility or complete screen identities.'])
(O/'validation.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2));raise SystemExit(bool(errors))
