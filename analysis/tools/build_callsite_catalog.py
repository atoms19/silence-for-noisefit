"""Offline URL and Retrofit call co-occurrence index, explicitly not full dataflow."""
from pathlib import Path
import json,re,collections
R=Path(__file__).resolve().parents[2]
C=json.loads((R/'analysis/classes.json').read_text());E=json.loads((R/'analysis/retrofit-endpoints.json').read_text())
lookup={(e['class'],e['method'].split()[-1]):e for e in E}
rows=[]
for cls,rel in C.items():
 if not any(cls.startswith(x) for x in ['com/noisefit','com/common_protocol','com/noise/']):continue
 p=R/rel;src=p.read_text()
 for m in re.finditer(r'^\.method ([^\n]+)\n(.*?)^\.end method',src,re.M|re.S):
  sig,body=m.groups();urls=sorted(set(re.findall(r'const-string(?:/jumbo)? \w+, "(https?://[^"\n]+)"',body)))
  if not urls:continue
  for call in re.finditer(r'invoke-(?:interface|virtual)(?:/range)? [^\n]*, L([^;]+);->([^\s]+)',body):
   e=lookup.get((call[1],call[2]))
   if e is None or e['path']!='<dynamic @Url>':continue
   rows.append({'verb':e['verb'],'url_candidates':urls,'source':rel,'line':src.count('\n',0,m.start())+body.count('\n',0,call.start())+2,'caller_method':sig,'target':e['class']+'->'+call[2]})
(R/'analysis/dynamic-url-callsites.json').write_text(json.dumps(rows,indent=2)+'\n')
out='# Dynamic URL call sites\n\nThis catalog joins dynamic Retrofit calls to HTTP(S) literal **candidates in the same caller method**. It is a co-occurrence index, not control-flow or register-value proof. Single-candidate rows are useful research leads; concatenation, branch choices and arguments must be read in the linked source. Query values are omitted here. Some dynamically supplied URLs have no local literal and are absent. No requests were sent.\n\n| HTTP | URL candidates | Caller | Evidence |\n| --- | --- | --- | --- |\n'
for e in rows:
 urls='<br>'.join('`'+u.split('?')[0]+ ('?<query omitted>' if '?' in u else '')+'`' for u in e['url_candidates'])
 out+=f"| {e['verb']} | {urls} | `{e['caller_method'].split('(')[0].split()[-1]}` | [{e['source'].split('/')[-1]}:{e['line']}](../../{e['source']}#L{e['line']}) |\n"
(R/'docs/catalogs/dynamic-url-callsites.md').write_text(out)
print('Dynamic URL call sites',len(rows))
