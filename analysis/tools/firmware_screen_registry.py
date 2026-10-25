"""Recover repeated, reviewed screen callback-registration stubs from raw Thumb bytes."""
from pathlib import Path
import json,struct,bisect
R=Path(__file__).resolve().parents[2];F=R/'analysis/firmware/colorfit-pulse-2';O=F/'deep-dive';b=(F/'extracted-891d18c1ed86/a.bin').read_bytes();BASE=0x1023000
H=lambda o:struct.unpack_from('<H',b,o)[0]
def literal(o):
 h=H(o)
 if h&0xf800!=0x4800:return None
 pool=((BASE+o+4)&~3)+(h&255)*4-BASE
 return struct.unpack_from('<I',b,pool)[0] if 0<=pool<len(b)-3 else None
rows=[]
for off in range(0,len(b)-48,2):
 if H(off)!=0xb510 or H(off+0x10)!=0x6081 or H(off+0x14)!=0x60c1:continue
 destroy=literal(off+0xe);create=literal(off+0x12)
 if not create or not destroy or not(create&1 and destroy&1):continue
 sid=None
 if literal(off+0x1c)==0x806abc and H(off+0x1e)&0xff00==0x2000:sid=H(off+0x1e)&255
 elif literal(off+0x1c)==0x806abc and H(off+0x1e)==0x8001:sid=1
 if sid is None:continue
 rows.append({'screen_id':sid,'stub':hex(BASE+off),'create':hex(create&~1),'destroy':hex(destroy&~1),'create_thumb_pointer':hex(create),'destroy_thumb_pointer':hex(destroy),'meaning':'pending callbacks stored at page-root +0xc (create), +0x8 (destroy), flag +0x20; screen ID stored to 0x00806abc'})
rows.sort(key=lambda r:r['screen_id'])
(O/'screen-registry.json').write_text(json.dumps(rows,indent=2)+'\n')
branches=json.loads((O/'branch-candidates.json').read_text());refs=json.loads((O/'string-code-references.json').read_text());prolog=[int(x,16) for x in json.loads((O/'function-prologue-candidates.json').read_text())]
for row in rows:
 a=int(row['create'],16);i=bisect.bisect_right(prolog,a);end=min(prolog[i] if i<len(prolog) else a+0x1000,a+0x1800)
 direct=[r['text'] for r in refs if a<=r['address']<end]
 row['create_nearest_next_prologue']=hex(end)
 row['direct_string_candidates']=list(dict.fromkeys(direct))
 row['direct_call_targets']=list(dict.fromkeys(hex(x['target']) for x in branches if a<=x['source']<end and x['op'] in ('bl','blx')))
 print(row['screen_id'],row['stub'],row['create'],row['destroy'],row['direct_string_candidates'][:5])
(O/'screen-registry.json').write_text(json.dumps(rows,indent=2)+'\n')
print('Recovered registration stubs',len(rows))
for target in [0x1044600,0x104a420]:
 print('callers',hex(target),[hex(x['source']) for x in branches if x['target']==target])
