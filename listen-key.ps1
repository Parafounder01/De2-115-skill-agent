<#
.SYNOPSIS
    Listen for KEY3 press events from DE2-115 serial clock over RS-232
    and simulate a Windows key press on the PC.

.DESCRIPTION
    Opens a COM port at 115200 baud, reads incoming bytes.
    On byte 0xBB (sent by FPGA when KEY3 is pressed), calls
    keybd_event(VK_LWIN, 0, 0, 0) to simulate pressing the Windows key,
    then keybd_event(VK_LWIN, 0, KEYEVENTF_KEYUP, 0) to release.

.PARAMETER ComPort
    COM port connected to DE2-115 UART TX (default: COM1).

.PARAMETER NoRelease
    If set, holds the Windows key down (useful to chain with other keys).
    Without this flag, press-and-immediate-release is the default.

.EXAMPLE
    .\listen-key.ps1 -ComPort COM3
#>
param(
    [string]$ComPort = "COM1",
    [switch]$NoRelease
)

# Win32 API declarations via C# P/Invoke
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class WinKey {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

    public const byte VK_LWIN = 0x5B;
    public const uint KEYEVENTF_KEYUP = 0x0002;
}
"@

Write-Host "╔═══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  DE2-115 KEY3 → Windows Key Listener        ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "  COM port : $ComPort  (115200 baud 8N1)" -ForegroundColor Yellow
Write-Host "  Waiting for 0xBB from FPGA... (Ctrl+C to stop)`n" -ForegroundColor Yellow

try {
    $sp = New-Object System.IO.Ports.SerialPort $ComPort, 115200, None, 8, One
    $sp.ReadTimeout = 1000  # ms — allows loop to stay responsive
    $sp.Open()
    Write-Host "  ✔ Port $ComPort opened." -ForegroundColor Green

    $count = 0
    while ($true) {
        try {
            $b = $sp.ReadByte()
            if ($b -eq 0xBB) {
                $count++
                Write-Host "  [$count] KEY3 pressed → sending Windows key..." -ForegroundColor Green
                [WinKey]::keybd_event([WinKey]::VK_LWIN, 0, 0, [UIntPtr]::Zero)
                if (-not $NoRelease) {
                    Start-Sleep -Milliseconds 50
                    [WinKey]::keybd_event([WinKey]::VK_LWIN, 0, [WinKey]::KEYEVENTF_KEYUP, [UIntPtr]::Zero)
                }
            }
        } catch [TimeoutException] {
            # Normal timeout — just loop again
        }
    }
} catch {
    Write-Host "  ✘ Error: $_" -ForegroundColor Red
} finally {
    if ($sp -and $sp.IsOpen) { $sp.Close() }
    Write-Host "`nPort closed. $count Windows key events sent." -ForegroundColor Yellow
}
