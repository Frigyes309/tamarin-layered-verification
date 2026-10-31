| Command | Mean Wall Time [s] | Change | Factor |
|:---|---:|---:|:---|
| `L123_Network` | 52.579 ± 0.629 |  |  |
| `L123_Network_TWO_BYZANTINE` | 3.271 ± 0.065 | -93.8% | (16.1x faster) |
| `L4_Transport` | 1.925 ± 0.044 | -96.3% | (27.3x faster) |
| `L4_Transport_UNBOUND_INPUTS` | 2.300 ± 0.056 | -95.6% | (22.9x faster) |
| `L5_Session` | 134.305 ± 3.314 | +155.4% | (2.6x slower) |
| `L6_Presentation` | 52.399 ± 1.373 | -0.3% |  |
| `L6_Presentation_SEPARATE_SLOTS` | 6.825 ± 0.128 | -87.0% | (7.7x faster) |
| `L7_Application` | 5.118 ± 0.151 | -90.3% | (10.3x faster) |
| `L7_Application_NO_CAS` | 46.798 ± 1.625 | -11.0% |  |
