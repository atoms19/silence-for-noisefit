# Backend servers and API surface

## Network policy for this research

All findings are local static evidence. No host below was resolved, probed or requested as part of application analysis. A literal URL establishes a reference; only client construction and call sites make a stronger case that it is an intended integration. Server internals, deployment status and current behavior are unknown.

## Configured clients and other host references

| Host/base | Evidence level | Intended or likely role |
| --- | --- | --- |
| `https://app-eks.gonoise.com` | Explicit main and token-refresh Retrofit base; many concrete calls | Primary identity, device catalog, health sync, firmware discovery/tracking, subscriptions and app configuration |
| `https://pre-order.gonoise.com` | Explicit shop Retrofit base | Commerce/shop integration |
| `http://api.weatherapi.com` | Explicit weather/sport client base | Weather and sports data for phone/device features |
| `https://api.twelvedata.com` | Explicit stock client base | Quotes, symbol search and stocks |
| `https://www.strava.com` | Explicit Retrofit base and concrete URLs | OAuth/token and activity integration |
| `https://p360.tvsmotor.com/gapi` | Apollo server URL | TVS GraphQL integration |
| `https://queue.fal.run/` | Explicit Flux client base | AI image/watch-face generation queue |
| `https://api.replicate.com` | App URL literal | Alternative image-generation path; not proof used in every session |
| `http://localhost/` | Download Retrofit placeholder with dynamic `@Url` | Base required to construct generic downloader; actual file URL is supplied separately |
| `https://app.gonoise.com` | App URL literals | Additional web/content/wellbeing links; do not assume same API deployment as main host |
| `https://noise-connect.gonoise.com`, `https://engage.gonoise.com` | App URL literals | Support/engagement endpoints or links; inspect corresponding call sites |
| `https://backend.gonoise.com/devices/file/link` | App literal/call-site lead | Device file-link integration |
| `http://app-micro-staging.gonoise.com/devices/file/link` | Staging literal | Environment-specific or legacy path; presence does not prove production traffic |
| `images.gonoise.com`, `watchfaces-cdn.gonoise.com`, `user-detail-service-cdn.gonoise.com`, `noise-images.s3.ap-south-1.amazonaws.com` | App asset/content URLs | Images, instructional media, watch face and QR resources; not verified firmware hosts |
| `http://veryfitproapi.veryfitplus.com/dailPlate/...` | Vendor integration URLs | IDO/VeryFit dial catalog |
| `http://offline-live1.services.u-blox.com/GetOfflineData.ashx` | AGPS call-site literal | GNSS assistance download |
| Sentry ingest host | App DSN literal | Error/diagnostic telemetry configuration |
| Firebase/Google, Facebook, Huawei, MoEngage and other SDK references | Packaged libraries and manifest | SDK integration/analytics/push/authentication capabilities; not a complete observed destination list |
| `https://open.creekcould.com`, `/v1/route/gpx` | Printable strings in Flutter `libapp.so` | Possible Creek route backend; AOT call flow not decompiled |
| `https://api.cognitive.microsofttranslator.com`, `https://api.country.is` | Printable strings in Flutter `libapp.so` | Translation / country detection references; execution unresolved |

