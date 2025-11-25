@echo off
REM Claude Code Feishu Report Hook for Windows
REM 在 Claude Code 任务完成时通过飞书 MCP 发送汇报

setlocal enabledelayedexpansion

REM ============ 配置区域 ============

REM 脚本所在目录
set SCRIPT_DIR=%~dp0

REM Node.js 发送脚本路径
set SEND_SCRIPT=%SCRIPT_DIR%send-feishu-message.js

REM 临时文件路径
set TEMP_FILE=%TEMP%\claude_hook_data_%RANDOM%.json
set LOG_FILE=%TEMP%\claude-feishu-hook.log

REM 是否启用调试
set DEBUG=true

REM ============ 主逻辑 ============

REM 记录开始时间
echo ========== Hook 开始执行 ========== >> %LOG_FILE%
echo [%date% %time%] Hook started >> %LOG_FILE%

REM 读取 stdin 到临时文件
type > %TEMP_FILE%

REM 检查临时文件是否为空
if not exist %TEMP_FILE% (
    echo 错误: 未收到 Hook 数据 >> %LOG_FILE%
    echo 错误: 未收到 Hook 数据 >&2
    exit /b 1
)

REM 使用 PowerShell 解析 JSON 并调用 Node.js 脚本
echo 解析 Hook 数据... >> %LOG_FILE%

powershell -ExecutionPolicy Bypass -NoProfile -Command ^
    "$hookData = Get-Content '%TEMP_FILE%' | ConvertFrom-Json; ^
     $sessionId = if ($hookData.session_id) { $hookData.session_id } else { 'unknown' }; ^
     $transcriptPath = if ($hookData.transcript_path) { $hookData.transcript_path } else { '' }; ^
     $cwd = if ($hookData.cwd) { $hookData.cwd } else { (Get-Location).Path }; ^
     $event = if ($hookData.hook_event_name) { $hookData.hook_event_name } else { 'unknown' }; ^
     $summary = 'Loading task summary...'; ^
     if (Test-Path $transcriptPath) { ^
         try { ^
             $transcript = Get-Content $transcriptPath | ConvertFrom-Json; ^
             $lastMessages = $transcript.messages | Select-Object -Last 3; ^
             $summary = ($lastMessages | ForEach-Object { ^
                 $role = if ($_.role -eq 'user') { '👤 用户: ' } else { '🤖 Claude: ' }; ^
                 $text = if ($_.content -is [array]) { $_.content[0].text } else { $_.content }; ^
                 $role + $text ^
             }) -join \"`n`n\"; ^
             $summary = $summary.Substring(0, [Math]::Min(1000, $summary.Length)); ^
         } catch { ^
             $summary = 'Failed to parse transcript'; ^
         } ^
     }; ^
     $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; ^
     Write-Host \"Calling Node.js script...\"; ^
     node '%SEND_SCRIPT%' --session_id \"$sessionId\" --summary \"$summary\" --timestamp \"$timestamp\" --cwd \"$cwd\" --event \"$event\""

set EXIT_CODE=%ERRORLEVEL%

REM 清理临时文件
del %TEMP_FILE% 2>nul

REM 记录结果
if %EXIT_CODE% EQU 0 (
    echo [%date% %time%] Hook 执行成功 >> %LOG_FILE%
) else (
    echo [%date% %time%] Hook 执行失败，退出码: %EXIT_CODE% >> %LOG_FILE%
)

echo ========== Hook 执行完成 ========== >> %LOG_FILE%

exit /b %EXIT_CODE%
