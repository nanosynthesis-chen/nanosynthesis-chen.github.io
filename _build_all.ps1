$dir = 'C:\Users\suhuai\Desktop\nanosynthesis-site'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# =========================================
# Step 1: 提取 GitHub 文章 blocks
# =========================================
Write-Host "Step 1: Extracting GitHub articles..."
$github = [System.IO.File]::ReadAllText("$dir\_pub_github.html", [System.Text.Encoding]::UTF8)
$numMatches = [regex]::Matches($github, '<span[^>]*>(\d+)\.\s*</span>')
$articleStarts = New-Object System.Collections.ArrayList
foreach ($mt in $numMatches) {
    $num = [int]$mt.Groups[1].Value
    $sf = $mt.Index; $ds = -1
    while ($sf -gt 0) {
        $idx = $github.LastIndexOf('<div class="item_line">', $sf)
        if ($idx -lt 0) { break }
        $chk = $github.Substring($idx, [Math]::Min(3000, $github.Length - $idx))
        if ($chk -match "<span[^>]*>$num\.\s*</span>") { $ds = $idx; break }
        $sf = $idx - 1
    }
    if ($ds -ge 0) { [void]$articleStarts.Add([pscustomobject]@{ Num=$num; Start=$ds }) }
}
$articleStarts = $articleStarts | Sort-Object Start
$ghArticles = @{}
for ($i = 0; $i -lt $articleStarts.Count; $i++) {
    $cur = $articleStarts[$i]
    $end = if ($i -lt $articleStarts.Count - 1) { $articleStarts[$i + 1].Start } else { $github.Length }
    $ghArticles[$cur.Num] = $github.Substring($cur.Start, $end - $cur.Start).Trim()
}
Write-Host "  Done: $($ghArticles.Count) articles"

# =========================================
# Step 2: 从 publication.html 提取公共部分
# =========================================
Write-Host "Step 2: Extracting parts from publication.html..."
$pub = [System.IO.File]::ReadAllText("$dir\publication.html", [System.Text.Encoding]::UTF8)

# 提取 <head> 部分 (包含 site-beautified.css)
$headEnd = $pub.IndexOf('</head>')
$headPart = $pub.Substring(0, $headEnd + 7)

# 从 head 中去掉内联 style（我们会加自己的）
# 保留结构和 CSS link，然后加上 item_line CSS
$itemLineCss = @"

<style type="text/css">
    .item_line {
        display: flex;
        flex-wrap: wrap;
        font-size: 1.6rem !important;
        margin-bottom: 24px;
    }
    .img_box {
        width: 280px !important;
        margin: 10px auto;
        margin-bottom: 30px !important;
    }
    .img_box>img {
        width: 100% !important;
        height: 100% !important;
    }
    .face_img {
        width: 280px;
    }
    .left_box {
        max-width: 100%;
        overflow-wrap: break-word;
        word-break: break-word;
        flex: 1;
    }
    .pub_publish {
        font-style: italic !important;
    }
    .pub_doi {
        color: #4289ff;
        font-weight: 800;
    }
</style>
"@

# 在 </head> 前插入 item_line CSS
$headWithCss = $headPart -replace '</head>', ($itemLineCss + "`r`n</head>")

# 提取 <header> 部分 (从 <header class="site-header"> 到 </header>)
$headerStart = $pub.IndexOf('<header class="site-header">')
$headerEnd = $pub.IndexOf('</header>', $headerStart)
$headerPart = $pub.Substring($headerStart, $headerEnd + 9 - $headerStart)

# 提取 footer 部分 (从 <footer 到 </body>)
$footerStart = $pub.IndexOf('<footer')
$bodyClose = $pub.IndexOf('</body>')
$footerPart = $pub.Substring($footerStart, $bodyClose + 7 - $footerStart)

# 加上 script
$scripts = '<script type="text/javascript" src="js/site-lightbox.js"></script>' + "`r`n" +
           '<script type="text/javascript" src="js/site-backtop.js"></script>' + "`r`n" +
           '</body></html>'

Write-Host "  head=$($headWithCss.Length) header=$($headerPart.Length) footer=$($footerPart.Length)"

# =========================================
# Step 3: 构建侧边栏 HTML
# =========================================
$sidePanelHtml = @"
<aside class="pub-side-panel">
    <a class="pub-side-back" href="publication.html">← 返回总览</a>
    <span class="pub-side-label">DECADES</span>
    <a class="pub-side-decade" href="publication-2026.html">2026–Now<span class="en">2026至今</span></a>
    <a class="pub-side-decade" href="publication-2021-2025.html">2021–2025<span class="en">西湖时期</span></a>
    <a class="pub-side-decade" href="publication-2016-2020.html">2016–2020<span class="en">NTU时期</span></a>
    <a class="pub-side-decade" href="publication-2011-2015.html">2011–2015<span class="en">早期发展</span></a>
    <a class="pub-side-decade" href="publication-2006-2010.html">2006–2010<span class="en">体系建立</span></a>
    <a class="pub-side-decade" href="publication-2001-2005.html">2001–2005<span class="en">建组初期</span></a>
</aside>
"@

