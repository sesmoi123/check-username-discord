@echo off
setlocal EnableExtensions
set "VER=9"
title Checker pseudo Discord - 3L 3C 4L 4C
color 0B

set "THREADS=20"
set "DELAY=60"
set "PROXYMODE=auto"
set "WEBHOOK=https://discord.com/api/webhooks/1545887085351804928/OhHVPWM-XwGM8eWg8mUahPLarLolhkSj_63oNyFr1Q0FDWxROzn5MQG9bDBqsWIIHLee"
set "PS1=%TEMP%\discord_name_checker.ps1"
set "OUTDIR=%TEMP%\discord-name-checker"

:menu
cls
echo.
echo   ============================================================
echo     CHECKER DE PSEUDO DISCORD     (sans token)
echo     start.bat v%VER%
echo   ============================================================
echo.
echo     [1]  3 lettres      (3L)    aaa  ..  zzz
echo     [2]  3 caracteres   (3C)    aaa  ..  999    (lettres + chiffres)
echo     [3]  3L + 3C        (les deux, l'un apres l'autre)
echo.
echo     [4]  4 lettres      (4L)    aaaa ..  zzzz
echo     [5]  4 caracteres   (4C)    aaaa ..  9999   (lettres + chiffres)
echo     [6]  4L + 4C        (les deux, l'un apres l'autre)
echo.
echo     [T]  Threads                : %THREADS%
echo     [D]  Ecart de depart (ms)   : %DELAY%
echo     [P]  Proxies                : %PROXYMODE%
echo     [W]  Webhook                : %WEBHOOK%
echo     [O]  Ouvrir le dossier des resultats
echo     [R]  Repartir de zero (efface la progression)
echo     [Q]  Quitter
echo.
set "c="
set /p "c=   Ton choix : "

if /i "%c%"=="1" (set "LEN=3" & set "SET=L" & goto :run)
if /i "%c%"=="2" (set "LEN=3" & set "SET=C" & goto :run)
if /i "%c%"=="3" (set "LEN=3" & set "SET=B" & goto :run)
if /i "%c%"=="4" (set "LEN=4" & set "SET=L" & goto :run)
if /i "%c%"=="5" (set "LEN=4" & set "SET=C" & goto :run)
if /i "%c%"=="6" (set "LEN=4" & set "SET=B" & goto :run)
if /i "%c%"=="T" goto :threads
if /i "%c%"=="D" goto :delay
if /i "%c%"=="P" goto :proxy
if /i "%c%"=="W" goto :webhook
if /i "%c%"=="O" goto :open
if /i "%c%"=="R" goto :reset
if /i "%c%"=="Q" goto :end
goto :menu

:threads
set "t="
set /p "t=   Nombre de threads (1-64) [%THREADS%] : "
if not "%t%"=="" set "THREADS=%t%"
goto :menu

:delay
set "d="
set /p "d=   Ecart de depart en ms (0 = plein gaz) [%DELAY%] : "
if not "%d%"=="" set "DELAY=%d%"
goto :menu

:proxy
cls
echo.
echo   Mode proxy actuel : %PROXYMODE%
echo.
echo     [0]  Desactive   (connexion directe)
echo     [1]  Auto        (20 sources, validation, rotation, rechargement auto)
echo     [2]  Fichier     (%OUTDIR%\proxies.txt)
echo.
set "p="
set /p "p=   Ton choix : "
if "%p%"=="0" set "PROXYMODE=off"
if "%p%"=="1" set "PROXYMODE=auto"
if "%p%"=="2" set "PROXYMODE=file"
goto :menu

:webhook
set "w="
set /p "w=   URL du webhook (vide = desactive) : "
set "WEBHOOK=%w%"
goto :menu

:open
if not exist "%OUTDIR%" md "%OUTDIR%" >nul 2>&1
start "" "%OUTDIR%"
goto :menu

:reset
if exist "%OUTDIR%" rd /s /q "%OUTDIR%" >nul 2>&1
echo.
echo   Progression effacee.
timeout /t 1 >nul 2>&1
goto :menu

:run
cls
echo.
echo   [ start.bat v%VER% ]
echo.
echo   Preparation du script PowerShell...
echo.

if exist "%PS1%" del /f /q "%PS1%" >nul 2>&1

powershell -NoProfile -ExecutionPolicy Bypass -Command "$f='%~f0'; $l=[IO.File]::ReadAllLines($f); $i=-1; for($k=0;$k -lt $l.Length;$k++){ if($l[$k].Trim() -eq '###PSSTART###'){ $i=$k; break } }; if($i -lt 0){ Write-Host '  EXTRACTION : marqueur introuvable'; exit 1 }; [IO.File]::WriteAllLines('%PS1%', $l[($i+1)..($l.Length-1)]); Write-Host ('  EXTRACTION : OK - lignes ' + ($i+1) + ' a ' + $l.Length)"

if not exist "%PS1%" (
    echo.
    echo   ECHEC : le script PowerShell n'a pas pu etre genere.
    pause
    goto :menu
)

echo.
echo   --- controle du script genere ---
findstr /n "SCRIPT_VERSION" "%PS1%"
echo   --------------------------------
echo.

