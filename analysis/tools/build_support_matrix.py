"""Static dispatcher-to-handler cross references; no device or network access."""
from pathlib import Path
import re,json
R=Path(__file__).resolve().parents[2]
C=json.loads((R/'analysis/classes.json').read_text())
methodpat=re.compile(r'^\.method ([^\n]+)\n(.*?)^\.end method',re.M|re.S)
def methods(p):
 return {sig.split()[-1]:body for sig,body in methodpat.findall(p.read_text())}
families={
 'QueryAction':('QueryDeviceDataActions','QueryDeviceUnitsHandler'),
 'UpdateDeviceAction':('UpdateDeviceDataActions','UpdateDeviceUnitsHandler'),
 'UserActivityAction':('UserActivityDataActions','UserActivityHandler')}
labels=['Zh','Pro','CF2','Evolve2','Ryeex','DFuture','CommonPt','Topstep','Creek','NFH','NavPlus']
all_rows=[]
for family,(base,suffix) in families.items():
 mapping={}
 for rel in ['analysis/smali/classes5/com/noisefit/util/ServiceUtil.smali','analysis/smali/classes18/com/noisefit/receiver/service/ConnectionService.smali']:
  p=R/rel; src=p.read_text(); current=None
  for n,line in enumerate(src.splitlines(),1):
   if line.startswith('.method') or line.startswith('.end method'): current=None
   action=re.search(r'Lcom/noisefit_commans/interfaces/(?:device_data/|data/)?'+family+r'\$([^;$]+);',line)
   if action: current=action[1]
   call=re.search(r'/'+base+r';->([^\s]+)',line)
   if current and call:
    mapping[current]=(call[1],rel,n);current=None
 handlers={}
 for label in labels:
  matches=[(c,p) for c,p in C.items() if c.endswith('/'+label+suffix)]
  if matches:
   cls,rel=matches[0];handlers[label]=(rel,methods(R/rel))
 rows=[]
 for action,(sig,src,line) in sorted(mapping.items()):
  result={}
  for label,(rel,ms) in handlers.items():
   body=ms.get(sig)
   if body is None: result[label]={'status':'inherited'}
   else:
    useful=[x for x in body.splitlines() if 'invoke-' in x and 'Intrinsics;' not in x]
    status='code' if useful or any(x in body for x in ('iput','sput','throw ')) else 'empty'
    calls=sorted(set(re.findall(r'invoke-[^\n]*, (L[^;]+;->[^\s]+)',body)))
    vendor=[c for c in calls if not any(s in c for s in ('Lkotlin','Ljava/','Landroid/','Lcom/noisefit_commans','Lcom/google/gson','Lcom/noisefit_','Lcom/noisefit/','Lcom/common_protocol/'))]
    result[label]={'status':status,'source':rel,'vendor_calls':vendor}
  row={'family':family,'action':action,'signature':sig,'dispatch_source':src,'dispatch_line':line,'handlers':result};rows.append(row);all_rows.append(row)
 out='# '+family+' handler coverage\n\nGenerated from dispatcher references in `ServiceUtil` and `ConnectionService` and matching vendor method declarations. `code` means an override has calls or state changes; `empty` means the declared override has no such work; `inherited` means no matching override in that class. This is **not** verified device support. Conditional guards, asynchronous work, native behavior and capabilities still apply. Only actions successfully matched to dispatch calls are included.\n\n'
 out+='| Action | Handler signature | '+' | '.join(labels)+' | Dispatcher evidence |\n| --- | --- | '+' | '.join('---' for x in labels)+' | --- |\n'
 for row in rows:
  values=[]
  for label in labels:
   e=row['handlers'].get(label,{'status':'unresolved'});status=e['status']
   values.append(f'[{status}](../../{e["source"]})' if 'source' in e else status)
  out+='| '+row['action']+' | `'+row['signature']+'` | '+' | '.join(values)+f' | [source:{row["dispatch_line"]}](../../{row["dispatch_source"]}#L{row["dispatch_line"]}) |\n'
 (R/'docs/catalogs'/f'{family}-handler-coverage.md').write_text(out)
(R/'analysis/handler-coverage.json').write_text(json.dumps(all_rows,indent=2)+'\n')
print('Mapped actions:',len(all_rows))
