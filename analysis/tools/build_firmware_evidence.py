"""Build bounded evidence for reviewed Pulse 2 code paths, without executing firmware."""
from pathlib import Path
import json,struct,subprocess,hashlib
R=Path(__file__).resolve().parents[2];F=R/'analysis/firmware/colorfit-pulse-2';O=F/'deep-dive';b=(F/'extracted-891d18c1ed86/a.bin').read_bytes();B=0x1023000
ranges={
'gui-task':(0x1079efc,0x107a014),'page-root-and-callbacks':(0x1076238,0x1076290),
'window-constructor':(0x1072e98,0x1072f02),'template-copy':(0x1072d80,0x1072dc0),
'resource-init':(0x1071e7c,0x1071f44),'resource-version-check':(0x1057964,0x1057ac0),
'watchface-node-parser':(0x1044600,0x104a420),'watchface-head-parser':(0x104a420,0x104a45c),
'watchface-build':(0x1086958,0x1086a34),'json-section-walk':(0x106e2d2,0x106e35c),
'pairing-create':(0x10912cc,0x10913c0),'pairing-qr':(0x1092fd4,0x10930fc),
'music-create':(0x108bc6c,0x108bcb4),'music-update':(0x108be4c,0x108bf20),
'factory-create':(0x1067e48,0x1067fe4),'five-page-menu':(0x104bfe4,0x104c1a8),
'resource-error-screen':(0x1098ac4,0x1098bdc),'sports-summary':(0x10a6ccc,0x10a6da0),
'ota-header-dispatch':(0x10a88f8,0x10a8c50),'task-create':(0x10adb10,0x10adb60),
'seven-page-viewer':(0x1088678,0x10889fc),'widget-watchface-build':(0x1086948,0x1086a34)}
E=O/'evidence';E.mkdir(exist_ok=True)
for name,(lo,hi) in ranges.items():
 text=subprocess.check_output(['python3',str(R/'analysis/tools/fw_view.py'),f'{lo:x}:{hi:x}'],text=True)
 (E/(name+'.txt')).write_text(f'Analyst-selected runtime range {lo:#010x}..{hi:#010x}; file offset = address - {B:#010x}.\nGenerated from mixed code/data linear disassembly. Literal pools are data, not executed instructions.\n\n'+text)
refs=json.loads((O/'string-code-references.json').read_text());keys=[]
for r in refs:
 if 0x1044600<=r['address']<0x104a420 and r['text'] not in [v['text'] for v in keys]:keys.append(dict(address=hex(r['address']),text=r['text']))
(O/'watchface-parser-keys.json').write_text(json.dumps(keys,indent=2)+'\n')
tasks=[]
for a in range(0x10bf628,0x10bf6b8,16):
 entry,name,stack,priority=struct.unpack_from('<4I',b,a-B);n=name-B
 tasks.append(dict(descriptor=hex(a),entry=hex(entry&~1),thumb_pointer=hex(entry),name=b[n:b.index(b'\0',n)].decode(),stack_depth_argument=stack,priority_argument=priority))
(O/'task-descriptors.json').write_text(json.dumps(tasks,indent=2)+'\n')
report=dict(binary_sha256=hashlib.sha256(b).hexdigest(),image_base=hex(B),image_length=len(b),footer_offset=hex(len(b)-48),reviewed_ranges={n:[hex(x) for x in r] for n,r in ranges.items()},validation=dict(task_descriptors=9,screen_registration_stubs=len(json.loads((O/'screen-registry.json').read_text())),watchface_image_count=51),limitations=['Addresses based on inferred load base; no debugger confirmation.','Linear disassembly mixes instructions and data.','No symbols, runtime traces, resource packs, bootloader dump, or complete flash image.'])
(O/'reviewed-evidence.json').write_text(json.dumps(report,indent=2)+'\n');print('Saved',len(ranges),'bounded evidence excerpts,',len(keys),'unique watchface string candidates,',len(tasks),'task descriptors')