if /i "%SET%"=="B" (
    call :check %LEN% L
    echo.
    call :check %LEN% C
) else (
    call :check %LEN% %SET%
)

echo.
echo   Termine.
echo   Resultats dans : %OUTDIR%
echo.
pause
goto :menu

:check
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -Length %1 -Charset %2 -Threads %THREADS% -DelayMs %DELAY% -Webhook "%WEBHOOK%" -ProxyMode "%PROXYMODE%"
goto :eof

:end
exit /b

###PSSTART###
param(
    [int]$Length = 3,
    [string]$Charset = 'L',
    [int]$Threads = 20,
    [int]$DelayMs = 60,
    [string]$Webhook = '',
    [string]$ProxyMode = 'auto',
    [string]$Endpoint = 'https://discord.com/api/v9/unique-username/username-attempt-unauthed'
)

$SCRIPT_VERSION = 'v9-proxy-hunter'

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Net.ServicePointManager]::ExpectContinue = $false
[Net.ServicePointManager]::Expect100Continue = $false
[Net.ServicePointManager]::DefaultConnectionLimit = 400

if ($Threads -lt 1) { $Threads = 1 }
if ($DelayMs -lt 0) { $DelayMs = 0 }

$HARD_MS   = 12000
$MAX_PROXY = 200
$MAX_CAND  = 4000
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'

$root = Join-Path $env:TEMP 'discord-name-checker'
[void][IO.Directory]::CreateDirectory($root)

$tag       = "$Length$Charset"
$listFile  = Join-Path $root "liste_$tag.txt"
$okFile    = Join-Path $root "dispo_$tag.txt"
$logFile   = Join-Path $root "verif_$tag.txt"
$proxyFile = Join-Path $root 'proxies.txt'

Write-Host ""
Write-Host "  Script     : $SCRIPT_VERSION"
Write-Host "  PowerShell : $($PSVersionTable.PSVersion)"

# ================== OUTILS ==================
function Test-One {
    param([string]$Url, [string]$Method, [string]$Body, $ProxyObj, [int]$CapMs, [string]$Ua)
    $req = $null
    try {
        $req = [System.Net.HttpWebRequest]::Create($Url)
        $req.Method = $Method
        $req.UserAgent = $Ua
        $req.Accept = 'application/json'
        $req.Timeout = $CapMs
        $req.ReadWriteTimeout = $CapMs
        $req.Proxy = $ProxyObj
        if ($Body) {
            $req.ContentType = 'application/json'
            $b = [Text.Encoding]::UTF8.GetBytes($Body)
            $req.ContentLength = $b.Length
            $st = $req.GetRequestStream(); $st.Write($b, 0, $b.Length); $st.Close()
        }
        $ar = $req.BeginGetResponse($null, $null)
        if (-not $ar.AsyncWaitHandle.WaitOne($CapMs + 500)) { try { $req.Abort() } catch { }; return @{ ok = $false; code = 0; body = ''; err = 'timeout' } }
        $resp = $null
        try { $resp = $req.EndGetResponse($ar) }
        catch [System.Net.WebException] {
            if ($_.Exception.Response) { $resp = $_.Exception.Response } else { return @{ ok = $false; code = 0; body = ''; err = $_.Exception.Message } }
        }
        if (-not $resp) { return @{ ok = $false; code = 0; body = ''; err = 'vide' } }
        $c = [int]$resp.StatusCode
        $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
        $b2 = $sr.ReadToEnd(); $sr.Close(); $resp.Close()
        return @{ ok = $true; code = $c; body = $b2; err = '' }
    } catch {
        return @{ ok = $false; code = 0; body = ''; err = $_.Exception.Message }
    } finally {
        if ($req) { try { $req.Abort() } catch { } }
    }
}

$SOURCES = @(
    'https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/http.txt',
    'https://raw.githubusercontent.com/monosans/proxy-list/main/proxies/http.txt',
    'https://raw.githubusercontent.com/clarketm/proxy-list/master/proxy-list-raw.txt',
    'https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/http.txt',
    'https://raw.githubusercontent.com/mmpx12/proxy-list/master/http.txt',
    'https://raw.githubusercontent.com/roosterkid/openproxylist/main/HTTPS_RAW.txt',
    'https://raw.githubusercontent.com/ALIILAPRO/Proxy/main/http.txt',
    'https://raw.githubusercontent.com/prxchk/proxy-list/main/http.txt',
    'https://raw.githubusercontent.com/zloi-user/hideip.me/main/http.txt',
    'https://raw.githubusercontent.com/elliottophellia/proxy-list/main/http.txt',
    'https://raw.githubusercontent.com/vakhov/fresh-proxy-list/master/http.txt',
    'https://raw.githubusercontent.com/Anonym0usWork1221/Free-Proxies/main/proxy_files/http_proxies.txt',
    'https://raw.githubusercontent.com/mertguvencli/http-proxy-list/main/proxy-list/data.txt',
    'https://raw.githubusercontent.com/sunny9577/proxy-scraper/master/proxies.txt',
    'https://raw.githubusercontent.com/andydunstall/proxy-list/master/http.txt',
    'https://api.proxyscrape.com/v2/?request=displayproxies&protocol=http&timeout=10000&country=all&ssl=yes&anonymity=all',
    'https://www.proxy-list.download/api/v1/get?type=http',
    'https://www.proxy-list.download/api/v1/get?type=https',
    'https://proxyspace.pro/http.txt',
    'https://spys.me/proxy.txt'
)

