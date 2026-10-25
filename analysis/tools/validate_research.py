"""Validate research artifacts and local Markdown references without network access."""
from pathlib import Path
import re,json,zipfile
R=Path(__file__).resolve().parents[2]
errors=[];links=0;mds=list((R/'docs').rglob('*.md'))
for p in mds:
    for m in re.finditer(r'\]\(([^\n]+?)\)',p.read_text()):
        target=m[1]
        if target.startswith(('http','mailto:','#')):continue
        path,_,frag=target.partition('#');q=p.parent/path;links+=1
        if not q.exists():errors.append(f'{p}: missing {target}')
        elif frag.startswith('L') and q.is_file() and int(frag[1:])>len(q.read_text(errors='replace').splitlines()):
            errors.append(f'{p}: invalid line {target}')
dex=list((R/'analysis/base').glob('classes*.dex'))
smali=list((R/'analysis/smali').rglob('*.smali'))
for d in dex:
    if not (R/'analysis/smali'/d.stem).is_dir():errors.append('Missing disassembly '+d.name)
if len(dex)!=18:errors.append('Expected 18 DEX files')
if 'Complete' not in (R/'analysis/disassembly.log').read_text():errors.append('Disassembly log incomplete')
with zipfile.ZipFile(R/'analysis/input/com.noisefit.apk') as z:
    declared=[x for x in z.namelist() if re.fullmatch(r'classes\d*\.dex',x)]
    if sorted(declared)!=sorted(x.name for x in dex):errors.append('DEX inventory differs from APK')
stats=json.loads((R/'analysis/stats.json').read_text())
if stats['smali_files']!=len(smali):errors.append('Smali count differs')
report={'status':'pass' if not errors else 'fail','markdown_files':len(mds),'local_links_checked':links,'dex_inputs':len(dex),'smali_files':len(smali),'stats':stats,'errors':errors}
(R/'analysis/validation.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
raise SystemExit(bool(errors))
