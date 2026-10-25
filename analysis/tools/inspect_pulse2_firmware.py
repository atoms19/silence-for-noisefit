"""Offline binary triage of the downloaded Pulse 2 image; never executes firmware."""
from pathlib import Path
import re,json,hashlib,struct,collections,math,zipfile
R=Path(__file__).resolve().parents[2];out=R/'analysis/firmware/colorfit-pulse-2'
meta=json.loads((out/'package-inspection.json').read_text());package=R/meta['file'];image=R/meta['extracted_to']/'a.bin';b=image.read_bytes()
strings=[{'offset':m.start(),'offset_hex':hex(m.start()),'text':m[0].decode('ascii')} for m in re.finditer(rb'[\x20-\x7e]{6,}',b)]
needles=['Goodix GR551x SDK','ColorFit Pulse 2','Noise Pulse 2','oy07_app_fw','elx_ota','OTA length','MSG_ID_GR_OTA','compression_type','version mismatch','now_boot_info','Bootloader[','NSW-26']
markers=[x for x in strings if any(n in x['text'] for n in needles)]
footer=len(b)-48;words=struct.unpack_from('<12I',b,footer);vectors=struct.unpack_from('<16I',b,0)
report={'image':str(image.relative_to(R)),'size':len(b),'sha256':hashlib.sha256(b).hexdigest(),'archive_sha256':hashlib.sha256(package.read_bytes()).hexdigest(),'archive_hash_matches_download_report':hashlib.sha256(package.read_bytes()).hexdigest()==meta['sha256'],'image_hash_matches_extraction_report':hashlib.sha256(b).hexdigest()==next(x['sha256'] for x in meta['entries'] if x['name']=='a.bin'),'printable_string_count':len(strings),'entropy_bits_per_byte':-sum(n/len(b)*math.log2(n/len(b)) for n in collections.Counter(b).values()),'initial_16_le_words':[hex(x) for x in vectors],'footer_offset':hex(footer),'footer_12_le_words':[hex(x) for x in words],'footer_name':b[footer+28:].split(b'\x00',1)[0].decode('ascii',errors='replace'),'footer_second_word_equals_footer_offset':words[1]==footer,'candidate_image_base':hex(words[3]),'candidate_reset_address':hex(vectors[1]),'candidate_reset_offset':hex((vectors[1]&~1)-words[3]),'candidate_reset_bytes':b[(vectors[1]&~1)-words[3]:(vectors[1]&~1)-words[3]+24].hex(),'markers':markers,'touchgui_transfer_type_for_a_bin':'0x23 (35), from internal.u3 filename map','assessment':'Model strings, GR551x SDK banner, vector-like header, executable-looking bytes and structured footer support a firmware code component. Exact chip variant, full-device image coverage, differential/base dependencies and signature policy remain unverified.'}
(out/'a-bin-triage.json').write_text(json.dumps(report,indent=2)+'\n')
(out/'a-bin-ascii-strings.json').write_text(json.dumps(strings,indent=2)+'\n')
print(json.dumps({k:v for k,v in report.items() if k not in ['markers','initial_16_le_words','footer_12_le_words']},indent=2))
print('Selected markers:',len(markers))
