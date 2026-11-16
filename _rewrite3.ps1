$dir = 'C:\Users\suhuai\Desktop\nanosynthesis-site'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# === Step 1: 读取 Excel JSON ===
$excel = [System.IO.File]::ReadAllText("$dir\_excel.json", [System.Text.Encoding]::UTF8) | ConvertFrom-Json
Write-Host "Excel: $($excel.Count) papers"

# === Step 2: 从 GitHub 提取每个编号对应的完整 article block ===
$github = [System.IO.File]::ReadAllText("$dir\_pub_github.html", [System.Text.Encoding]::UTF8)

# 找到所有 <span>数字. </span> 及其位置
$numPattern = '<span[^>]*>(\d+)\.\s*</span>'
$numMatches = [regex]::Matches($github, $numPattern)
Write-Host "GitHub numbered spans: $($numMatches.Count)"

# 收集每个编号对应的 block 起始位置（向前找最近的 <div class="item_line">）
$articleStarts = New-Object System.Collections.ArrayList
foreach ($m in $numMatches) {
    $num = [int]$m.Groups[1].Value
    # 从 span 位置向前找最近的 <div class="item_line">
    $searchFrom = $m.Index
    $divStart = -1
    while ($searchFrom -gt 0) {
        $idx = $github.LastIndexOf('<div class="item_line">', $searchFrom)
        if ($idx -lt 0) { break }
        # 验证这个 div 里面确实包含我们要的编号
        $checkText = $github.Substring($idx, [Math]::Min(3000, $github.Length - $idx))
        if ($checkText -match "<span[^>]*>$num\.\s*</span>") {
            $divStart = $idx
            break
        }
        $searchFrom = $idx - 1
    }
    if ($divStart -ge 0) {
        [void]$articleStarts.Add([pscustomobject]@{ Num=$num; Start=$divStart; SpanPos=$m.Index })
    }
}
Write-Host "Article starts found: $($articleStarts.Count)"

# 按 Start 位置排序
$articleStarts = $articleStarts | Sort-Object Start

# 确定每个 block 的结束位置：下一个 article 的 Start 之前
$ghArticles = @{}
for ($i = 0; $i -lt $articleStarts.Count; $i++) {
    $cur = $articleStarts[$i]
    $end = $github.Length
    if ($i -lt $articleStarts.Count - 1) {
        $end = $articleStarts[$i + 1].Start
    }
    # 向前再 trim 一下空白和换行
    $block = $github.Substring($cur.Start, $end - $cur.Start).Trim()
    $ghArticles[$cur.Num] = $block
}
Write-Host "GitHub articles extracted: $($ghArticles.Count)"

# 验证：检查几个关键编号
foreach ($chk in @(13, 40, 210)) {
    if ($ghArticles.ContainsKey($chk)) {
        $sample = $ghArticles[$chk]
        $m = [regex]::Match($sample, 'pub_title[^>]*>([^<]+)')
        $ttl = $m.Groups[1].Value
        if ($ttl.Length -gt 80) { $ttl = $ttl.Substring(0, 80) }
        Write-Host "  #$chk : $ttl"
    } else {
        Write-Host "  #$chk : NOT FOUND"
    }
}

# === Step 3: 准备各 decade 的文章列表 ===
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
    $afterItems = $bodyContent.Substring($bodyContent.IndexOf('<footer', $firstItem))
    if ($afterItems -eq "") { $afterItems = "</body>`r`n</html>" }
    
    # 收集新的 article blocks
    $newArticles = New-Object System.Collections.ArrayList
    
    if ($t.Decade -eq "2026-now") {
        # ICML 214 在最前面
        if ($ghArticles.ContainsKey(210)) {
            $icmlBlock = $ghArticles[210] -replace '<span>210\.\s*</span>', '<span>214. </span>'
            [void]$newArticles.Add($icmlBlock)
        }
        foreach ($num in (212..205)) {
            if ($num -eq 213) { continue }
            if ($ghArticles.ContainsKey($num)) { [void]$newArticles.Add($ghArticles[$num]) }
            else { Write-Host "  WARN: missing num=$num" }
        }
    } else {
        $nums = $excel | Where-Object { $_.Decade -eq $t.Decade } | ForEach-Object { $_.Num } | Sort-Object -Descending
        foreach ($num in $nums) {
            if ($ghArticles.ContainsKey($num)) { [void]$newArticles.Add($ghArticles[$num]) }
            else { Write-Host "  WARN: missing num=$num" }
        }
    }
    
    Write-Host "  Articles: $($newArticles.Count)"
    
    # 组合
    $newBodyContent = $beforeItems + ($newArticles -join "`n")
    $newRaw = $beforeBody + $newBodyContent + $afterFooter
    
    [System.IO.File]::WriteAllText($targetPath, $newRaw, $utf8NoBom)
    Write-Host "  SAVED"
}

Write-Host ""
Write-Host "ALL DONE!"
