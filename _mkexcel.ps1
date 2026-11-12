Add-Type -AssemblyName System.IO.Compression.FileSystem
$dir = 'C:\Users\suhuai\Desktop\nanosynthesis-site'
$zip = [System.IO.Compression.ZipFile]::OpenRead("$dir\papers.xlsx")
$ssEntry = $zip.GetEntry("xl/sharedStrings.xml")
$ssReader = New-Object System.IO.StreamReader($ssEntry.Open())
[xml]$ssXml = $ssReader.ReadToEnd(); $ssReader.Close()
$shared = @()
foreach ($si in $ssXml.sst.si) {
    if ($si.t) { $shared += [string]$si.t }
    elseif ($si.r) { $txt = ""; foreach ($r in $si.r) { $txt += [string]$r.t }; $shared += $txt }
    else { $shared += "" }
}
$shEntry = $zip.GetEntry("xl/worksheets/sheet1.xml")
$shReader = New-Object System.IO.StreamReader($shEntry.Open())
[xml]$shXml = $shReader.ReadToEnd(); $shReader.Close(); $zip.Dispose()
function CellVal($c) {
    if (-not $c) { return $null }
    $t = $c.t; $v = $c.v
    if ($t -eq "s") { return $shared[[int]$v] }
    if ($v) { return [string]$v }
    return $null
}
$rows = $shXml.worksheet.sheetData.row
$excel = @()
for ($i = 4; $i -lt $rows.Count; $i++) {
    $r = $rows[$i]; $cells = @{}
    foreach ($c in $r.c) { $col = $c.r -replace '\d',''; $cells[$col] = CellVal $c }
    if ($cells['A'] -match '^\d+$') {
        $num = [int]$cells['A']
        $yearNum = $null
        if ($cells['E'] -match '(\d{4})') { $yearNum = [int]$Matches[1] }
        $decade = ""
        if ($yearNum) {
            if ($yearNum -ge 2026) { $decade = "2026-now" }
            elseif ($yearNum -ge 2021) { $decade = "2021-2025" }
            elseif ($yearNum -ge 2016) { $decade = "2016-2020" }
            elseif ($yearNum -ge 2011) { $decade = "2011-2015" }
            elseif ($yearNum -ge 2006) { $decade = "2006-2010" }
            else { $decade = "2001-2005" }
        }
        $excel += [pscustomobject]@{ Num=$num; Decade=$decade }
    }
}
$excel = $excel | Sort-Object Num
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText("$dir\_excel.json", ($excel | ConvertTo-Json -Depth 2), $utf8NoBom)
Write-Host "Written $($excel.Count) entries to _excel.json"
