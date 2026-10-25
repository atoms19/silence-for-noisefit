# Weather on the watch

How NoiseFit's TouchGUI SDK pushes weather to a ColorFit Pulse 2, from NoiseFit 5.4.6 smali. **Not yet verified on hardware.** Weather is an ordinary short command on the command channel; the SDK has no weather source of its own, NoiseFit fetches the data from its backend and passes `TGWeather` to `TGCommandBuilder.U`.

## Command (`internal/l9.U`)

Chosen by `internal/a0.o()`: `protocolVersion >> 8 == 3` or device id `0x1fa` (both from the device-info reply; see doc 11).

**New format, `0A 04` + body** (`internal/g5` with `y8(0x0a, 4)`):

```
type  temperature  max  min  humidity  b5 b6 b7 b8 b9 b10   |  per future day: type max min
```

- Bytes are signed 8-bit; the six `b` bytes are other `TGWeather` fields that NoiseFit never sets (sent as 0). With capability `0x2090b04` the SDK also appends one byte and a zero int32; Silence assumes it is not set.
- NoiseFit sends today's data first, then four future days (`SetWeatherData` in `noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler$setWeatherData$1$1`): `temperature` = current, `max`/`min` = today's range, `humidity`, then days 2-5 as (type, max, min).

**Legacy format, `0A 01` + 18-byte body** (`internal/v8` with `y8(0x0a, 1)`): `type temperature max min humidity b5 b6` then three bytes per future day (loop over the list; the buffer holds three days). Inferred; used only when `o()` is false.

Field mapping (obfuscated bean to meaning) comes from the setters NoiseFit calls: `o`=temperature, `r`=max, `s`=min, `q`=humidity, `y`=type; for a future day `d`=max, `e`=min, `f`=type.

## Weather type codes (`Evolve2UpdateDeviceUnitsHandler.m2`)

Keyed by OpenWeather-style condition names: clear 1, clouds 2, rain 4, thunderstorm 6, snow 7, tornado 9, sand 0xa, drizzle 0x12; mist/smoke/haze/dust/fog and anything else 0x11. `TGWeatherType` defines codes up to 0x19 whose meaning was not recovered.

## In Silence

`services/touchgui_weather.dart` builds both formats (unit-tested) and maps Open-Meteo's WMO codes onto the types above. `services/weather_service.dart` searches cities and fetches a five-day forecast from Open-Meteo (free, no key, Celsius). The Weather card in Studio picks a place, sends now, and can keep the watch updated hourly while connected and after each bind. Unverified: the legacy format, the unknown bytes, whether the watch expects Celsius or follows its own unit setting, and what the codes outside the NoiseFit set display.
