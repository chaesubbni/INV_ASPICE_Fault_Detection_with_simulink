# 06. Requirements Traceability Matrix

| User Req. | System Req. | Software Req. | SADS Component | SUDS Unit | Test |
|---|---|---|---|---|---|
| UR-INV-001 | SYS-INV-001/002 | SWRS-CTRL-001/002, SWRS-INV-001 | SPWM_Controller, TwoLevel_Inverter | SPWM, TwoLevelInverter | TC-CTRL-001, TC-INV-001 |
| UR-DIAG-001 | SYS-DIAG-001 | SWRS-DIAG-001/002 | Voltage_Diagnosis | OverVoltageCondition, DebounceCounter | TC-DIAG-002 |
| UR-DIAG-002 | SYS-DIAG-001 | SWRS-DIAG-003 | Voltage_Diagnosis | DebounceCounter | TC-DIAG-001 |
| UR-SAFE-001 | SYS-SAFE-001 | SWRS-SAFE-001/002 | Fault_Manager | FaultManager | TC-SAFE-001 |
| UR-REC-001 | SYS-REC-001 | SWRS-DIAG-004/005 | Voltage_Diagnosis | FaultLatch | TC-LATCH-001, TC-REC-001 |
| UR-ASPICE-001 | - | SWRS-NF-002/004 | Monitoring | Automated test | 모든 TC |

## 모델 요소 연결 규칙

현재 예제는 별도 Requirements Toolbox 없이 이름 기반 추적성을 사용한다.

- 모델 Subsystem 이름은 SADS Component 이름과 동일하게 유지한다.
- SUDS Unit은 해당 Subsystem 내부 블록 그룹으로 구현한다.
- 테스트 스크립트의 검증 메시지에 Test ID를 포함한다.
- 실제 회사 프로젝트에서는 사내 Requirement ID를 Requirements Toolbox link로 모델 블록과 Test Harness에 직접 연결한다.

