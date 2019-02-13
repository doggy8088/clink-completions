@echo off

REM choco install clink -y

net session >nul 2>&1
if %errorLevel% == 0 (
    GOTO Install
) else (
    echo Failure: Administrative permissions required!!!
    GOTO End
)

:Install

SET TargetFolder="%ProgramFiles(x86)%\clink\0.4.9"

XCOPY /E /Y modules           %TargetFolder%\modules\
XCOPY /E /Y spec              %TargetFolder%\spec\
XCOPY /E /Y dotnetcli21.lua   %TargetFolder%\
XCOPY /E /Y npm.lua           %TargetFolder%\
XCOPY /E /Y angular-cli-6.lua %TargetFolder%\
XCOPY /E /Y chocolatey.lua    %TargetFolder%\
XCOPY /E /Y git.lua           %TargetFolder%\
XCOPY /E /Y git_prompt.lua    %TargetFolder%\
XCOPY /E /Y net.lua           %TargetFolder%\
XCOPY /E /Y ssh.lua           %TargetFolder%\
XCOPY /E /Y yarn.lua          %TargetFolder%\

XCOPY /E /Y .busted           %TargetFolder%\
XCOPY /E /Y .init.lua         %TargetFolder%\
XCOPY /E /Y .luacheckrc       %TargetFolder%\
XCOPY /E /Y .luacov           %TargetFolder%\

:End