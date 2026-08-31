# 01. 사용자 및 시스템 요구사항

## 1. 목적과 범위

본 문서는 3상 인버터 제어 시스템에 DC-Link 과전압 진단을 통합하는 예제의 최상위 요구사항을 정의한다. 요구사항의 수치와 동작 조건은 교육용 가정값이며 실제 사내 규격을 대체하지 않는다.

## 2. 사용자 요구사항

| ID | 사용자 요구사항 | 수용 기준 |
|---|---|---|
| UR-INV-001 | 사용자는 DC 전원을 3상 교류 출력으로 변환하는 인버터의 PWM 제어와 부하 전류를 시뮬레이션할 수 있어야 한다. | 정상상태에서 120도 위상차를 갖는 3상 전압과 전류가 생성된다. |
| UR-DIAG-001 | 사용자는 DC-Link의 지속적인 과전압을 검출할 수 있어야 한다. | 420 V 초과가 100 ms 지속될 때 Fault가 Set된다. |
| UR-DIAG-002 | 사용자는 순간 노이즈성 과전압 때문에 인버터가 불필요하게 정지하지 않기를 원한다. | 100 ms 미만 과전압에서는 Fault가 Set되지 않는다. |
| UR-SAFE-001 | 과전압이 확정되면 인버터 스위칭을 안전하게 정지해야 한다. | Fault 확정 후 1 sample 이내에 모든 게이트 명령이 0이 된다. |
| UR-REC-001 | 전압이 안전영역으로 복귀해도 의도하지 않은 자동 재시동이 없어야 한다. | Vdc < 400 V와 Reset 요청이 동시에 만족할 때만 Fault가 Clear된다. |
| UR-ASPICE-001 | 요구사항, 설계, 모델 및 테스트 사이의 추적성을 확인할 수 있어야 한다. | 각 SRS 항목에 SADS/SUDS 요소와 테스트 ID가 연결된다. |

## 3. 시스템 요구사항

| ID | 시스템 요구사항 |
|---|---|
| SYS-INV-001 | 시스템은 400 V nominal DC-Link와 이상적인 2레벨 3상 VSI를 포함해야 한다. |
| SYS-INV-002 | 시스템은 10 kHz SPWM으로 50 Hz, 변조지수 0.8의 3상 기준전압을 생성해야 한다. |
| SYS-LOAD-001 | 시스템은 각 상 R=0.5 ohm, L=2.5 mH인 평형 부하를 포함해야 한다. |
| SYS-DIAG-001 | 시스템은 Vdc > 420 V 상태의 연속 지속시간을 감시해야 한다. |
| SYS-SAFE-001 | 확정된 과전압 Fault는 상·하단 6개 게이트 출력을 모두 Disable해야 한다. |
| SYS-REC-001 | Fault는 Vdc < 400 V 상태에서 유효한 Reset 요청을 받아야 해제되어야 한다. |

## 4. 시스템 컨텍스트

```text
DC-Link Scenario
      │ Vdc
      ├───────────────┐
      ▼               ▼
Voltage Diagnosis   3-phase VSI ──▶ R-L motor-equivalent load
      │ OV_Fault       ▲                    │ Iabc
      ▼                │ Gate[6]            ▼
Fault Manager ◀──── SPWM Controller       Monitoring
      │
      └── PWM_Enable / PWM_Disable_Request
```

