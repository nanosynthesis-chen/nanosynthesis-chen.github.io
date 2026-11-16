$dir = 'C:\Users\suhuai\Desktop\nanosynthesis-site'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$github = [System.IO.File]::ReadAllText("$dir\_pub_github.html", [System.Text.Encoding]::UTF8)

# 1. 找所有 item_line 块（GitHub 里的 article）
# 简单策略：按 "<div class=\"item_line\">" 分割 + 直到下一个 item_line 或 footer
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
    $block = $github.Substring($start, $end - $start)
    $allBlocks += $block
    $pos = $end
}
Write-Host "GitHub total item_line blocks: $($allBlocks.Count)"

# 2. 提取每块的编号和出版年份
$parsed = @()
foreach ($b in $allBlocks) {
    $num = $null
    $nm = [regex]::Match($b, '<span[^>]*>(\d+)\.\s*')
    if ($nm.Success) { $num = [int]$nm.Groups[1].Value }
    
    $year = $null
    $ym = [regex]::Match($b, 'class=[^>]*pub_year[^>]*>(\d{4})')
    if ($ym.Success) { $year = [int]$ym.Groups[1].Value }
    
    $parsed += [pscustomobject]@{ Num=$num; Year=$year; Block=$b }
}

# 3. 用 Excel 213 条做 decade 权威分组
$excel = Get-Content "$dir\_excel.json" -Raw | ConvertFrom-Json

# 建 Excel 权威 num→decade 映射
$xlMap = @{}
foreach ($p in $excel) { $xlMap[$p.Num] = $p.Decade }

# GitHub 额外编号 ICML（不在 Excel），手动标记
# Principle-Evolvable 那篇，在 GitHub 里编号 210（GitHub 原版），我们要改成 214

# 4. 分类：用 Excel decade 给 GitHub article 归类
$decadeFiles = @(
    @{ Decade="2001-2005"; File="publication-2001-2005.html"; Years=@(2001..2005) },
    @{ Decade="2006-2010"; File="publication-2006-2010.html"; Years=@(2006..2010) },
    @{ Decade="2011-2015"; File="publication-2011-2015.html"; Years=@(2011..2015) },
    @{ Decade="2016-2020"; File="publication-2016-2020.html"; Years=@(2016..2020) },
    @{ Decade="2021-2025"; File="publication-2021-2025.html"; Years=@(2021..2025) },
    @{ Decade="2026-now"; File="publication-2026.html"; Years=@(2026..2030) }
)

foreach ($t in $decadeFiles) {
    Write-Host ""
    Write-Host "=== $($t.File) (decade=$($t.Decade)) ==="
    
    $grouped = @()
    foreach ($a in $parsed) {
        if ($null -eq $a.Num) { continue }
        # 优先用 Excel 权威映射
        if ($xlMap.ContainsKey($a.Num)) {
            if ($xlMap[$a.Num] -eq $t.Decade) { $grouped += $a }
        } else {
            # Excel 没有的（ICML 214），用年份判断
            if ($a.Year -and $t.Years -contains $a.Year) { $grouped += $a }
        }
    }
    Write-Host "  Grouped articles: $($grouped.Count)"
    foreach ($a in $grouped) { Write-Host "    #$($a.Num) year=$($a.Year)" }
}

Write-Host ""
Write-Host "DONE listing."
