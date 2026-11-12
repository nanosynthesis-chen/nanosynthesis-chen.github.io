Add-Type -AssemblyName System.IO.Compression.FileSystem
$dir = 'C:\Users\suhuai\Desktop\nanosynthesis-site'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# === Step 1: 从已有的 _excel.json 读取 ===
$excel = [System.IO.File]::ReadAllText("$dir\_excel.json", [System.Text.Encoding]::UTF8) | ConvertFrom-Json
Write-Host "Excel: $($excel.Count) papers"

# === Step 2: 从 GitHub 提取 item_line blocks ===
$github = [System.IO.File]::ReadAllText("$dir\_pub_github.html", [System.Text.Encoding]::UTF8)
$allBlocks = New-Object System.Collections.ArrayList
$pos = 0
while ($true) {
    $start = $github.IndexOf('<div class="item_line">', $pos)
    if ($start -lt 0) { break }
    $next = $github.IndexOf('<div class="item_line">', $start + 1)
    $footerIdx = $github.IndexOf('<footer', $start)
    $end = $github.Length
    if ($next -gt 0 -and $next -lt $end) { $end = $next }
    if ($footerIdx -gt 0 -and $footerIdx -lt $end) { $end = $footerIdx }
    [void]$allBlocks.Add($github.Substring($start, $end - $start))
    $pos = $end
}
Write-Host "GitHub item_line blocks: $($allBlocks.Count)"

# 解析每个 block 的编号
$parsed = New-Object System.Collections.ArrayList
foreach ($b in $allBlocks) {
    $nm = [regex]::Match($b, '<span[^>]*>(\d+)\.\s*')
    if ($nm.Success) {
        [void]$parsed.Add([pscustomobject]@{ Num=[int]$nm.Groups[1].Value; Block=$b })
    }
}
Write-Host "Parsed blocks with numbers: $($parsed.Count)"

# 构建 GitHub 编号 -> block 的哈希表
$ghMap = @{}
foreach ($p in $parsed) { $ghMap[$p.Num] = $p.Block }

# === Step 3: ICML 特殊处理 ===
$icmlEntry = $parsed | Where-Object { $_.Block -match 'Principle-Evolvable' } | Select-Object -First 1
$icmlNumInGh = if ($icmlEntry) { $icmlEntry.Num } else { $null }
Write-Host "ICML in GitHub num: $icmlNumInGh (will renumber to 214)"

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
    Write-Host "=== $($t.File) ($($t.Decade)) ==="
    $targetPath = Join-Path $dir $t.File
    $raw = [System.IO.File]::ReadAllText($targetPath, [System.Text.Encoding]::UTF8)
    
    # 拆分: <body> 之前, body内, <footer> 之后
    $bodyStart = $raw.IndexOf('<body'); if ($bodyStart -lt 0) { $bodyStart = $raw.IndexOf('<BODY') }
    if ($bodyStart -lt 0) { Write-Host "  SKIP: no <body> tag"; continue }
    
    $footerStart = $raw.IndexOf('<footer', $bodyStart)
    if ($footerStart -lt 0) { $footerStart = $raw.Length }
    
    $beforeBody = $raw.Substring(0, $bodyStart)
    $bodyContent = $raw.Substring($bodyStart, $footerStart - $bodyStart)
    $afterFooter = $raw.Substring($footerStart)
    
    # 找到 body 里第一个 item_line
    $firstItem = $bodyContent.IndexOf('<div class="item_line">')
    if ($firstItem -lt 0) { Write-Host "  SKIP: no item_line in body"; continue }
    
    $beforeItems = $bodyContent.Substring(0, $firstItem)
    $articlesEnd = $bodyContent.IndexOf('<footer')
    if ($articlesEnd -lt 0) { $articlesEnd = $bodyContent.Length }
    $afterItems = $bodyContent.Substring($articlesEnd)
    
    # 收集新的 article blocks
    $newArticles = New-Object System.Collections.ArrayList
    
    if ($t.Decade -eq "2026-now") {
        # ICML 214 + Excel 205-212 (跳过 213)
        if ($icmlEntry) {
            $icmlRenumbered = $icmlEntry.Block -replace "<span>$icmlNumInGh\.\s*", '<span>214. '
            [void]$newArticles.Add($icmlRenumbered)
        }
        foreach ($num in (212..205)) {
            if ($num -eq 213) { continue }
            if ($ghMap.ContainsKey($num)) { [void]$newArticles.Add($ghMap[$num]) }
            else { Write-Host "  WARNING: GitHub missing num=$num" }
        }
    } else {
        # 按 Excel decade 分组，倒序（新的在前）
        $nums = $excel | Where-Object { $_.Decade -eq $t.Decade } | ForEach-Object { $_.Num } | Sort-Object -Descending
        foreach ($num in $nums) {
            if ($ghMap.ContainsKey($num)) { [void]$newArticles.Add($ghMap[$num]) }
            else { Write-Host "  WARNING: GitHub missing num=$num" }
        }
    }
    
    Write-Host "  New article blocks: $($newArticles.Count)"
    
    # 组合
    $newBodyContent = $beforeItems + ($newArticles -join "`n") + $afterItems
    $newRaw = $beforeBody + $newBodyContent + $afterFooter
    
    [System.IO.File]::WriteAllText($targetPath, $newRaw, $utf8NoBom)
    Write-Host "  SAVED"
}

Write-Host ""
Write-Host "ALL DONE!"
