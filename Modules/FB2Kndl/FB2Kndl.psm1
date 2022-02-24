function ConvertTo-xHtml {
    param (
        [string]$FB2Path,
        [string]$TempPath,
        [switch]$Cover = $false
    )
    # preparing working folder
    $TargetPath = Join-Path -Path $TempPath -ChildPath ((New-Guid).Guid -replace '-', '')
    New-Item -Path $TargetPath -ItemType Directory | Out-Null
    Write-Host ' Creating opf/xhtml/ncx.. ' -NoNewline
    # convert fb2 to xhtml,opf,ncx
    $xslt = New-Object Xml.Xsl.XslCompiledTransform
    'index.xhtml', 'content.opf', 'toc.ncx' | ForEach-Object {
        try {
            $xsl = (Get-Content -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath "$_.xsl") -Raw) -as [xml]
            if ($Cover -and ($_ -eq 'index.xhtml')) { ($xsl.stylesheet.param | Where-Object { $_.name -eq "addimage"}).select = 1 }
            $xslt.Load($xsl)
            Clear-Variable -Name 'xsl'
        } catch { Write-Host 'failed' -ForegroundColor Red; return $null }
        $xslt.Transform($FB2Path, (Join-Path -Path $TargetPath -ChildPath $_))
    }
    Write-Host 'ok' -ForegroundColor Green
    Clear-Variable -Name 'xslt'
    Copy-Item -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath 'styles.css') -Destination $TargetPath
    # extracting images
    $binary = ((Get-Content -LiteralPath $FB2Path -Raw) -as [xml]).FictionBook.binary -as [PSCustomObject]
    if ($binary.Count) {
        Write-Host ' Extracting images.. ' -NoNewline
        $imgerr = 0
        $binary | ForEach-Object {
            try {
                Set-Content -Path (Join-Path -Path $TargetPath -ChildPath $_.id) -Value ([Convert]::FromBase64String($_.'#text')) -AsByteStream -Force
            } catch { $imgerr++ }
        }
        if ($imgerr) { Write-Host "$imgerr files failed" -ForegroundColor Red }
        else { Write-Host 'ok' -ForegroundColor Green }
    }
    Clear-Variable -Name 'binary'
    return $TargetPath
}
function ConvertTo-Mobi {
    param (
        [string]$TargetPath,
        [string]$ErrorLogPath
    )
    Write-Host ' Converting to ' -NoNewLine
    Write-Host 'Mobi' -NoNewLine -ForegroundColor Blue
    Write-Host '.. ' -NoNewline
    $job = Start-Job -InputObject (Join-Path -Path $TargetPath -ChildPath 'content.opf') {
        & (Join-Path -Path $Using:PSScriptRoot -ChildPath 'kindlegen.exe') $input -c2 -dont_append_source -gen_ff_mobi7 -locale en
    }
    $i = 0
    [Console]::CursorVisible = $false
    while ($job.State -eq 'Running') {
        Write-Host ('|/-\'[$i] + "`b") -NoNewLine -ForegroundColor Yellow
        $i = $i -eq 3 ? 0 : $i + 1
        Start-Sleep -s 0.2
    }
    [Console]::CursorVisible = $true
    $kg = Receive-Job $job
    $job | Remove-Job
    if ((($kg | Where-Object { $_ })[-1] -like '*Mobi file built*') -and (Test-Path -LiteralPath (Join-Path -Path $TargetPath -ChildPath 'content.mobi'))) {
        Move-Item -LiteralPath (Join-Path -Path $TargetPath -ChildPath 'content.mobi') -Destination "$TargetPath.mobi" -Force
        return $true
    } else {
        $kg | Where-Object { $_ } | Out-File -FilePath $ErrorLogPath -Encoding oem
        return $false
    }
}
function ConvertTo-ePub {
    param ( [string]$TargetPath )
    $metainf = @'
<?xml version="1.0" encoding="UTF-8" ?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
'@
    Write-Host ' Converting to ' -NoNewLine
    Write-Host 'ePub' -NoNewLine -ForegroundColor Cyan
    Write-Host '.. ' -NoNewline
    New-Item -Path (Join-Path -Path $TargetPath -ChildPath 'META-INF') -ItemType Directory | Out-Null
    $metainf | Out-File -FilePath (Join-Path -Path $TargetPath -ChildPath 'META-INF' -AdditionalChildPath 'container.xml')
    'application/epub+zip' | Out-File -FilePath (Join-Path -Path $TargetPath -ChildPath 'mimetype') -NoNewline
    Compress-Archive -LiteralPath (Join-Path -Path $TargetPath -ChildPath 'mimetype') -DestinationPath "$TargetPath.epub" -CompressionLevel NoCompression
    Remove-Item -LiteralPath (Join-Path -Path $TargetPath -ChildPath 'mimetype')
    Compress-Archive -Path (Join-Path -Path $TargetPath -ChildPath '*') -DestinationPath "$TargetPath.epub" -Update
    if (Test-Path -LiteralPath "$TargetPath.epub") { return $true }
    else { return $false }
}
function Set-ValidName {
    param ([string]$Name)
    $Dict = @(
        @{ ru = 'вий'; en = 'vy' },
        @{ ru = 'гий'; en = 'gy' },
        @{ ru = 'дий'; en = 'dy' },
        @{ ru = 'ний'; en = 'ny' },
        @{ ru = 'сий'; en = 'sy' },
        @{ ru = 'тий'; en = 'ty' },
        @{ ru = 'жд'; en = 'zd' },
        @{ ru = 'ай'; en = 'ay' },
        @{ ru = 'ей'; en = 'ey' },
        @{ ru = 'ёй'; en = 'ey' },
        @{ ru = 'ий'; en = 'iy' },
        @{ ru = 'ия'; en = 'ia' },
        @{ ru = 'ой'; en = 'oy' },
        @{ ru = 'уй'; en = 'uy' },
        @{ ru = 'ый'; en = 'uy' },
        @{ ru = 'эй'; en = 'ey' },
        @{ ru = 'ья'; en = 'ia' },
        @{ ru = 'ье'; en = 'ye' },
        @{ ru = 'ьё'; en = 'ye' },
        @{ ru = 'ьа'; en = 'ia' },
        @{ ru = 'ьи'; en = 'yi' },
        @{ ru = 'ьо'; en = 'yo' },
        @{ ru = 'ьу'; en = 'yu' },
        @{ ru = 'ьы'; en = 'yy' },
        @{ ru = 'ьэ'; en = 'ye' },
        @{ ru = 'ью'; en = 'yu' },
        @{ ru = 'кс'; en = 'x' },
        @{ ru = 'юй'; en = 'yuy' },
        @{ ru = 'яй'; en = 'yay' },
        @{ ru = 'лю'; en = 'liu' },
        @{ ru = 'ж'; en = 'zh' },
        @{ ru = 'х'; en = 'kh' },
        @{ ru = 'ц'; en = 'ts' },
        @{ ru = 'ч'; en = 'ch' },
        @{ ru = 'ш'; en = 'sh' },
        @{ ru = 'я'; en = 'ya' },
        @{ ru = 'ю'; en = 'yu' },
        @{ ru = 'щ'; en = 'sch' },
        @{ ru = 'ъ'; en = '' },
        @{ ru = 'ь'; en = '' },
        @{ ru = 'а'; en = 'a' },
        @{ ru = 'б'; en = 'b' },
        @{ ru = 'в'; en = 'v' },
        @{ ru = 'г'; en = 'g' },
        @{ ru = 'д'; en = 'd' },
        @{ ru = 'е'; en = 'e' },
        @{ ru = 'ё'; en = 'e' },
        @{ ru = 'з'; en = 'z' },
        @{ ru = 'и'; en = 'i' },
        @{ ru = 'й'; en = 'y' },
        @{ ru = 'к'; en = 'k' },
        @{ ru = 'л'; en = 'l' },
        @{ ru = 'м'; en = 'm' },
        @{ ru = 'н'; en = 'n' },
        @{ ru = 'о'; en = 'o' },
        @{ ru = 'п'; en = 'p' },
        @{ ru = 'р'; en = 'r' },
        @{ ru = 'с'; en = 's' },
        @{ ru = 'т'; en = 't' },
        @{ ru = 'у'; en = 'u' },
        @{ ru = 'ф'; en = 'f' },
        @{ ru = 'ы'; en = 'y' },
        @{ ru = 'э'; en = 'e' }
    )
    $NewName = $Name.Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
    $Dict.ForEach({ if ($NewName -match $_.ru) { $NewName = $NewName -replace $_.ru, $_.en } })
    return $NewName
}
function ConvertFrom-FB2 {
    [Alias('cvfb')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName="mobi", ValueFromPipeline, Position = 0)]
        [Parameter(Mandatory, ParameterSetName="epub", ValueFromPipeline, Position = 0)]
        [ValidatePattern('\.fb2z?$', ErrorMessage = "You should specify .fb2/.fb2z files")]
        [string[]]$Path,    
        [Parameter(Mandatory, ParameterSetName="mobi", Position = 1)][Alias('m')]
        [switch]$ToMOBI,
        [Parameter(Mandatory, ParameterSetName="epub", Position = 1)][Alias('e')]
        [switch]$ToEPUB,
        [Parameter(Position = 2)][Alias('t')]
        [switch]$Transliterate,
        [Parameter(Position = 3)][Alias('s')]
        [switch]$SequenceToTitle
    )
    begin {
        # preparing temp folder
        $temppath = Join-Path -Path $Env:temp -ChildPath ('fb2kndl' + ((New-Guid).Guid -replace '-', ''))
        New-Item -Path $temppath -ItemType Directory | Out-Null
    }
    process {
        $Path | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | ForEach-Object {
            $sourcefile = Get-Item -LiteralPath $_
            Write-Host $sourcefile.Name -ForegroundColor Magenta
            $fb2path = $sourcefile.FullName
            if ($sourcefile.Extension -eq '.fb2z') {
                $expandarchive = @{
                    LiteralPath = $sourcefile
                    DestinationPath = (Join-Path -Path $temppath -ChildPath 'fb2zip')
                    PassThru = $true
                }
                $archivefb2path = (Expand-Archive @expandarchive | Where-Object { $_.Extension -eq '.fb2' })[0].FullName
                $fb2path = (Move-Item -LiteralPath $archivefb2path -Destination $temppath -PassThru).FullName
                Remove-Item -LiteralPath (Join-Path -Path $temppath -ChildPath 'fb2zip') -Recurse -Force
            }
            $fb2titleinfo = ((Get-Content -LiteralPath $fb2path) -as [xml]).FictionBook.description.'title-info'
            if ($fb2titleinfo.author.Count -eq 1) { $author = $fb2titleinfo.author } else { $author = $fb2titleinfo.author[0] }
            $fb2info = [PSCustomObject]@{
                Title = $fb2titleinfo.'book-title'
                Author = "{0} {1}" -f $author.'last-name', $author.'first-name'
                Sequence = $false
            }
            if ($fb2titleinfo.sequence.Count) {
                if ($fb2titleinfo.sequence.Count -eq 1) { $sequence = $fb2titleinfo.sequence } else { $sequence = $fb2titleinfo.sequence[0] }
                if ($sequence.HasAttribute('number')) { $sequence = [PSCustomObject]@{ Name = $sequence.name; Number = $sequence.number }}
                Clear-Variable -Name 'sequence'
            }
            Clear-Variable -Name 'fb2titleinfo', 'author'
            if ($targetpath = ConvertTo-xHtml -FB2Path $fb2path -TempPath $temppath -Cover:$ToEPUB) {
                if ($SequenceToTitle -and $fb2info.Sequence) {
                    Write-Host ' Add sequence to book title.. ' -NoNewline
                    try {
                        $opf = (Get-Content -LiteralPath (Join-Path -Path $targetpath -ChildPath 'content.opf') -Raw) -as [Xml]
                        $opf.package.metadata.title = "{0}{1} {2}" -f ($fb2info.Sequence.Name -replace '\B.|\W', ''),
                            $fb2info.Sequence.Number, $opf.package.metadata.title
                        $opf.Save((Join-Path -Path $targetpath -ChildPath 'content.opf'))
                        Write-Host 'ok' -ForegroundColor Green
                    } catch { Write-Host 'failed' -ForegroundColor Red } finally { Clear-Variable -Name 'opf' }
                }
                if ($ToMOBI) {
                    $ext = (ConvertTo-Mobi -TargetPath $targetpath -ErrorLogPath "$($sourcefile.FullName).log") ? 'mobi' : $false
                } elseif ($ToEPUB) { $ext = (ConvertTo-ePub -TargetPath $targetpath) ? 'epub' : $false }
                if ($ext) {
                    if ($Transliterate) {
                        if ($fb2info.Sequence) { $basename = "{0} {1} - {2}" -f $fb2info.Sequence.Name, $fb2info.Sequence.Number, $fb2info.Title }
                        else { $basename = $fb2info.Title }
                        $van = Set-ValidName -Name $fb2info.Author
                        if (-not(Test-Path -LiteralPath (Join-Path -Path $sourcefile.Directory.FullName -ChildPath $van) -PathType Container)) {
                            New-Item -Path (Join-Path -Path $sourcefile.Directory.FullName -ChildPath $van) -ItemType Directory | Out-Null
                        }
                        $basename = Join-Path -Path $van -ChildPath (Set-ValidName -Name $basename)
                        Clear-Variable -Name 'van'
                    } else { $basename = $sourcefile.BaseName }
                    Move-Item -LiteralPath "$targetpath.$ext" -Destination (Join-Path -Path $sourcefile.Directory.FullName -ChildPath "$basename.$ext") -Force
                    Write-Host 'ok' -ForegroundColor Green
                } else { Write-Host 'failed' -ForegroundColor Red }
            } else { Write-Host ' Failed to convert' -ForegroundColor Red }
            Clear-Variable -Name 'fb2info'
        }
    }
    end { Remove-Item -LiteralPath $temppath -Recurse -Force }
}
Export-ModuleMember -Function ConvertFrom-FB2 -Alias cvfb