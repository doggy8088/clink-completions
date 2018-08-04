@echo off

REM choco install clink -y

SET TargetFolder="c:\Program Files (x86)\clink\0.4.9\modules\"

XCOPY /E modules %TargetFolder %
XCOPY /E spec %TargetFolder%
XCOPY /E dotnetcli21.lua %TargetFolder%