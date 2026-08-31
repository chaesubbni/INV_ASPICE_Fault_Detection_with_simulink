function modelPath = build_INV_ASPICE_demo()
%BUILD_INV_ASPICE_DEMO Build the executable inverter/diagnosis Simulink model.
% The generated plant is an ideal switching-equation model and does not
% require Simscape Electrical.

rootDir = fileparts(mfilename('fullpath'));
initFile = fullfile(rootDir, 'init_INV_ASPICE_demo.m');
run(initFile);
evalin('base', sprintf('run(''%s'')', strrep(initFile, '''', '''''')));

model = 'INV_ASPICE_Inverter_Demo';
modelPath = fullfile(rootDir, [model '.slx']);

if bdIsLoaded(model)
    close_system(model, 0);
end

if isfile(modelPath)
    load_system(modelPath);
    Simulink.BlockDiagram.deleteContents(model);
else
    new_system(model, 'Model');
end

set_param(model, ...
    'SolverType', 'Fixed-step', ...
    'Solver', 'FixedStepDiscrete', ...
    'FixedStep', num2str(INV_Ts, '%.15g'), ...
    'StartTime', '0.0', ...
    'StopTime', num2str(INV_StopTime, '%.15g'), ...
    'SaveTime', 'on', ...
    'TimeSaveName', 'tout', ...
    'SignalLogging', 'off', ...
    'ReturnWorkspaceOutputs', 'on', ...
    'InitFcn', "run(fullfile(fileparts(get_param(bdroot,'FileName')),'init_INV_ASPICE_demo.m'))");

addScenario([model '/DC_Link_Scenario']);
addSpwm([model '/SPWM_Controller']);
addDiagnosis([model '/Voltage_Diagnosis']);
addFaultManager([model '/Fault_Manager']);
addInverter([model '/TwoLevel_Inverter']);
addLoad([model '/RL_3Phase_Load']);

set_param([model '/DC_Link_Scenario'], 'Position', [30 55 230 155], 'BackgroundColor', 'lightBlue');
set_param([model '/SPWM_Controller'], 'Position', [30 235 230 335], 'BackgroundColor', 'lightBlue');
set_param([model '/Voltage_Diagnosis'], 'Position', [295 50 515 175], 'BackgroundColor', 'yellow');
set_param([model '/Fault_Manager'], 'Position', [590 210 810 365], 'BackgroundColor', 'orange');
set_param([model '/TwoLevel_Inverter'], 'Position', [885 215 1085 340], 'BackgroundColor', 'green');
set_param([model '/RL_3Phase_Load'], 'Position', [1160 215 1360 340], 'BackgroundColor', 'cyan');

% Main architecture connections.
wire(model, 'DC_Link_Scenario/1', 'Voltage_Diagnosis/1');
wire(model, 'DC_Link_Scenario/2', 'Voltage_Diagnosis/2');
wire(model, 'DC_Link_Scenario/1', 'TwoLevel_Inverter/4');
wire(model, 'SPWM_Controller/1', 'Fault_Manager/1');
wire(model, 'SPWM_Controller/2', 'Fault_Manager/2');
wire(model, 'SPWM_Controller/3', 'Fault_Manager/3');
wire(model, 'Voltage_Diagnosis/1', 'Fault_Manager/4');
wire(model, 'Fault_Manager/1', 'TwoLevel_Inverter/1');
wire(model, 'Fault_Manager/3', 'TwoLevel_Inverter/2');
wire(model, 'Fault_Manager/5', 'TwoLevel_Inverter/3');
wire(model, 'TwoLevel_Inverter/1', 'RL_3Phase_Load/1');
wire(model, 'TwoLevel_Inverter/2', 'RL_3Phase_Load/2');
wire(model, 'TwoLevel_Inverter/3', 'RL_3Phase_Load/3');

% Vector monitors.
add_block('simulink/Signal Routing/Mux', [model '/Mux_Vabc'], ...
    'Inputs', '3', 'Position', [1115 410 1120 475]);
add_block('simulink/Signal Routing/Mux', [model '/Mux_Iabc'], ...
    'Inputs', '3', 'Position', [1390 410 1395 475]);
add_block('simulink/Signal Routing/Mux', [model '/Mux_Gate6'], ...
    'Inputs', '6', 'Position', [845 390 850 510]);

for k = 1:3
    wire(model, sprintf('TwoLevel_Inverter/%d', k), sprintf('Mux_Vabc/%d', k));
    wire(model, sprintf('RL_3Phase_Load/%d', k), sprintf('Mux_Iabc/%d', k));
end
for k = 1:6
    wire(model, sprintf('Fault_Manager/%d', k), sprintf('Mux_Gate6/%d', k));
end

% Logged signals used by the automated verification script.
addLogger(model, 'Log_Vdc', 'Vdc_log', [300 405 410 435]);
addLogger(model, 'Log_OV_Fault', 'Fault_log', [300 450 410 480]);
addLogger(model, 'Log_PWM_Enable', 'PWMEnable_log', [600 435 730 465]);
addLogger(model, 'Log_DebounceCount', 'DebounceCount_log', [300 495 440 525]);
addLogger(model, 'Log_Gate6', 'Gate6_log', [880 455 990 485]);
addLogger(model, 'Log_Vabc', 'Vabc_log', [1160 430 1270 460]);
addLogger(model, 'Log_Iabc', 'Iabc_log', [1420 430 1530 460]);

wire(model, 'DC_Link_Scenario/1', 'Log_Vdc/1');
wire(model, 'Voltage_Diagnosis/1', 'Log_OV_Fault/1');
wire(model, 'Fault_Manager/7', 'Log_PWM_Enable/1');
wire(model, 'Voltage_Diagnosis/2', 'Log_DebounceCount/1');
wire(model, 'Mux_Gate6/1', 'Log_Gate6/1');
wire(model, 'Mux_Vabc/1', 'Log_Vabc/1');
wire(model, 'Mux_Iabc/1', 'Log_Iabc/1');

% Root outputs make the key interface explicit when the model is reused.
addOut(model, 'Vdc', 1, [1550 60 1580 80]);
addOut(model, 'OV_Fault', 2, [1550 100 1580 120]);
addOut(model, 'PWM_Enable', 3, [1550 140 1580 160]);
addOut(model, 'Vabc', 4, [1550 200 1580 220]);
addOut(model, 'Iabc', 5, [1550 250 1580 270]);
wire(model, 'DC_Link_Scenario/1', 'Vdc/1');
wire(model, 'Voltage_Diagnosis/1', 'OV_Fault/1');
wire(model, 'Fault_Manager/7', 'PWM_Enable/1');
wire(model, 'Mux_Vabc/1', 'Vabc/1');
wire(model, 'Mux_Iabc/1', 'Iabc/1');

annotationText = sprintf([ ...
    'INV ASPICE DEMO - ideal 2-level VSI + SPWM + R-L load + DC-Link OV diagnosis\n' ...
    'Illustrative values only | Ts = %.0f us | fpwm = %.0f kHz | OV: > %.0f V for %.0f ms'], ...
    INV_Ts*1e6, INV_PwmFrequency/1e3, INV_OV_SetThreshold, INV_OV_DebounceTime*1e3);
note = Simulink.Annotation(model, annotationText);
note.Position = [25 5 1050 35];
note.FontSize = 12;
note.FontWeight = 'bold';

set_param(model, 'SimulationCommand', 'update');
save_system(model, modelPath);
fprintf('Built model: %s\n', modelPath);
end

function addScenario(path)
add_block('built-in/Subsystem', path);
add_block('simulink/Sources/Constant', [path '/Vdc_Nominal'], ...
    'Value', 'INV_VdcNom', 'Position', [25 35 85 65]);
add_block('simulink/Sources/Step', [path '/Short_OV_On'], ...
    'Time', 'INV_ShortOvStart', 'Before', '0', 'After', '30', ...
    'SampleTime', 'INV_Ts', 'Position', [25 85 85 115]);
add_block('simulink/Sources/Step', [path '/Short_OV_Off'], ...
    'Time', 'INV_ShortOvEnd', 'Before', '0', 'After', '-30', ...
    'SampleTime', 'INV_Ts', 'Position', [25 130 85 160]);
add_block('simulink/Sources/Step', [path '/Long_OV_On'], ...
    'Time', 'INV_LongOvStart', 'Before', '0', 'After', '30', ...
    'SampleTime', 'INV_Ts', 'Position', [25 175 85 205]);
add_block('simulink/Sources/Step', [path '/Long_OV_Off_to_390V'], ...
    'Time', 'INV_LongOvEnd', 'Before', '0', 'After', '-40', ...
    'SampleTime', 'INV_Ts', 'Position', [25 220 85 250]);
add_block('simulink/Math Operations/Add', [path '/Build_Vdc_Profile'], ...
    'Inputs', '+++++', 'Position', [150 80 180 220]);
addOut(path, 'Vdc', 1, [240 135 270 155]);

wire(path, 'Vdc_Nominal/1', 'Build_Vdc_Profile/1');
wire(path, 'Short_OV_On/1', 'Build_Vdc_Profile/2');
wire(path, 'Short_OV_Off/1', 'Build_Vdc_Profile/3');
wire(path, 'Long_OV_On/1', 'Build_Vdc_Profile/4');
wire(path, 'Long_OV_Off_to_390V/1', 'Build_Vdc_Profile/5');
wire(path, 'Build_Vdc_Profile/1', 'Vdc/1');

add_block('simulink/Sources/Step', [path '/Reset_Set'], ...
    'Time', 'INV_ResetTime', 'Before', '0', 'After', '1', ...
    'SampleTime', 'INV_Ts', 'Position', [25 300 85 330]);
add_block('simulink/Sources/Step', [path '/Reset_Clear'], ...
    'Time', 'INV_ResetTime + INV_ResetPulseWidth', 'Before', '0', 'After', '-1', ...
    'SampleTime', 'INV_Ts', 'Position', [25 345 85 375]);
add_block('simulink/Math Operations/Add', [path '/Build_Reset_Pulse'], ...
    'Inputs', '++', 'Position', [150 310 180 365]);
addOut(path, 'ResetFault', 2, [240 325 270 345]);
wire(path, 'Reset_Set/1', 'Build_Reset_Pulse/1');
wire(path, 'Reset_Clear/1', 'Build_Reset_Pulse/2');
wire(path, 'Build_Reset_Pulse/1', 'ResetFault/1');
end

function addSpwm(path)
add_block('built-in/Subsystem', path);
add_block('simulink/Sources/Clock', [path '/Clock'], 'Position', [25 125 55 145]);
add_block('simulink/Math Operations/Gain', [path '/Electrical_Angle'], ...
    'Gain', '2*pi*INV_ElectricalFreq', 'Position', [90 115 165 155]);
add_block('simulink/Math Operations/Bias', [path '/Phase_B_minus_120deg'], ...
    'Bias', '-2*pi/3', 'Position', [200 165 300 195]);
add_block('simulink/Math Operations/Bias', [path '/Phase_C_plus_120deg'], ...
    'Bias', '2*pi/3', 'Position', [200 235 300 265]);
add_block('simulink/Math Operations/Trigonometric Function', [path '/Sin_A'], ...
    'Operator', 'sin', 'Position', [335 80 380 110]);
add_block('simulink/Math Operations/Trigonometric Function', [path '/Sin_B'], ...
    'Operator', 'sin', 'Position', [335 165 380 195]);
add_block('simulink/Math Operations/Trigonometric Function', [path '/Sin_C'], ...
    'Operator', 'sin', 'Position', [335 235 380 265]);
for phase = 'ABC'
    add_block('simulink/Math Operations/Gain', [path '/Modulation_' phase], ...
        'Gain', 'INV_ModulationIndex', 'Position', phasePos(phase, 420, 80, 70, 30));
end
add_block('simulink/Sources/Repeating Sequence', [path '/Triangular_Carrier'], ...
    'rep_seq_t', '[0 INV_Tpwm/2 INV_Tpwm]', ...
    'rep_seq_y', '[-1 1 -1]', 'Position', [420 330 520 370]);

for idx = 1:3
    phase = 'ABC'; phase = phase(idx);
    y = 75 + (idx-1)*85;
    add_block('simulink/Logic and Bit Operations/Relational Operator', ...
        [path '/Compare_' phase], 'Operator', '>=', 'Position', [570 y 615 y+35]);
    addOut(path, ['RawGate_' phase], idx, [675 y+7 705 y+27]);
    wire(path, ['Modulation_' phase '/1'], ['Compare_' phase '/1']);
    wire(path, 'Triangular_Carrier/1', ['Compare_' phase '/2']);
    wire(path, ['Compare_' phase '/1'], ['RawGate_' phase '/1']);
end

wire(path, 'Clock/1', 'Electrical_Angle/1');
wire(path, 'Electrical_Angle/1', 'Sin_A/1');
wire(path, 'Electrical_Angle/1', 'Phase_B_minus_120deg/1');
wire(path, 'Electrical_Angle/1', 'Phase_C_plus_120deg/1');
wire(path, 'Phase_B_minus_120deg/1', 'Sin_B/1');
wire(path, 'Phase_C_plus_120deg/1', 'Sin_C/1');
wire(path, 'Sin_A/1', 'Modulation_A/1');
wire(path, 'Sin_B/1', 'Modulation_B/1');
wire(path, 'Sin_C/1', 'Modulation_C/1');
end

function pos = phasePos(phase, x, y0, dy, h)
idx = find('ABC' == phase, 1);
y = y0 + (idx-1)*dy;
pos = [x y x+90 y+h];
end

function addDiagnosis(path)
add_block('built-in/Subsystem', path);
addIn(path, 'Vdc', 1, [25 55 55 75]);
addIn(path, 'ResetFault', 2, [25 350 55 370]);
add_block('simulink/Sources/Constant', [path '/OV_Set_Threshold'], ...
    'Value', 'INV_OV_SetThreshold', 'Position', [90 100 160 130]);
add_block('simulink/Logic and Bit Operations/Relational Operator', ...
    [path '/OV_Condition'], 'Operator', '>', 'Position', [200 55 245 90]);
wire(path, 'Vdc/1', 'OV_Condition/1');
wire(path, 'OV_Set_Threshold/1', 'OV_Condition/2');

add_block('simulink/Discrete/Unit Delay', [path '/Counter_z1'], ...
    'InitialCondition', '0', 'SampleTime', 'INV_Ts', 'Position', [90 175 135 205]);
add_block('simulink/Sources/Constant', [path '/One'], ...
    'Value', '1', 'Position', [90 225 135 255]);
add_block('simulink/Math Operations/Add', [path '/Increment'], ...
    'Inputs', '++', 'Position', [190 175 220 220]);
add_block('simulink/Discontinuities/Saturation', [path '/Counter_Saturation'], ...
    'UpperLimit', 'INV_OV_DebounceCount', 'LowerLimit', '0', ...
    'Position', [260 175 335 220]);
add_block('simulink/Sources/Constant', [path '/Zero'], ...
    'Value', '0', 'Position', [275 260 325 290]);
add_block('simulink/Signal Routing/Switch', [path '/Reset_Counter_When_Normal'], ...
    'Criteria', 'u2 ~= 0', 'Threshold', '0.5', 'Position', [390 175 440 245]);
wire(path, 'Counter_z1/1', 'Increment/1');
wire(path, 'One/1', 'Increment/2');
wire(path, 'Increment/1', 'Counter_Saturation/1');
wire(path, 'Counter_Saturation/1', 'Reset_Counter_When_Normal/1');
wire(path, 'OV_Condition/1', 'Reset_Counter_When_Normal/2');
wire(path, 'Zero/1', 'Reset_Counter_When_Normal/3');
wire(path, 'Reset_Counter_When_Normal/1', 'Counter_z1/1');

add_block('simulink/Sources/Constant', [path '/Debounce_Count_Limit'], ...
    'Value', 'INV_OV_DebounceCount', 'Position', [475 250 560 280]);
add_block('simulink/Logic and Bit Operations/Relational Operator', ...
    [path '/Fault_Detected'], 'Operator', '>=', 'Position', [600 190 645 225]);
wire(path, 'Reset_Counter_When_Normal/1', 'Fault_Detected/1');
wire(path, 'Debounce_Count_Limit/1', 'Fault_Detected/2');

add_block('simulink/Discrete/Unit Delay', [path '/Fault_z1'], ...
    'InitialCondition', 'false', 'SampleTime', 'INV_Ts', 'Position', [490 50 535 80]);
add_block('simulink/Logic and Bit Operations/Logical Operator', [path '/Latch_OR'], ...
    'Operator', 'OR', 'Inputs', '2', 'Position', [685 75 725 120]);
wire(path, 'Fault_z1/1', 'Latch_OR/1');
wire(path, 'Fault_Detected/1', 'Latch_OR/2');

add_block('simulink/Sources/Constant', [path '/Reset_Threshold'], ...
    'Value', 'INV_OV_ResetThreshold', 'Position', [200 395 280 425]);
add_block('simulink/Logic and Bit Operations/Relational Operator', ...
    [path '/Safe_Voltage_For_Reset'], 'Operator', '<', 'Position', [330 335 375 370]);
add_block('simulink/Logic and Bit Operations/Logical Operator', [path '/Reset_Allowed'], ...
    'Operator', 'AND', 'Inputs', '2', 'Position', [430 340 470 385]);
add_block('simulink/Logic and Bit Operations/Logical Operator', [path '/NOT_Reset_Allowed'], ...
    'Operator', 'NOT', 'Position', [530 345 570 380]);
add_block('simulink/Logic and Bit Operations/Logical Operator', [path '/Next_Fault_State'], ...
    'Operator', 'AND', 'Inputs', '2', 'Position', [785 90 825 135]);
wire(path, 'Vdc/1', 'Safe_Voltage_For_Reset/1');
wire(path, 'Reset_Threshold/1', 'Safe_Voltage_For_Reset/2');
wire(path, 'ResetFault/1', 'Reset_Allowed/1');
wire(path, 'Safe_Voltage_For_Reset/1', 'Reset_Allowed/2');
wire(path, 'Reset_Allowed/1', 'NOT_Reset_Allowed/1');
wire(path, 'Latch_OR/1', 'Next_Fault_State/1');
wire(path, 'NOT_Reset_Allowed/1', 'Next_Fault_State/2');
wire(path, 'Next_Fault_State/1', 'Fault_z1/1');

addOut(path, 'OV_Fault', 1, [885 100 915 120]);
addOut(path, 'DebounceCount', 2, [885 195 915 215]);
addOut(path, 'OV_Condition_Out', 3, [885 280 915 300]);
wire(path, 'Next_Fault_State/1', 'OV_Fault/1');
wire(path, 'Reset_Counter_When_Normal/1', 'DebounceCount/1');
wire(path, 'OV_Condition/1', 'OV_Condition_Out/1');
end

function addFaultManager(path)
add_block('built-in/Subsystem', path);
for idx = 1:3
    phase = 'ABC'; phase = phase(idx);
    y = 45 + (idx-1)*100;
    addIn(path, ['RawGate_' phase], idx, [25 y 55 y+20]);
end
addIn(path, 'OV_Fault', 4, [25 370 55 390]);
add_block('simulink/Logic and Bit Operations/Logical Operator', [path '/PWM_Enable_NOT_Fault'], ...
    'Operator', 'NOT', 'Position', [105 360 150 400]);
wire(path, 'OV_Fault/1', 'PWM_Enable_NOT_Fault/1');

outIdx = 1;
for idx = 1:3
    phase = 'ABC'; phase = phase(idx);
    y = 35 + (idx-1)*110;
    add_block('simulink/Logic and Bit Operations/Logical Operator', [path '/Upper_' phase], ...
        'Operator', 'AND', 'Inputs', '2', 'Position', [240 y 285 y+40]);
    add_block('simulink/Logic and Bit Operations/Logical Operator', [path '/Complement_' phase], ...
        'Operator', 'NOT', 'Position', [105 y+45 150 y+80]);
    add_block('simulink/Logic and Bit Operations/Logical Operator', [path '/Lower_' phase], ...
        'Operator', 'AND', 'Inputs', '2', 'Position', [240 y+60 285 y+100]);
    wire(path, ['RawGate_' phase '/1'], ['Upper_' phase '/1']);
    wire(path, 'PWM_Enable_NOT_Fault/1', ['Upper_' phase '/2']);
    wire(path, ['RawGate_' phase '/1'], ['Complement_' phase '/1']);
    wire(path, ['Complement_' phase '/1'], ['Lower_' phase '/1']);
    wire(path, 'PWM_Enable_NOT_Fault/1', ['Lower_' phase '/2']);
    addOut(path, ['Gate_' phase 'U'], outIdx, [355 y+5 385 y+25]); outIdx = outIdx + 1;
    addOut(path, ['Gate_' phase 'L'], outIdx, [355 y+70 385 y+90]); outIdx = outIdx + 1;
    wire(path, ['Upper_' phase '/1'], ['Gate_' phase 'U/1']);
    wire(path, ['Lower_' phase '/1'], ['Gate_' phase 'L/1']);
end
addOut(path, 'PWM_Enable', 7, [355 390 385 410]);
wire(path, 'PWM_Enable_NOT_Fault/1', 'PWM_Enable/1');
end

function addInverter(path)
add_block('built-in/Subsystem', path);
for idx = 1:3
    phase = 'ABC'; phase = phase(idx);
    y = 50 + (idx-1)*95;
    addIn(path, ['Gate_' phase 'U'], idx, [25 y 55 y+20]);
    add_block('simulink/Signal Attributes/Data Type Conversion', [path '/BoolToDouble_' phase], ...
        'OutDataTypeStr', 'double', 'Position', [90 y-5 160 y+25]);
    wire(path, ['Gate_' phase 'U/1'], ['BoolToDouble_' phase '/1']);
end
addIn(path, 'Vdc', 4, [25 350 55 370]);
add_block('simulink/Math Operations/Add', [path '/Sum_Switch_States'], ...
    'Inputs', '+++', 'Position', [210 105 240 245]);
add_block('simulink/Math Operations/Gain', [path '/Neutral_State_OneThird'], ...
    'Gain', '1/3', 'Position', [285 155 350 195]);
for idx = 1:3
    phase = 'ABC'; phase = phase(idx);
    wire(path, ['BoolToDouble_' phase '/1'], sprintf('Sum_Switch_States/%d', idx));
end
wire(path, 'Sum_Switch_States/1', 'Neutral_State_OneThird/1');

for idx = 1:3
    phase = 'ABC'; phase = phase(idx);
    y = 45 + (idx-1)*100;
    add_block('simulink/Math Operations/Add', [path '/Phase_State_' phase], ...
        'Inputs', '+-', 'Position', [410 y 445 y+45]);
    add_block('simulink/Math Operations/Product', [path '/Phase_Voltage_' phase], ...
        'Inputs', '**', 'Position', [505 y 545 y+45]);
    addOut(path, ['V' lower(phase)], idx, [620 y+10 650 y+30]);
    wire(path, ['BoolToDouble_' phase '/1'], ['Phase_State_' phase '/1']);
    wire(path, 'Neutral_State_OneThird/1', ['Phase_State_' phase '/2']);
    wire(path, ['Phase_State_' phase '/1'], ['Phase_Voltage_' phase '/1']);
    wire(path, 'Vdc/1', ['Phase_Voltage_' phase '/2']);
    wire(path, ['Phase_Voltage_' phase '/1'], ['V' lower(phase) '/1']);
end
end

function addLoad(path)
add_block('built-in/Subsystem', path);
for idx = 1:3
    phase = 'abc'; phase = phase(idx);
    y = 45 + (idx-1)*120;
    upperPhase = upper(phase);
    addIn(path, ['V' phase], idx, [25 y+35 55 y+55]);
    add_block('simulink/Discrete/Unit Delay', [path '/I' phase '_z1'], ...
        'InitialCondition', '0', 'SampleTime', 'INV_Ts', 'Position', [100 y 145 y+30]);
    add_block('simulink/Math Operations/Gain', [path '/R_times_I' phase], ...
        'Gain', 'INV_LoadR', 'Position', [190 y 255 y+30]);
    add_block('simulink/Math Operations/Add', [path '/V_minus_RI_' upperPhase], ...
        'Inputs', '+-', 'Position', [300 y+30 335 y+75]);
    add_block('simulink/Math Operations/Gain', [path '/Ts_over_L_' upperPhase], ...
        'Gain', 'INV_Ts/INV_LoadL', 'Position', [380 y+35 455 y+70]);
    add_block('simulink/Math Operations/Add', [path '/I_next_' upperPhase], ...
        'Inputs', '++', 'Position', [505 y 540 y+55]);
    addOut(path, ['I' phase], idx, [610 y+15 640 y+35]);
    wire(path, ['I' phase '_z1/1'], ['R_times_I' phase '/1']);
    wire(path, ['V' phase '/1'], ['V_minus_RI_' upperPhase '/1']);
    wire(path, ['R_times_I' phase '/1'], ['V_minus_RI_' upperPhase '/2']);
    wire(path, ['V_minus_RI_' upperPhase '/1'], ['Ts_over_L_' upperPhase '/1']);
    wire(path, ['I' phase '_z1/1'], ['I_next_' upperPhase '/1']);
    wire(path, ['Ts_over_L_' upperPhase '/1'], ['I_next_' upperPhase '/2']);
    wire(path, ['I_next_' upperPhase '/1'], ['I' phase '_z1/1']);
    wire(path, ['I_next_' upperPhase '/1'], ['I' phase '/1']);
end
end

function addLogger(system, name, variable, position)
add_block('simulink/Sinks/To Workspace', [system '/' name], ...
    'VariableName', variable, 'SaveFormat', 'Timeseries', ...
    'MaxDataPoints', '1e6', 'Decimation', '1', 'Position', position);
end

function addIn(system, name, port, position)
add_block('simulink/Ports & Subsystems/In1', [system '/' name], ...
    'Port', num2str(port), 'Position', position);
end

function addOut(system, name, port, position)
add_block('simulink/Ports & Subsystems/Out1', [system '/' name], ...
    'Port', num2str(port), 'Position', position);
end

function wire(system, source, destination)
add_line(system, source, destination, 'autorouting', 'on');
end
