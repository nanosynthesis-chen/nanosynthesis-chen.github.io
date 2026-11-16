$c = [System.IO.File]::ReadAllText('C:\Users\suhuai\Desktop\nanosynthesis-site\_pub_github.html', [System.Text.Encoding]::UTF8)
Write-Host "File length: $($c.Length)"

# 匹配 编号. "题目", 
$pattern = '(\d{1,3})\.\s*"([^"]+)",'
$matches = [regex]::Matches($c, $pattern)
Write-Host "Found $($matches.Count) papers"

$papers = @()
foreach ($m in $matches) {
    $num = [int]$m.Groups[1].Value
    $title = ($m.Groups[2].Value -replace '\s+',' ').Trim()
    $papers += [pscustomobject]@{ Num=$num; Title=$title }
}

# 导出
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText('C:\Users\suhuai\Desktop\nanosynthesis-site\_github_papers.json', ($papers | ConvertTo-Json -Depth 2), $utf8)

Write-Host "Saved. Total=$($papers.Count)"
Write-Host "Range=$($papers[0].Num)-$($papers[-1].Num)"
Write-Host "First 5:"
foreach ($p in ($papers | Select-Object -First 5)) { Write-Host "  #$($p.Num) $($p.Title.Substring(0,[Math]::Min(60,$p.Title.Length)))..." }
Write-Host "Last 5:"
foreach ($p in ($papers | Select-Object -Last 5)) { Write-Host "  #$($p.Num) $($p.Title.Substring(0,[Math]::Min(60,$p.Title.Length)))..." }
