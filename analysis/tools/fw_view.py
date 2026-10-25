"""Print an address range from offline linear Thumb disassembly with resolved string loads."""
from pathlib import Path
import json,re,sys,struct
R=Path(__file__).resolve().parents[2];F=R/'analysis/firmware/colorfit-pulse-2';O=F/'deep-dive'
refs={r['address']:r for r in json.loads((O/'string-code-references.json').read_text())};b=(F/'extracted-891d18c1ed86/a.bin').read_bytes();BASE=0x1023000
ranges=[tuple(int(x,16) for x in s.split(':')) for s in sys.argv[1:]]
for line in (O/'linear-thumb-disassembly.txt').read_text().splitlines():
 m=re.match(r'^\s*([0-9a-f]+):',line)
 if not m:continue
 a=int(m[1],16)
 if not any(lo<=a<hi for lo,hi in ranges):continue
 r=refs.get(a)
 if r:line+='  ; STRING '+repr(r['text'])
 elif '\tldr' in line and '[pc' in line:
  t=re.search(r'@ (0x[0-9a-f]+)',line)
  if t:
   o=int(t[1],16)-BASE
   if 0<=o<=len(b)-4:line+='  ; WORD '+hex(struct.unpack_from('<I',b,o)[0])
 print(line)
