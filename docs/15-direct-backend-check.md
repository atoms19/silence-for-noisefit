# Direct unauthenticated firmware-check attempt

The user authorized a direct backend request and reported the installed watch version as `5.4.328.26`, superseding the earlier no-backend-request constraint for this check.

A single unauthenticated POST was attempted to `https://app-eks.gonoise.com/core/watch/firmware_versions`, using [request.json](../analysis/backend-check/request.json). Candidate numeric version `26` comes from the reported suffix, and firmware ID `2109` is the APK's default for Pulse 2. Neither value was verified from private runtime state. MAC was set to null, `isOTARequired` to false, and no account token was sent. This is an incomplete unauthenticated baseline, not an exact replay of the app's request.

## Result

The local HTTP client exited with curl code **6**, `Could not resolve host: app-eks.gonoise.com`; HTTP status was **000**. This is a local DNS/network failure, not an HTTP response. No request reached the backend in this attempt. It provides no evidence about server availability, authentication enforcement, request validity, release eligibility or firmware availability.

The reproducible [check-firmware.sh](../analysis/backend-check/check-firmware.sh) sends one POST, with a timeout and no retries, redirects or firmware downloads. It saves the HTTP status, headers/body if available, and transport errors under `analysis/backend-check/`. Running it in the user's regular terminal may have network access unavailable in this sandbox. A subsequent HTTP rejection could reflect missing device fields or authentication; a single response should not be generalized into a complete server policy.

## Subsequent result from the user's regular terminal

The user ran the prepared script outside the sandbox. The saved artifacts now show curl exit code `0`, HTTP status **200**, and the following JSON response:

```json
{
  "success": true,
  "data": null,
  "message": "Successfully executed",
  "time": "1792867488348"
}
```

The saved request remains the unauthenticated Pulse 2 baseline with `version: 26`, `firmware_id: 2109`, `device_type: colorfit_pulse_2`, `platform: android`, `mac: null` and `isOTARequired: false`. The response contains no firmware metadata or download URL. For this request, the endpoint did not return an authentication error; the application-level body reports success with null data. This does not establish that all firmware APIs or file URLs are public, nor that authenticated device-specific requests behave identically.

Possible explanations include no eligible update for these inputs or differences between the baseline and the actual app request. The response does not distinguish those cases. It does not prove `5.4.328.26` is the latest release, that no firmware exists on the server, that every request is accepted unauthenticated, or that MAC/account/eligibility information is irrelevant. No returned firmware URL was present to request, and no additional backend query was made during response inspection.

The current response files overwrite the original transport-failure files; the initial DNS failure is preserved as a narrative observation above.

## Controlled `isOTARequired: true` comparison

The user authorized another check with `isOTARequired` set to true, and retrieval/extraction if firmware becomes available. A separate [request](../analysis/backend-check/ota-required-true/request.json) changes only that boolean; numeric version, firmware ID, null MAC, endpoint and headers remain unchanged. The baseline response is preserved in the parent directory.

The sandbox attempt again failed at DNS resolution (curl exit 6, HTTP 000), so it produced no backend response. The user can run [the separate check script](../analysis/backend-check/ota-required-true/check-firmware.sh) from the regular terminal. Results are saved in `analysis/backend-check/ota-required-true/` for comparison. No firmware has been downloaded or extracted from this attempt. A true flag may influence server behavior, but does not guarantee metadata or override eligibility checks.

## Successful true-flag response from the user terminal

The separate request returned HTTP 200 and `success: true` with a non-null metadata object. Comparing the saved request JSON confirms that only `isOTARequired` changed from false to true. The returned release is integer version `26`, version name `V5.4.328.26`, matching the user-reported installed version. It includes a Pulse 2 package URL on `images.gonoise.com`, `forceUpdate: true`, `is_force: 0`, and empty secondary component URLs. These differently named flags should not be assumed to have identical meanings.

For these two saved unauthenticated requests, changing the flag is associated with null versus populated metadata. This demonstrates that same-version metadata is available for this input; it does not establish the full server eligibility policy or how the downloaded package is authenticated. See [the firmware acquisition notes](16-returned-pulse-2-firmware.md).
