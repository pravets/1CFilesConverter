@ECHO OFF

rem Convert (dump) 1C configuration file (*.cf) to 1C:Designer XML format
rem %1 - path to 1C configuration source (1C configuration file (*.cf), infobase or 1C:EDT project)
rem %2 - path to folder to save configuration files in 1C:Designer XML format

IF not defined V8_VERSION set V8_VERSION=8.3.20.2290
IF not defined V8_TEMP set V8_TEMP=%TEMP%\1c

IF not "%V8_CONVERT_TOOL%" equ "designer" IF not "%V8_CONVERT_TOOL%" equ "ibcmd" set V8_CONVERT_TOOL=designer
set V8_TOOL="C:\Program Files\1cv8\%V8_VERSION%\bin\1cv8.exe"
set IBCMD_TOOL="C:\Program Files\1cv8\%V8_VERSION%\bin\ibcmd.exe"
IF not defined V8_RING_TOOL (
    FOR /F "usebackq tokens=1 delims=" %%i IN (`where ring`) DO (
        set V8_RING_TOOL="%%i"
    )
)

set IB_PATH=%V8_TEMP%\tmp_db
set WS_PATH=%V8_TEMP%\edt_ws

set CONFIG_SOURCE=%1
IF defined CONFIG_SOURCE set CONFIG_SOURCE=%CONFIG_SOURCE:"=%
set CONFIG_PATH=%2
IF defined CONFIG_PATH set CONFIG_PATH=%CONFIG_PATH:"=%

IF not defined CONFIG_SOURCE (
    echo Missed parameter 1 "path to 1C configuration source (1C configuration file (*.cf), infobase or 1C:EDT project)"
    exit /b 1
)
IF not defined CONFIG_PATH (
    echo Missed parameter 2 "path to folder to save configuration files in 1C:Designer XML format"
    exit /b 1
)

echo Clear temporary files...
IF exist "%V8_TEMP%" rd /S /Q "%V8_TEMP%"
md "%V8_TEMP%"
IF exist "%CONFIG_PATH%" rd /S /Q "%CONFIG_PATH%"
md "%CONFIG_PATH%"

echo Checking configuration source type...

IF /i "%CONFIG_SOURCE:~-3%" equ ".cf" (
    echo Source type: Configuration file ^(CF^)
    goto export_cf
)
IF exist "%CONFIG_SOURCE%\1cv8.1cd" (
    echo Source type: Infobase
    set IB_PATH=%CONFIG_SOURCE%
    goto export_ib
)
IF exist "%CONFIG_SOURCE%\DT-INF\" (
    echo Source type: 1C:EDT project
    goto export_edt
)

echo Error cheking type of configuration "%CONFIG_SOURCE%"!
echo Infobase, configuration file (*.cf) or 1C:EDT project expected.
exit /b 1

:export_cf

echo Creating infobase "%IB_PATH%" from file "%CONFIG_SOURCE%"...

md "%IB_PATH%"

IF "%V8_CONVERT_TOOL%" equ "designer" (
    %V8_TOOL% CREATEINFOBASE File="%IB_PATH%"; /DisableStartupDialogs /UseTemplate "%CONFIG_SOURCE%"
) ELSE (
    %IBCMD_TOOL% infobase create --db-path="%IB_PATH%" --create-database --load="%CONFIG_SOURCE%"
)

:export_ib

echo Export configuration from infobase "%IB_PATH%" to 1C:Designer XML format "%CONFIG_PATH%"...
IF "%V8_CONVERT_TOOL%" equ "designer" (
    %V8_TOOL% DESIGNER /IBConnectionString File="%IB_PATH%"; /DisableStartupDialogs /DumpConfigToFiles "%CONFIG_PATH%" -force
) ELSE (
    %IBCMD_TOOL% infobase config export --db-path="%IB_PATH%" "%CONFIG_PATH%" --force
)

goto end

:export_edt

echo Export "%EDT_PATH%" to 1C:Designer XML format "%CONFIG_PATH%"...
md "%WS_PATH%"
call %V8_RING_TOOL% edt workspace export --project "%CONFIG_SOURCE%" --configuration-files "%CONFIG_PATH%" --workspace-location "%WS_PATH%"

:end

echo Clear temporary files...
IF exist "%V8_TEMP%" rd /S /Q "%V8_TEMP%"