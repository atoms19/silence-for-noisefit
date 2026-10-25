# Recovering Pulse 2 firmware from an existing Android installation

## Discovery authentication and binary download are separate

The main API client attaches `access-token: Bearer <stored token>`. Firmware discovery routes include `POST /core/watch/firmware_versions` and `POST /firmware-versions/v3/recent`; they return firmware metadata and URLs. This establishes that the app sends authentication, not independent proof of the server's enforcement.

The generic firmware downloader uses a separate `HttpClientDownload` built without the main authentication interceptor. Its Retrofit service accepts a dynamic URL, optionally an `accept-encoding` header, and streams a response body. No NoiseFit bearer header is added by the inspected download client. Therefore the binary URL might be public, signed/expiring, tokenized in the query/path or otherwise protected independently. The exact live policy remains unknown without an existing response or network interaction. Merely possessing a URL does not provide its bytes offline.

Sources: [NetworkModule:882](../analysis/smali/classes18/com/noisefit/di/NetworkModule.smali#L882), [DownloadService:1](../analysis/smali/classes18/com/noisefit/data/remote/abstraction/DownloadService.smali#L1), [NetworkConnectionInterceptor:1678](../analysis/smali/classes18/com/noisefit/data/remote/NetworkConnectionInterceptor.smali#L1678).

## Offline recovery routes, in priority order

| Route | What could be recovered | Access / limitations |
| --- | --- | --- |
| App external cache | Original downloaded archive, incomplete downloads or old copies | Ordinary ADB may read it, depending on Android/device restrictions |
| App private cache | TouchGUI `TGOTA<timestamp>` extraction directories and component files | Usually requires existing root access or a debuggable app permitting `run-as` |
| Existing app files, saved state and logs | Previous update response, filename, URL, firmware ID/version, and occasionally copied packages | Private app data normally needs the same additional access; URL/metadata alone is not firmware |
| Existing backups or copied update files | Previously preserved archive or components | No backend access required; must verify the model and package completeness |
| Readout from the wearable | Potential installed image | No generic firmware-readback API established; ADB access to the phone alone does not provide this |

For Android user 0, candidate paths derived from the inspected APIs are:

```text
/storage/emulated/0/Android/data/com.noisefit/cache/
/data/user/0/com.noisefit/cache/TGOTA<timestamp>/
/data/user/0/com.noisefit/files/
/data/user/0/com.noisefit/shared_prefs/
/data/user/0/com.noisefit/databases/
```

These are expected Android path mappings, not observed directories on the user's device. `/data/data/com.noisefit/` can be an alias; secondary users/work profiles use different IDs. A cache package need not end in `.zip`: the app derives its filename from the URL, and TouchGUI parses the content with `ZipInputStream`.

Sources: [CheckForUpdatesFragment:3111](../analysis/smali/classes4/com/noisefit/ui/myDevice/manage/CheckForUpdatesFragment.smali#L3111), [TGOTAManagerProxy:26](../analysis/smali/classes5/com/touchgui/sdk/TGOTAManagerProxy.smali#L26), [tb:1](../analysis/smali/classes5/com/touchgui/sdk/internal/tb.smali#L1).

## Why an old completed update might no longer be available

TouchGUI deletes its extracted directory after its completion callback and in its handled OTA failure path. The app also attempts to delete its downloaded file on cleanup. Abrupt termination, failed cleanup, copies or other entry points could leave material, so offline inspection is worthwhile, but there is no guarantee a previous firmware package survives.

Sources: [q6:1](../analysis/smali/classes5/com/touchgui/sdk/internal/q6.smali#L1), [h:554](../analysis/smali/classes5/com/touchgui/sdk/h.smali#L554), [CheckForUpdatesViewModel:1984](../analysis/smali/classes4/com/noisefit/ui/myDevice/manage/CheckForUpdatesViewModel.smali#L1984).

## Preservation-first ADB workflow

Before opening or refreshing the app, disable its Internet connectivity (Wi-Fi, mobile data and any Ethernet/VPN network path). A read-only investigation should first identify the actual installed package/version and device user, preserve accessible caches, then inspect private data only if access is already available. A band connection is unnecessary for reading files already stored on the phone.

Do not clear storage/cache, uninstall/reinstall, trigger an update, unlock the bootloader or start a rooting procedure to pursue this cache. Bootloader unlocking can wipe the data being sought. Ordinary `adb pull` cannot bypass private app storage permissions. The supplied APK declares `allowBackup=false`, so legacy ADB backup should not be relied upon for private-data extraction.

Recovered candidates should be copied to the workspace, hashed, checked for archive integrity and inspected offline. Match model identifiers (`colorfit_pulse_2`), firmware catalog context (default ID 2109), version and component metadata; avoid assuming every `.bin` is firmware, because watch faces and other resources coexist. Partial files or an unrelated model package are not a verified usable firmware image.

No ADB device inspection, cache extraction or network request has been performed for this chapter. If no firmware bytes remain in accessible storage or an existing backup, ADB cannot recreate a deleted package from its URL; acquiring it would then require another source or relaxing the no-network constraint.

## What an authenticated backend check could establish

The APK contains `POST /auth_v2/watch/login`, `POST /auth_v2/watch/send-otp`, `POST /auth_v2/watch/verify-otp` and a refresh-token flow. `LoginRequest` has `login_type`, `value`, `password`, `token` and `image_url` fields; which are required depends on the actual login mode. These declarations do not prove every mode is currently enabled. A screen displaying an account identity is not itself an API credential. A valid existing session or a successful normal login would provide the authentication context, alongside actual device metadata for the firmware query.

Sources: [AuthenticationRepositoryImpl$loginUser$2:1](../analysis/smali/classes18/com/noisefit/data/repository/implementation/AuthenticationRepositoryImpl$loginUser$2.smali#L1), [LoginRequest:1](../analysis/smali/classes18/com/noisefit/data/remote/request/LoginRequest.smali#L1), [dynamic API call sites](catalogs/dynamic-url-callsites.md).

The manual update success collector obtains nullable `BaseApiResponseData.data` and passes it to `CheckForUpdatesViewModel.n0(UpdateResponse?, boolean)`. That method explicitly handles a null update by setting the update-available state false and returning. The package URL in `UpdateResponse` is also nullable. Therefore the client is designed to tolerate a successful request without usable firmware metadata; static analysis cannot promise that the backend always supplies a package, including when already current. The exact no-update payload, whether an identical-version package is offered, eligibility/rollout rules and any separate reinstall facility remain server-side unknowns. `isOTARequired` is a client flag, not proof of a server override or guaranteed download.

Sources: [CheckForUpdatesViewModel$checkForUpdates$1$1:1](../analysis/smali/classes4/com/noisefit/ui/myDevice/manage/CheckForUpdatesViewModel$checkForUpdates$1$1.smali#L1), [CheckForUpdatesViewModel:1516](../analysis/smali/classes4/com/noisefit/ui/myDevice/manage/CheckForUpdatesViewModel.smali#L1516), [UpdateResponse:1](../analysis/smali/classes18/com/noisefit/data/remote/response/UpdateResponse.smali#L1).

Offline cache recovery is the first choice under the user's no-request constraint and may recover the exact previously delivered package. It cannot answer current server policy. An authenticated check could answer what this account/device/version is offered now, but would require relaxing that constraint and might still return no package. No such query has been performed.
