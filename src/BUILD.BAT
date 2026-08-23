@echo off
REM -- Build LOWPASSF.EXE with MASM 6.11, outputs to .\BUILD\
if not exist BUILD mkdir BUILD
cd BUILD
ML.EXE /Fl /I..\ ..\LOWPASSF.ASM
if errorlevel 1 goto fail
echo BUILD OK: BUILD\LOWPASSF.EXE
cd ..
goto end
:fail
echo BUILD FAILED -- see BUILD\LOWPASSF.LST listing above
cd ..
:end
