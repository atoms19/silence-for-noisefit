# ColorFit Pulse 2 — Evolve2/TouchGUI action evidence

The exact model has explicit version/pairing branches in the Evolve2 integration. Rows below filter the existing dispatcher/handler analysis to that adapter. `code` indicates calls or state changes, `empty` an override without such work, and `inherited` no matching override in that class. This does not establish support on the physical Pulse 2, successful device execution, or wire opcodes. Vendor calls are direct calls in that method; work delegated to helpers/coroutines may not appear here.

## QueryAction

| Shared action | Handler method | Status | Direct vendor calls | Evidence |
| --- | --- | --- | --- | --- |
| ChatAiAudioToText | `h(Ljava/lang/String;Lcom/noisefit_commans/models/ChatGptSdkType;)V` | inherited |  | — |
| CheckDeviceWorn | `j()V` | inherited |  | — |
| DownloadOTAStatus | `k(II)V` | inherited |  | — |
| GetActivityRecogniseSettings | `l()V` | inherited |  | — |
| GetAgpsState | `m()V` | inherited |  | — |
| GetAlarms | `n()V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->A0()Lcom/touchgui/sdk/TGCommand;` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2QueryDeviceUnitsHandler.smali) |
| GetAllSportWidgetList | `o()V` | inherited |  | — |
| GetApplicationList | `p()V` | inherited |  | — |
| GetAutoSleep | `q()V` | empty |  | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2QueryDeviceUnitsHandler.smali) |
| GetBluetoothCallStatus | `s()V` | inherited |  | — |
| GetBodyTempUnit | `t()V` | inherited |  | — |
| GetBreathingData | `u()V` | inherited |  | — |
| GetBreathingLight | `v()V` | inherited |  | — |
| GetBrightnessLevelSettings | `w()V` | inherited |  | — |
| GetCallAlertState | `x()V` | inherited |  | — |
| GetCameraSwitchSettings | `y()V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->i()Lcom/touchgui/sdk/TGCommand;` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2QueryDeviceUnitsHandler.smali) |
| GetContactList | `z(I)V` | code |  | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2QueryDeviceUnitsHandler.smali) |
| GetCourseList | `A()V` | inherited |  | — |
| GetCustomReplies | `B()V` | code |  | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2QueryDeviceUnitsHandler.smali) |
| GetDeviceUnits | `C()V` | empty |  | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2QueryDeviceUnitsHandler.smali) |
| GetDoNotDisturbData | `D()V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->L()Lcom/touchgui/sdk/TGCommand;` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2QueryDeviceUnitsHandler.smali) |
| GetDrinkWaterSettings | `E()V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->W()Lcom/touchgui/sdk/TGCommand;` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2QueryDeviceUnitsHandler.smali) |
| GetESimEid | `G()V` | inherited |  | — |
| GetExerciseHeartRate | `H()V` | inherited |  | — |
| GetFavouriteContactList | `I()V` | inherited |  | — |
| GetFindPhoneSwitch | `K()V` | inherited |  | — |
| GetFirmwareLogs | `L()V` | inherited |  | — |
| GetGlowFriendContactsList | `N()V` | inherited |  | — |
| GetHRVData | `O()V` | inherited |  | — |
| GetHandWashData | `P()V` | inherited |  | — |
| GetHeartRateAlert | `Q()V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->y0()Lcom/touchgui/sdk/TGCommand;` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2QueryDeviceUnitsHandler.smali) |
| GetHeartRateInterval | `R()V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->B0()Lcom/touchgui/sdk/TGCommand;` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2QueryDeviceUnitsHandler.smali) |
| GetLanguage | `S()V` | code |  | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2QueryDeviceUnitsHandler.smali) |
| GetLocalMusic | `T()V` | inherited |  | — |
| GetMealReminderSettings | `U()V` | inherited |  | — |
| GetMedicineReminderSettings | `V()V` | inherited |  | — |
| GetMenstrualSettings | `X()V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->getPhysiologicalCycle()Lcom/touchgui/sdk/TGCommand;` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2QueryDeviceUnitsHandler.smali) |
| GetMusicControlSettings | `Y()V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->c0()Lcom/touchgui/sdk/TGCommand;` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2QueryDeviceUnitsHandler.smali) |
| GetNotificationSettings | `a0()V` | inherited |  | — |
| GetQuickBleCallingSwitch | `r()V` | inherited |  | — |
| GetQuickEyeMovementSwitch | `b0()V` | inherited |  | — |
| GetReminders | `c0()V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->t()Lcom/touchgui/sdk/TGCommand;` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2QueryDeviceUnitsHandler.smali) |
| GetSOSContactList | `d0()V` | inherited |  | — |
| GetScreenAwakeInterval | `e0()V` | inherited |  | — |
| GetSedentaryData | `f0()V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->s()Lcom/touchgui/sdk/TGCommand;` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2QueryDeviceUnitsHandler.smali) |
| GetSimpleVaultInfo | `g0()V` | inherited |  | — |
| GetSkinTemperatureSettings | `h0()V` | inherited |  | — |
| GetSleepReminder | `i0()V` | inherited |  | — |
| GetSocialCustomReplies | `j0()V` | inherited |  | — |
| GetSpo2Settings | `k0()V` | inherited |  | — |
| GetSportModeInfo | `l0()V` | inherited |  | — |
| GetSportWidgetSortList | `m0()V` | inherited |  | — |
| GetStockList | `n0()V` | inherited |  | — |
| GetStressReminder | `p0()V` | inherited |  | — |
| GetStressSettings | `q0()V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->T()Lcom/touchgui/sdk/TGCommand;` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2QueryDeviceUnitsHandler.smali) |
| GetSuperNotificationToggle | `r0()V` | inherited |  | — |
| GetTimeFormat | `s0()V` | inherited |  | — |
| GetUPIQRCode | `t0()V` | inherited |  | — |
| GetVaultInfo | `w0(Ljava/lang/String;)V` | inherited |  | — |
| GetVibrationIntensity | `x0()V` | inherited |  | — |
| GetWalkReminderData | `y0()V` | inherited |  | — |
| GetWatchFaceDetailById | `z0(Lcom/noisefit_commans/models/WatchFace;)V` | inherited |  | — |
| GetWatchFaces | `B0()V` | inherited |  | — |
| GetWatchPassword | `C0()V` | inherited |  | — |
| GetWidgetSortList | `E0()V` | inherited |  | — |
| GetWorldClock | `F0()V` | inherited |  | — |
| GetWristLiftGesture | `G0()V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->e0()Lcom/touchgui/sdk/TGCommand;` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2QueryDeviceUnitsHandler.smali) |
| QueryBatteryPower | `H0()V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->getBatteryInfo()Lcom/touchgui/sdk/TGCommand;` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2QueryDeviceUnitsHandler.smali) |
| QueryFirmwareLogs | `M(I)V` | inherited |  | — |
| QueryFirmwareUpgrade | `I0()V` | empty |  | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2QueryDeviceUnitsHandler.smali) |
| QueryFirmwareVersion | `K0()V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->i0()Lcom/touchgui/sdk/TGCommand;` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2QueryDeviceUnitsHandler.smali) |
| SendSongName | `M0(ILjava/lang/String;Ljava/lang/Integer;Ljava/lang/String;)V` | code |  | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2QueryDeviceUnitsHandler.smali) |
| SyncDeviceUnits | `O0()V` | inherited |  | — |
| UpdateChatGptImage | `P0(Ljava/util/List;)V` | inherited |  | — |
| UpdateOTAAvailability | `Q0(ZLjava/lang/String;Ljava/lang/String;Z)V` | inherited |  | — |
| UpdateVolume | `N0(II)V` | code |  | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2QueryDeviceUnitsHandler.smali) |
| VerifyPhilipsKey | `R0()V` | inherited |  | — |