Main source: [NetworkModule:1](../analysis/smali/classes18/com/noisefit/di/NetworkModule.smali#L1). Additional literal sources and call sites are linked individually in [app URL literals](catalogs/app-url-literals.md), [dynamic call-site candidates](catalogs/dynamic-url-callsites.md), and [native URL strings](../analysis/native-url-literals.json). Native strings can contain diagnostic/docs URLs and must not all be treated as live integrations.

## What the primary backend appears responsible for

Endpoint families and repository payloads support these client-side roles:

| Area | Examples of paths or literal prefixes | What is established / inferred |
| --- | --- | --- |
| Identity and account | `/users/auth/sign_up`, `/auth_v2/refresh-token`, `/users/auth/update_mobile`, `/user_detail/profile/update` | Authentication/profile operations are declared; token headers and refresh flow are present |
| Device registration and capabilities | `/user_detail/watch/devices/create`, `/user_detail/watch/devices/list`, `/user_detail/watch/device_features`, `/user_detail/watch/watch-token` | Cloud device records/capabilities and watch tokens; exact ownership policy is server-side |
| Firmware | `/core/watch/firmware_versions`, `/firmware-versions/v3/recent`, `/user_detail/user/firmware/tracking` | Discovery/version selection and completion tracking; server-side rollout rules inferred, not recovered |
| Download links | `/user_detail/watch/file/link`, `/devices/file/link` on other referenced environments | Obtain file links; filenames/hosts may be response-driven |
| Health sync | `/multisync/v2/create`, `/multisync/v2/health-events`, `/watch/heart_rates/v2/history`, `/watch/blood_oxygen/v2/history`, `/watch/stress/v2/history` | Upload and historical retrieval/aggregation capabilities |
| Sleep and recovery | `/sleep_activities/v3/rewamp/create`, `/watch/sleep/v1/history`, `/watch/sleep/v2/recovery/calendar`, `/multisync/v2/sleep-planner/create` | Sleep records and derived views; exact algorithms are not recoverable from paths |
| AI health analysis | `/multisync/ai/health/analysis/list/`, `/multisync/ai/health/analysis/detail/` | Analysis listing/detail retrieval; do not infer server model or pipeline |
| Watch faces | `/cloud_watch_faces/v3/dial_plate/info`, `/watch_faces/v3/current` | Catalog/current-face tracking and downloadable resources |
| Social/challenges | `/activity_challenge/v3/...`, `/trophies/v3/recent`, `/buddies/profile` | Challenge membership/progress/social profile operations |
| App release/config | `/core/watch/app_version/check`, `/core/watch/app_version/config` | App version/configuration; separate from band firmware |
| Support/diagnostics | `/logging/falcon/upload_logs`, `/user_detail/user/device/complaint/logs`, `/user_detail/feedback/create`, `/user_detail/upload_crash_report` | Feedback and logs, including device/firmware/RRI logs where supplied |
| Warranty, commerce, subscriptions | `/warranty/v3/...`, `/core/shopify/token`, subscription-related literal paths | Product/account entitlements and purchase integrations |
| eSIM and voice bridge | `/auth_v2/watch/esim/send-otp`, `/auth_v2/watch/esim/verify-otp`, `/watch/ai-bridge/data/voice-ai` | Specialized phone/watch backend functions; model-dependent |

Sources: [NetworkService:1](../analysis/smali/classes18/com/noisefit/data/remote/abstraction/NetworkService.smali#L1), [DeviceRepositoryImpl:1](../analysis/smali/classes18/com/noisefit/data/repository/implementation/DeviceRepositoryImpl.smali#L1), [SyncRepositoryImpl$postDataToServer$2:1](../analysis/smali/classes18/com/noisefit/data/repository/implementation/SyncRepositoryImpl$postDataToServer$2.smali#L1), and the catalogs. Path examples retain the APK's spelling, including `rewamp`.

## API inventory and its completeness boundary

[retrofit-endpoints.md](catalogs/retrofit-endpoints.md) enumerates **411 HTTP method declarations** across app-owned interfaces with parameters and source locations. Many use `@Url`, so the declaration does not identify a fixed path. [dynamic-url-callsites.md](catalogs/dynamic-url-callsites.md) adds **288** dynamic call sites with literal candidates in the same method. [app-url-literals.md](catalogs/app-url-literals.md) lists **416 unique literals** from the app/adapters/common protocol. These counts overlap and must not be added as a count of unique APIs.

The dynamic catalog is a co-occurrence index; concatenation and branch-specific argument assignment still need source inspection. URLs returned by servers, native/Flutter networking, GraphQL operations, dynamically assembled strings and SDK-only endpoints are not all represented as Retrofit rows. Raw app URL occurrence data is in [url-literals.json](../analysis/url-literals.json); it also retains third-party DEX references. Query values are omitted from rendered URL tables because literals can include integration tokens; parameter names remain available in declarations/source.

## Main request headers and token handling

`NetworkConnectionInterceptor.s()` constructs headers including:

```text
content-type: application/json
version: 876
version-name: 5.4.6
Accept-Encoding: gzip
user-agent: <constructed client agent>
device-model: <Android Build.MODEL>
device-manufacturer: <Android Build.BRAND>
os-version: <Android version>
platform: android
sub-wearable-type: <selected type, or band/watch fallback>
country: <country>
accept-language: <app language>
epoch-time: <current time>
access-token: Bearer <stored access token>   [when available]
```

The access token is carried under **`access-token`** in this inspected main client, rather than assuming a standard `Authorization` header. Other clients can use different interceptors. Later branches add device-specific context; inspect the complete method before constructing any future authorized request. Token-refresh API declarations include `refresh-token`, `wearable-type` and `user-agent` headers. Runtime tokens were not acquired or exposed.

Sources: [NetworkConnectionInterceptor:1678](../analysis/smali/classes18/com/noisefit/data/remote/NetworkConnectionInterceptor.smali#L1678), [TokenRefreshApi:1](../analysis/smali/classes18/com/noisefit/data/remote/abstraction/TokenRefreshApi.smali#L1), [NetworkConnectionInterceptor$getUpdatedToken$2:1](../analysis/smali/classes18/com/noisefit/data/remote/NetworkConnectionInterceptor$getUpdatedToken$2.smali#L1).

## An ambiguous external firmware interface

`ExternalFirmwareService` declares `GET /account/login` and `GET /device/queryFirmwareVersion`, each with a body parameter. Standard Retrofit GET-body validation makes this declaration unusual. The inspected `ExternalModule` supplies a repository taking this service, but no concrete base URL for this interface was established. Treat it as a packaged integration requiring validation, not a confirmed additional live firmware backend.

Source: [ExternalFirmwareService:1](../analysis/smali/classes18/com/noisefit/data/remote/abstraction/ExternalFirmwareService.smali#L1), [ExternalModule:1](../analysis/smali/classes18/com/noisefit/di/ExternalModule.smali#L1).

## Server implementation remains unknown

Host names and route prefixes are not proof of AWS EKS deployment, microservice boundaries, databases, object storage for firmware, specific cloud vendors, rollout cohorts or signing services. Those are plausible interpretations only. The APK establishes the client contracts, and current production responses were intentionally not queried.
