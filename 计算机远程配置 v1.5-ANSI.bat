@echo on
color 0a
:: �����ӳ�չ��ģʽ������ʹ�ö�̬����
setlocal ENABLEDELAYEDEXPANSION
title �����Զ�����ýű�
:: ��ӡ��ǰ�ű��ļ����ļ��ṹ
cd /D "%~dp0"
tree /F
echo �����Զ�����ýű� v1.5



:: Check if the script is running as Administrator
net session >nul 2>&1
if %errorlevel% == 0 (
    echo Running as Administrator.
    goto initlization
) else (
    echo Not running as Administrator.
)
:: Create a temporary VBScript file to elevate privileges
set "temp_vbs=%temp%\elevate.vbs"
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp_vbs%"
echo UAC.ShellExecute "%~f0", "", "", "runas", 1 >> "%temp_vbs%"
:: Run the VBScript file to elevate the batch file
cscript //nologo "%temp_vbs%"
del "%temp_vbs%"
exit



:initlization
:: ------------------------------------------------------------------------------------------------------------------------
:: ѡȡ����ϵͳ
:: ��ȡ����ϵͳ��Ϣ
for /f "tokens=2 delims==" %%G in ('wmic os get version /value') do set OS_VERSION=%%G
for /f "tokens=2 delims==" %%G in ('wmic os get buildnumber /value') do set OS_BUILDNUMBER=%%G
:: �ж� Windows 10�� Windows 11
if "%OS_VERSION:~0,3%" == "10." (
    if %OS_BUILDNUMBER% LSS 22000 (
        set OS_NAME=Windows10
    ) else (
        set OS_NAME=Windows11
    )
)
:: �ж� Windows 7�� Windows XP
if "%OS_VERSION:~0,3%" == "6.1" set OS_NAME=Windows7
if "%OS_VERSION:~0,3%" == "5.1" set OS_NAME=WindowsXP
:: ��ӡ�жϽ��
echo [Windows NT �ں˰汾]:"%OS_VERSION%",[����ϵͳ�ڲ��汾��]:"%OS_BUILDNUMBER%",[����ϵͳ]:"%OS_NAME%"
:: �ж�ִ����������ת
if not defined OS_NAME (
    echo Unsupported Windows version
    goto NoSupport
)
if "%OS_NAME%" == "Windows11" (
    echo Windows11 is not supported
    goto NoSupport
)
if "%OS_NAME%" == "Windows10" (
    echo Running Windows 10 code
    goto Windows10
)
if "%OS_NAME%" == "Windows7" (
    echo Running Windows 7 code
    goto Windows7
)
if "%OS_NAME%" == "WindowsXP" (
    echo Running Windows XP code
    goto WindowsXP
)
:: ------------------------------------------------------------------------------------------------------------------------



:Windows10
:: ------------------------------------------------------------------------------------------------------------------------
:: 1. ע�����
:: 1.1 ����ע�����ص�����
reg export "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" "%~dp0CombinedBackup.reg" /y
reg export "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Personalization" "%~dp0PersonalizationBackup.reg" /y
:: 1.2 ��ԭע���
:: reg import "%~dp0CombinedBackup.reg"
:: reg import "%~dp0PersonalizationBackup.reg"



:: 2. �滻ϵͳ�ļ�
:: 2.1 �滻ϵͳ�ļ�·��GroupPolicy
xcopy "%~dp0.\GroupPolicy" "C:\Windows\System32\GroupPolicy" /E /Y /I
:: 2.2 ִ��ע���reg�ļ�
reg import "%~dp0Microsoft_output.reg"



:: 3. �޸ķ���
:: 3.1 ���÷�����������Ϊ���Զ���
sc config "SessionEnv" start=auto
sc config "TermService" start=auto
sc config "UmRdpService" start=auto
:: 3.2 ��������
net start "SessionEnv"
net start "TermService"
net start "UmRdpService"



