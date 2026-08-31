function exportedFiles = export_INV_model_diagrams()
%EXPORT_INV_MODEL_DIAGRAMS Export top-level and diagnostic diagrams as PNG.

rootDir = fileparts(mfilename('fullpath'));
model = 'INV_ASPICE_Inverter_Demo';
modelPath = fullfile(rootDir, [model '.slx']);
if ~isfile(modelPath)
    build_INV_ASPICE_demo();
end
load_system(modelPath);

resultsDir = fullfile(rootDir, 'results');
if ~isfolder(resultsDir)
    mkdir(resultsDir);
end

topFile = fullfile(resultsDir, 'model_architecture.png');
diagFile = fullfile(resultsDir, 'voltage_diagnosis_detail.png');

print(['-s' model], '-dpng', '-r160', topFile);
print(['-s' model '/Voltage_Diagnosis'], '-dpng', '-r160', diagFile);

exportedFiles = string({topFile; diagFile});
fprintf('Exported model diagrams:\n%s\n%s\n', topFile, diagFile);
end

