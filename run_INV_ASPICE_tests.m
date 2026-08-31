function summary = run_INV_ASPICE_tests()
%RUN_INV_ASPICE_TESTS Simulate and verify the inverter/OV diagnosis demo.

rootDir = fileparts(mfilename('fullpath'));
initFile = fullfile(rootDir, 'init_INV_ASPICE_demo.m');
run(initFile);
evalin('base', sprintf('run(''%s'')', strrep(initFile, '''', '''''')));

model = 'INV_ASPICE_Inverter_Demo';
modelPath = fullfile(rootDir, [model '.slx']);
if ~isfile(modelPath)
    build_INV_ASPICE_demo();
end
load_system(modelPath);

simIn = Simulink.SimulationInput(model);
simIn = simIn.setModelParameter( ...
    'StopTime', num2str(INV_StopTime, '%.15g'), ...
    'ReturnWorkspaceOutputs', 'on');
simOut = sim(simIn);

vdcLog = simOut.get('Vdc_log');
faultLog = simOut.get('Fault_log');
pwmLog = simOut.get('PWMEnable_log');
countLog = simOut.get('DebounceCount_log');
gateLog = simOut.get('Gate6_log');
vabcLog = simOut.get('Vabc_log');
iabcLog = simOut.get('Iabc_log');

t = faultLog.Time(:);
vdc = asMatrix(vdcLog);
fault = logical(asMatrix(faultLog));
pwmEnable = logical(asMatrix(pwmLog));
count = asMatrix(countLog);
gate6 = logical(asMatrix(gateLog));
vabc = asMatrix(vabcLog);
iabc = asMatrix(iabcLog);

% Event times.
faultRise = find(diff([false; fault(:,1)]) == 1, 1, 'first');
assert(~isempty(faultRise), 'TC-DIAG-002: OV fault was never asserted.');
faultSetTime = t(faultRise);
faultFallCandidates = find(diff([fault(:,1); fault(end,1)]) == -1);
faultFallCandidates = faultFallCandidates(t(faultFallCandidates) >= INV_ResetTime - INV_Ts);
assert(~isempty(faultFallCandidates), 'TC-REC-001: OV fault was never cleared.');
faultClearTime = t(faultFallCandidates(1));
expectedFaultTime = INV_LongOvStart + INV_OV_DebounceTime - INV_Ts;

% Test evaluations.
shortMask = t >= INV_ShortOvStart & t < INV_ShortOvEnd;
betweenMask = t >= INV_ShortOvEnd + INV_Ts & t < INV_LongOvStart;
faultMask = t >= faultSetTime & t < INV_ResetTime;
latchMask = t >= INV_LongOvEnd + INV_Ts & t < INV_ResetTime;
normalMask = t >= 0.010 & t < INV_ShortOvStart;

tcCtrl = all(isfinite(iabc(:))) && max(abs(iabc(normalMask,:)), [], 'all') > 1.0;
tcShort = ~any(fault(shortMask,1)) && max(count(shortMask,1)) < INV_OV_DebounceCount;
tcCounterReset = all(count(betweenMask,1) == 0);
tcDetectTime = abs(faultSetTime - expectedFaultTime) <= 2*INV_Ts;
tcPwmDisable = all(~pwmEnable(faultMask,1));
tcAllGatesOff = all(~gate6(faultMask,:), 'all');
tcLatch = all(fault(latchMask,1));
tcRecovery = abs(faultClearTime - INV_ResetTime) <= 2*INV_Ts && ...
    any(pwmEnable(t >= INV_ResetTime & t < INV_ResetTime + 10*INV_Ts,1));
tcNeutral = max(abs(sum(vabc,2))) < 1e-9;

testID = [ ...
    "TC-CTRL-001"; "TC-DIAG-001"; "TC-DIAG-003"; "TC-DIAG-002"; ...
    "TC-SAFE-001A"; "TC-SAFE-001B"; "TC-LATCH-001"; ...
    "TC-REC-001"; "TC-INV-001"];
pass = [tcCtrl; tcShort; tcCounterReset; tcDetectTime; tcPwmDisable; ...
    tcAllGatesOff; tcLatch; tcRecovery; tcNeutral];
measured = [ ...
    string(sprintf('peak |Iabc|=%.3f A', max(abs(iabc(normalMask,:)), [], 'all'))); ...
    string(sprintf('short OV max count=%.0f', max(count(shortMask,1)))); ...
    string(sprintf('count after short OV=%.0f', max(count(betweenMask,1)))); ...
    string(sprintf('fault set t=%.6f s', faultSetTime)); ...
    string(sprintf('PWM enabled samples during fault=%d', nnz(pwmEnable(faultMask,1)))); ...
    string(sprintf('nonzero gate samples during fault=%d', nnz(gate6(faultMask,:)))); ...
    string(sprintf('fault-low samples before reset=%d', nnz(~fault(latchMask,1)))); ...
    string(sprintf('fault clear t=%.6f s', faultClearTime)); ...
    string(sprintf('max |Va+Vb+Vc|=%.3e V', max(abs(sum(vabc,2)))))];
expected = [ ...
    "finite 3-phase current, peak > 1 A"; ...
    "50 ms OV does not reach 100 ms count"; ...
    "counter returns to zero"; ...
    string(sprintf('fault set at %.6f s +/- 2Ts', expectedFaultTime)); ...
    "PWM_Enable=0 while fault latched"; ...
    "all six gates=0 while fault latched"; ...
    "fault remains latched until reset"; ...
    string(sprintf('fault clear at %.6f s +/- 2Ts', INV_ResetTime)); ...
    "Va+Vb+Vc=0"];

summary = table(testID, pass, measured, expected, ...
    'VariableNames', {'TestID','Pass','Measured','Expected'});

resultsDir = fullfile(rootDir, 'results');
if ~isfolder(resultsDir)
    mkdir(resultsDir);
end
writetable(summary, fullfile(resultsDir, 'test_summary.csv'));
save(fullfile(resultsDir, 'simulation_results.mat'), ...
    't', 'vdc', 'fault', 'pwmEnable', 'count', 'gate6', 'vabc', 'iabc', ...
    'faultSetTime', 'faultClearTime', 'summary');

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1200 900]);
tiledlayout(fig, 4, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot(t, vdc(:,1), 'LineWidth', 1.3); hold on;
yline(INV_OV_SetThreshold, '--r', 'OV set');
yline(INV_OV_ResetThreshold, ':k', 'reset threshold');
grid on; ylabel('Vdc [V]'); title('DC-Link over-voltage diagnosis and inverter response');

nexttile;
stairs(t, double(fault(:,1)), 'r', 'LineWidth', 1.3); hold on;
stairs(t, double(pwmEnable(:,1)), 'b', 'LineWidth', 1.0);
grid on; ylim([-0.1 1.1]); ylabel('Logic'); legend('OV Fault','PWM Enable','Location','best');

nexttile;
plot(t, vabc, 'LineWidth', 0.7);
grid on; ylabel('Vabc [V]'); legend('Va','Vb','Vc','Location','best');

nexttile;
plot(t, iabc, 'LineWidth', 0.9);
grid on; ylabel('Iabc [A]'); xlabel('Time [s]'); legend('Ia','Ib','Ic','Location','best');

exportgraphics(fig, fullfile(resultsDir, 'simulation_overview.png'), 'Resolution', 160);
close(fig);

disp(summary);
fprintf('Fault asserted at %.6f s; cleared at %.6f s.\n', faultSetTime, faultClearTime);
fprintf('Result files: %s\n', resultsDir);

if ~all(pass)
    failedIDs = strjoin(cellstr(testID(~pass)), ', ');
    error('INV_ASPICE:VerificationFailed', 'Failed tests: %s', failedIDs);
end
fprintf('All %d verification checks PASSED.\n', height(summary));
end

function data = asMatrix(ts)
data = squeeze(ts.Data);
n = numel(ts.Time);
if isvector(data)
    data = data(:);
elseif size(data,1) ~= n && size(data,2) == n
    data = data.';
end
data = reshape(data, n, []);
end
