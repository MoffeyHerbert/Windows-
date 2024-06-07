@echo on
color 0a
:: �����ӳ�չ��ģʽ������ʹ�ö�̬����
setlocal ENABLEDELAYEDEXPANSION
title �����Զ�����ýű�
:: ��ӡ��ǰ�ű��ļ����ļ��ṹ
cd /D "%~dp0"
tree /F



:: Check if the script is running as Administrator
net session >nul 2>&1
if %errorlevel% == 0 (
    echo Running as Administrator.
    goto start
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
if "%OS_VERSION%" == "6.1" set OS_NAME=Windows7
if "%OS_VERSION%" == "5.1" set OS_NAME=WindowsXP
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
    goto start
)
if "%OS_NAME%" == "Windows7" (
    echo Running Windows 7 code
    goto Windows7
)
if "%OS_NAME%" == "WindowsXP" (
    echo Running Windows XP code
    goto Windows7
)



:start
:: 1. ע�����
:: 1.1 ����ע�����ص�����
reg export "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" "%~dp0CombinedBackup.reg" /y
reg export "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" "%~dp0TerminalServerBackup.reg" /y
reg export "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Remote Assistance" "%~dp0RemoteAssistanceBackup.reg" /y
reg export "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Personalization" "%~dp0PersonalizationBackup.reg" /y
:: 1.2 ��ԭע���
:: reg import "%~dp0CombinedBackup.reg"
:: reg import "%~dp0TerminalServerBackup.reg"
:: reg import "%~dp0RemoteAssistanceBackup.reg"
:: reg import "%~dp0PersonalizationBackup.reg"



:: 2. �޸ķ���
:: 2.1 ���÷�����������Ϊ���Զ���
sc config "SessionEnv" start=auto
sc config "TermService" start=auto
sc config "UmRdpService" start=auto
:: 2.2 ��������
net start "SessionEnv"
net start "TermService"
net start "UmRdpService"



:: 3. �滻ϵͳ�ļ�
:: 3.1 �滻ϵͳ�ļ�·��GroupPolicy
xcopy "%~dp0.\GroupPolicy" "C:\Windows\System32\GroupPolicy" /E /Y /I
:: 3.2 ִ��ע���reg�ļ�
reg import "%~dp0Microsoft_output.reg"



:: 4. �޸ı�������Ա༭����Windows 10 ���ݰ� �������ã�����Ȼִ��һ�Σ�
:: 4.1 ��������á�����ģ���Windows�����Զ����������Զ������Ự��������ȫ��Զ�̣�RDP������Ҫ��ʹ��ָ���İ�ȫ��(�����ã���ȫ��:RDP)
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v SecurityLayer /t REG_DWORD /d 2 /f
:: 4.2 ��������á�����ģ���Windows�����Զ����������Զ������Ự���������ӡ������û�ͨ��ʹ��Զ������������Զ������(δ����)
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fDenyTSConnections /f
:: 4.3 ��������á�����ģ���ϵͳ��Զ��Э�������������Զ��Э��(δ����)
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fAllowToGetHelp /f
:: 4.4 ��������á�����ģ���Windows�����Զ����������Զ������Ự�������豸����Դ�ض����������������ض���(δ����)
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fDisableClip /f
:: 4.5 ��������á�����ģ��������������Ի����á�����ʾ����(������)
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v NoLockScreen /t REG_DWORD /d 1 /f



:: 5. ����û���
:: 5.1 Grant the permission to the Administrators group
%~dp0ntrights.exe -u "Administrators" +r SeRemoteInteractiveLogonRight
:: 5.2 Grant the permission to the Remote Desktop Users group,Win11 is unavailable
%~dp0ntrights.exe -u "Remote Desktop Users" +r SeRemoteInteractiveLogonRight
:: 5.3 Grant the permission to the Users group
%~dp0ntrights.exe -u "Users" +r SeRemoteInteractiveLogonRight



:Windows7
:: 6. ����Զ�̽����ϵͳ����
:: 6.1 Enable Remote Desktop
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
:: 6.2 Enable Remote Assistance
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Remote Assistance" /v fAllowToGetHelp /t REG_DWORD /d 1 /f
:: 6.3 Disable Network Level Authentication
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 0 /f



:: 7. ���õ�Դ������ȥ������
:: 7.1 Set the power scheme to "High performance"
powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
:: 7.2 Set the sleep timeout for both plugged in and on battery to "Never"
powercfg /x standby-timeout-ac 0
powercfg /x standby-timeout-dc 0
:: 7.3 Set the monitor timeout for both plugged in and on battery to "Never"
powercfg /x monitor-timeout-ac 0
powercfg /x monitor-timeout-dc 0



:: 8. ����Զ�̽����ϵͳ����
:: 8.1 ���±��������
gpupdate /force
:: 8.2 ���Զ��3389�˿�
netstat -ano|findstr "3389"



:NoSupport
pause