# 05. Verification Plan

## 1. 테스트 환경

- SIL 수준 Simulink simulation
- Solver: FixedStepDiscrete
- Step size: 10 us
- Stop time: 280 ms
- 자동 검증: `run_INV_ASPICE_tests.m`

## 2. 테스트 케이스

| Test ID | 입력/조건 | 기대 결과 | 관련 SRS |
|---|---|---|---|
| TC-CTRL-001 | 정상 Vdc, 0~30 ms | PWM switching 및 유한한 3상 전류 발생 | SWRS-CTRL-001/002, SWRS-LOAD-001 |
| TC-DIAG-001 | Vdc=430 V, 30~80 ms | 50 ms 이후 Fault=0, counter reset | SWRS-DIAG-002/003 |
| TC-DIAG-002 | Vdc=430 V, 100 ms 이상 | 약 200 ms에서 Fault=1 | SWRS-DIAG-001/002 |
| TC-SAFE-001 | OV_Fault=1 | PWM_Enable=0, Gate[6]=0 | SWRS-SAFE-001/002 |
| TC-LATCH-001 | Vdc가 390 V로 복귀, Reset 전 | Fault=1 유지 | SWRS-DIAG-004 |
| TC-REC-001 | Vdc=390 V, 250 ms Reset pulse | Fault=0, PWM 재개 | SWRS-DIAG-005 |
| TC-INV-001 | 정상 switching | Va+Vb+Vc≈0 | SWRS-INV-001 |

## 3. 경계값 추가 시험 권장

실제 사양 적용 시 아래 Model Test 또는 Test Harness를 추가한다.

- 419.9 V / 420.0 V / 420.1 V
- 99.99 ms / 100.00 ms / 100.01 ms
- Threshold 주변 노이즈와 chatter
- Counter overflow 및 sample-time 변경
- Reset 요청이 있어도 Vdc가 400 V 이상인 경우
- PWM deadtime, ADC filter 및 센서 rationality fault