## UpdateDeviceAction

| Shared action | Handler method | Status | Direct vendor calls | Evidence |
| --- | --- | --- | --- | --- |
| ActivateESim | `h(Ljava/lang/String;)V` | inherited |  | — |
| AddReminder | `i(Lcom/noisefit_commans/models/ReminderList$Reminder;)V` | inherited |  | — |
| CheckAutoSportStatus | `j()V` | inherited |  | — |
| CheckOngoingWorkout | `k()V` | inherited |  | — |
| ClearUPIQRCode | `e0(I)V` | inherited |  | — |
| CloseFindPhoneFromWatch | `l(Z)V` | inherited |  | — |
| DeleteCircuitCourse | `n()V` | inherited |  | — |
| DeleteFavouritesContact | `o(Ljava/util/List;)V` | inherited |  | — |
| DeleteLocalMusic | `p(Ljava/util/List;)V` | inherited |  | — |
| DeleteReminders | `q(Lcom/noisefit_commans/models/ReminderList;)V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/bean/TGEventReminder;-><init>()V`<br>`Lcom/touchgui/sdk/bean/TGEventReminder;->A(I)V`<br>`Lcom/touchgui/sdk/bean/TGEventReminder;->q(I)V`<br>`Lcom/touchgui/sdk/bean/TGEventReminder;->s(I)V`<br>`Lcom/touchgui/sdk/bean/TGEventReminder;->t(I)V`<br>`Lcom/touchgui/sdk/bean/TGEventReminder;->u(I)V`<br>`Lcom/touchgui/sdk/bean/TGEventReminder;->v(I)V` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| DeleteStock | `r(Ljava/lang/String;)V` | inherited |  | — |
| DeleteVaultInfo | `s(Ljava/util/ArrayList;)V` | inherited |  | — |
| FindDevice | `t(Lcom/noisefit_commans/models/SwitchSetting;)V` | code |  | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| SMSPermissionToggle | `A1(Z)V` | inherited |  | — |
| SendAiActionInfo | `B(Lcom/noisefit_commans/models/AiActionInfo;)V` | inherited |  | — |
| SendAiCmd | `D(I)V` | inherited |  | — |
| SendAiHistoryUiInfo | `E(Lcom/noisefit_commans/models/HistoryTemplateUI;)V` | inherited |  | — |
| SendAiOpenFunctionInfo | `G(Lcom/noisefit_commans/models/AiOpenFunctionInfo;)V` | inherited |  | — |
| SendAiRecordingCommand | `H(I)V` | inherited |  | — |
| SendAiToggleInfo | `I(Lcom/noisefit_commans/models/AiToggleInfo;)V` | inherited |  | — |
| SendAiViewUiInfo | `L(Lcom/noisefit_commans/models/AiViewUiInfo;)V` | inherited |  | — |
| SendAppNotification | `M(Lcom/noisefit_commans/models/AppNotification;)V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->A(Lcom/touchgui/sdk/bean/TGMessage;)Lcom/touchgui/sdk/TGCommand;`<br>`Lcom/touchgui/sdk/bean/TGMessage;-><init>()V`<br>`Lcom/touchgui/sdk/bean/TGMessage;->h(I)V` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| SendErrorNotificationToWatch | `N(Ljava/lang/String;)V` | inherited |  | — |
| SendSuperNotificationInfo | `O(Lcom/noisefit_commans/models/SuperNotificationInfoBean;)V` | inherited |  | — |
| SetAPGSStatus | `P(Z)V` | inherited |  | — |
| SetActivityRecogniseSwitch | `R(Lcom/noisefit_commans/models/SwitchSetting;)V` | inherited |  | — |
| SetAppForegroundState | `S(Z)V` | inherited |  | — |
| SetAutoSleep | `T(Lcom/noisefit_commans/models/AutoSleep;)V` | inherited |  | — |
| SetAutoWorkoutStatus | `U(Z)V` | inherited |  | — |
| SetBleCallingSwitch | `V(Z)V` | inherited |  | — |
| SetBodyTemperatureUnit | `W(Lcom/noisefit_commans/models/Units;)V` | inherited |  | — |
| SetBreathingData | `X(Lcom/noisefit_commans/models/BreathingData;)V` | inherited |  | — |
| SetBrightnessLevel | `Y(I)V` | inherited |  | — |
| SetCallAlertSwitch | `a0(Z)V` | inherited |  | — |
| SetCircuitCourse | `d0(Lcom/noisefit_commans/models/Course;)V` | inherited |  | — |
| SetContactList | `f0(Ljava/util/List;I)V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/bean/TGContacts;-><init>()V` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| SetContactWithImage | `g0(Ljava/util/List;Ljava/lang/String;Ljava/lang/String;)V` | inherited |  | — |
| SetCustomBackground | `h0(Landroid/net/Uri;Ljava/lang/String;I)V` | inherited |  | — |
| SetCustomBackgroundWithLayout | `i0(Landroid/net/Uri;Lcom/noisefit_commans/models/WatchFaceLayout;ILkotlin/Pair;)V` | inherited |  | — |
| SetDefaultValues | `j0()V` | inherited |  | — |
| SetDeviceAiConfig | `l0(Lcom/noisefit_commans/models/DeviceAiConfig;)V` | inherited |  | — |
| SetDeviceDateTime | `m0(Ljava/util/Calendar;Lcom/noisefit_commans/models/TimeFormat;)V` | code |  | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| SetDeviceUnits | `n0(Lcom/noisefit_commans/models/DeviceUnits;)V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->z0(Lcom/touchgui/sdk/bean/TGUnitConfig;)Lcom/touchgui/sdk/TGCommand;`<br>`Lcom/touchgui/sdk/bean/TGUnitConfig;-><init>()V`<br>`Lcom/touchgui/sdk/bean/TGUnitConfig;->h(I)V`<br>`Lcom/touchgui/sdk/bean/TGUnitConfig;->n(I)V` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| SetDiyWatchFaceAnalog | `p0(Lcom/noisefit_commans/models/DiyWfAnalogWatchData;)V` | inherited |  | — |
| SetDiyWatchFaceCustom | `q0(Lcom/noisefit_commans/models/DiyCustomWatchFace;)V` | code | `Lcom/touchgui/sdk/TGClient;->f()Lcom/touchgui/sdk/TGDialManager;`<br>`Lcom/touchgui/sdk/TGDialManager;->c(Lcom/touchgui/sdk/TGDialManager$OnSyncDialListener;)V`<br>`Lcom/touchgui/sdk/TGDialManager;->e(Lcom/touchgui/sdk/TGDial;)V`<br>`Lcom/touchgui/sdk/TGDialManager;->g(Lcom/touchgui/sdk/TGDialManager$OnSyncDialListener;)V`<br>`Lcom/touchgui/sdk/TGPhotoDialBuilder;-><init>()V`<br>`Lcom/touchgui/sdk/TGPhotoDialBuilder;->a()Lcom/touchgui/sdk/TGDial;`<br>`Lcom/touchgui/sdk/TGPhotoDialBuilder;->c(I)Lcom/touchgui/sdk/TGPhotoDialBuilder;`<br>`Lcom/touchgui/sdk/TGPhotoDialBuilder;->i(I)Lcom/touchgui/sdk/TGPhotoDialBuilder;` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| SetDiyWatchFaceDigital | `r0(Lcom/noisefit_commans/models/DiyWfDigitalWatchData;)V` | inherited |  | — |
| SetDrinkWaterReminder | `s0(Lcom/noisefit_commans/models/SedentaryData;)V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->r(Lcom/touchgui/sdk/bean/TGRemindDrinking;)Lcom/touchgui/sdk/TGCommand;`<br>`Lcom/touchgui/sdk/bean/TGRemindDrinking;-><init>()V`<br>`Lcom/touchgui/sdk/bean/TGRemindDrinking;->n(I)V`<br>`Lcom/touchgui/sdk/bean/TGRemindDrinking;->u(I)V`<br>`Lcom/touchgui/sdk/bean/TGRemindDrinking;->v(I)V`<br>`Lcom/touchgui/sdk/bean/TGRemindDrinking;->w(I)V`<br>`Lcom/touchgui/sdk/bean/TGRemindDrinking;->x(I)V`<br>`Lcom/touchgui/sdk/bean/TGRemindDrinking;->y(I)V` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| SetEvData | `t0(Lcom/noisefit_commans/models/EvInfoData;)V` | inherited |  | — |
| SetEvReminder | `u0(I)V` | inherited |  | — |
| SetExerciseHeartRateAlert | `v0(Lcom/noisefit_commans/models/HeartRateAlert;)V` | inherited |  | — |
| SetFactoryReset | `w0()V` | inherited |  | — |
| SetFindMyPhone | `x0(Lcom/noisefit_commans/models/SwitchSetting;)V` | inherited |  | — |
| SetGlowFriendEmoji | `y0(Lcom/noisefit_commans/models/GlowFriendEmoji;)V` | inherited |  | — |
| SetGlowFriendMessageStatus | `z0(Lcom/noisefit_commans/models/GlowFriendEmoji;)V` | inherited |  | — |
| SetHRVData | `A0(Lcom/noisefit_commans/models/HRVData;)V` | inherited |  | — |
| SetHandWashing | `B0(Lcom/noisefit_commans/models/HandWashing;)V` | inherited |  | — |
| SetHeartRateAlert | `C0(Lcom/noisefit_commans/models/HeartRateAlert;)V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->Q(Lcom/touchgui/sdk/bean/TGHeartRateRangeConfig;)Lcom/touchgui/sdk/TGCommand;`<br>`Lcom/touchgui/sdk/bean/TGHeartRateRangeConfig;-><init>()V`<br>`Lcom/touchgui/sdk/bean/TGHeartRateRangeConfig;->j(Z)V`<br>`Lcom/touchgui/sdk/bean/TGHeartRateRangeConfig;->k(Z)V`<br>`Lcom/touchgui/sdk/bean/TGHeartRateRangeConfig;->l(I)V`<br>`Lcom/touchgui/sdk/bean/TGHeartRateRangeConfig;->m(I)V`<br>`Lcom/touchgui/sdk/bean/TGHeartRateRangeConfig;->n(I)V`<br>`Lcom/touchgui/sdk/bean/TGHeartRateRangeConfig;->o(I)V`<br>`Lcom/touchgui/sdk/bean/TGHeartRateRangeConfig;->p(I)V`<br>`Lcom/touchgui/sdk/bean/TGHeartRateRangeConfig;->r(I)V` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| SetHeartRateInterval | `D0(Lcom/noisefit_commans/models/HeartRateInterval;)V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->q(Lcom/touchgui/sdk/bean/TGHeartRateMonitoringModeConfig;)Lcom/touchgui/sdk/TGCommand;`<br>`Lcom/touchgui/sdk/bean/TGHeartRateMonitoringModeConfig;-><init>()V`<br>`Lcom/touchgui/sdk/bean/TGHeartRateMonitoringModeConfig;->h(Z)V`<br>`Lcom/touchgui/sdk/bean/TGHeartRateMonitoringModeConfig;->i(I)V`<br>`Lcom/touchgui/sdk/bean/TGHeartRateMonitoringModeConfig;->j(I)V`<br>`Lcom/touchgui/sdk/bean/TGHeartRateMonitoringModeConfig;->k(I)V`<br>`Lcom/touchgui/sdk/bean/TGHeartRateMonitoringModeConfig;->l(I)V`<br>`Lcom/touchgui/sdk/bean/TGHeartRateMonitoringModeConfig;->m(I)V`<br>`Lcom/touchgui/sdk/bean/TGHeartRateMonitoringModeConfig;->n(I)V` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| SetIncomingCallInfo | `E0(Lcom/noisefit_commans/models/IncomingCall;)V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->C(I)Lcom/touchgui/sdk/TGCommand;` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| SetInitialParseVideoDial | `F0(Lcom/noisefit_commans/models/DiyCustomWatchFace;)V` | inherited |  | — |
| SetInitialVideoDial | `G0(Lcom/noisefit_commans/models/DiyCustomWatchFace;)V` | inherited |  | — |
| SetLocation | `H0(Landroid/location/Location;)V` | inherited |  | — |
| SetLowBatteryReminder | `I0(ZI)V` | inherited |  | — |
| SetManualMeasurement | `K0(Lcom/noisefit_commans/models/ManualMeasureType;Z)V` | inherited |  | — |
| SetMealReminder | `L0(Lcom/noisefit_commans/models/SedentaryData;)V` | inherited |  | — |
| SetMedicineReminder | `M0(Lcom/noisefit_commans/models/SedentaryData;)V` | inherited |  | — |
| SetMorningPost | `N0(Lcom/noisefit_commans/models/MorningBrief;)V` | inherited |  | — |
| SetMusicSwitch | `O0(Lcom/noisefit_commans/models/SwitchSetting;)V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->D(Z)Lcom/touchgui/sdk/TGCommand;` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| SetNotificationSettings | `P0(Lcom/noisefit_commans/models/NotificationSettings;)V` | inherited |  | — |
| SetQuickEyeMovementSwitch | `Q0(Z)V` | inherited |  | — |
| SetRealTimeDataState | `R0(Z)V` | inherited |  | — |
| SetRestartDevice | `S0()V` | inherited |  | — |
| SetSOSContact | `T0(Lcom/noisefit_commans/models/SOSContact;)V` | inherited |  | — |
| SetScreenAwakeInterval | `U0(I)V` | inherited |  | — |
| SetSedentaryData | `V0(Lcom/noisefit_commans/models/SedentaryData;)V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->l0(Lcom/touchgui/sdk/bean/TGSedentaryConfig;)Lcom/touchgui/sdk/TGCommand;`<br>`Lcom/touchgui/sdk/bean/TGSedentaryConfig;-><init>()V`<br>`Lcom/touchgui/sdk/bean/TGSedentaryConfig;->n(I)V`<br>`Lcom/touchgui/sdk/bean/TGSedentaryConfig;->u(I)V`<br>`Lcom/touchgui/sdk/bean/TGSedentaryConfig;->v(I)V`<br>`Lcom/touchgui/sdk/bean/TGSedentaryConfig;->w(I)V`<br>`Lcom/touchgui/sdk/bean/TGSedentaryConfig;->x(I)V`<br>`Lcom/touchgui/sdk/bean/TGSedentaryConfig;->y(I)V` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| SetSkinTemperatureSettings | `W0(Lcom/noisefit_commans/models/SkinTemperatureData;)V` | inherited |  | — |
| SetSpo2Settings | `X0(Lcom/noisefit_commans/models/Spo2Data;)V` | inherited |  | — |
| SetSportModeInfo | `Y0(Lcom/noisefit_commans/models/SportsModeList;)V` | inherited |  | — |
| SetSportWidgetSortList | `a1(Ljava/util/List;)V` | inherited |  | — |
| SetStressData | `d1(Lcom/noisefit_commans/models/SedentaryData;)V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->X(Lcom/touchgui/sdk/bean/TGStressConfig;)Lcom/touchgui/sdk/TGCommand;`<br>`Lcom/touchgui/sdk/bean/TGStressConfig;-><init>()V`<br>`Lcom/touchgui/sdk/bean/TGStressConfig;->h(Z)V`<br>`Lcom/touchgui/sdk/bean/TGStressConfig;->i(I)V`<br>`Lcom/touchgui/sdk/bean/TGStressConfig;->j(I)V`<br>`Lcom/touchgui/sdk/bean/TGStressConfig;->k(I)V`<br>`Lcom/touchgui/sdk/bean/TGStressConfig;->l(I)V`<br>`Lcom/touchgui/sdk/bean/TGStressConfig;->m(I)V`<br>`Lcom/touchgui/sdk/bean/TGStressConfig;->n(I)V` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| SetStressReminder | `e1(Lcom/noisefit_commans/models/SedentaryData;)V` | inherited |  | — |
| SetTemperatureUnit | `g1(Ljava/lang/String;)V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->z0(Lcom/touchgui/sdk/bean/TGUnitConfig;)Lcom/touchgui/sdk/TGCommand;`<br>`Lcom/touchgui/sdk/bean/TGUnitConfig;-><init>()V`<br>`Lcom/touchgui/sdk/bean/TGUnitConfig;->l(I)V` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| SetUPIQRCode | `i1(Ljava/util/List;)V` | inherited |  | — |
| SetUserInfo | `j1(Lcom/noisefit_commans/models/UserInfo;Lcom/noisefit_commans/models/UserGoals;Ljava/lang/String;)V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->I(Lcom/touchgui/sdk/bean/TGProfile;)Lcom/touchgui/sdk/TGCommand;`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->r0(Lcom/touchgui/sdk/bean/TGTarget;)Lcom/touchgui/sdk/TGCommand;`<br>`Lcom/touchgui/sdk/bean/TGProfile;-><init>()V`<br>`Lcom/touchgui/sdk/bean/TGProfile;->f(I)V`<br>`Lcom/touchgui/sdk/bean/TGProfile;->g(I)V`<br>`Lcom/touchgui/sdk/bean/TGProfile;->h(I)V`<br>`Lcom/touchgui/sdk/bean/TGTarget;-><init>()V`<br>`Lcom/touchgui/sdk/bean/TGTarget;->h(I)V`<br>`Lcom/touchgui/sdk/bean/TGTarget;->i(I)V`<br>`Lcom/touchgui/sdk/bean/TGTarget;->j(I)V`<br>`Lcom/touchgui/sdk/bean/TGTarget;->k(I)V`<br>`Lcom/touchgui/sdk/bean/TGTarget;->m(I)V` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| SetVaultInfo | `k1(Lcom/noisefit_commans/models/VaultInfo;)V` | inherited |  | — |
| SetVibrationIntensity | `l1(Lcom/noisefit_commans/models/VibrationIntensity;)V` | inherited |  | — |
| SetVideoWatchFaceCustom | `m1(Lcom/noisefit_commans/models/DiyCustomWatchFace;)V` | inherited |  | — |
| SetWalkReminderPro3 | `n1(Lcom/noisefit_commans/models/WalkReminderData;)V` | inherited |  | — |
| SetWatchFace | `o1(Lcom/noisefit_commans/models/WatchFace;)V` | code | `Lcom/touchgui/sdk/TGClient;->f()Lcom/touchgui/sdk/TGDialManager;`<br>`Lcom/touchgui/sdk/TGDialManager;->c(Lcom/touchgui/sdk/TGDialManager$OnSyncDialListener;)V`<br>`Lcom/touchgui/sdk/TGDialManager;->e(Lcom/touchgui/sdk/TGDial;)V`<br>`Lcom/touchgui/sdk/TGDialManager;->g(Lcom/touchgui/sdk/TGDialManager$OnSyncDialListener;)V` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| SetWatchFaceCustom | `p1(Lcom/noisefit_commans/models/CustomWatchFace;)V` | inherited |  | — |
| SetWatchFaceCustomHybrid | `q1(Lcom/noisefit_commans/models/WatchFacesCustomHybrid;)V` | inherited |  | — |
| SetWatchLanguage | `s1(Ljava/lang/String;)V` | inherited |  | — |
| SetWatchPassword | `t1(Lcom/noisefit_commans/models/WatchPassword;)V` | inherited |  | — |
| SetWeatherData | `g1(Ljava/lang/String;)V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->z0(Lcom/touchgui/sdk/bean/TGUnitConfig;)Lcom/touchgui/sdk/TGCommand;`<br>`Lcom/touchgui/sdk/bean/TGUnitConfig;-><init>()V`<br>`Lcom/touchgui/sdk/bean/TGUnitConfig;->l(I)V` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| SetWeatherDataHourly | `v1(Ljava/util/List;Ljava/util/List;Ljava/lang/String;)V` | inherited |  | — |
| SetWeatherSwitch | `w1(Lcom/noisefit_commans/models/SwitchSetting;)V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->F(Z)Lcom/touchgui/sdk/TGCommand;` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| SetWorldClock | `x1(Lcom/noisefit_commans/models/WorldClocksPushData;)V` | inherited |  | — |
| SetWristLiftGesture | `y1(Lcom/noisefit_commans/models/WristLiftGesture;)V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->M(Lcom/touchgui/sdk/bean/TGRaiseWristConfig;)Lcom/touchgui/sdk/TGCommand;`<br>`Lcom/touchgui/sdk/bean/TGRaiseWristConfig;-><init>()V`<br>`Lcom/touchgui/sdk/bean/TGRaiseWristConfig;->h(Z)V`<br>`Lcom/touchgui/sdk/bean/TGRaiseWristConfig;->i(Z)V`<br>`Lcom/touchgui/sdk/bean/TGRaiseWristConfig;->k(I)V`<br>`Lcom/touchgui/sdk/bean/TGRaiseWristConfig;->l(I)V`<br>`Lcom/touchgui/sdk/bean/TGRaiseWristConfig;->m(I)V`<br>`Lcom/touchgui/sdk/bean/TGRaiseWristConfig;->n(I)V` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| ShutDownDevice | `z1()V` | inherited |  | — |
| StartCameraMode | `B1(Z)V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->E0(Z)Lcom/touchgui/sdk/TGCommand;` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| StartWorkout | `D1(IJZ)V` | inherited |  | — |
| SyncFavouriteContact | `E1(Ljava/util/List;Ljava/util/List;IZ)V` | inherited |  | — |
| SyncStockInfoList | `F1(Lcom/noisefit_commans/models/StockInfoList;)V` | inherited |  | — |
| UpdateAPGSData | `G1(Landroid/net/Uri;Landroid/net/Uri;)V` | inherited |  | — |
| UpdateAlarm | `H1(Lcom/noisefit_commans/models/AlarmsList;Lcom/noisefit_commans/models/AlarmAction;)V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/bean/TGAlarm;-><init>()V`<br>`Lcom/touchgui/sdk/bean/TGAlarm;->n(I)V`<br>`Lcom/touchgui/sdk/bean/TGAlarm;->o(I)V`<br>`Lcom/touchgui/sdk/bean/TGAlarm;->p(I)V`<br>`Lcom/touchgui/sdk/bean/TGAlarm;->q(I)V`<br>`Lcom/touchgui/sdk/bean/TGAlarm;->w(Z)V` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| UpdateAllSportWidgetList | `I1(Ljava/lang/String;)V` | inherited |  | — |
| UpdateApplicationList | `J1(Ljava/util/List;)V` | inherited |  | — |
| UpdateBreathingLight | `K1(Lcom/noisefit_commans/models/BreathingLight;)V` | inherited |  | — |
| UpdateChatGptInitialisation | `L1(ZLjava/lang/String;Lcom/noisefit_commans/models/ChatGptSdkType;)V` | inherited |  | — |
| UpdateChatGptMessage | `M1(Ljava/lang/String;ZZ)V` | inherited |  | — |
| UpdateCustomReply | `N1(Lcom/noisefit_commans/models/CustomReplyData;)V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/bean/TGQuickReply;-><init>()V`<br>`Lcom/touchgui/sdk/bean/TGQuickReply;->f(I)V` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| UpdateDND | `O1(Lcom/noisefit_commans/models/DoNotDisturb;)V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->D0(Lcom/touchgui/sdk/bean/TGNotDisturbConfig;)Lcom/touchgui/sdk/TGCommand;`<br>`Lcom/touchgui/sdk/bean/TGNotDisturbConfig;-><init>()V`<br>`Lcom/touchgui/sdk/bean/TGNotDisturbConfig;->f(Z)V`<br>`Lcom/touchgui/sdk/bean/TGNotDisturbConfig;->g(I)V`<br>`Lcom/touchgui/sdk/bean/TGNotDisturbConfig;->h(I)V`<br>`Lcom/touchgui/sdk/bean/TGNotDisturbConfig;->i(I)V`<br>`Lcom/touchgui/sdk/bean/TGNotDisturbConfig;->j(I)V` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| UpdateFirmware | `P1(Ljava/lang/String;)V` | code | `Lcom/touchgui/sdk/TGClient;->w()Lcom/touchgui/sdk/TGOTAManager;`<br>`Lcom/touchgui/sdk/TGOTAManager;->b(Lcom/touchgui/sdk/TGOTACallback;)V` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| UpdateGlowFriendContactsList | `Q1(Ljava/util/List;)V` | inherited |  | — |
| UpdateLanguage | `R1(Lcom/noisefit_commans/models/Language;)V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->z0(Lcom/touchgui/sdk/bean/TGUnitConfig;)Lcom/touchgui/sdk/TGCommand;`<br>`Lcom/touchgui/sdk/bean/TGUnitConfig;-><init>()V`<br>`Lcom/touchgui/sdk/bean/TGUnitConfig;->i(I)V` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| UpdateLocalMusic | `S1(Lcom/noisefit_commans/models/AudioModel;Ljava/util/List;)V` | inherited |  | — |
| UpdateMenstrualData | `T1(Lcom/noisefit_commans/models/MenstrualData;)V` | code | `Lcom/touchgui/sdk/TGClient;->s()Lcom/touchgui/sdk/TGCommandBuilder;`<br>`Lcom/touchgui/sdk/TGCommand;->a(Lcom/touchgui/sdk/TGCallback;)V`<br>`Lcom/touchgui/sdk/TGCommandBuilder;->F0(Lcom/touchgui/sdk/bean/TGPhysiologicalCycle;)Lcom/touchgui/sdk/TGCommand;`<br>`Lcom/touchgui/sdk/bean/TGPhysiologicalCycle;-><init>()V`<br>`Lcom/touchgui/sdk/bean/TGPhysiologicalCycle;->i(Z)V`<br>`Lcom/touchgui/sdk/bean/TGPhysiologicalCycle;->k(I)V`<br>`Lcom/touchgui/sdk/bean/TGPhysiologicalCycle;->l(I)V`<br>`Lcom/touchgui/sdk/bean/TGPhysiologicalCycle;->m(I)V`<br>`Lcom/touchgui/sdk/bean/TGPhysiologicalCycle;->n(I)V`<br>`Lcom/touchgui/sdk/bean/TGPhysiologicalCycle;->o(I)V`<br>`Lcom/touchgui/sdk/bean/TGPhysiologicalCycle;->p(I)V` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali) |
| UpdateNotificationToggle | `U1(Z)V` | inherited |  | — |
| UpdateOngoingWorkout | `V1(IJI)V` | inherited |  | — |
| UpdateSleepReminder | `W1(Lcom/noisefit_commans/models/SleepReminder;)V` | inherited |  | — |
| UpdateSocialCustomReply | `X1(Lcom/noisefit_commans/models/CustomReplyData;)V` | inherited |  | — |
| UpdateSuperNotificationToggle | `Y1(Z)V` | inherited |  | — |
| UpdateWidgetSortList | `Z1(Ljava/util/List;)V` | inherited |  | — |
| VisionUpdateFirmware | `a2(Ljava/util/List;)V` | inherited |  | — |
| WritePhilipsKeyByProduction | `b2(Ljava/lang/String;)V` | inherited |  | — |

## UserActivityAction

| Shared action | Handler method | Status | Direct vendor calls | Evidence |
| --- | --- | --- | --- | --- |
| ClearSyncData | `h()V` | inherited |  | — |
| GetBloodOxygenLevel | `j()V` | code | `Lcom/touchgui/sdk/TGClient;->q()Z` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UserActivityHandler.smali) |
| GetBloodPressure | `k()V` | empty |  | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UserActivityHandler.smali) |
| GetHeartHistory | `m(Ljava/util/Calendar;)V` | code | `Lcom/touchgui/sdk/TGClient;->q()Z` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UserActivityHandler.smali) |
| GetHeartRate | `n()V` | code | `Lcom/touchgui/sdk/TGClient;->q()Z` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UserActivityHandler.smali) |
| GetSleepData | `o(Ljava/lang/String;)V` | code | `Lcom/touchgui/sdk/TGClient;->q()Z` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UserActivityHandler.smali) |
| GetStepsData | `p(Ljava/lang/String;)V` | code | `Lcom/touchgui/sdk/TGClient;->q()Z` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UserActivityHandler.smali) |
| GetStressCount | `q()V` | code | `Lcom/touchgui/sdk/TGClient;->q()Z` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UserActivityHandler.smali) |
| Refresh | `s(Lcom/noisefit_commans/models/SportsModeRequest;)V` | inherited |  | — |
| SetSpo2Measurement | `u(Z)V` | inherited |  | — |
| SetWeatherData | `v(Ljava/util/List;)V` | inherited |  | — |
| SyncSportsActivity | `w(Ljava/lang/String;)V` | code | `Lcom/touchgui/sdk/TGClient;->n()Z` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UserActivityHandler.smali) |
| SyncUserActivity | `x(Ljava/lang/String;Z)V` | code | `Lcom/touchgui/sdk/TGClient;->n()Z`<br>`Lcom/touchgui/sdk/TGClient;->q()Z` | [handler](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UserActivityHandler.smali) |
| UpdateSportsMode | `y(Lcom/noisefit_commans/models/SportsModeRequest;)V` | inherited |  | — |
