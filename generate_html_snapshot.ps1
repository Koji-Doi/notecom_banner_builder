param (
    [string]$templateFile,  # HTMLテンプレートファイルのパス
    [string]$tsvFile,       # TSVデータファイルのパス
    [int]$width = 1920,     # 出力画像の幅（デフォルト: 1920）
    [int]$height = 1006,    # 出力画像の高さ（デフォルト: 1006）
    [string]$prefix = ""    # pngファイル名の接頭辞
)

# PowerShellの文字コードをUTF-8に設定
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

# 必要な引数が指定されているかチェック
if (-not $templateFile -or -not $tsvFile) {
    Write-Output "Usage: .\generate_html_snapshot.ps1 -templateFile <HTML file> -tsvFile <TSV file> [-width <width>] [-height <height>]"
    exit 1
}

# 出力ファイル名をTSVファイル名に基づいて決定
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($tsvFile)
$htmlFile = "$baseName.html"
$pngFile = "$prefix$baseName.png"

# HTMLテンプレートファイルをUTF-8で読み込む
if (-Not (Test-Path $templateFile)) {
    Write-Output "Error: Cannot find the template file: $templateFile"
    exit 1
}
$template = Get-Content -Path $templateFile -Raw -Encoding UTF8

# デフォルト値の定義（ここで定義されたプレースホルダーにはデフォルト値が適用される）
$defaultValues = @{
    "title"    = "Untitled"
    "maintext" = ""
    "basecolor"= "green"
}

# TSVファイルをUTF-8で読み込む
if (-Not (Test-Path $tsvFile)) {
    Write-Output "Error: Cannot find the TSV file: $tsvFile"
    exit 1
}

# TSVのデータを辞書形式で保存
$replacements = @{}
$lines = Get-Content -Path $tsvFile -Encoding UTF8
foreach ($line in $lines) {
    $parts = $line -split "`t", 2  # タブ区切りで分割
    if ($parts.Count -eq 2) {
        $key = $parts[0].Trim()
        $value = $parts[1].Trim()
        $replacements[$key] = $value
    }
}

# プレースホルダー ([[key]]) を適切な値に置き換え
$matches = [regex]::Matches($template, "\[\[(.*?)\]\]")  # すべてのプレースホルダーを検索
foreach ($match in $matches) {
    $key = $match.Groups[1].Value
    if ($replacements.ContainsKey($key)) {
        $value = $replacements[$key]  # TSVにある値を使う
    } elseif ($defaultValues.ContainsKey($key)) {
        $value = $defaultValues[$key]  # デフォルト値を使う
    } else {
        $value = ""  # どちらもない場合は空文字
    }
    $template = $template -replace [regex]::Escape("[[$key]]"), $value
}

# 置換後のHTMLファイルをUTF-8 (BOMなし) で保存
$template | Set-Content -Path $htmlFile -Encoding UTF8

Write-Output "Done! HTML file saved: $htmlFile"

# Microsoft Edge のパスを確認
$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-Not (Test-Path $edgePath)) {
    Write-Output "Error: Microsoft Edge is not found: $edgePath"
    exit 1
}

# EdgeのヘッドレスモードでHTMLをPNGに変換
$pngFullPath = [System.IO.Path]::Combine($PWD.Path, $pngFile)

# EdgeのヘッドレスモードでHTMLをPNGに変換
$command = @(
    "--headless=new",
    "--disable-gpu",
    "--disable-software-rasterizer",
    #"--dump-dom",
    "--user-agent=""Mozilla/5.0 (Windows NT 10.0; Win64; x64)""",
    "--hide-scrollbars",
    "--screenshot=$pngFullPath",
    "--window-size=$width,$height",
    "--disable-features=InfiniteSessionRestore",
    "file:///$PWD/$htmlFile"
)

Write-Output "Opening Edge to take a screenshot..."

# Start-Process を使い、Edge を起動
Start-Process -FilePath $edgePath -ArgumentList $command -NoNewWindow -Wait

# スクリーンショットが正しく作成されたか確認
if (-Not (Test-Path $pngFile)) {
    Write-Output "Error: Could not save the screenshot."
    exit 1
}

Write-Output "Done! Screenshot saved: $pngFile"
