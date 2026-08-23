@echo off
REM -- Build LOWPASSF.EXE with MASM 6.11, outputs to .\BUILD\
if not exist BUILD mkdir BUILD
cd BUILD
ML.EXE /Fl /I..\ ..\LOWPASSF.ASM
cd ..
