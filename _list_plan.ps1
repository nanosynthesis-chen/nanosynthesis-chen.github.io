$dir = 'C:\Users\suhuai\Desktop\nanosynthesis-site'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$github = [System.IO.File]::ReadAllText("$dir\_pub_github.html", [System.Text.Encoding]::UTF8)

# 1. 从 GitHub 提取所有 <div class="item_line"> 块
$blocks = [regex]::Matches($github, '(?s)<div class="item_line">(.*?)(?=<div class="item_line"|</div>\s*</div>\s*<footer|</footer>)')
Write-Host "GitHub total item_line blocks: $($blocks.Count)"

# 2. 提取每个块的编号和标题
$allArticles = @()
foreach ($m in $blocks) {
    $block = $m.Groups[0].Value
    # 提取编号
    $numMatch = [regex]::Match($block, '<span[^>]*>(\d+)\.\s*')
    $num = if ($numMatch.Success) { [int]$numMatch.Groups[1].Value } else { $null }
    # 提取标题
    $titleMatch = [regex]::Match($block, "class=['"]pub_title['"]>(.*?)</span>", [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $title = if ($titleMatch.Success) { ($titleMatch.Groups[1].Value -replace '\s+',' ' -replace '"','"' -replace '<[^>]+>','').Trim() } else { "" }
    $allArticles += [pscustomobject]@{ Num=$num; Title=$title; Block=$block }
}
Write-Host "Parsed: $($allArticles.Count) articles"

# 3. 用年份标题 section 切分（GitHub 里有 2006/2007/.../2026 的 div 标题）
# GitHub publication.html 是按年份分组的，item_line 跟随年份标题
# 我需要找到从哪个 item_line 开始属于哪个 decade：
# 2001-2005: 用年份 <2006
# 2006-2010: 年份 2006-2010
# 2011-2015: 年份 2011-2015
# 2016-2020: 年份 2016-2020
# 2021-2025: 年份 2021-2025
# 2026-now: 年份 2026+

# 但直接从 GitHub publication.html 找年份太复杂，还是用 Excel 的 decade 分组！
# Excel 我们已经有了
$excel = Get-Content "$dir\_excel.json" -Raw | ConvertFrom-Json

# 用 Excel decade 分组 + 倒序（和 GitHub 顺序一致）
$excelByDecade = @{}
foreach ($d in $excel | Group-Object Decade) {
    $excelByDecade[$d.Name] = @($d.Group | Sort-Object Num -Descending)
}

# 从 Excel decade → 编号范围，再反查 GitHub article
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
    Write-Host "=== $($t.File) (decade=$($t.Decade)) ==="
    
    # Excel 这个 decade 有哪些编号（倒序）
    $xlList = $excelByDecade[$t.Decade]
    Write-Host "  Excel nums: $($xlList[0].Num) down to $($xlList[-1].Num)"
    
    # GitHub 2026 特殊：多一个 ICML 214 不在 Excel 里
    if ($t.Decade -eq "2026-now") {
        # 从 GitHub 找 ICML 那篇（标题含 Principle-Evolvable）
        $icml = $allArticles | Where-Object { $_.Title -match "Principle-Evolvable" } | Select-Object -First 1
        if ($icml) { Write-Host "  ICML 214 found in GitHub (num=$($icml.Num))" }
    }
    
    # 从 GitHub 取这些编号的 article block
    $targetNums = @($xlList | ForEach-Object { $_.Num })
    # 2026 特殊：在最前面加上 ICML 的 article
    $articlesFromGitHub = @()
    if ($t.Decade -eq "2026-now") {
        $icml = $allArticles | Where-Object { $_.Title -match "Principle-Evolvable" } | Select-Object -First 1
        if ($icml) { $articlesFromGitHub += $icml }
        foreach ($n in $targetNums) {
            if ($n -eq 213) { continue }  # 跳过 213
            $found = $allArticles | Where-Object { $_.Num -eq $n } | Select-Object -First 1
            if ($found) { $articlesFromGitHub += $found } else { Write-Host "    MISSING #$n" }
        }
    } else {
        foreach ($n in $targetNums) {
            $found = $allArticles | Where-Object { $_.Num -eq $n } | Select-Object -First 1
            if ($found) { $articlesFromGitHub += $found } else { Write-Host "    MISSING #$n" }
        }
    }
    
    Write-Host "  GitHub articles found: $($articlesFromGitHub.Count)"
    foreach ($a in $articlesFromGitHub) { Write-Host "    #$($a.Num) $($a.Title.Substring(0,[Math]::Min(60,$a.Title.Length)))..." }
}

Write-Host ""
Write-Host "Done listing. Ready to write..."