function Get-ProxyList {
    $set = New-Object 'System.Collections.Generic.HashSet[string]'
    $q = New-Object 'System.Collections.Concurrent.ConcurrentQueue[string]'
    foreach ($s in $SOURCES) { $q.Enqueue($s) }

    $n = [math]::Min(20, $SOURCES.Count)
    $pool = [runspacefactory]::CreateRunspacePool(1, $n)
    $pool.Open()
    $sbp = {
        param($q, $out, $ua)
        $item = ''
        while ($q.TryDequeue([ref]$item)) {
            try {
                $wc = New-Object System.Net.WebClient
                $wc.Proxy = $null
                $wc.Headers.Add('User-Agent', $ua)
                $wc.Headers.Add('Accept', '*/*')
                $txt = $wc.DownloadString($item)
                $wc.Dispose()
                $out.Enqueue($txt)
            } catch { }
        }
    }
    $outQ = New-Object 'System.Collections.Concurrent.ConcurrentQueue[string]'
    $hs = @()
    for ($i = 0; $i -lt $n; $i++) {
        $ps = [powershell]::Create(); $ps.RunspacePool = $pool
        [void]$ps.AddScript($sbp).AddArgument($q).AddArgument($outQ).AddArgument($UA)
        $hs += [pscustomobject]@{ PS = $ps; H = $ps.BeginInvoke() }
    }
    foreach ($h in $hs) { try { [void]$h.PS.EndInvoke($h.H) } catch { }; try { $h.PS.Dispose() } catch { } }
    try { $pool.Close() } catch { }; try { $pool.Dispose() } catch { }

    $blob = ''
    $t = ''
    while ($outQ.TryDequeue([ref]$t)) { $blob += $t + "`n" }

    foreach ($m in [regex]::Matches($blob, '\b(?:\d{1,3}\.){3}\d{1,3}:\d{2,5}\b')) {
        [void]$set.Add($m.Value)
    }
    return @($set)
}

function Test-ProxyList {
    param($list, [int]$CapMs)
    $ok = New-Object 'System.Collections.Concurrent.ConcurrentQueue[string]'
    $q  = New-Object 'System.Collections.Concurrent.ConcurrentQueue[string]'
    foreach ($p in $list) { $q.Enqueue($p) }
    $n = [math]::Min(150, $list.Count)
    if ($n -lt 1) { return @() }

    $pool = [runspacefactory]::CreateRunspacePool(1, $n)
    $pool.Open()
    $sbp = {
        param($q, $ok, $cap, $ua)
        $item = ''
        while ($q.TryDequeue([ref]$item)) {
            $px = New-Object System.Net.WebProxy -ArgumentList @(('http://' + $item), $true)
            try {
                $req = [System.Net.HttpWebRequest]::Create('https://discord.com/api/v9/gateway')
                $req.Method = 'GET'
                $req.UserAgent = $ua
                $req.Accept = 'application/json'
                $req.Timeout = $cap
                $req.ReadWriteTimeout = $cap
                $req.Proxy = $px
                $ar = $req.BeginGetResponse($null, $null)
                if (-not $ar.AsyncWaitHandle.WaitOne($cap + 500)) { try { $req.Abort() } catch { }; continue }
                $r = $req.EndGetResponse($ar)
                $c = [int]$r.StatusCode
                $r.Close()
                if ($c -eq 200) { $ok.Enqueue($item) }
            } catch { }
        }
    }
    $hs = @()
    for ($i = 0; $i -lt $n; $i++) {
        $ps = [powershell]::Create(); $ps.RunspacePool = $pool
        [void]$ps.AddScript($sbp).AddArgument($q).AddArgument($ok).AddArgument($CapMs).AddArgument($UA)
        $hs += [pscustomobject]@{ PS = $ps; H = $ps.BeginInvoke() }
    }
    $pending = $hs
    return @{ ok = $ok; q = $q; hs = $hs; pool = $pool }
}

# ================== RECOLTE DES PROXIES ==================
$proxies = @()

