"""Offline inventory of supplied app logs. Does not print raw logs or URL queries."""
from pathlib import Path
import re,json,hashlib,collections,urllib.parse
R=Path(__file__).resolve().parents[2]
p=R/'analysis/device-cache/appLogs/logs.txt';data=p.read_bytes();lines=data.decode('utf-8',errors='replace').splitlines()
patterns={'firmware':r'firmware|firmware_id|fw_version|FirmwareInfo','ota':r'\bOTA\b|TGOTA|updateFirmware|firmware_versions|firmware-versions','download':r'download|\.zip|\.bin|\.ota','evolve':r'Evolve','device_model':r'colorfit_pulse_2|ColorFit Pulse 2','version':r'version'}
counts={k:sum(bool(re.search(p,l,re.I)) for l in lines) for k,p in patterns.items()}
urls=collections.Counter()
for line in lines:
 for value in re.findall(r'https?://[^\s"<>]+',line):
  try:
   u=urllib.parse.urlsplit(value)
   urls[(u.hostname,re.sub(r'/\d+(?=/|$)','/<number>',u.path))]+=1
  except ValueError:pass
report={'source':str(p.relative_to(R)),'size':len(data),'sha256':hashlib.sha256(data).hexdigest(),'line_count':len(lines),'first_timestamp':lines[0][:23] if lines else None,'last_timestamp':lines[-1][:23] if lines else None,'match_counts':counts,'url_host_paths_without_queries':[{'host':h,'path':p,'count':n} for (h,p),n in sorted(urls.items())],'evidence_line_numbers':{k:[n for n,l in enumerate(lines,1) if re.search(patterns[k],l,re.I)][:20] for k in ['evolve','device_model']},'limitations':'Only the supplied log file was inspected. Absent strings do not prove no historical OTA or cached private firmware exists. No raw account data, weather query values, tokens or MAC addresses are reproduced.'}
(R/'analysis/device-cache/log-inspection.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
