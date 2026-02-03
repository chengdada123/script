@echo off
echo ————————————————-
echo – %~nx0
echo –
echo – Windows 远程桌面端口修改
echo – 提示: 远程端口默认为 3389(十六进制 0xd3d)
echo –
echo – 当前端口（十六进制）:
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v "PortNumber"
echo ————————————————-
:: check admin
net session >nul 2>&1
if %errorLevel% == 0 (echo [管理员模式]) else (echo 错误：请在文件上右键，使用管理员运行 & pause & goto :EOF)
:: check admin
set /p rdp_port="输入要修改的端口号 (默认为 3389):"
if "%rdp_port%" EQU "" set rdp_port=3389
echo – 按任意键确认将远程桌面端口设置为： %rdp_port%
pause
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v "PortNumber" /t REG_DWORD /d %rdp_port% /f
echo – 新端口 （十六进制）:
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v "PortNumber"
echo — 将新端口添加到防火墙例外 …
netsh advfirewall firewall add rule name="RDP Port %rdp_port%" profile=any protocol=TCP action=allow dir=in localport=%rdp_port%
echo ———- 按任意键重启 TermService 服务，使新设置生效（远程桌面将被断开）
echo ———- 若远程桌面断开后无法连入，尝试重启系统即可生效
pause
echo — 重新启动远程桌面服务 …
net stop TermService /y
net start TermService /y
:DONE
echo ———- 完成
pause
