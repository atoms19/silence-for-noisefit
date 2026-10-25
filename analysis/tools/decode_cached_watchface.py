"""Offline structural extraction of the supplied cached GLX watchface; no device writes."""
from pathlib import Path
import struct,json,hashlib
from PIL import Image,ImageDraw
R=Path(__file__).resolve().parents[2];src=R/'analysis/device-cache/watchface.zip';b=src.read_bytes();out=R/'analysis/firmware/colorfit-pulse-2/deep-dive/watchface';out.mkdir(exist_ok=True)
magic,jo,jl,io,il,do,dl=struct.unpack_from('<7I',b)
assert magic==0xffaa22 and do+4+dl==len(b)
cfg=json.loads(b[jo+4:jo+4+jl].rstrip(b'\0'));(out/'layout.json').write_text(json.dumps(cfg,indent=2)+'\n')
n=struct.unpack_from('<I',b,io+4)[0];assert il==4+n*16
rows=[];bank0,bank1=struct.unpack_from('<2I',b,do+4)
for i in range(n):
 ident,w,h,fmt,unk,off=struct.unpack_from('<4H2I',b,io+8+i*16)
 base=do+4+(bank0 if fmt==0 else bank1);start=base+off-(bank0 if fmt==0 else 0)
 # Raw offsets already include bank0; compressed offsets are relative to bank1.
 row=dict(id=ident,width=w,height=h,format=fmt,unknown=unk,relative_offset=off,file_offset=start)
 if fmt==0:
  raw=b[start:start+w*h*2];assert len(raw)==w*h*2
  for order in ('little','big'):
   pixels=[]
   for p in range(0,len(raw),2):
    v=int.from_bytes(raw[p:p+2],order);pixels.append((((v>>11)&31)*255//31,((v>>5)&63)*255//63,(v&31)*255//31))
   im=Image.new('RGB',(w,h));im.putdata(pixels);im.save(out/f'image-{ident:02d}-rgb565-{order}.png')
  row['raw_bytes']=len(raw)
 rows.append(row)
for i,row in enumerate(rows):
 if row['format']!=0:
  end=rows[i+1]['file_offset'] if i+1<len(rows) else len(b)
  row['encoded_length']=end-row['file_offset'];(out/f'image-{row["id"]:02d}-encoded.bin').write_bytes(b[row['file_offset']:end])
report=dict(source=str(src.relative_to(R)),sha256=hashlib.sha256(b).hexdigest(),magic=hex(magic),header_relative_origin=4,json_offset=jo+4,json_length=jl,index_offset=io+4,index_length=il,data_offset=do+4,data_length=dl,raw_bank_offset=bank0,compressed_bank_offset=bank1,image_count=n,images=rows,warning='Both RGB565 byte orders retained for review; big-endian visually confirmed in docs. Format 1 pixel encoding remains unresolved.')
(out/'structure.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:v for k,v in report.items() if k!='images'},indent=2))
