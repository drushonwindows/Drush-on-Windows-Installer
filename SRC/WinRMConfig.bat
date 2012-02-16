@ECHO OFF

IF "%1"=="-help" (
  GOTO syntax
)
IF "%1"=="-h" (
  GOTO syntax
)
IF "%1"=="-?" (
  GOTO syntax
)

sc config WinRM start= delayed-auto
sc start WinRM 

IF NOT "%ERRORLEVEL%"=="0" ( 
  IF NOT "%ERRORLEVEL%"=="1056" (
    @ECHO Start WinRM failed with code %ERRORLEVEL%
    GOTO error
  ) 
)  
@ECHO Service already running is not a fatal error. Resuming execution. 

IF NOT "%1"=="" (
  IF NOT "%1"=="0" (
    IF "%1"=="80" (
      CALL winrm set winrm/config/service @{EnableCompatibilityHttpListener="true"} 2>&1 
    ) ELSE (
      CALL winrm create winrm/config/listener?Address=*+Transport=HTTP @{Port="%1"} 2>&1
      IF ERRORLEVEL 1 (
        CALL winrm set winrm/config/listener?Address=*+Transport=HTTP @{Port="%1"} 2>&1
      )
    )
  )
)

IF ERRORLEVEL 1 ( 
  @ECHO Enable WinRM HTTP Listener failed to execute!
  GOTO error
)

IF NOT "%1"=="" (
  IF NOT "%1"=="0" (
    IF "%1"=="80" (
      netsh advfirewall firewall set rule name="Windows Remote Management - Compatibility Mode (HTTP-In)" new enable=yes
    ) ELSE (
      netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new localport=%1
      netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new enable=yes
    )
  )
)

IF ERRORLEVEL 1 ( 
  @ECHO Enable WinRM firewall failed to execute!
  GOTO error
)

GOTO end

:syntax
@ECHO Syntax: WinRMConfig.bat [port number]
GOTO end

:error
GOTO end

:end
@ECHO Done.
