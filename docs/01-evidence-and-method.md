# Evidence and reproducible method

## Artifact identity

| Property | Value |
| --- | --- |
| Supplied file | `NoiseFit_+Health+&+Fitness_5.4.6_APKPure.xapk` |
| XAPK size | 311,010,347 bytes |
| XAPK SHA-256 | `2ee2eb92b990f5989b5a3611a39acd99c8c7eca15b48fa421f53b13d2656a737` |
| Base APK SHA-256 | `2ee2ec8c387d6f98be8b82ec3b58515c407cdd9b9a57e01fa911aa226abfb17c` |
| Package/version | `com.noisefit` / 5.4.6 / 876 |
| Minimum/target Android SDK | 26 / 36 |
| Splits | Base, `config.arm64_v8a`, `config.en`, `config.hdpi` |
| Bytecode | 18 DEX files; 128,185 emitted smali files |
| Native libraries | 70 ARM64 `.so` files |

Identity is read from the decoded manifest and XAPK [manifest.json](../analysis/input/manifest.json). All split hashes and sizes are in [hashes.json](../analysis/hashes.json). These hashes identify the local sample; the distribution filename and archive comments do not independently establish publisher authenticity. No signature comparison with an official release was performed.

## Toolchain and what “decompiled” means here

The installed Android SDK supplied `apkanalyzer`, `aapt2` and Android tools baksmali 3.0.9. Every DEX was translated to readable **smali disassembly**, preserving annotations, method calls, constants and branches. Original Kotlin/Java source was not recovered. Some names remain meaningful, while many method names and fields have been obfuscated. Inner coroutine names often preserve the original business operation. Native machine code and Flutter AOT were inventoried/scanned, not fully decompiled.

An attempt to download JADX from GitHub failed at DNS resolution because the environment disables networking. Analysis then used the installed SDK entirely offline. No application/backend URL was requested. The SDK's bundled JCommander is incompatible with certain baksmali help and `-j` options, so the successful command uses default options. The completed [disassembly log](../analysis/disassembly.log) records all 18 inputs.

## Reproduction

From this workspace, with the same installed SDK paths:

```sh
mkdir -p analysis/input analysis/base
unzip -q 'NoiseFit_+Health+&+Fitness_5.4.6_APKPure.xapk' -d analysis/input
unzip -q analysis/input/com.noisefit.apk 'classes*.dex' 'assets/*' -d analysis/base
/home/atoms/Android/Sdk/cmdline-tools/latest/bin/apkanalyzer manifest print analysis/input/com.noisefit.apk > analysis/AndroidManifest.xml
python3 analysis/tools/disassemble.py
python3 analysis/tools/build_catalogs.py
python3 analysis/tools/build_callsite_catalog.py
python3 analysis/tools/build_support_matrix.py
python3 analysis/tools/write_research.py
```

The scripts perform local reads/writes and invoke local Java tools; they have no network client. `disassemble.py` assumes extracted DEX inputs. For another machine, change the SDK root in that script. Standard Python 3.9 is sufficient. The narrative is reviewed interpretation; regeneration re-renders those notes rather than performing a new semantic audit.

The network XML was decoded with `apkanalyzer resources xml --file res/xml/network_security_config.xml`. Resource IDs were resolved using `aapt2 dump resources`; the output is [resources.txt](../analysis/resources.txt). ARM64 files were extracted from the native split and printable URL strings collected separately in [native-url-literals.json](../analysis/native-url-literals.json).

## Evidence layout and limits

`analysis/smali/classesN/` corresponds to `classesN.dex`; `classes/` corresponds to `classes.dex`. Each document links to source files and often a method or line. `#L` fragments are useful when hosted in a code viewer; local editors may require opening the referenced file and going to the indicated line.

Automated inventories are broad but deliberately limited: URL literals can be examples, web links or SDK defaults; dynamic URL associations are method co-occurrence candidates, not dataflow proof; UUIDs may be unrelated; handler coverage detects matching overrides, not runtime support. Data coming from remote configuration, responses, encryption, native code or constructed strings can be missing. The user identified the device as ColorFit Pulse 2. No paired runtime state, server response, BLE capture or firmware download was available for validation.
