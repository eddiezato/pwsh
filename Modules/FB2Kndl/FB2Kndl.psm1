function Convert-FB2 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,ValueFromPipeline,Position = 0)]
        [ValidatePattern('\.fb2$', ErrorMessage = "You should specify .fb2 files.")]
        [string[]] $Path
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
        $tempdir = Join-Path -Path $Env:temp -ChildPath ('fb2kndl-' + ((New-Guid).Guid -replace '-', ''))
        New-Item -Path $tempdir -ItemType Directory | Out-Null
    }
    process {
        $Path | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | ForEach-Object {
            # preparing working folder
            $item = Get-Item -LiteralPath $_
            $dir = Join-Path -Path $tempdir -ChildPath $item.BaseName
            New-Item -Path $dir -ItemType Directory | Out-Null
            # performing xslt transform
            $xslt = New-Object Xml.Xsl.XslCompiledTransform
            'index.xhtml', 'content.opf', 'toc.ncx' | ForEach-Object {
                try { $xslt.Load("$PSScriptRoot\$_.xsl") } catch { throw $Error }
                $xslt.Transform($item.FullName, "$dir\$_")
            }
            Clear-Variable -Name xslt
            Copy-Item -LiteralPath "$PSScriptRoot\styles.css" -Destination "$dir\"
            # writing sequence to title 
            $fb2 = (Get-Content -LiteralPath $item.FullName -Raw) -as [Xml]
            $sequence = $fb2.FictionBook.description.'title-info'.sequence -as [PSCustomObject]
            $binary = $fb2.FictionBook.binary -as [PSCustomObject]
            Clear-Variable -Name fb2
            if ($sequence.Count) {
                if ($sequence.Count -gt 1) { $sequence = $sequence[0] }
                if ($sequence.HasAttribute('number')) {
                    $sequence = ($sequence.name -replace '\B.|\W', '') + $sequence.number
                    $opf = (Get-Content -LiteralPath "$dir\content.opf" -Raw) -as [Xml]
                    $opf.package.metadata.title = $sequence, $opf.package.metadata.title -join ' '
                    $opf.Save("$dir\content.opf")
                    Clear-Variable -Name opf
                }
            }
            # extracting images
            $binary | ForEach-Object {
                Set-Content -Path "$dir\$($_.id)" -Value ([Convert]::FromBase64String($_.'#text')) -AsByteStream
            }
            Clear-Variable -Name binary
            # creating epub
            New-Item -Path "$dir\META-INF" -ItemType Directory | Out-Null
            $metainf | Out-File -FilePath "$dir\META-INF\container.xml"
            'application/epub+zip' | Out-File -FilePath "$dir\mimetype" -NoNewline
            Compress-Archive -Path "$dir\mimetype" -DestinationPath "$dir.epub" -CompressionLevel NoCompression
            Remove-Item -LiteralPath "$dir\mimetype"
            Compress-Archive -Path "$dir\*" -DestinationPath "$dir.epub" -Update
            Copy-Item -LiteralPath "$dir.epub" -Destination $item.Directory.FullName -Force
        }
    }
    end {
        Remove-Item -LiteralPath $tempdir -Recurse -Force
    }
}
Export-ModuleMember -Function Convert-FB2