# =========================================
# Step 4: 构建每个 decade 子页
# =========================================
$excel = [System.IO.File]::ReadAllText("$dir\_excel.json", [System.Text.Encoding]::UTF8) | ConvertFrom-Json

$decades = @(
    @{ File="publication-2001-2005.html"; Title="2001–2005"; Subtitle="GROUP ORIGINS · 建组初期"; Decade="2001-2005"; Highlight="2001-2005" },
    @{ File="publication-2006-2010.html"; Title="2006–2010"; Subtitle="LAB FOUNDATIONS · 纳米合成体系建立"; Decade="2006-2010"; Highlight="2006-2010" },
    @{ File="publication-2011-2015.html"; Title="2011–2015"; Subtitle="EARLY GROWTH · 早期发展"; Decade="2011-2015"; Highlight="2011-2015" },
    @{ File="publication-2016-2020.html"; Title="2016–2020"; Subtitle="RAPID EXPANSION · 快速发展"; Decade="2016-2020"; Highlight="2016-2020" },
    @{ File="publication-2021-2025.html"; Title="2021–2025"; Subtitle="MATURITY · 稳定发展"; Decade="2021-2025"; Highlight="2021-2025" },
    @{ File="publication-2026.html"; Title="2026–Now"; Subtitle="FRONTIER PUSH · 前沿探索"; Decade="2026-now"; Highlight="2026-now" }
)

# 侧边栏 active 映射
$sideLinkMap = @{
    "2001-2005" = "publication-2001-2005.html"
    "2006-2010" = "publication-2006-2010.html"
    "2011-2015" = "publication-2011-2015.html"
    "2016-2020" = "publication-2016-2020.html"
    "2021-2025" = "publication-2021-2025.html"
    "2026-now"  = "publication-2026.html"
}

foreach ($d in $decades) {
    Write-Host ""
    Write-Host "Building $($d.File)..."
    
    # 收集文章
    $artBlocks = New-Object System.Collections.ArrayList
    
    if ($d.Decade -eq "2026-now") {
        # ICML 214 先
        if ($ghArticles.ContainsKey(210)) {
            $icml = $ghArticles[210] -replace '<span>210\.\s*</span>', '<span>214. </span>'
            [void]$artBlocks.Add($icml)
        }
        # GitHub 只有 1-210，所以 2026 的文章是 ICML(210→214) + 210-205 (跳过 ICML 已用的 210)
        foreach ($n in @(209,208,207,206,205)) {
            if ($ghArticles.ContainsKey($n)) { [void]$artBlocks.Add($ghArticles[$n]) }
        }
    } else {
        $nums = $excel | Where-Object { $_.Decade -eq $d.Decade } | ForEach-Object { $_.Num } | Sort-Object -Descending
        foreach ($n in $nums) {
            if ($ghArticles.ContainsKey($n)) { [void]$artBlocks.Add($ghArticles[$n]) }
            else { Write-Host "  WARNING: GitHub missing #$n" }
        }
    }
    
    # 高亮当前 decade 的侧边栏链接
    $sidePanel = $sidePanelHtml -replace 'href="publication-' + ($sideLinkMap[$d.Decade] -replace 'publication-',''), ('href="publication-' + ($sideLinkMap[$d.Decade] -replace 'publication-','') + '" class="pub-side-decade active"')
    
    # 构建 publication-region
    $h1Html = '<h1 class="publication-region-title">' + $d.Title + '<br><span style="font-size:16px;font-weight:500;color:var(--muted);letter-spacing:2px;">' + $d.Subtitle + '</span></h1>'
    
    # 组合 publication-region 内部
    $regionInner = $h1Html + "`r`n" +
                   '<div style="margin-top: 30px;">' + "`r`n" +
                   ($artBlocks -join "`r`n") + "`r`n" +
                   '</div>' + "`r`n" +
                   '</div>'  # 关闭 publication-region
    
    # 完整 body 内容
    $bodyContent = $headerPart + "`r`n" +
                   $sidePanel + "`r`n" +
                   '<div class="publication-region">' + "`r`n" +
                   $regionInner + "`r`n" +
                   $footerPart + "`r`n" +
                   $scripts
    
    # 完整 HTML
    $fullPage = $headWithCss + "`r`n<body class=`"pub-has-sidepanel`">`r`n" + $bodyContent + "`r`n"
    
    [System.IO.File]::WriteAllText("$dir\$($d.File)", $fullPage, $utf8NoBom)
    
    # 验证
    $open = ([regex]::Matches($fullPage, '<div[\s>]')).Count
    $close = ([regex]::Matches($fullPage, '</div>')).Count
    $fi = $fullPage.IndexOf('<footer')
    $bc = $fullPage.IndexOf('</body>')
    $nums_found = [regex]::Matches($fullPage, '<span[^>]*>(\d+)\.\s*</span>') | ForEach-Object { [int]$_.Groups[1].Value }
    Write-Host "  Articles=$($artBlocks.Count), found=$($nums_found.Count), div_diff=$($open-$close), footer_ok=$($fi -lt $bc)"
}

Write-Host ""
Write-Host "ALL DONE!"
