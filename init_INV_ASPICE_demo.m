%% INV ASPICE inverter demo parameters
% All values are illustrative assumptions, not Hyundai Mobis specifications.

INV_Ts                = 1.0e-5;   % [s] model/control sample time
INV_StopTime          = 0.28;     % [s]

INV_VdcNom            = 400.0;    % [V]
INV_OV_SetThreshold   = 420.0;    % [V], strict greater-than comparison
INV_OV_ResetThreshold = 400.0;    % [V], reset is allowed below this value
INV_OV_DebounceTime   = 0.100;    % [s]
INV_OV_DebounceCount  = round(INV_OV_DebounceTime / INV_Ts);

INV_PwmFrequency      = 10000.0;  % [Hz]
INV_Tpwm              = 1.0 / INV_PwmFrequency;
INV_ElectricalFreq    = 50.0;     % [Hz]
INV_ModulationIndex   = 0.80;     % [-]

INV_LoadR             = 0.50;     % [ohm/phase]
INV_LoadL             = 2.5e-3;   % [H/phase]

% Built-in demonstration scenario
INV_ShortOvStart      = 0.030;     % [s]
INV_ShortOvEnd        = 0.080;     % [s]
INV_LongOvStart       = 0.100;     % [s]
INV_LongOvEnd         = 0.230;     % [s]
INV_ResetTime         = 0.250;     % [s]
INV_ResetPulseWidth   = 0.001;     % [s]

assert(INV_OV_DebounceCount >= 1, 'Debounce count must be positive.');
assert(INV_Ts <= INV_Tpwm/5, 'Sample time must resolve the PWM carrier.');

