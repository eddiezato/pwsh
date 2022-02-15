function Convert-Fb2 {
    param (
        [PSObject]$Item,
        [string]$TempDir,
        [switch]$SeqInTitle = $false
    )
    # preparing working folder
    $ItemDir = Join-Path -Path $TempDir -ChildPath $Item.BaseName
    New-Item -Path $ItemDir -ItemType Directory | Out-Null
    # performing xslt transform
    Write-Host (Get-Date).ToLongTimeString().PadLeft(9, ' ') -NoNewline -ForegroundColor DarkGray
    Write-Host ' Creating opf/xhtml/ncx.. ' -NoNewline
    $xslt = New-Object Xml.Xsl.XslCompiledTransform
    'index.xhtml', 'content.opf', 'toc.ncx' | ForEach-Object {
        try { $xslt.Load("$PSScriptRoot\$_.xsl") } catch { Write-Host 'failed' -ForegroundColor Red; return $null }
        $xslt.Transform($Item.FullName, "$ItemDir\$_")
    }
    Clear-Variable -Name xslt
    Write-Host 'ok' -ForegroundColor Green
    Copy-Item -LiteralPath "$PSScriptRoot\styles.css" -Destination "$ItemDir\"
    $fb2 = (Get-Content -LiteralPath $Item.FullName -Raw) -as [xml]
    $binary = $fb2.FictionBook.binary -as [PSCustomObject]
    if ($SeqInTitle) {
        # writing sequence to title
        $sequence = $fb2.FictionBook.description.'title-info'.sequence -as [PSCustomObject]
        if ($sequence.Count) {
            Write-Host (Get-Date).ToLongTimeString().PadLeft(9, ' ') -NoNewline -ForegroundColor DarkGray
            Write-Host ' Writing sequence to title.. ' -NoNewline
            if ($sequence.Count -gt 1) { $sequence = $sequence[0] }
            if ($sequence.HasAttribute('number')) {
                $sequence = ($sequence.name -replace '\B.|\W', '') + $sequence.number
                try {
                    $opf = (Get-Content -LiteralPath "$ItemDir\content.opf" -Raw) -as [Xml]
                    $opf.package.metadata.title = $sequence, $opf.package.metadata.title -join ' '
                    $opf.Save("$ItemDir\content.opf")
                } catch { return $null } finally { Clear-Variable -Name opf }
                Write-Host 'ok' -ForegroundColor Green
            } else { Write-Host 'failed' -ForegroundColor Red }
        }
    }
    Clear-Variable -Name fb2
    # extracting images
    if ($binary.Count) {
        Write-Host (Get-Date).ToLongTimeString().PadLeft(9, ' ') -NoNewline -ForegroundColor DarkGray
        Write-Host ' Extracting images.. ' -NoNewline
        $binary | ForEach-Object {
            Set-Content -Path "$ItemDir\$($_.id)" -Value ([Convert]::FromBase64String($_.'#text')) -AsByteStream
        }
        Write-Host 'ok' -ForegroundColor Green
    }
    Clear-Variable -Name binary
    return $ItemDir
}
function Convert-Fb2ePub {
    [Alias('cvfe')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,ValueFromPipeline,Position = 0)]
        [ValidatePattern('\.fb2$', ErrorMessage = "You should specify .fb2 files.")]
        [string[]]$Path,
        [Parameter(Position = 1)][Alias('s')]
        [switch]$SequenceToTitle = $false
    )
    begin {
        $metainf = @'
<?xml version="1.0" encoding="UTF-8" ?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
'@
        # preparing temp folder
        $tempd = Join-Path -Path $Env:temp -ChildPath ('fb2kndl-' + ((New-Guid).Guid -replace '-', ''))
        New-Item -Path $tempd -ItemType Directory | Out-Null
    }
    process {
        $Path | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | ForEach-Object {
            # convert fb2 to opf,xhtml,ncx
            $file = Get-Item -LiteralPath $_
            Write-Host $file.Name -ForegroundColor Magenta
            if ($dir = Convert-Fb2 -Item $file -TempDir $tempd -SeqInTitle:$SequenceToTitle) {
                # creating epub
                Write-Host (Get-Date).ToLongTimeString().PadLeft(9, ' ') -NoNewline -ForegroundColor DarkGray
                Write-Host ' Converting to ' -NoNewLine
                Write-Host 'ePub' -NoNewLine -ForegroundColor Cyan
                Write-Host '.. ' -NoNewline -ForegroundColor DarkGray
                New-Item -Path "$dir\META-INF" -ItemType Directory | Out-Null
                $metainf | Out-File -FilePath "$dir\META-INF\container.xml"
                'application/epub+zip' | Out-File -FilePath "$dir\mimetype" -NoNewline
                Compress-Archive -Path "$dir\mimetype" -DestinationPath "$dir.epub" -CompressionLevel NoCompression
                Remove-Item -LiteralPath "$dir\mimetype"
                Compress-Archive -Path "$dir\*" -DestinationPath "$dir.epub" -Update
                if (Test-Path -LiteralPath "$dir.epub") {
                    Copy-Item -LiteralPath "$dir.epub" -Destination $file.Directory.FullName -Force
                    Write-Host 'ok' -ForegroundColor Green
                } else { Write-Host 'failed' -ForegroundColor Red }
            }
        }
    }
    end { Remove-Item -LiteralPath $tempd -Recurse -Force }
}
function Convert-Fb2Mobi {
    [Alias('cvfm')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,ValueFromPipeline,Position = 0)]
        [ValidatePattern('\.fb2$', ErrorMessage = "You should specify .fb2 files.")]
        [string[]]$Path,
        [Parameter(Position = 1)][Alias('s')]
        [switch]$SequenceToTitle = $false
    )
    begin {
        # preparing temp folder
        $tempd = Join-Path -Path $Env:temp -ChildPath ('fb2kndl-' + ((New-Guid).Guid -replace '-', ''))
        New-Item -Path $tempd -ItemType Directory | Out-Null
    }
    process {
        $Path | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | ForEach-Object {
            # convert fb2 to opf,xhtml,ncx
            $file = Get-Item -LiteralPath $_
            Write-Host $file.Name -ForegroundColor Magenta
            if ($dir = Convert-Fb2 -Item $file -TempDir $tempd -SeqInTitle:$SequenceToTitle) {
                Write-Host (Get-Date).ToLongTimeString().PadLeft(9, ' ') -NoNewline -ForegroundColor DarkGray
                Write-Host ' Converting to ' -NoNewLine
                Write-Host 'Mobi' -NoNewLine -ForegroundColor Blue
                Write-Host '.. ' -NoNewline -ForegroundColor DarkGray
                $job = Start-Job -InputObject "$dir\content.opf" {
                    & "$($Using:PSScriptRoot)\kindlegen.exe" $input -c2 -dont_append_source -gen_ff_mobi7 -locale en
                }
                $c = @('Yellow', $Host.UI.RawUI.BackgroundColor)
                $i = 0
                [Console]::CursorVisible = $false
                Write-Host "[    ]`b" -NoNewLine -ForegroundColor Yellow
                while ($job.State -eq 'Running') {
                    Write-Host "`b`b`b`b" -NoNewline
                    Write-Host '    '.SubString(0, $i) -NoNewLine -BackgroundColor $c[0]
                    Write-Host '    '.SubString($i) -NoNewLine -BackgroundColor $c[1]
                    if ($i -lt 4) { $i++ }
                    else { $i = 0; $c[0], $c[1] = $c[1], $c[0] }
                    Start-Sleep -s 0.2
                }
                Write-Host "`b`b`b`b`b" -NoNewLine
                [Console]::CursorVisible = $true
                $kg = Receive-Job $job
                $job | Remove-Job
                if ((($kg | Where-Object { $_ })[-1] -like '*Mobi file built*') -and (Test-Path -LiteralPath "$dir\content.mobi")) {
                    Copy-Item -LiteralPath "$dir\content.mobi" -Destination ($file.FullName -replace '\.fb2$', '.mobi') -Force
                    Write-Host 'ok    ' -ForegroundColor Green
                } else {
                    $kg | Where-Object { $_ } | Out-File -FilePath ($file.FullName -replace '\.fb2$', '.mobi-error.log') -Encoding oem
                    Write-Host 'failed' -ForegroundColor Red
                }
            }
        }
    }
    end { Remove-Item -LiteralPath $tempd -Recurse -Force }
}
Export-ModuleMember -Function Convert-Fb2Mobi, Convert-Fb2ePub -Alias cvfe, cvfm