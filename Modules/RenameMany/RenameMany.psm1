$banner = {
    Clear-Host
    @"
`e[3;90mpossible commands:
 ∙ `e[36ma|text|position`e[90m                       add text │ ∙ `e[36mp[l]|number|char`e[90m           padding
 ∙ `e[36md[t]|start[text]|length[text]`e[90m  delete ([t]ext) │ ∙ `e[36ms[o]|start|length|position`e[90m add substring ([o]riginal)
 ∙ `e[36me|text`e[90m                               extension │ ∙ `e[36mr|find|replace`e[90m             replace
 ∙ `e[36mi|start|position|zeros`e[90m               add index │`e[0m
`e[94mcommands:`e[0m
"@ | Write-Host
}
function Rename-One {
    [CmdletBinding()]
    param ([Object]$Item, [uint]$Index, [string[]]$Commands)
    $Name = $Item.PSIsContainer ? $Item.Name : $Item.BaseName
    $Ext = $Item.PSIsContainer ? '' : $Item.Extension
    $Commands | ForEach-Object {
        $c = ($_ + '|' * (3 - ($_[0..($_.Length - 1)] | Where-Object { $_ -eq '|' }).Count)).Split('|') -as [Object[]]
        switch -wildcard ($c[0]) {
            # add 'a|text|position'
            'a' {
                if ($c[1]) {
                    $p = ($c[2] -ne '') -and ($null -ne ($c[2] -as [uint])) -and (($c[2] -as [uint]) -le $Name.Length) ? $c[2] -as [uint] : $Name.Length
                    $Name = $Name.Substring(0, $p) + $c[1] + $Name.Substring($p)
                }
            }
            # delete (find [t]ext) 'd[t]|start[text]|length[text]'
            'd*' {
                if (($c[1] -eq '') -and ($c[2] -eq '')) { $Name = '' }
                else {
                    if ($c[0][1] -eq 't') {
                        $s = $c[1] -ne '' ? $Name.IndexOf($c[1]) : 0
                        $l = $c[2] -ne '' ? $Name.LastIndexOf($c[2]) : $Name.Length
                        if (($s -eq -1) -or ($l -eq -1)) { $s = $l = 0 } else { $l = $l + $c[2].Length - $s }
                    } else {
                        $s = ($c[1] -ne '') -and ($null -ne ($c[1] -as [uint])) -and (($c[1] -as [uint]) -le ($Name.Length - 1)) ? $c[1] -as [uint] : 0
                        $l = ($c[2] -ne '') -and ($null -ne ($c[2] -as [uint])) -and ((($c[2] -as [uint]) + $c[1]) -le $Name.Length) ? $c[2] -as [uint] : ($Name.Length - $s)
                    }
                    $Name = $Name.Substring(0, $s) + $Name.Substring(($s + $l))
                }
            }
            # extension 'e|text'
            'e' { $Ext = ($c[1] -ne '') -and (-not $c[1].StartsWith('.')) ? ('.' + $c[1]) : $c[1] }
            # index 'i|start|position|zeros
            'i' {
                $s = $null -ne ($c[1] -as [uint]) ? $c[1] -as [uint] : 0
                $p = ($c[2] -ne '') -and ($null -ne ($c[2] -as [uint])) -and (($c[2] -as [uint]) -le $Name.Length) ? $c[2] -as [uint] : $Name.Length
                $z = $null -ne ($c[3] -as [uint]) ? $c[3] -as [uint] : 0
                $Name = $Name.Substring(0, $p) + ($s + $Index).ToString('0' * $z) + $Name.Substring($p)
            }
            # padding 'p[l]|number|char'
            'p*' {
                if (($c[1] -as [uint]) -and ($c[2] -ne '')) { $Name = $c[0][1] -eq 'l' ? $Name.PadLeft($c[1] -as [uint], $c[2][0]) : $Name.PadRight($c[1] -as [uint], $c[2][0]) }}
            # replace 'r|find|replace'
            'r' { if ($c[1]) { $Name = $Name.Replace($c[1], $c[2]) }}
            # substring (original) s[o]|start|length|position
            's*' {
                $tempName = $c[0][1] -eq 'o' ? ($Item.PSIsContainer ? $Item.Name : $Item.BaseName) : $Name
                $s = ($c[1] -ne '') -and ($null -ne ($c[1] -as [uint])) -and (($c[1] -as [uint]) -le ($tempName.Length - 1)) ? $c[1] -as [uint] : 0
                $l = ($c[2] -ne '') -and ($null -ne ($c[2] -as [uint])) -and ((($c[2] -as [uint]) + $s) -le $tempName.Length) ? $c[2] -as [uint] : $tempName.Length - $s
                $p = ($c[3] -ne '') -and ($null -ne ($c[3] -as [uint])) -and (($c[3] -as [uint]) -le $Name.Length) ? $c[3] -as [uint] : $Name.Length
                $Name = $Name.Substring(0, $p) + $tempName.Substring($s, $l) + $Name.Substring($p)
            }
        }
    }
    $Name += $Ext
    return ([PSCustomObject]@{
        Name = $Name
        willRename = $Name -cne $Item.Name ? $true : $false
        isInvalid = ($Name.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ne -1) -or ($Name.Length -lt 1) ? $true : $false
    })
}
function Get-Button {
    param (
        [string[]]$Name,
        [switch]$Enable
    )
    $Buttons = @(' more ', " $Name ", ' reset ', ' quit ')
    $color = { "{0}{1}" -f ($i -ne 1 ? '95' : ($Enable ? '92' : '90')), ($i -eq $p ? ';7' : '') }
    [Console]::CursorVisible = $false
    $p = 0;
    foreach ($i in 0..($Buttons.Count - 1)) { "`e[{1}m{0}`e[0m" -f $Buttons[$i], (& $color) | Write-Host -NoNewline }
    "`r" | Write-Host -NoNewline
    $Host.UI.RawUI.FlushInputBuffer();
    $continue = $true
    do {
        $key = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
        switch ($key.VirtualKeyCode) {
            37 {
                if ($p -ne 0) { $p -- }
                foreach ($i in 0..($Buttons.Count - 1)) { "`e[{1}m{0}`e[0m" -f $Buttons[$i], (& $color) | Write-Host -NoNewline }
                "`r" | Write-Host -NoNewline
            }
            39 {
                if ($p -ne ($Buttons.Count - 1)) { $p ++ }
                foreach ($i in 0..($Buttons.Count - 1)) { "`e[{1}m{0}`e[0m" -f $Buttons[$i], (& $color) | Write-Host -NoNewline }
                "`r" | Write-Host -NoNewline
            }
            13 { if ($Enable -or ($p -ne 1)) { $continue = $false }}
            27 { $p = 3; $continue = $false }
        }
    } while ($continue)
    "{0}`r" -f (' ' * " $($Buttons -join '  ') ".Length) | Write-Host -NoNewline
    [Console]::CursorVisible = $true
    return $p
}
function Rename-Many {
    [Alias('rnm')]
    [CmdletBinding()]
    param ([Parameter(Mandatory, ValueFromPipeline, Position = 0)] [array]$InputObjects)

    $InputObjects = Get-Item -LiteralPath ($PSCmdlet.MyInvocation.ExpectingInput ? $input : $InputObjects) | Sort-Object -Property FullName
    if ($InputObjects.Count)
    {
        $InputObjects | ForEach-Object { $pad = [uint]$pad -lt $_.Name.Length ? $_.Name.Length : $pad }
        & $banner
        $commands = $previews = @()
        $continue_rename = $true
        do {
            $continue_preview = $true
            do {
                "`e[90m->`e[0m " | Write-Host -NoNewline
                $c = $Host.UI.ReadLine()
                if ($c -match '^(a|dt?|e|i|pl?|r|so?)($|\|)') { $commands += $c }
                else { $Host.UI.RawUI.CursorPosition = @{ X = 0; Y = $Host.UI.RawUI.CursorPosition.Y - 1 }}
                $b = Get-Button -Name 'preview' -Enable:($commands.Count -as [bool])
                switch ($b) {
                    1 { if ($commands.Count) { $continue_preview = $false }}
                    2 { $commands = @(); & $banner }
                    3 { exit(0) }
                }
            } while ($continue_preview)
            foreach ($i in 0..($InputObjects.Count - 1)) {
                $result = Rename-One -Item $InputObjects[$i] -Index $i -Commands $commands
                $previews += [PSCustomObject]@{
                    Parent = $InputObjects[$i].PSIsContainer ? $InputObjects[$i].Parent.FullName : $InputObjects[$i].DirectoryName
                    Name = $InputObjects[$i].Name
                    NewName = $result.Name
                    willRename = $result.willRename
                    isDuplicate = $false
                    isInvalid = $result.isInvalid
                }
            }
            $dupes = ($previews | Group-Object -Property { Join-Path -Path $_.Parent -ChildPath ($_.isInvalid ? $_.Name : $_.NewName) } | Where-Object { $_.Count -gt 1 }).Name
            $previews | Where-Object { -not $_.isInvalid -and ((Join-Path -Path $_.Parent -ChildPath $_.NewName) -in $dupes) } | ForEach-Object { $_.isDuplicate = $true }
            Remove-Variable dupes
            "`n{0}`e[94mpreview`e[0m" -f (' ' * $pad) | Write-Host
            $previews | ForEach-Object {
                " {0}`e[90m --> {2}{1}`e[0m" -f $_.Name.PadLeft($pad, ' '), $_.NewName, (($_.isDuplicate -or $_.isInvalid) ? "`e[91m" : ($_.willRename ? "`e[92m" : "`e[0m")) | Write-Host
            }
            Write-Host
            if ($previews.isInvalid -contains $true) { "`e[3;91m ∙ files with invalid new names will be skipped `e[0m" | Write-Host }
            if ($previews.isDuplicate -contains $true) { "`e[3;91m ∙ unable to proceed, check duplicate names`e[0m" | Write-Host }
            $b = Get-Button -Name 'rename' -Enable:(($previews.willRename -contains $true) -and ($previews.isDuplicate -notcontains $true) -and ($previews.isInvalid -contains $false))
            switch ($b) {
                0 { $previews = @(); "`e[94mcommands:`e[0m" | Write-Host }
                1 { $continue_rename = $false }
                2 { $previews = $commands = @(); & $banner }
                3 { exit(0) }
            }
        } while ($continue_rename)
        "`n`e[94mRenaming...`e[0m" | Write-Host -NoNewline
        try {
            $previews | Where-Object { $_.willRename -and -not $_.isInvalid } | ForEach-Object {
                $prename = $_.Name + '.!rename'
                Rename-Item -Path (Join-Path -Path $_.Parent -ChildPath $_.Name) -NewName $prename
                $_.Name = $prename
            }
            $previews | Where-Object { $_.willRename -and -not $_.isInvalid } | ForEach-Object { Rename-Item -Path (Join-Path -Path $_.Parent -ChildPath $_.Name) -NewName $_.NewName }
        } catch {
            "`e[91mfail`e[0m`n" | Write-Host
            Get-Error
            "`n`e[90mPress any key...`e[0m" | Write-Host -NoNewline
            $Host.UI.RawUI.ReadKey() | Out-Null
            exit(1)
        }
        "`e[92mok`e[0m" | Write-Host
        Start-Sleep -Seconds 1
    }
}
Export-ModuleMember -Function Rename-Many -Alias rnm