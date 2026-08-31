# 02. Software Requirements Specification (SRS)

## 1. 인터페이스

| 신호 | 방향 | 형식 | 단위 | 설명 |
|---|---|---|---|---|
| `Vdc` | Input | double | V | DC-Link 측정전압 |
| `ResetFault` | Input | boolean | - | 운전자/상위 SW의 Fault Reset 요청 |
| `RawGate_A/B/C` | Input | boolean | - | SPWM 상단 스위치 원시 명령 |
| `OV_Fault` | Output | boolean | - | 확정 및 Latch된 과전압 고장 |
| `PWM_Enable` | Output | boolean | - | 게이트 출력 허용 상태 |
| `Gate_AU/AL/BU/BL/CU/CL` | Output | boolean | - | 최종 6개 스위치 명령 |

## 2. 기능 요구사항

| ID | 요구사항 | 검증 기준 |
|---|---|---|
| SWRS-CTRL-001 | SW는 50 Hz, 120도 위상차의 3상 정현파 기준값을 생성해야 한다. | 세 기준파 위상차가 각각 120도이다. |
| SWRS-CTRL-002 | SW는 10 kHz triangular carrier와 기준파를 비교해 SPWM 상단 게이트 명령을 생성해야 한다. | 정상구간에서 각 상 게이트가 주기적으로 스위칭한다. |
| SWRS-DIAG-001 | SW는 `Vdc > 420 V`일 때 과전압 조건을 TRUE로 판단해야 한다. | 420 V에서는 FALSE, 420 V 초과에서는 TRUE이다. |
| SWRS-DIAG-002 | SW는 과전압 조건이 연속 100 ms 유지될 때 `OV_Fault`를 TRUE로 설정해야 한다. | 100 ms 도달 시점 허용오차는 1 sample이다. |
| SWRS-DIAG-003 | 과전압 조건이 100 ms 이전에 해제되면 Debounce counter를 0으로 초기화해야 한다. | 50 ms 과전압 후 Fault=FALSE, counter=0이다. |
| SWRS-DIAG-004 | 확정된 `OV_Fault`는 Vdc가 정상으로 복귀해도 Latch되어야 한다. | Reset 전까지 Fault=TRUE이다. |
| SWRS-DIAG-005 | `Vdc < 400 V`와 `ResetFault=TRUE`가 동시에 만족하면 `OV_Fault`를 해제해야 한다. | Reset 후 1 sample 이내 Fault=FALSE이다. |
| SWRS-SAFE-001 | `OV_Fault=TRUE`이면 `PWM_Enable=FALSE`이어야 한다. | 논리적으로 항상 `PWM_Enable = NOT OV_Fault`이다. |
| SWRS-SAFE-002 | `PWM_Enable=FALSE`이면 6개 최종 게이트 명령은 모두 FALSE이어야 한다. | Fault 구간의 모든 Gate 값이 0이다. |
| SWRS-INV-001 | 인버터 모델은 최종 상단 게이트와 Vdc로 부하 중성점 기준 3상 전압을 계산해야 한다. | `Va+Vb+Vc`가 수치오차 범위에서 0이다. |
| SWRS-LOAD-001 | 부하 모델은 `di/dt=(v-Ri)/L`을 이산시간으로 계산해야 한다. | 정상 PWM 구간에 유한한 평형 3상 전류가 생성된다. |

## 3. 비기능 요구사항

| ID | 요구사항 |
|---|---|
| SWRS-NF-001 | 모델은 MATLAB/Simulink R2026a에서 추가 Simscape 제품 없이 실행되어야 한다. |
| SWRS-NF-002 | 모든 calibration 값은 초기화 스크립트에 중앙 관리되어야 한다. |
| SWRS-NF-003 | 모델은 10 us fixed-step discrete solver를 사용해야 한다. |
| SWRS-NF-004 | 자동 테스트는 Pass/Fail과 주요 검출시간을 CSV로 저장해야 한다. |

