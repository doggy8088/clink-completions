@echo off

REM choco install clink -y

SET TargetFolder="c:\Program Files (x86)\clink\0.4.9"

XCOPY /E /Y modules           %TargetFolder%\modules\
XCOPY /E /Y spec              %TargetFolder%\spec\
XCOPY /E /Y dotnetcli21.lua   %TargetFolder%\
XCOPY /E /Y npm.lua           %TargetFolder%\
XCOPY /E /Y angular-cli-6.lua %TargetFolder%\

XCOPY /E /Y .busted     %TargetFolder%\
XCOPY /E /Y .init.lua   %TargetFolder%\
XCOPY /E /Y .luacheckrc %TargetFolder%\
XCOPY /E /Y .luacov     %TargetFolder%\
