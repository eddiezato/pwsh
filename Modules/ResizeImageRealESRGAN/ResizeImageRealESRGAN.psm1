function Draw-Progress {
    param (
        [string]$Text,
        [int]$Percent,
        [string]$Color = 'Yellow',
        [switch]$Complete
    )
    if (-not $Complete) {
        Write-Host '[' -NoNewLine -ForegroundColor $Color
        $progress = "$Percent %".PadLeft(12, ' ').PadRight(20, ' ')
        Write-Host $progress.SubString(0, [Math]::Round($Percent / 5)) -NoNewLine -BackgroundColor $Color -ForegroundColor $Host.UI.RawUI.BackgroundColor
        Write-Host $progress.SubString([Math]::Round($Percent / 5), 20 - [Math]::Round($Percent / 5)) -NoNewLine -ForegroundColor $Color
        Write-Host '] ' -NoNewLine -ForegroundColor $Color
        Write-Host "$Text`r" -NoNewLine
    } else {
        Write-Host ("{0}`r[" -f (' ' * ($Text.Length + 23))) -NoNewLine -ForegroundColor $Color
        Write-Host 'ok' -NoNewLine -ForegroundColor Green
        Write-Host "] " -NoNewLine -ForegroundColor $Color
        Write-Host $Text
    }
}
function Resize-ImageRealESRGAN {
    [Alias('rireg')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [ValidatePattern('\.(jpe?g|png|webp)$', ErrorMessage = "You should specify jpg|jpeg|png|webp images")]
        [string[]]$Input
    )
    process {
        $Input | Foreach-Object {
            if (Test-Path -LiteralPath $_ -PathType Leaf) {
                $i = 0
                $file = Get-Item -LiteralPath $_
                [Console]::CursorVisible = $false
                Draw-Progress -Text $file.Name -Percent $i
                $job = Start-Job -ScriptBlock {
                    & "$($Using:PSScriptRoot)\app\realesrgan-ncnn-vulkan.exe" -i "$(($Using:file).Name)" -n realesrgan-x4plus -o "$(($Using:file).BaseName)_x.png" *>&1
                }
                while ($job.State -eq "Running") {
                    $outValue = Receive-Job $job
                    if ($outValue) {
                        $p = (($outValue -as [string]) -split ',')[0] -as [int]
                        if ($p -and ($p -ne $i)) { $i = $p; Draw-Progress -Text $file.Name -Percent $i }
                    }
                    Start-Sleep -Seconds 0.1
                }
                [Console]::CursorVisible = $true
                Draw-Progress -Text $file.Name -Complete
            }
        }
    }
}
Export-ModuleMember -Function Resize-ImageRealESRGAN -Alias rireg