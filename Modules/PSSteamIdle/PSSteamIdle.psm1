function Write-Time {
    Write-Host ("[{0}] " -f (Get-Date -Format "HH\:mm\:ss")) -NoNewLine -ForegroundColor DarkGray
}
function Start-SteamIdle {
    [Alias('ssi')]
    [CmdletBinding()]
    param (
        [Alias('i')]
        [uint]$AppId,
        [Alias('t')]
        [ValidateSet(10, 15, 20, 30)]
        [byte]$IdleFor = 20
    )
    if (!$AppId) { $AppId = (Get-Clipboard) -as [uint] }
    if ($AppId) {
        Write-Host 'Press Esc to stop' -ForegroundColor DarkGray
        Write-Time; Write-Host 'Start idling ' -NoNewLine
        try { $details = Invoke-RestMethod -Uri "https://store.steampowered.com/api/appdetails?appids=$AppId" } catch { $details = $null }
        Write-Host (($details -and $details."$AppId".success) ? $details."$AppId".data.name : $AppId) -ForegroundColor Magenta
        Remove-Variable -Name details
        $play = $true
        $pass = 0
        [Console]::CursorVisible = $false
        while ($play) {
            $idle = Start-Job -ArgumentList $AppId, $IdleFor, "$PSScriptRoot\Facepunch.Steamworks.Win64.dll" -ScriptBlock {
                Add-Type -Path $args[2]
                [Steamworks.SteamClient]::Init($args[0])
                $i = 60 * $args[1]
                while ($i + 1) {
                    (-- $i)
                    Start-Sleep -Seconds 1
                }
                [Steamworks.SteamClient]::Shutdown()
            }
            Write-Time; Write-Host ("Pass {0} " -f (++ $pass).ToString().PadRight(4, '.')) -NoNewLine
            $time = 60 * $IdleFor + 1
            while (($idle.State -eq 'Running') -and $play) {
                if ([Console]::KeyAvailable) {
                    if (([Console]::ReadKey($true)).Key -eq [ConsoleKey]::Escape) { $play = $false }
                }
                $jobOut = Receive-Job -Job $idle
                if ($jobOut -and [bool]($jobOut -as [int]) -and (($jobOut -as [int]) -ne $time)) {
                    $time = $jobOut -as [int]
                    Write-Host ([TimeSpan]::FromSeconds($time).ToString("mm\:ss"))"`b`b`b`b`b`b" -NoNewLine -ForegroundColor Yellow
                }
                Start-Sleep -Seconds 0.5
            }
            Stop-Job -Job $idle
            Remove-Job -Job $idle
            if ($play) {
                Start-Sleep -Seconds 5
                Write-Host 'done ' -ForegroundColor Green
            } else { Write-Host 'canceled' -ForegroundColor Red }
        }
        [Console]::CursorVisible = $true
    } else { throw "AppId isn't valid" }
}
Export-ModuleMember -Function Start-SteamIdle -Alias ssi