"""Offline firmware analysis helpers. The ELF is an analyst-generated wrapper, not recovered symbols."""
from pathlib import Path
import struct,json,re,subprocess,hashlib,collections
R=Path(__file__).resolve().parents[2]
F=R/'analysis/firmware/colorfit-pulse-2';O=F/'deep-dive'
O.mkdir(exist_ok=True)
b=(F/'extracted-891d18c1ed86/a.bin').read_bytes();BASE=0x01023000
payload=b[:-48];offset=0x100
names=b'\0.text\0.symtab\0.strtab\0.shstrtab\0';strings=b'\0$t\0'
syms=b'\0'*16+struct.pack('<IIIBBH',1,BASE,0,0,0,1)
blob=bytearray(b'\0'*offset)+payload
while len(blob)%4:blob+=b'\0'
symoff=len(blob);blob+=syms;stroff=len(blob);blob+=strings;nameoff=len(blob);blob+=names
while len(blob)%4:blob+=b'\0'
shoff=len(blob);blob+=b'\0'*40
for vals in [(1,1,6,BASE,offset,len(payload),0,0,4,0),(7,2,0,0,symoff,len(syms),3,2,4,16),(15,3,0,0,stroff,len(strings),0,0,1,0),(23,3,0,0,nameoff,len(names),0,0,1,0)]:blob+=struct.pack('<10I',*vals)
ident=b'\x7fELF'+bytes([1,1,1])+b'\0'*9
blob[:52]=struct.pack('<16sHHIIIIIHHHHHH',ident,2,40,1,struct.unpack_from('<I',b,4)[0],0,shoff,0x05000000,52,0,0,40,5,4)
elf=O/'analyst-wrapper.elf';elf.write_bytes(blob)
with (O/'linear-thumb-disassembly.txt').open('w') as f:
 p=subprocess.run(['llvm-objdump','-d','--triple=thumbv7em-none-eabi','--mcpu=cortex-m4','--no-show-raw-insn','--print-imm-hex',str(elf)],stdout=f,stderr=subprocess.PIPE,text=True)
 (O/'disassembly-stderr.txt').write_text(p.stderr)
 if p.returncode:raise SystemExit(p.returncode)
print('ELF wrapper and linear Thumb disassembly written.',flush=True)
# Resolve PC-relative literal loads and ADR references against the local image.
import bisect
allstrings=json.loads((F/'a-bin-ascii-strings.json').read_text())
starts=[x['offset'] for x in allstrings]
def string_at(addr):
 off=addr-BASE;i=bisect.bisect_right(starts,off)-1
 if i>=0 and off<starts[i]+len(allstrings[i]['text']):
  s=allstrings[i];return {'string_offset':s['offset'],'string_address':hex(BASE+s['offset']),'text':s['text'],'substring_offset':off-s['offset']}
 return None
ins=[];byaddr={}
for line in (O/'linear-thumb-disassembly.txt').read_text().splitlines():
 m=re.match(r'^\s*([0-9a-f]+):\s+([a-z][a-z0-9.]*)\s*(.*)',line)
 if not m:continue
 addr=int(m[1],16);op=m[2];rest=m[3];operand=rest.split('@',1)[0].strip()
 d={'address':addr,'address_hex':hex(addr),'offset':addr-BASE,'op':op,'operands':operand,'text':line.strip()}
 ins.append(d);byaddr[addr]=d
branches=[];refs=[];prologs=[]
for d in ins:
 op=d['op'];a=d['address'];operand=d['operands'];line=d['text']
 if (op.startswith('push') and 'lr' in operand) or (op.startswith('stmdb') and 'sp!' in operand and 'lr' in operand):prologs.append(a)
 if op in ('bl','blx','b','b.w'):
  m=re.match(r'0x([0-9a-f]+)',operand)
  if m:branches.append({'source':a,'target':int(m[1],16),'op':op})
 target=None;literal=None
 if op in ('ldr','ldr.w') and '[pc' in operand:
  m=re.search(r'@ (0x[0-9a-f]+)',line)
  if m:
   literal=int(m[1],16);o=literal-BASE
   if 0<=o<=len(b)-4:target=struct.unpack_from('<I',b,o)[0]
 elif op in ('adr','adr.w'):
  m=re.search(r'#(-?0x[0-9a-f]+|\d+)',operand)
  if m:target=((a+4)&~3)+int(m[1],0)
 if target is not None:
  s=string_at(target)
  if s:refs.append({**d,**s,'target':hex(target),'literal_pool_address':hex(literal) if literal else None})
entries=set(prologs)|{x['target'] for x in branches if x['op'] in ('bl','blx') and BASE<=x['target']<BASE+len(payload)}
entries=sorted(entries)
def candidate_entry(a):
 # A nearby PUSH-LR boundary is stronger than an arbitrary linear disassembly target.
 i=bisect.bisect_right(prologs,a)-1
 return prologs[i] if i>=0 else None
for r in refs:
 e=candidate_entry(r['address']);r['nearest_prologue']=hex(e) if e is not None else None
 r['distance_from_prologue']=r['address']-e if e is not None else None
(O/'string-code-references.json').write_text(json.dumps(refs,indent=2)+'\n')
(O/'branch-candidates.json').write_text(json.dumps(branches,indent=2)+'\n')
(O/'function-prologue-candidates.json').write_text(json.dumps([hex(x) for x in prologs],indent=2)+'\n')
# Pointer occurrence index is data evidence, not proof of a code cross-reference.
ptrs=[]
for off in range(0,len(b)-3,4):
 v=struct.unpack_from('<I',b,off)[0];s=string_at(v)
 if s and not s['substring_offset']:ptrs.append({'offset':off,'address':hex(BASE+off),'target':hex(v),**s})
(O/'string-pointer-occurrences.json').write_text(json.dumps(ptrs,indent=2)+'\n')
summary={'image_base_assumption':hex(BASE),'elf_wrapper':'analyst-generated; no original symbols','linear_instructions':len(ins),'push_lr_candidates':len(prologs),'branch_candidates':len(branches),'resolved_string_load_candidates':len(refs),'exact_string_pointer_occurrences':len(ptrs),'warning':'Linear disassembly also interprets data as instructions. These inventories are leads; reviewed code paths are documented separately.'}
(O/'analysis-summary.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps(summary,indent=2))
for r in refs:
 if any(x in r['text'] for x in ['gui_task','sport_menu_deal','WATCH_NUM','menu_chose_index','glx_image_loader_load','check_res_version','page_id is null','glx_checkout_type']):
  print(r['address_hex'],r['nearest_prologue'],r['text'][:95],flush=True)
