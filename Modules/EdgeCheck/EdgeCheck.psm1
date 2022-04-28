function Get-Edge {
    # params
    [CmdletBinding(DefaultParameterSetName="Casual")]
    param (
        [Alias("c")]
        [Parameter(ParameterSetName = "Pro", Mandatory = $true)]
        [ValidateSet("stable", "beta", "dev", "canary")]
        [string]$Channel,
        [Alias("v")]
        [Parameter(ParameterSetName = "Pro", Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Version,
        [Alias("a")]
        [Parameter(ParameterSetName = "Pro")]
        [ValidateSet("x64", "x86")]
        [string]$Architecture = "x64",
        [Alias("d")]
        [Parameter(ParameterSetName = "Pro")]
        [switch]$Download = $false,
        [Alias("x")]
        [switch]$Extract = $false
    )
    # run gui for default check
    if ($PSCmdlet.ParameterSetName -eq "Casual") {
        # get versions
        $Response = $null
        try { $Response = Invoke-RestMethod -Method Get -Uri "https://edgeupdates.microsoft.com/api/products" }
        catch { throw "Can't check Edge versions. Try again." }
        # store versions
        $verlist = @()
        if ($Response) {
            foreach ($ver in ($Response | Where-Object { $_.Product.ToLower() -in @("stable", "beta", "dev", "canary") })) {
                $item = $ver.Releases | Where-Object { ($_.Platform.ToLower() -eq "windows") -and ($_.Architecture.ToLower() -eq $Architecture) }
                $verlist += [PSCustomObject]@{
                    Channel = $ver.Product.ToString().ToLower()
                    Version = $item.ProductVersion.ToString()
                    Published = (Get-Date -Date $item.PublishedTime).ToString("yyyy.MM.dd HH:mm")
                }
            }
            if (-not $verlist) { throw "Can't check Edge versions (no data). Try again." }
        } else { throw "Can't check Edge versions (bad response). Try again." }
        # draw gui
        Clear-Host
        Write-Host "Arrows" -NoNewLine -ForegroundColor Cyan; Write-Host " to navigate, " -NoNewLine
        Write-Host "Enter" -NoNewLine -ForegroundColor Cyan; Write-Host " to download, " -NoNewLine
        Write-Host "Esc" -NoNewLine -ForegroundColor Cyan; Write-Host " to exit"
        Write-Host "`n Channel    Version         Published`n -------    -------         ---------" -ForegroundColor DarkGray
        foreach ($ver in $verlist) { " {0}  {1}  {2}" -f $ver.Channel.PadRight(9, " "), $ver.Version.PadRight(14, " "), $ver.Published }
        Write-Host
        [Console]::CursorVisible = $false
        $fcolor = $Host.UI.RawUI.ForegroundColor
        $bcolor = $Host.UI.RawUI.BackgroundColor
        $curpos = 0
        $Host.UI.RawUI.CursorPosition = @{ X = 0; Y = $curpos + 4 }
        Write-Host (" {0}" -f $verlist[$curpos].Channel.PadRight(9, " ")) -NoNewLine -ForegroundColor $bcolor -BackgroundColor $fcolor
        # run navigation
        $Host.UI.RawUI.FlushInputBuffer();
        $navflag = $true
        do {
            $key = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
            switch ($key.VirtualKeyCode) {
                38 {
                    if ($curpos -gt 0) {
                        $Host.UI.RawUI.CursorPosition = @{ X = 0; Y = $curpos + 4 }
                        Write-Host (" {0}" -f $verlist[$curpos].Channel.PadRight(9, " ")) -NoNewLine -ForegroundColor $fcolor -BackgroundColor $bcolor
                        $curpos--
                        $Host.UI.RawUI.CursorPosition = @{ X = 0; Y = $curpos + 4 }
                        Write-Host (" {0}" -f $verlist[$curpos].Channel.PadRight(9, " ")) -NoNewLine -ForegroundColor $bcolor -BackgroundColor $fcolor
                    }
                    break
                }
                40 {
                    if ($curpos -lt $verlist.Count - 1 ) {
                        $Host.UI.RawUI.CursorPosition = @{ X = 0; Y = $curpos + 4 }
                        Write-Host (" {0}" -f $verlist[$curpos].Channel.PadRight(9, " ")) -NoNewLine -ForegroundColor $fcolor -BackgroundColor $bcolor
                        $curpos++
                        $Host.UI.RawUI.CursorPosition = @{ X = 0; Y = $curpos + 4 }
                        Write-Host (" {0}" -f $verlist[$curpos].Channel.PadRight(9, " ")) -NoNewLine -ForegroundColor $bcolor -BackgroundColor $fcolor
                    }
                    break
                }
                67 {
                    Set-Clipboard ("Get-Edge -c {0} -v {1}" -f $verlist[$curpos].Channel, $verlist[$curpos].Version)
                    $Host.UI.RawUI.CursorPosition = @{ X = 0; Y = $curpos + 4 }
                    Write-Host (" {0}" -f $verlist[$curpos].Channel.PadRight(9, " ")) -NoNewLine -ForegroundColor $bcolor -BackgroundColor Yellow
                    break
                }
                13 {
                    # run architecture navigation
                    $Host.UI.RawUI.CursorPosition = @{ X = 0; Y = $curpos + 4 }
                    Write-Host " x64 " -NoNewLine -ForegroundColor $bcolor -BackgroundColor $fcolor
                    Write-Host " x86 " -NoNewLine -ForegroundColor $fcolor -BackgroundColor $bcolor
                    $Architecture = "x64"
                    $Host.UI.RawUI.FlushInputBuffer();
                    $nav2flag = $true
                    do {
                        $key = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
                        switch ($key.VirtualKeyCode) {
                            37 {
                                if ($Architecture -eq "x86") {
                                    $Host.UI.RawUI.CursorPosition = @{ X = 0; Y = $curpos + 4 }
                                    Write-Host " x64 " -NoNewLine -ForegroundColor $bcolor -BackgroundColor $fcolor
                                    Write-Host " x86 " -NoNewLine -ForegroundColor $fcolor -BackgroundColor $bcolor
                                    $Architecture = "x64"
                                }
                                break
                            }
                            39 {
                                if ($Architecture -eq "x64") {
                                    $Host.UI.RawUI.CursorPosition = @{ X = 0; Y = $curpos + 4 }
                                    Write-Host " x64 " -NoNewLine -ForegroundColor $fcolor -BackgroundColor $bcolor
                                    Write-Host " x86 " -NoNewLine -ForegroundColor $bcolor -BackgroundColor $fcolor
                                    $Architecture = "x86"
                                }
                                break
                            }
                            13 {
                                $Channel = $verlist[$curpos].Channel
                                $Version = $verlist[$curpos].Version
                                $Download = $true
                                $navflag = $false
                                $nav2flag = $false
                                break
                            }
                            27 {
                                $Host.UI.RawUI.CursorPosition = @{ X = 0; Y = $curpos + 4 }
                                Write-Host (" {0}" -f $verlist[$curpos].Channel.PadRight(9, " ")) -NoNewLine -ForegroundColor $bcolor -BackgroundColor $fcolor
                                $nav2flag = $false
                            }
                        }
                    } while ($nav2flag)
                }
                27 { $navflag = $false }
            }
        } while ($navflag)
        $Host.UI.RawUI.CursorPosition = @{ X = 0; Y = $verlist.Count + 5 }
        [Console]::CursorVisible = $true
        # exit if Esc pressed
        if (-not $Download) { return }
    }
    # check if the selected version is available for download
    Write-Host "Checking availability..." -NoNewLine
    $Response = $null
    $url = -join (
        "https://msedge.api.cdp.microsoft.com/api/v1.1/internal/contents/Browser/namespaces/Default/names/msedge-",
        $Channel,
        "-win-",
        $Architecture,
        "/versions/",
        $Version,
        "/files?action=GenerateDownloadInfo&foregroundPriority=true"
    )
    try { $Response = Invoke-RestMethod -Method Post -Uri $url }
    catch { Write-Host " fail" -ForegroundColor Red; return }
    if ($Response) {
        Write-Host " ok" -ForegroundColor Green
        # start download
        if ($Download) {
            Write-Host "Downloading..." -NoNewLine
            $Release = $Response | Where-Object { $_.FileId.ToLower() -eq "microsoftedge_$($Architecture)_$($Version).exe" }
            $edgebits = @{
                Source = "{0}&mkt={1}" -f $Release.Url, (Get-WinSystemLocale).Name
                Destination = "msedge_$($Architecture)_$($Channel)_$($Version).exe"
                DisplayName = "$Channel $Version"
                Description = "{0} MiB" -f [Math]::Round($Release.SizeInBytes / 1MB, 2)
            }
            try { Start-BitsTransfer @edgebits }
            catch { Write-Host " fail" -ForegroundColor Red; throw "BITS failed. Try again." }
            # extract with 7z
            if (Test-Path -LiteralPath "msedge_$($Architecture)_$($Channel)_$($Version).exe") {
                Write-Host " ok" -ForegroundColor Green
                if ($Extract) {
                    Write-Host "Extracting..."
                    $sevenzip = "7z.exe"
                    if (Test-Path -LiteralPath "$PSScriptRoot\7z.exe") { $sevenzip = "$PSScriptRoot\7z.exe" }
                    try {
                        & $sevenzip x "msedge_$($Architecture)_$($Channel)_$($Version).exe" -aoa -bso0 -bsp1 -y
                        & $sevenzip x "msedge.7z" -aoa -bso0 -bsp1 -y
                        if (Test-Path -Path "Edge") {
                            Move-Item -Path "Chrome-bin\*" -Destination "Edge" -Force
                            Remove-Item -Path "Chrome-bin" -Force
                        }
                        else { Rename-Item -Path "Chrome-bin" -NewName "Edge" -Force }
                        Remove-Item -Path "msedge.7z" -Force
                        $Host.UI.RawUI.CursorPosition = @{ X = 13; Y = $Host.UI.RawUI.CursorPosition.Y - 1 }
                        Write-Host " ok" -ForegroundColor Green
                    }
                    catch {
                        $Host.UI.RawUI.CursorPosition = @{ X = 13; Y = $Host.UI.RawUI.CursorPosition.Y - 1 }
                        Write-Host " fail" -ForegroundColor Red; throw
                    }
                }
            } else { Write-Host " fail" -ForegroundColor Red; throw }
        }
    } else { Write-Host " fail" -ForegroundColor Red; throw }
}
Export-ModuleMember -Function Get-Edge