:: 4. �޸ı�������Ա༭����Windows 10 ���ݰ� �������ã�����Ȼִ��һ�Σ�
:: 4.1 ��������á�����ģ���Windows�����Զ����������Զ������Ự��������ȫ��Զ�̣�RDP������Ҫ��ʹ��ָ���İ�ȫ��(�����ã���ȫ��:RDP)
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v SecurityLayer /t REG_DWORD /d 2 /f
:: 4.2 ��������á�����ģ���Windows�����Զ����������Զ������Ự���������ӡ������û�ͨ��ʹ��Զ������������Զ������(δ����)
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fDenyTSConnections
if %errorlevel%==0 (
    reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fDenyTSConnections /f
) else (
    echo [ERROR] 4.2 ��������á�����ģ���Windows�����Զ����������Զ������Ự���������ӡ������û�ͨ��ʹ��Զ������������Զ������(δ����)
)
:: 4.3 ��������á�����ģ���ϵͳ��Զ��Э�������������Զ��Э��(δ����)
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fAllowToGetHelp
if %errorlevel%==0 (
    reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fAllowToGetHelp /f
) else (
    echo [ERROR] 4.3 ��������á�����ģ���ϵͳ��Զ��Э�������������Զ��Э��(δ����)
)
:: 4.4 ��������á�����ģ���Windows�����Զ����������Զ������Ự�������豸����Դ�ض����������������ض���(δ����)
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fDisableClip
if %errorlevel%==0 (
    reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fDisableClip /f
) else (
    echo [ERROR] 4.4 ��������á�����ģ���Windows�����Զ����������Զ������Ự�������豸����Դ�ض����������������ض���(δ����)
)
:: 4.5 ��������á�����ģ��������������Ի����á�����ʾ����(������)
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v NoLockScreen /t REG_DWORD /d 1 /f



:: 5. ����û���
:: 5.1 Grant the permission to the Administrators group
"%~dp0ntrights.exe" -u "Administrators" +r SeRemoteInteractiveLogonRight
:: 5.2 Grant the permission to the Remote Desktop Users group,Win11 is unavailable
"%~dp0ntrights.exe" -u "Remote Desktop Users" +r SeRemoteInteractiveLogonRight
:: 5.3 Grant the permission to the Users group
"%~dp0ntrights.exe" -u "Users" +r SeRemoteInteractiveLogonRight



:: 6. �رշ���ǽ
netsh advfirewall set allprofiles state off
netsh advfirewall show allprofiles

goto verify
:: ------------------------------------------------------------------------------------------------------------------------



:WindowsXP
:: ����δ��֤
:: ------------------------------------------------------------------------------------------------------------------------
:: 1. ��������"Remote Desktop Help Session Manager" �� "Telnet"
:: 1.1 ���÷�����������Ϊ���Զ���
sc config helpsvc start=auto
sc config TlntSvr start=auto
:: 1.2 ��������
net start helpsvc
net start TlntSvr



:: 2. ע�����
:: 2.1 ����ע�����ص�����
reg export "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\Root\RDPDR" "%~dp0RDPDRBackup.reg" /y
:: 2.2 ��ԭע���
:: reg import "%~dp0dp0RDPDRBackup.reg"



:: 3.1 ��ע����ҵ� HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\Root\RDPDR ����RDPDR�ϵ���Ҽ���ѡ��Ȩ�ޡ����ı䡰everyone����Ȩ��Ϊ����ȫ���ơ�
"%~dp0subinacl.exe" /subkeyreg "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\Root\RDPDR" /grant=everyone=f
:: 3.2 ����ע���
reg import "%~dp0windows_xp_ghost.reg"



:: 4. �رշ���ǽ
netsh firewall set opmode disable
netsh firewall show state

goto verify
:: ------------------------------------------------------------------------------------------------------------------------



:Windows7
:: ------------------------------------------------------------------------------------------------------------------------
:: 1. �رշ���ǽ
netsh advfirewall set allprofiles state off
netsh advfirewall show allprofiles

goto verify
:: ------------------------------------------------------------------------------------------------------------------------



:verify
:: ------------------------------------------------------------------------------------------------------------------------
:: 1. ע�����
:: 1.1 ����ע�����ص�����
reg export "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" "%~dp0TerminalServerBackup.reg" /y
reg export "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Remote Assistance" "%~dp0RemoteAssistanceBackup.reg" /y
:: 1.2 ��ԭע���
:: reg import "%~dp0TerminalServerBackup.reg"
:: reg import "%~dp0RemoteAssistanceBackup.reg"



:: 2. ����Զ�̽����ϵͳ����
:: 2.1 Enable Remote Desktop
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
:: 2.2 Enable Remote Assistance
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Remote Assistance" /v fAllowToGetHelp /t REG_DWORD /d 1 /f
:: 2.3 Disable Network Level Authentication
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 0 /f



:: 3. ���õ�Դ������ȥ������
:: 3.1 Set the power scheme to "High performance"
powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
:: 3.2 Set the sleep timeout for both plugged in and on battery to "Never"
powercfg /x standby-timeout-ac 0
powercfg /x standby-timeout-dc 0
:: 3.3 Set the monitor timeout for both plugged in and on battery to "Never"
powercfg /x monitor-timeout-ac 0
powercfg /x monitor-timeout-dc 0



:: 4. ����Զ�̽����ϵͳ����
:: 4.1 ���±��������
gpupdate /force
:: 4.2 ���Զ��3389�˿�
netstat -ano | findstr "3389"
:: ------------------------------------------------------------------------------------------------------------------------



:NoSupport
pause