if ($ProxyMode -eq 'auto') {
    Write-Host ""
    Write-Host "  Recherche de proxies sur $($SOURCES.Count) sources..."
    $cand = Get-ProxyList
    Write-Host "  Candidats uniques : $($cand.Count)"

    if ($cand.Count -gt $MAX_CAND) {
        $cand = $cand | Select-Object -First $MAX_CAND
        Write-Host "  Limite a $MAX_CAND pour la validation"
    }

    if ($cand.Count -gt 0) {
        Write-Host "  Validation (test HTTPS vers Discord sur chaque proxy)..."
        $job = Test-ProxyList -list $cand -CapMs 6000
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $last = 0
        while ($true) {
            $done = $cand.Count - $job.q.Count
            if (($sw.Elapsed.TotalSeconds - $last) -ge 2) {
                $last = [int]$sw.Elapsed.TotalSeconds
                Write-Host -NoNewline ("`r    testes: $done / $($cand.Count)   vivants: $($job.ok.Count)      ")
            }
            $busy = $false
            foreach ($h in $job.hs) { if (-not $h.H.IsCompleted) { $busy = $true; break } }
            if (-not $busy) { break }
            Start-Sleep -Milliseconds 300
        }
        foreach ($h in $job.hs) { try { [void]$h.PS.EndInvoke($h.H) } catch { }; try { $h.PS.Dispose() } catch { } }
        try { $job.pool.Close() } catch { }; try { $job.pool.Dispose() } catch { }

        $t = ''
        while ($job.ok.TryDequeue([ref]$t)) { $proxies += $t }
        Write-Host ""
    }
    Write-Host "  Proxies operationnels : $($proxies.Count)"
    if ($proxies.Count -gt $MAX_PROXY) {
        $proxies = $proxies | Select-Object -First $MAX_PROXY
        Write-Host "  Garde les $MAX_PROXY premiers"
    }
}
elseif ($ProxyMode -eq 'file') {
    if (Test-Path $proxyFile) {
        $proxies = @(Get-Content $proxyFile | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\S+:\d+$' })
        Write-Host "  Proxies lus depuis le fichier : $($proxies.Count)"
    } else {
        Write-Host "  Fichier absent : $proxyFile"
    }
}

# ================== TEST DIRECT ==================
Write-Host "  Test direct vers Discord..."
$direct = Test-One -Url $Endpoint -Method 'POST' -Body '{"username":"zzzqzzzq"}' -ProxyObj $null -CapMs 8000 -Ua $UA
if ($direct.ok) { Write-Host "  Direct : OK (HTTP $($direct.code))" } else { Write-Host "  Direct : KO -> $($direct.err)" }

if ($proxies.Count -gt 0) { Write-Host "  Mode   : rotation sur $($proxies.Count) proxies" }
elseif ($direct.ok)       { Write-Host "  Mode   : direct (aucun proxy trouve)" }
else                      { Write-Host "  Mode   : direct, on continue quand meme" }

# ================== LISTE ==================
if ($Charset -eq 'L') { $alpha = [char[]]'abcdefghijklmnopqrstuvwxyz' }
else                  { $alpha = [char[]]'abcdefghijklmnopqrstuvwxyz0123456789' }

if (Test-Path $listFile) {
    $all = [IO.File]::ReadAllLines($listFile)
} else {
    Write-Host "  Generation de la liste $tag ..."
    $cur = New-Object 'System.Collections.Generic.List[string]'
    $cur.Add('')
    for ($k = 0; $k -lt $Length; $k++) {
        $next = New-Object 'System.Collections.Generic.List[string]' ($cur.Count * $alpha.Count)
        foreach ($p in $cur) { foreach ($a in $alpha) { $next.Add($p + $a) } }
        $cur = $next
    }
    [IO.File]::WriteAllLines($listFile, $cur)
    $all = $cur.ToArray()
}

$checked = New-Object 'System.Collections.Generic.HashSet[string]'
if (Test-Path $logFile) {
    foreach ($line in [IO.File]::ReadLines($logFile)) {
        $p = $line.IndexOf([char]9)
        if ($p -gt 0) {
            $st = $line.Substring($p + 1)
            if ($st -ne 'err' -and $st -ne 'timeout') { [void]$checked.Add($line.Substring(0, $p)) }
        }
    }
}

$queue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[string]'
$todo = 0
foreach ($n in $all) { if (-not $checked.Contains($n)) { $queue.Enqueue($n); $todo++ } }

Write-Host ""
Write-Host "  Cible      : $tag   ($($all.Length) pseudos au total)"
Write-Host "  A verifier : $todo"
if ($todo -eq 0) { Write-Host "  Tout est deja verifie."; return }
Write-Host "  Fichier    : $okFile"
Write-Host "  Reglage    : ecart $DelayMs ms / $Threads threads"
if ($Webhook) { Write-Host "  Webhook    : actif" } else { Write-Host "  Webhook    : desactive" }
Write-Host ""

# ================== ETAT PARTAGE ==================
$sync = @{
    lock      = (New-Object System.Object)
    next      = [DateTime]::UtcNow
    gap       = $DelayMs
    gapMin    = 15
    clean     = 0
    lastAdapt = [DateTime]::UtcNow
    c429      = 0
    cKO       = 0
    inflight  = 0
    lastResp  = [DateTime]::UtcNow
    pIdx      = 0
    proxies   = $proxies
    pCool     = [System.Collections.Concurrent.ConcurrentDictionary[string,System.DateTime]]::new()
    pErr      = [System.Collections.Concurrent.ConcurrentDictionary[string,int]]::new()
    stop      = $false
}

# ================== WEBHOOK ==================
function Send-Embed {
    param([string]$Title, [string]$Desc, [int]$Color)
    if (-not $Webhook) { return }
    $payload = @{
        content = "**$Title**"
        embeds  = @(@{
            title = $Title; description = $Desc; color = $Color
            timestamp = (Get-Date).ToUniversalTime().ToString('o')
            footer = @{ text = "Discord Name Checker" }
        })
    } | ConvertTo-Json -Depth 6 -Compress

    for ($t = 0; $t -lt 4; $t++) {
        $r = Test-One -Url $Webhook -Method 'POST' -Body $payload -ProxyObj $null -CapMs 10000 -Ua 'DiscordNameChecker'
        if ($r.ok -and $r.code -ne 429) { break }
        if ($r.code -eq 429) {
            $ms = 2000
            if ($r.body -match '"retry_after"\s*:\s*([0-9.]+)') { $ms = [int]([double]$matches[1] * 1000) + 300 }
            Start-Sleep -Milliseconds $ms
        } else { Start-Sleep -Milliseconds 600 }
    }
}

$results = New-Object 'System.Collections.Concurrent.ConcurrentQueue[string]'
$hits    = New-Object 'System.Collections.Concurrent.ConcurrentQueue[string]'
$pending = New-Object 'System.Collections.Concurrent.ConcurrentQueue[string]'

$whPS = $null; $whRS = $null; $whHandle = $null

$whSb = {
    param($hits, $webhook, $sync)
    $next = [DateTime]::UtcNow
    $item = ''
    while ($true) {
        if ($hits.TryDequeue([ref]$item)) {
            $gap = ($next - [DateTime]::UtcNow).TotalMilliseconds
            if ($gap -gt 0) { Start-Sleep -Milliseconds ([int]$gap) }

            $payload = @{
                content = "**$item** disponible"
                embeds  = @(@{
                    title = $item; description = "Pseudo disponible : **$item**"; color = 5763719
                    timestamp = (Get-Date).ToUniversalTime().ToString('o')
                    footer = @{ text = "Discord Name Checker" }
                })
            } | ConvertTo-Json -Depth 6 -Compress

            for ($t = 0; $t -lt 5; $t++) {
                try {
                    $bytes = [Text.Encoding]::UTF8.GetBytes($payload)
                    $req = [System.Net.HttpWebRequest]::Create($webhook)
                    $req.Method = 'POST'
                    $req.ContentType = 'application/json'
                    $req.UserAgent = 'DiscordNameChecker'
                    $req.Timeout = 10000
                    $req.ReadWriteTimeout = 10000
                    $req.Proxy = $null
                    $req.ContentLength = $bytes.Length
                    $st = $req.GetRequestStream(); $st.Write($bytes, 0, $bytes.Length); $st.Close()
                    $ar = $req.BeginGetResponse($null, $null)
                    if (-not $ar.AsyncWaitHandle.WaitOne(10500)) { try { $req.Abort() } catch { }; continue }
                    $resp = $req.EndGetResponse($ar)
                    $code = [int]$resp.StatusCode
                    $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
                    $body = $sr.ReadToEnd(); $sr.Close(); $resp.Close()
                    if ($code -eq 429) {
                        $ms = 2000
                        if ($body -match '"retry_after"\s*:\s*([0-9.]+)') { $ms = [int]([double]$matches[1] * 1000) + 300 }
                        Start-Sleep -Milliseconds $ms
                        continue
                    }
                    break
                } catch { Start-Sleep -Milliseconds 600 }
            }
            $next = [DateTime]::UtcNow.AddMilliseconds(1400)
        } elseif ([bool]$sync['stop']) { break }
        else { Start-Sleep -Milliseconds 120 }
    }
}

if ($Webhook) { Send-Embed -Title "Demarrage" -Desc "Verification des pseudos **$tag** en cours..." -Color 3447003 }

if ($Webhook) {
    $whRS = [runspacefactory]::CreateRunspace(); $whRS.Open()
    $whPS = [powershell]::Create(); $whPS.Runspace = $whRS
    [void]$whPS.AddScript($whSb).AddArgument($hits).AddArgument($Webhook).AddArgument($sync)
    $whHandle = $whPS.BeginInvoke()
}

# ================== RECRUTEUR DE PROXIES ==================
$mgrPS = $null; $mgrRS = $null; $mgrHandle = $null

if ($ProxyMode -eq 'auto') {
    $getFn  = (Get-Command Get-ProxyList).ScriptBlock
    $testFn = (Get-Command Test-ProxyList).ScriptBlock

    $mgrSb = {
        param($sync, $getFn, $testFn, $maxProxy, $maxCand, $ua)
        while (-not [bool]$sync['stop']) {
            Start-Sleep -Seconds 60
            if ([bool]$sync['stop']) { break }

            $pl = $sync['proxies']
            $now = [DateTime]::UtcNow
            $alive = 0
            foreach ($p in $pl) {
                $t = [DateTime]::MinValue
                if (-not $sync['pCool'].TryGetValue($p, [ref]$t)) { $alive++ }
                elseif ($t -le $now) { $alive++ }
            }

            $seuil = [math]::Max(8, [int]($pl.Count * 0.4))
            if ($alive -lt $seuil) {
                try {
                    $cand = & $getFn
                    if ($cand.Count -gt $maxCand) { $cand = $cand | Select-Object -First $maxCand }
                    if ($cand.Count -gt 0) {
                        $job = & $testFn $cand 6000
                        while ($true) {
                            $busy = $false
                            foreach ($h in $job.hs) { if (-not $h.H.IsCompleted) { $busy = $true; break } }
                            if (-not $busy) { break }
                            Start-Sleep -Milliseconds 300
                        }
                        foreach ($h in $job.hs) { try { [void]$h.PS.EndInvoke($h.H) } catch { }; try { $h.PS.Dispose() } catch { } }
                        try { $job.pool.Close() } catch { }; try { $job.pool.Dispose() } catch { }

                        $fresh = @()
                        $t = ''
                        while ($job.ok.TryDequeue([ref]$t)) { $fresh += $t }
                        if ($fresh.Count -gt 0) {
                            $merged = @($pl + $fresh | Select-Object -Unique)
                            if ($merged.Count -gt $maxProxy) { $merged = $merged | Select-Object -First $maxProxy }
                            $sync['proxies'] = $merged
                        }
                    }
                } catch { }
            }
        }
    }

    $mgrRS = [runspacefactory]::CreateRunspace(); $mgrRS.Open()
    $mgrPS = [powershell]::Create(); $mgrPS.Runspace = $mgrRS
    [void]$mgrPS.AddScript($mgrSb).AddArgument($sync).AddArgument($getFn).AddArgument($testFn).AddArgument($MAX_PROXY).AddArgument($MAX_CAND).AddArgument($UA)
    $mgrHandle = $mgrPS.BeginInvoke()
}

# ================== WORKER ==================
$sb = {
    param($queue, $results, $hits, $done, $endpoint, $delay, $sync, $ua, $hardms, $idx)
    $lockObj = $sync['lock']
    $item    = ''
    try {
        while ($queue.TryDequeue([ref]$item)) {

            $wait = 0
            [System.Threading.Monitor]::Enter($lockObj)
            try {
                $now = [DateTime]::UtcNow
                $nxt = [DateTime]$sync['next']
                if ($nxt -gt $now) { $wait = [int](($nxt - $now).TotalMilliseconds) }
                $sync['next'] = $now.AddMilliseconds($wait + [int]$sync['gap'])
            } finally { [System.Threading.Monitor]::Exit($lockObj) }
            if ($wait -gt 0) { Start-Sleep -Milliseconds $wait }

            $pl = $sync['proxies']
            $pc = $pl.Count
            $px = $null
            $pxStr = ''
            if ($pc -gt 0) {
                $tries = [math]::Min($pc, 30)
                for ($a = 0; $a -lt $tries; $a++) {
                    $ix = 0
                    [System.Threading.Monitor]::Enter($lockObj)
                    try { $ix = ([int]$sync['pIdx'] + 1) % $pc; $sync['pIdx'] = $ix } finally { [System.Threading.Monitor]::Exit($lockObj) }
                    $cand = $pl[$ix]
                    $tt = [DateTime]::MinValue
                    if ($sync['pCool'].TryGetValue($cand, [ref]$tt)) {
                        if ($tt -gt [DateTime]::UtcNow) { continue }
                    }
                    $pxStr = $cand
                    break
                }
                if (-not $pxStr) { $pxStr = $pl[[int]$sync['pIdx'] % $pc] }
                $px = New-Object System.Net.WebProxy -ArgumentList @(('http://' + $pxStr), $true)
            }

            $name   = $item
            $status = 'err'

            for ($t = 0; $t -lt 3; $t++) {
                $req = $null
                try {
                    $bytes = [Text.Encoding]::UTF8.GetBytes('{"username":"' + $name + '"}')

                    $req = [System.Net.HttpWebRequest]::Create($endpoint)
                    $req.Method = 'POST'
                    $req.ContentType = 'application/json'
                    $req.UserAgent = $ua
                    $req.Accept = 'application/json'
                    $req.Referer = 'https://discord.com/register'
                    try { $req.Headers.Add('Origin', 'https://discord.com') } catch { }
                    $req.Timeout = $hardms
                    $req.ReadWriteTimeout = $hardms
                    $req.KeepAlive = $true
                    $req.Proxy = $px
                    $req.ContentLength = $bytes.Length

                    $sync['inflight'] = [int]$sync['inflight'] + 1

                    $st = $req.GetRequestStream()
                    $st.Write($bytes, 0, $bytes.Length)
                    $st.Close()

                    $ar = $req.BeginGetResponse($null, $null)
                    if (-not $ar.AsyncWaitHandle.WaitOne($hardms + 500)) {
                        try { $req.Abort() } catch { }
                        $sync['inflight'] = [int]$sync['inflight'] - 1
                        $sync['lastResp'] = [DateTime]::UtcNow
                        $sync['cKO'] = [int]$sync['cKO'] + 1
                        if ($pxStr) {
                            $e = 0
                            [void]$sync['pErr'].TryGetValue($pxStr, [ref]$e)
                            $sync['pErr'][$pxStr] = $e + 1
                            if ($e + 1 -ge 3) { $sync['pCool'][$pxStr] = [DateTime]::UtcNow.AddSeconds(60) }
                        }
                        $status = 'timeout'
                        break
                    }

                    $resp = $null
                    try { $resp = $req.EndGetResponse($ar) }
                    catch [System.Net.WebException] {
                        if ($_.Exception.Response) { $resp = $_.Exception.Response } else { throw }
                    }

                    $code = 0; $txt = ''
                    if ($resp) {
                        $code = [int]$resp.StatusCode
                        $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
                        $txt = $sr.ReadToEnd(); $sr.Close(); $resp.Close()
                    }

                    $sync['inflight'] = [int]$sync['inflight'] - 1
                    $sync['lastResp'] = [DateTime]::UtcNow
                    if ($pxStr) { $sync['pErr'][$pxStr] = 0 }

                    if ($txt -match '"taken"\s*:\s*true')  { $status = 'pris';  break }
                    if ($txt -match '"taken"\s*:\s*false') { $status = 'dispo'; break }

                    if ($code -eq 429) {
                        $ms = 1200
                        if ($txt -match '"retry_after"\s*:\s*([0-9.]+)') { $ms = [int]([double]$matches[1] * 1000) + 200 }

                        [System.Threading.Monitor]::Enter($lockObj)
                        try {
                            if ($pxStr) { $sync['pCool'][$pxStr] = [DateTime]::UtcNow.AddMilliseconds([math]::Max($ms, 800)) }
                            $n2 = [DateTime]::UtcNow
                            if (($n2 - [DateTime]$sync['lastAdapt']).TotalSeconds -gt 1.0) {
                                $g = [int]$sync['gap']
                                if ($g -lt 30) { $g = 30 }
                                $sync['gap'] = [int][math]::Min(1500, [int]($g * 1.6))
                                $sync['lastAdapt'] = $n2
                                $sync['clean'] = 0
                            }
                            $sync['c429'] = [int]$sync['c429'] + 1
                        } finally { [System.Threading.Monitor]::Exit($lockObj) }

                        Start-Sleep -Milliseconds ([math]::Min(2000, $ms))
                        continue
                    }

                    if ($code -eq 200) { $status = 'dispo'; break }
                    $status = "http$code"
                    break
                } catch {
                    try { if ($req) { $req.Abort() } catch { } } catch { }
                    try { $sync['inflight'] = [int]$sync['inflight'] - 1 } catch { }
                    if ([int]$sync['inflight'] -lt 0) { $sync['inflight'] = 0 }
                    $sync['lastResp'] = [DateTime]::UtcNow
                    if ($pxStr) {
                        $e = 0
                        [void]$sync['pErr'].TryGetValue($pxStr, [ref]$e)
                        $sync['pErr'][$pxStr] = $e + 1
                        if ($e + 1 -ge 3) { $sync['pCool'][$pxStr] = [DateTime]::UtcNow.AddSeconds(60) }
                    }
                    Start-Sleep -Milliseconds 200
                }
            }

            $c = [int]$sync['clean'] + 1
            if ($c -ge 400) {
                $c = 0
                $g = [int]$sync['gap']
                if ($g -gt [int]$sync['gapMin']) { $sync['gap'] = [int][math]::Max([int]$sync['gapMin'], [int]($g * 0.88)) }
            }
            $sync['clean'] = $c

            if ($status -eq 'dispo') { $hits.Enqueue($name) }
            $results.Enqueue($name + [char]9 + $status)
        }
    } catch {
        $results.Enqueue("ERREUR_WORKER$idx" + [char]9 + "err")
    } finally {
        $done.Enqueue($idx)
    }
}

# ================== PASSES ==================
$processed = 0
$found     = 0
$okW  = New-Object System.IO.StreamWriter($okFile, $true)
$logW = New-Object System.IO.StreamWriter($logFile, $true)
$titreBase = "Checker Discord $tag"

try {
    for ($pass = 1; $pass -le 2; $pass++) {

        if ($pass -eq 2) {
            if ($pending.Count -eq 0) { break }
            $tmp = ''
            while ($pending.TryDequeue([ref]$tmp)) { $queue.Enqueue($tmp) }
            Write-Host ""
            Write-Host "  --- Passe de rattrapage : $($queue.Count) pseudos en erreur ---"
            Write-Host ""
        }

        $passTotal = $queue.Count
        if ($passTotal -eq 0) { continue }

        $sync['next']     = [DateTime]::UtcNow
        $sync['lastResp'] = [DateTime]::UtcNow

        $done = New-Object 'System.Collections.Concurrent.ConcurrentQueue[int]'
        $pool = [runspacefactory]::CreateRunspacePool(1, $Threads)
        $pool.Open()

        $handles = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt $Threads; $i++) {
            $ps = [powershell]::Create()
            $ps.RunspacePool = $pool
            [void]$ps.AddScript($sb).AddArgument($queue).AddArgument($results).AddArgument($hits).AddArgument($done).AddArgument($Endpoint).AddArgument($DelayMs).AddArgument($sync).AddArgument($UA).AddArgument($HARD_MS).AddArgument($i)
            try { [void]$handles.Add([pscustomobject]@{ PS = $ps; H = $ps.BeginInvoke() }) }
            catch { $done.Enqueue($i) }
        }

        $passDone = 0
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $line = ''
        $idle = 0
        $lastDraw = [DateTime]::MinValue
        $lastTitle = [DateTime]::MinValue

        try {
            while ($done.Count -lt $Threads) {

                $n = 0
                while ($n -lt 6000 -and $results.TryDequeue([ref]$line)) {
                    $p = $line.IndexOf([char]9)
                    $logW.WriteLine($line)
                    if ($p -gt 0) {
                        $st = $line.Substring($p + 1)
                        if ($st -eq 'dispo') { $okW.WriteLine($line.Substring(0, $p)); $found++ }
                        elseif ($st -eq 'err' -or $st -eq 'timeout') { $pending.Enqueue($line.Substring(0, $p)) }
                    }
                    $processed++; $passDone++; $n++
                }
                if ($n -gt 0) { $logW.Flush(); $okW.Flush() }

                if ($queue.Count -eq 0 -and $results.Count -eq 0 -and [int]$sync['inflight'] -eq 0) { $idle++ } else { $idle = 0 }
                if ($idle -gt 250) { break }

                $spd = $passDone / [math]::Max($sw.Elapsed.TotalSeconds, 0.001)
                $pct = [math]::Round($passDone * 100 / $passTotal, 2)
                if ($spd -gt 0) { $eta = [TimeSpan]::FromSeconds(($passTotal - $passDone) / $spd).ToString('hh\:mm\:ss') } else { $eta = '--:--:--' }
                $age = [int]([DateTime]::UtcNow - [DateTime]$sync['lastResp']).TotalSeconds

                $plNow = $sync['proxies']
                $alive = 0
                $nowT = [DateTime]::UtcNow
                foreach ($p in $plNow) {
                    $tt = [DateTime]::MinValue
                    if (-not $sync['pCool'].TryGetValue($p, [ref]$tt)) { $alive++ } elseif ($tt -le $nowT) { $alive++ }
                }

                $txt = "  P$pass $passDone/$passTotal ($pct%)  dispo:$found  cours:$($sync['inflight'])  rep:${age}s  429:$($sync['c429'])  KO:$($sync['cKO'])  $([math]::Round($spd,1))/s  ecart:$($sync['gap'])ms  prx:$alive/$($plNow.Count)  ETA $eta"

                if (($nowT - $lastTitle).TotalMilliseconds -ge 400) {
                    $lastTitle = $nowT
                    try { [Console]::Title = "$titreBase | P$pass $pct% | $found dispo | $([math]::Round($spd,1))/s | prx $alive" } catch { }
                }
                if (($nowT - $lastDraw).TotalMilliseconds -ge 1000) {
                    $lastDraw = $nowT
                    Write-Host -NoNewline ("`r" + $txt + "          ")
                }

                Start-Sleep -Milliseconds 120
            }

            while ($results.TryDequeue([ref]$line)) {
                $p = $line.IndexOf([char]9)
                $logW.WriteLine($line)
                if ($p -gt 0) {
                    $st = $line.Substring($p + 1)
                    if ($st -eq 'dispo') { $okW.WriteLine($line.Substring(0, $p)); $found++ }
                    elseif ($st -eq 'err' -or $st -eq 'timeout') { $pending.Enqueue($line.Substring(0, $p)) }
                }
                $processed++; $passDone++
            }
        } finally {
            $logW.Flush(); $okW.Flush()
            foreach ($h in $handles) { try { [void]$h.PS.EndInvoke($h.H) } catch { }; try { $h.PS.Dispose() } catch { } }
            try { $pool.Close() } catch { }
            try { $pool.Dispose() } catch { }
        }
    }
} finally {
    $logW.Flush(); $logW.Close(); $okW.Flush(); $okW.Close()

    $sync['stop'] = $true
    if ($whPS)  { try { [void]$whPS.EndInvoke($whHandle) } catch { }; try { $whPS.Dispose() } catch { } }
    if ($whRS)  { try { $whRS.Close() } catch { }; try { $whRS.Dispose() } catch { } }
    if ($mgrPS) { try { [void]$mgrPS.EndInvoke($mgrHandle) } catch { }; try { $mgrPS.Dispose() } catch { } }
    if ($mgrRS) { try { $mgrRS.Close() } catch { }; try { $mgrRS.Dispose() } catch { } }
}

if ($sync['proxies'].Count -gt 0) { try { [IO.File]::WriteAllLines($proxyFile, $sync['proxies']) } catch { } }

Write-Host ""
Write-Host ""
Write-Host "  Termine : $processed verifies, $found disponibles."
Write-Host "  Disponibles : $okFile"
Write-Host "  Journal     : $logFile"
try { [Console]::Title = "$titreBase | termine" } catch { }

if ($Webhook) { Send-Embed -Title "Termine" -Desc "**$tag** : $processed pseudos verifies, **$found** disponibles." -Color 10181046 }
