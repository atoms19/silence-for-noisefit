"""Offline extraction using Android SDK's bundled baksmali; never uses network."""
from pathlib import Path
import subprocess, json, hashlib, zipfile
root=Path(__file__).resolve().parents[2]
sdk=Path('/home/atoms/Android/Sdk/cmdline-tools/latest/lib/external')
cp=':'.join(str(p) for p in sdk.rglob('*.jar') if any(x in str(p) for x in ['/smali/','/guava/','/jcommander/']))
for dex in sorted((root/'analysis/base').glob('classes*.dex')):
    out=root/'analysis/smali'/dex.stem
    print('Disassembling',dex.name,flush=True)
    subprocess.run(['java','-Xmx3g','-cp',cp,'com.android.tools.smali.baksmali.Main','disassemble',str(dex),'-o',str(out)],check=True)
records=[]
for p in [*root.glob('*.xapk'),*(root/'analysis/input').glob('*.apk')]:
    records.append({'file':str(p.relative_to(root)), 'size':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
(root/'analysis/hashes.json').write_text(json.dumps(records,indent=2)+'\n')
print('Complete',flush=True)
