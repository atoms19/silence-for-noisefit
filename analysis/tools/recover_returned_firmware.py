"""Download the explicitly returned Pulse 2 package, then inventory/extract without execution.
Run from a network-enabled terminal. Uses no account token and sends no firmware-check request.
"""
from pathlib import Path, PurePosixPath
import json,hashlib,subprocess,urllib.parse,zipfile,stat
R=Path(__file__).resolve().parents[2]
response=R/'analysis/backend-check/ota-required-true/response-body.txt'
data=json.loads(response.read_text())['data']
url=data['url'];u=urllib.parse.urlsplit(url)
if u.scheme!='https' or u.hostname!='images.gonoise.com' or not u.path.startswith('/firmwares/production/colorfit_pulse_2/'):
    raise SystemExit('Returned URL does not match the expected HTTPS Pulse 2 firmware path.')
name=PurePosixPath(u.path).name
if not name or name in ('.','..'):raise SystemExit('Invalid package filename')
out=R/'analysis/firmware/colorfit-pulse-2';out.mkdir(parents=True,exist_ok=True)
package=out/name
if not package.exists():
    partial=out/(name+'.part')
    command=['curl','--fail','--silent','--show-error','--location','--max-redirs','3','--proto','=https','--proto-redir','=https','--connect-timeout','15','--max-time','300','--retry','0','--max-filesize',str(256*1024*1024),'--dump-header',str(out/'download-headers.txt'),'--output',str(partial),url]
    print('Downloading firmware package from returned URL (no account token).',flush=True)
    result=subprocess.run(command,capture_output=True,text=True)
    (out/'download-status.json').write_text(json.dumps({'curl_exit_code':result.returncode,'stderr':result.stderr,'url_host':u.hostname,'url_path':u.path},indent=2)+'\n')
    if result.returncode:
        print(result.stderr.strip(),flush=True)
        raise SystemExit(result.returncode)
    partial.replace(package)
else:print('Using existing local package; no download request.',flush=True)
blob=package.read_bytes();digest=hashlib.sha256(blob).hexdigest()
report={'file':str(package.relative_to(R)),'size':len(blob),'sha256':digest,'source_host':u.hostname,'source_path':u.path,'returned_version':data.get('version'),'returned_version_name':data.get('version_name'),'request_isOTARequired':True,'first_64_bytes_hex':blob[:64].hex(),'zip':zipfile.is_zipfile(package),'entries':[],'validation_limit':'ZIP CRC and SHA-256 are not proof of publisher authenticity, firmware compatibility, or image signing.'}
if report['zip']:
    extract=out/('extracted-'+digest[:12]);members=[]
    with zipfile.ZipFile(package) as archive:
        entries=archive.infolist()
        if len(entries)>10000 or sum(x.file_size for x in entries)>512*1024*1024:raise SystemExit('Archive exceeds extraction limits; inspect manually.')
        for entry in entries:
            path=PurePosixPath(entry.filename)
            if path.is_absolute() or '..' in path.parts or '\\' in entry.filename or ':' in entry.filename or stat.S_ISLNK(entry.external_attr>>16):
                raise SystemExit('Unsafe archive entry: '+repr(entry.filename))
            members.append(entry)
        bad=archive.testzip()
        if bad is not None:raise SystemExit('ZIP integrity failure: '+bad)
        extract.mkdir(exist_ok=True)
        for entry in members:
            archive.extract(entry,extract)
            record={'name':entry.filename,'size':entry.file_size,'compressed_size':entry.compress_size,'crc32':format(entry.CRC,'08x')}
            if not entry.is_dir():
                b=archive.read(entry)
                record.update({'sha256':hashlib.sha256(b).hexdigest(),'first_32_bytes_hex':b[:32].hex()})
                if entry.filename.lower().endswith(('.json','.txt','.cfg','.ini','.xml')) and len(b)<65536:
                    record['text']=b.decode('utf-8',errors='replace')
            report['entries'].append(record)
    report['extracted_to']=str(extract.relative_to(R));report['zip_crc_check']='pass'
else:report['assessment']='Downloaded bytes are not a standard ZIP; no extraction attempted.'
(out/'package-inspection.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({k:v for k,v in report.items() if k!='entries'},indent=2))
print('Entries:',len(report['entries']))
for entry in report['entries']:print(entry['size'],entry['name'])
