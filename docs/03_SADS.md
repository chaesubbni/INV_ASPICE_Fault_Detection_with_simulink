# 03. Software Architecture Design Specification (SADS)

## 1. 아키텍처 개요

```text
+-------------------+       RawGateABC       +------------------+
|  SPWM_Controller  | ---------------------> |  Fault_Manager   |
+-------------------+                        +---------+--------+
                                                       |
DC_Link_Scenario -- Vdc --> Voltage_Diagnosis          | Gate[6]
                              | OV_Fault                v
                              +----------------> +------+----------+
                                                 | TwoLevel_Inverter|
                                                 +------+----------+
                                                        | Vabc
                                                        v
                                                 +------+----------+
                                                 | RL_3Phase_Load  |
                                                 +-----------------+
```

## 2. SW Component 책임

| Component | 책임 | 입력 | 출력 |
|---|---|---|---|
| `DC_Link_Scenario` | 정상/단기/장기 과전압 및 Reset 자극 생성 | Simulation time | `Vdc`, `ResetFault` |
| `SPWM_Controller` | 3상 정현파와 triangular carrier를 이용한 raw PWM 생성 | Simulation time | `RawGate_A/B/C` |
| `Voltage_Diagnosis` | 임계값, Debounce, Latch, Reset 처리 | `Vdc`, `ResetFault` | `OV_Fault`, `DebounceCount`, `OV_Condition` |
| `Fault_Manager` | 고장 상태를 최종 6개 게이트 허용/차단 명령으로 중재 | Raw gates, `OV_Fault` | Gate[6], `PWM_Enable` |
| `TwoLevel_Inverter` | 2레벨 VSI의 스위칭 상태로부터 3상 전압 계산 | Gate upper[3], `Vdc` | `Va/Vb/Vc` |
| `RL_3Phase_Load` | 3상 부하의 이산시간 전류 상태 계산 | `Va/Vb/Vc` | `Ia/Ib/Ic` |
| `Monitoring` | 검증용 신호 기록 | Vdc, Fault, gates, Vabc, Iabc | MAT/SimulationOutput data |

## 3. 인터페이스 및 실행주기

모든 Component는 단일 fixed-step `Ts=10 us`로 실행한다. 이 예제는 멀티레이트 스케줄링과 AUTOSAR RTE를 포함하지 않는다.

| Interface | Producer | Consumer | Rate |
|---|---|---|---:|
| `Vdc` | DC_Link_Scenario | Voltage_Diagnosis, TwoLevel_Inverter | 10 us |
| `RawGateABC` | SPWM_Controller | Fault_Manager | 10 us |
| `OV_Fault` | Voltage_Diagnosis | Fault_Manager, Monitoring | 10 us |
| `Gate6` | Fault_Manager | TwoLevel_Inverter, Monitoring | 10 us |
| `Vabc` | TwoLevel_Inverter | RL_3Phase_Load, Monitoring | 10 us |
| `Iabc` | RL_3Phase_Load | Monitoring | 10 us |

## 4. 안전 메커니즘

`Fault_Manager`는 각 raw gate에 `PWM_Enable`을 AND하여 최종 게이트를 만든다. 하단 gate는 raw 상단 gate의 보수(complement)에 Enable을 AND한다. Fault 상태에서는 상단과 하단 모두 0이며 Shoot-through 방지를 위한 deadtime은 본 예제 범위 밖이다.

