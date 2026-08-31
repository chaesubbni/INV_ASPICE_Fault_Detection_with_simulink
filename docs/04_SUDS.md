# 04. Software Unit Design Specification (SUDS)

## 1. SPWM Unit

전기각과 3상 기준파는 다음과 같다.

```text
theta = 2*pi*f_e*t
m_a = M*sin(theta)
m_b = M*sin(theta - 2*pi/3)
m_c = M*sin(theta + 2*pi/3)
```

`m_x >= triangular_carrier`일 때 해당 상의 raw upper gate를 TRUE로 한다. Lower gate는 FaultManager에서 complement로 만든다.

## 2. OverVoltageCondition Unit

```text
OV_Condition = (Vdc > OV_SetThreshold)
OV_SetThreshold = 420 V
```

비교 연산은 strict greater-than이다. 따라서 정확히 420 V에서는 조건이 FALSE이다.

## 3. DebounceCounter Unit

```text
if OV_Condition
    Counter_next = min(Counter_prev + 1, DebounceCount)
else
    Counter_next = 0
end

FaultDetected = (Counter_next >= DebounceCount)
DebounceCount = round(0.100 / Ts) = 10000 counts
```

## 4. FaultLatch Unit

```text
ResetAllowed = ResetFault AND (Vdc < OV_ResetThreshold)
OV_Fault_next = (OV_Fault_prev OR FaultDetected) AND NOT ResetAllowed
OV_ResetThreshold = 400 V
```

Reset 요청만으로는 해제할 수 없고 안전전압 조건이 함께 만족되어야 한다.

## 5. FaultManager Unit

```text
PWM_Enable = NOT OV_Fault

Gate_AU = RawGate_A AND PWM_Enable
Gate_AL = NOT(RawGate_A) AND PWM_Enable
Gate_BU = RawGate_B AND PWM_Enable
Gate_BL = NOT(RawGate_B) AND PWM_Enable
Gate_CU = RawGate_C AND PWM_Enable
Gate_CL = NOT(RawGate_C) AND PWM_Enable
```

## 6. TwoLevelInverter Unit

상단 스위치 상태를 `Sa`, `Sb`, `Sc`라 할 때 부하 중성점의 공통모드 스위칭 상태는 다음과 같다.

```text
Sn = (Sa + Sb + Sc)/3
Va = (Sa - Sn)*Vdc
Vb = (Sb - Sn)*Vdc
Vc = (Sc - Sn)*Vdc
```

이 방정식은 이상적인 2레벨 bridge의 중성점 기준 상전압을 표현하며 diode freewheeling 및 스위칭 손실은 포함하지 않는다.

## 7. RLLoadPhase Unit

각 상의 상태 업데이트는 forward Euler 방식이다.

```text
di/dt = (v - R*i)/L
i_next = i_prev + Ts*(v - R*i_prev)/L
```

`R=0.5 ohm`, `L=2.5 mH`, `Ts=10 us`를 사용한다.

