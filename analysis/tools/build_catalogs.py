"""Generate static evidence catalogs; reads local disassembly only, no network."""
from pathlib import Path
import re, json, collections, urllib.parse
ROOT=Path(__file__).resolve().parents[2]
DOC=ROOT/'docs/catalogs'
paths=sorted((ROOT/'analysis/smali').rglob('*.smali'))
classes={}; urls=[]; endpoints=[]; uuids=[]; package_counts=collections.Counter()
methods=re.compile(r'^\.method ([^\n]+)\n(.*?)^\.end method',re.M|re.S)
urlpat=re.compile(r'https?://[^\s"<>\\]+')
uuidpat=re.compile(r'(?i)\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b')
for p in paths:
    rel=str(p.relative_to(ROOT)); src=p.read_text(errors='replace'); cm=re.search(r'^\.class (?:[^\n]* )?(L[^;]+);',src,re.M)
    if not cm: continue
    cls=cm.group(1)[1:]; classes[cls]=rel
    package_counts['/'.join(cls.split('/')[:3])]+=1
    app=any(cls.startswith(x) for x in ('com/noisefit','com/common_protocol','com/noise/'))
    for n,line in enumerate(src.splitlines(),1):
        if 'const-string' in line or line.startswith('.field'):
            for url in urlpat.findall(line):
                urls.append({'url':url,'host':url.split('/')[2],'source':rel,'line':n,'app_owned_class':app})
            for u in uuidpat.findall(line):
                uuids.append({'uuid':u.lower(),'source':rel,'line':n})
    if app:
        for m in methods.finditer(src):
            sig,body=m.groups()
            verb=re.search(r'^    \.annotation runtime Lretrofit2/http/(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS);(.*?)^    \.end annotation',body,re.M|re.S)
            if verb:
                v=re.search(r'value = "([^"]*)"',verb.group(2))
                params=[]
                for a in re.finditer(r'\.annotation runtime Lretrofit2/http/(Url|Query|Path|Header|Body|Part|Field|QueryMap|HeaderMap|PartMap|FieldMap);(.*?)\.end annotation',body,re.S):
                    val=re.search(r'value = "([^"]*)"',a.group(2)); params.append(a.group(1)+(':'+val.group(1) if val else ''))
                types=re.findall(r'Lcom/(?:noisefit|noise)[^"\s;]*;',body)
                endpoints.append({'class':cls,'method':sig,'verb':verb.group(1),'path':v.group(1) if v else '<dynamic @Url>','parameters':params,'types':sorted(set(types)),'source':rel,'line':src.count('\n',0,m.start())+1})
for name,data in [('classes',classes),('url-literals',urls),('retrofit-endpoints',endpoints),('uuid-literals',uuids),('package-counts',dict(package_counts.most_common()))]:
    (ROOT/'analysis'/f'{name}.json').write_text(json.dumps(data,indent=2)+'\n')
def esc(v): return str(v).replace('|','\\|').replace('\n',' ')
def table(headers,rows):
    return '| '+' | '.join(headers)+' |\n| '+' | '.join('---' for h in headers)+' |\n'+''.join('| '+' | '.join(esc(c) for c in row)+' |\n' for row in rows)
def ref(e): return f"[{e['source'].split('/')[-1]}:{e['line']}](../../{e['source']}#L{e['line']})"
(DOC/'retrofit-endpoints.md').write_text('# Retrofit endpoint declarations\n\nGenerated from all app-owned Retrofit annotations. Dynamic `@Url` entries require call-site analysis; they do not each identify a unique API. Presence is static evidence, not proof of execution. All paths are inert text.\n\n'+table(['Class / method','HTTP','Declared path','Parameters','Evidence'],[(e['class'].replace('/','.')+'::'+e['method'].split('(')[0].split()[-1],e['verb'],'`'+e['path']+'`',', '.join(e['parameters']),ref(e)) for e in endpoints]))
appurls=[u for u in urls if u['app_owned_class']]
groups=collections.defaultdict(list)
for u in appurls: groups[u['url']].append(u)
(DOC/'app-url-literals.md').write_text('# App-owned URL literals\n\nUnique HTTP(S) literals from NoiseFit adapters, main app, shared module, and common protocol classes. Partial URLs remain partial. UI links, web pages, SDK keys in URL queries, examples and API paths can coexist here; this is an evidence inventory, not a verified server list. No URL was requested.\n\n'+table(['URL literal','Occurrences','First evidence'],[('`'+url.split('?')[0]+ ('?<query omitted>' if '?' in url else '')+'`',len(es),ref(es[0])) for url,es in sorted(groups.items())]))
ug=collections.defaultdict(list)
for u in uuids: ug[u['uuid']].append(u)
(DOC/'uuid-literals.md').write_text('# UUID literals\n\nAll exact UUID literals in DEX, including unrelated SDK and test constants. Do not assume every UUID is a wearable GATT UUID. See the protocol notes for interpreted values. Computed UUIDs are outside this catalog.\n\n'+table(['UUID','Occurrences','First evidence'],[(u,len(es),ref(es[0])) for u,es in sorted(ug.items())]))
shared=ROOT/'analysis/smali/classes5/com/noisefit_commans/interfaces'
families=['ConnectState','BindState','WatchBindState','QueryAction','QueryCallback','UpdateDeviceAction','UpdateDeviceDataCallback','UserActivityAction','UserActivityCallback']
text='# Band/app action and event catalog\n\nGenerated from shared action/callback subtype names and fields. An action declaration does not imply support on every model; base handlers often return without doing anything. These are application-level names, not on-wire opcodes.\n'
for family in families:
    files=sorted(shared.rglob(family+'$*.smali'))
    rows=[]
    for p in files:
        name=p.stem.split('$',1)[1]
        if '$' in name: continue
        src=p.read_text(); fields=re.findall(r'^\.field (?:private|public|protected)(?: final)? ([^\n]+)',src,re.M)
        fields=[f for f in fields if not any(x in f for x in ('INSTANCE:','$stable','CREATOR:'))]
        rel=str(p.relative_to(ROOT)); rows.append((name,'; '.join(fields),f'[{p.name}](../../{rel})'))
    text+='\n## '+family+f' ({len(rows)})\n\n'+table(['Name','Payload fields','Evidence'],rows)
(DOC/'band-actions.md').write_text(text)
(ROOT/'analysis/stats.json').write_text(json.dumps({'dex_classes':len(classes),'retrofit_methods':len(endpoints),'app_unique_url_literals':len(groups),'uuid_literals_unique':len(ug),'smali_files':len(paths)},indent=2)+'\n')
print((ROOT/'analysis/stats.json').read_text())
