# TSVファイルリスト
$tsvFiles = 1..11 | ForEach-Object { "banner$_-g.tsv" }

# 各TSVファイルに対してスクリプトを実行
foreach ($file in $tsvFiles) {
    Write-Host "Processing $file..."
    .\generate_html_snapshot.ps1 -templateFile "template_withbg250309.html" -tsvFile $file
}
