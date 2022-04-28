function Get-Chrome {
    [CmdletBinding()]
    param (
        [Alias('c')][ValidateSet('stable', 'beta', 'dev', 'canary')]
        [string]$Channel,
        [Alias('x')]
        [switch]$Extract
    )
    $request_json = @"
{
  "request": { "protocol": "3.1", "dedup": "cr", "ismachine": 1,
    "hw": { "physmemory": "16", "sse3": "1", "avx": "1" },
    "os": { "platform": "win", "version": "10.0.22000", "arch": "x86_64" },
    "app": [{ "appid": "{8A69D345-D564-463C-AFF1-A69D9E530F96}", "updatecheck": {}},
      { "appid": "{8237E44A-0054-442C-B6B6-EA0509993955}", "updatecheck": {}},
      { "appid": "{401C381F-E0DE-4B85-8BD8-3F3F14FBDA57}", "updatecheck": {}},
      { "appid": "{4EA16AC7-FD5A-47C3-875B-DBF4A2008C20}", "ap": "x64-canary", "updatecheck": {}}]}
}
"@
    try { $response_json = (Invoke-RestMethod -Method Post -Uri 'https://tools.google.com/service/update2/json' -Body $request_json).Replace(")]}'`n", "") | ConvertFrom-Json }
    catch { throw 'Something went wrong.' }
    if ($null -ne $response_json) {
        if ($Channel) {
            $app = $response_json.response.app[('stable', 'beta', 'dev', 'canary').IndexOf($Channel)]
            $bits = @{
                Source = -join @(($app.updatecheck.urls.url | Where-Object { $_.codebase -match "https://dl.google.com" }).codebase, $app.updatecheck.manifest.packages.package[0].name)
                Destination = $app.updatecheck.manifest.packages.package[0].name
                DisplayName = 'Google Chrome'
                Description = " {0} {1}" -f $app.cohortname, $app.updatecheck.manifest.version
            }
            try { Start-BitsTransfer @bits }
            catch { throw 'BITS failed. Try again.' }
            if ($Extract) {
                7z x $bits.Destination -aoa -bso0 -bsp1 -y
                7z x 'chrome.7z' -aoa -bso0 -bsp1 -y
                Rename-Item -LiteralPath 'Chrome-bin' -NewName 'App'
                'chrome.7z', $bits.Destination,
                    "App\$($app.updatecheck.manifest.version)\default_apps",
                    "App\$($app.updatecheck.manifest.version)\Extensions",
                    "App\$($app.updatecheck.manifest.version)\WidevineCdm" | Remove-Item -Recurse -Force
                Get-ChildItem -Path "App\$($app.updatecheck.manifest.version)\Locales\*.pak" -Exclude 'en-US.pak' | Remove-Item -Force
            }
        } else {
            $response_json.response.app | Format-Table @{ Label = 'Channel'; Expression = { $_.cohortname }}, @{ Label = 'Version'; Expression = { $_.updatecheck.manifest.version }}
        }
    }
}
Export-ModuleMember -Function Get-Chrome