@echo on
color 0a
:: �����ӳ�չ��ģʽ������ʹ�ö�̬����
setlocal ENABLEDELAYEDEXPANSION
title �����Զ�����ýű�



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



:: 3. �޸ı�������Ա༭��
:: 3.1 ��������á�����ģ���Windows�����Զ����������Զ������Ự��������ȫ��Զ�̣�RDP������Ҫ��ʹ��ָ���İ�ȫ��(�����ã���ȫ��:RDP)
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v SecurityLayer /t REG_DWORD /d 2 /f >nul
:: 3.2 ��������á�����ģ���Windows�����Զ����������Զ������Ự���������ӡ������û�ͨ��ʹ��Զ������������Զ������(δ����)
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fDenyTSConnections /f >nul 2>&1
:: 3.3 ��������á�����ģ���ϵͳ��Զ��Э�������������Զ��Э��(δ����)
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fAllowToGetHelp /f >nul 2>&1
:: 3.4 ��������á�����ģ���Windows�����Զ����������Զ������Ự�������豸����Դ�ض����������������ض���(δ����)
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fDisableClip /f >nul 2>&1


:: 4. ����û��飺������ָ��һ��ִ��·������������ڵĻ������˻��������Ͳ���Ҫ��������
:: 4.1 Change the directory to the Resource Kit Tools installation path (if not added to the PATH environment variable)
:: Ntrights.exe utility is not included in the default Windows installation and must be downloaded separately as part of the Windows Server 2003 Resource Kit Tools.
:: cd "C:\Program Files (x86)\Windows Resource Kits\Tools\"
:: 4.2 Grant the permission to the Administrators group
%~dp0ntrights.exe -u "Administrators" +r SeRemoteInteractiveLogonRight
:: 4.3 Grant the permission to the Remote Desktop Users group,Win11 is unavailable
%~dp0ntrights.exe -u "Remote Desktop Users" +r SeRemoteInteractiveLogonRight
:: 4.4 Grant the permission to the Users group
%~dp0ntrights.exe -u "Users" +r SeRemoteInteractiveLogonRight



:: 5. ����Զ�̽����ϵͳ����
:: 5.1 Enable Remote Desktop
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul
:: 5.2 Enable Remote Assistance
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Remote Assistance" /v fAllowToGetHelp /t REG_DWORD /d 1 /f >nul
:: 5.3 Disable Network Level Authentication
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 0 /f >nul



:: 6. ���õ�Դ����
:: 6.1 Set the power scheme to "High performance"
powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
:: 6.2 Set the sleep timeout for both plugged in and on battery to "Never"
powercfg /x standby-timeout-ac 0
powercfg /x standby-timeout-dc 0
:: 6.3 Set the monitor timeout for both plugged in and on battery to "Never"
powercfg /x monitor-timeout-ac 0
powercfg /x monitor-timeout-dc 0
:: 6.4 ��������á�����ģ��������������Ի����á�����ʾ����(������)
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v NoLockScreen /t REG_DWORD /d 1 /f



:: 7. ����Զ�̽����ϵͳ����
:: 7.1 ���±��������
gpupdate /force
:: 7.2 ���Զ��3389�˿�
netstat -ano|findstr "3389"



pause