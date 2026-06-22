%% Runs all unit tests for ADC_Project

clc;

projectRoot = fileparts(mfilename("fullpath"));

addpath(fullfile(projectRoot, "Design"));
addpath(fullfile(projectRoot, "Test"));

results = runtests(fullfile(projectRoot, "Test"));
disp(results);