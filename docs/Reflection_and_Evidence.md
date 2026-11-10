# CSC 4360 Activity 14 · Reflection and evidence

| Item | Your record |
| --- | --- |
| Name | |
| Repository URL | |
| Device or emulator model | |
| Android version | |
| Notification permission | |
| Test date | |

## Valid payload used for T1–T3

```json
{
  "notification": {
    "title": "Campus event update",
    "body": "The student activities fair starts at 4 PM."
  },
  "data": {
    "action": "update_ui",
    "asset": "promo"
  }
}
```

## Results

| Test | Expected handler and result | Observed result | Pass / Fail / Blocked | Evidence reference |
| --- | --- | --- | --- | --- |
| T1 | `onMessage` · promo announcement appears | | | |
| T2 | `onMessageOpenedApp` · promo announcement appears after tap | | | |
| T3 | `getInitialMessage` · promo announcement appears after cold-start tap | | | |
| T4 | `onMessage` · unsupported-asset diagnostic, previous title and image preserved | | | |

Link one short recording with timestamps or four labeled screenshots. Redact
device tokens and credentials. Record only what you observed.

## Reflection

Write three short responses totaling about 150–250 words. Remove the prompts
after replacing them with your answers.

1. **Setup and payload.** Explain one configuration decision. Describe what
   `action` and `asset` did to the screen.
2. **Lifecycle and evidence.** Compare the T1–T3 handlers and cite the evidence
   you captured. Explain why the background isolate cannot directly update the
   widgets.
3. **Validation and next step.** Explain the T4 diagnostic and what stayed
   visible. Describe one actual failure and fix or a risk you checked, plus one
   justified improvement.

## Limitations and assistance

Record any blocked test, the observed condition, and any AI assistance as
required by the course policy.
