# INV_ASPICE_Fault_Detection_with_simulink

INV A-SPICE 개발 문서의 고장진단 요구사항을 분석하고, 고장 조건이 충족될 때 Fault Flag가 설정되도록 MATLAB/Simulink로 구현하고 검증한 실습입니다.

이 저장소는 인버터 제어 직무의 A-SPICE 문서 흐름을 한 번에 설명하기 위한 실행 가능한 예제입니다.

`사용자 요구사항 → 시스템 요구사항/아키텍처 → SRS → SADS → SUDS → Simulink 모델 → 검증`

## 포함 범위

- 10 kHz SPWM 제어기
- 이상적인 6스위치, 2레벨 3상 전압형 인버터(VSI)
- 3상 R–L 모터 등가 부하
- DC-Link 과전압 진단
- 100 ms 연속시간 Debounce
- Fault Latch와 저전압 복귀 후 수동 Reset
- FaultManager 기반 6개 게이트 일괄 차단
- 자동 테스트 및 시뮬레이션 결과 그래프

> 이 모델은 제어 SW와 고장진단의 요구사항 추적성을 보여주는 모델입니다. 실제 MOSFET/IGBT 손실, 데드타임, 역병렬 다이오드, 회생전류, DC-Link capacitor dynamics, 센서 오차 및 PCB 기생성분은 모델링하지 않습니다.

## 빠른 실행

MATLAB에서 이 폴더를 Current Folder로 설정한 뒤 실행합니다.

```matlab
build_INV_ASPICE_demo
run_INV_ASPICE_tests
open_system('INV_ASPICE_Inverter_Demo')
```

생성되는 핵심 파일은 다음과 같습니다.

- `INV_ASPICE_Inverter_Demo.slx`: 실행 가능한 Simulink 모델
- `results/simulation_overview.png`: 전압, 고장, PWM, 상전류 결과
- `results/test_summary.csv`: 자동 검증 결과

## 기본 가정값

| 항목 | 값 |
|---|---:|
| DC-Link 정상전압 | 400 V |
| 과전압 Set 임계값 | 420 V 초과 |
| 과전압 Debounce | 100 ms |
| Reset 허용 전압 | 400 V 미만 |
| PWM 주파수 | 10 kHz |
| 기본파 주파수 | 50 Hz |
| 변조지수 | 0.8 |
| 모델 표본시간 | 10 us |
| 부하 | R=0.5 ohm, L=2.5 mH / phase |

모든 숫자는 설명을 위한 가정값이며 실제 프로젝트에서는 제공받은 SRS/SADS/SUDS의 값으로 교체해야 합니다. 파라미터는 [init_INV_ASPICE_demo.m](init_INV_ASPICE_demo.m)에 모아 두었습니다.

## 시나리오

| 구간 | Vdc | 예상 동작 |
|---|---:|---|
| 0~30 ms | 400 V | 정상 PWM 및 3상 전류 |
| 30~80 ms | 430 V | 50 ms 과전압, Fault 미발생 |
| 80~100 ms | 400 V | Debounce counter reset |
| 100~230 ms | 430 V | 100 ms 후 OV Fault 확정 및 PWM 차단 |
| 230~250 ms | 390 V | 전압 복귀, Fault는 Latch 유지 |
| 250 ms | Reset pulse | Fault 해제 및 PWM 재개 |

## 문서

- [사용자·시스템 요구사항](docs/01_User_and_System_Requirements.md)
- [SRS](docs/02_SRS.md)
- [SADS](docs/03_SADS.md)
- [SUDS](docs/04_SUDS.md)
- [검증 계획](docs/05_Verification_Plan.md)
- [추적성 매트릭스](docs/06_Traceability_Matrix.md)
