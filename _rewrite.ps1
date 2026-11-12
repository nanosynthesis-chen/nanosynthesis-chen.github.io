Add-Type -AssemblyName System.IO.Compression.FileSystem
$dir = 'C:\Users\suhuai\Desktop\nanosynthesis-site'

# === Step 1: 重新从 xlsx 生成 _excel.json ===
$src = Get-ChildItem "$dir\papers.xlsx" -ErrorAction SilentlyContinue
if (-not $src) {
    Copy-Item "c:\Users\suhuai\.trae-cn\attachments\cad599d6-a232-4749-b920-86debfcdf0a5_2ec483b6-4fd1-4306-9750-e20a653e0afb_2001-2026发表文章情况一览表-自查 (version 1).xlsx" "$dir\papers.xlsx" -Force
}
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
    $r = $rows[$i]
    $cells = @{}
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
Write-Host "Excel: $($excel.Count) papers"

# === Step 2: 从 GitHub 提取 item_line blocks ===
$github = [System.IO.File]::ReadAllText("$dir\_pub_github.html", [System.Text.Encoding]::UTF8)
$allBlocks = @()
$pos = 0
while ($true) {
    $start = $github.IndexOf('<div class="item_line">', $pos)
    if ($start -lt 0) { break }
    $next = $github.IndexOf('<div class="item_line">', $start + 1)
    $footerIdx = $github.IndexOf('<footer', $start)
    $end = $github.Length
    if ($next -gt 0 -and $next -lt $end) { $end = $next }
    if ($footerIdx -gt 0 -and $footerIdx -lt $end) { $end = $footerIdx }
    $allBlocks += $github.Substring($start, $end - $start)
    $pos = $end
}
Write-Host "GitHub item_line blocks: $($allBlocks.Count)"

# 解析每个 block 的编号
$parsed = @()
foreach ($b in $allBlocks) {
    $nm = [regex]::Match($b, '<span[^>]*>(\d+)\.\s*')
    if ($nm.Success) { $parsed += [pscustomobject]@{ Num=[int]$nm.Groups[1].Value; Block=$b } }
}

# === Step 3: 分类 + 写入 ===
$xlMap = @{}
foreach ($p in $excel) { $xlMap[$p.Num] = $p.Decade }

# GitHub 里 ICML 那篇（Principle-Evolvable）编号多少？
$icmlBlock = $parsed | Where-Object { $_.Block -match 'Principle-Evolvable' } | Select-Object -First 1
$icmlNumInGitHub = if ($icmlBlock) { $icmlBlock.Num } else { $null }
Write-Host "ICML in GitHub num: $icmlNumInGitHub (will renumber to 214)"

$decadeFiles = @(
    @{ Decade="2001-2005"; File="publication-2001-2005.html" },
    @{ Decade="2006-2010"; File="publication-2006-2010.html" },
    @{ Decade="2011-2015"; File="publication-2011-2015.html" },
    @{ Decade="2016-2020"; File="publication-2016-2020.html" },
    @{ Decade="2021-2025"; File="publication-2021-2025.html" },
    @{ Decade="2026-now"; File="publication-2026.html" }
)

foreach ($t in $decadeFiles) {
    Write-Host ""
    Write-Host "=== $($t.File) ==="
    $targetPath = Join-Path $dir $t.File
    $c = [System.IO.File]::ReadAllText($targetPath, [System.Text.Encoding]::UTF8)
    
    # 找出文件中的 item_line 位置
    $bs = $c.IndexOf('<body'); if ($bs -lt 0) { $bs = 0 }
    $fs = $c.IndexOf('<footer', $bs); if ($fs -lt 0) { $fs = $c.Length }
    $beforeBody = $c.Substring(0, $bs)
    $body = $c.Substring($bs, $fs - $bs)
    $afterFooter = $c.Substring($fs)
    
    # 收集新的 article blocks（来自 GitHub）
    $newArticles = @()
    
    if ($t.Decade -eq "2026-now") {
        # 2026 特殊：ICML 214 + Excel 205-212（跳过 213）
        # ICML 放在最前面
        if ($icmlBlock) {
            # 把 ICML 的编号改成 214
            $icmlNew = $icmlBlock.Block -replace "<span>$icmlNumInGitHub\.\s*", '<span>214. '
            $newArticles += $icmlNew
        }
        foreach ($num in 212..205) {
            if ($num -eq 213) { continue }
            $found = $parsed | Where-Object { $_.Num -eq $num } | Select-Object -First 1
            if ($found) { $newArticles += $found.Block }
        }
    } else {
        foreach ($xl in $excel | Where-Object { $_.Decade -eq $t.Decade } | Sort-Object Num -Descending) {
            $found = $parsed | Where-Object { $_.Num -eq $xl.Num } | Select-Object -First 1
            if ($found) { $newArticles += $found.Block }
        }
    }
    
    Write-Host "  New article blocks: $($newArticles.Count)"
    
    # 在 body 里找到第一个 item_line 的位置，从那里开始替换到 footer 前
    $firstItem = $body.IndexOf('<div class="item_line">')
    $beforeItems = if ($firstItem -gt 0) { $body.Substring(0, $firstItem) } else { $body }
    $bodyFooterPos = $body.IndexOf('<footer')
    $articlesEnd = if ($bodyFooterPos -gt 0) { $bodyFooterPos } else { $body.Length }
    
    # 组合
    $newBody = $beforeItems + ($newArticles -join "`n") + $body.Substring($articlesEnd)
    
    [System.IO.File]::WriteAllText($targetPath, $beforeBody + $newBody + $afterFooter, $utf8NoBom)
    Write-Host "  SAVED"
}

Write-Host ""
Write-Host "ALL DONE!"
