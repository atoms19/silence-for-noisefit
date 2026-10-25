# Returned ColorFit Pulse 2 firmware metadata

## What the true-flag query returned

The user ran the prepared unauthenticated request with `isOTARequired: true` from a network-enabled terminal. The response is preserved in [response-body.txt](../analysis/backend-check/ota-required-true/response-body.txt); [response-inspection.json](../analysis/backend-check/ota-required-true/response-inspection.json) records its hash and the request comparison.

| Field | Returned value |
| --- | --- |
| HTTP / application status | 200 / `success: true` |
| Integer release version | `26` |
| Version name | `V5.4.328.26` |
| Download host | `images.gonoise.com` |
| Download path | `/firmwares/production/colorfit_pulse_2/url/20220816054411/ColorFitPulse2V26diffa.zip` |
| `forceUpdate` | `true` |
| `is_force` | `0` |
| `image_url`, `touch_url`, `hr_url` | Empty strings |

The description lists improved connectivity, performance and bug resolution. The returned version matches the version reported by the user; this is not evidence that a newer release was found. The path's timestamp-like segment is a literal server path, not an independently verified release date.

The saved baseline request returned null data. The comparison confirms that only `isOTARequired` changed. Thus these two results provide concrete evidence that the flag influences the offered metadata for these inputs, without proving global endpoint policy. No account token or real MAC was supplied. The metadata was accessible unauthenticated in this transaction; download accessibility is a separate question.

## Package acquisition and extraction

[recover_returned_firmware.py](../analysis/tools/recover_returned_firmware.py) reads the saved response, validates the expected HTTPS host/Pulse 2 path, downloads only that returned package without an account token, hashes it, tests ZIP CRCs, and extracts it locally after checking entry paths, sizes and symlink flags. It neither executes package contents nor sends anything to the watch. HTTPS redirects are allowed with a limit; no firmware discovery request is made by this script.

Run from the regular network-enabled terminal:

```sh
python3 /home/atoms/programming/noise-decoder/analysis/tools/recover_returned_firmware.py
```

Output is saved under `analysis/firmware/colorfit-pulse-2/`, including `package-inspection.json` when local inspection succeeds. Existing local package bytes are inspected without redownloading.

The attempt inside this workspace failed before contacting the download host: curl exit 6, `Could not resolve host: images.gonoise.com`. No firmware bytes have been obtained by that attempt. The user subsequently ran the script successfully from the regular terminal. The 500,177-byte ZIP and its sole 862,752-byte `a.bin` entry are now preserved locally, with matching hashes and a passing ZIP CRC check. See [the recovered firmware analysis](17-recovered-firmware-analysis.md).

## Compatibility and interpretation

`diffa` in the filename suggests a differential package, but its format, required base version and component contents cannot be established from the name. Do not classify it as a full flash image or a safe reinstall image until its contents are analyzed. The generic TouchGUI filename allowlist in chapter 11 is not this package's actual inventory.

ZIP integrity and a locally calculated SHA-256 hash do not establish publisher signatures, bootloader acceptance or compatibility with a hardware revision. This research is acquisition and offline analysis; no flashing is authorized or performed.
