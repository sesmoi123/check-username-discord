@echo off
setlocal EnableExtensions
title Checker pseudo Discord - 3L 3C 4L 4C
color 0B

set "THREADS=4"
set "DELAY=2000"
set "WEBHOOK=https://discord.com/api/webhooks/1545887085351804928/OhHVPWM-XwGM8eWg8mUahPLarLolhkSj_63oNyFr1Q0FDWxROzn5MQG9bDBqsWIIHLee"
set "PS1=%TEMP%\discord_name_checker.ps1"
set "OUTDIR=%TEMP%\discord-name-checker"

:menu
cls
echo.
echo   ============================================================
echo     CHECKER DE PSEUDO DISCORD     (sans token, sans proxy)
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
echo     [T]  Threads            : %THREADS%
echo     [D]  Delai entre checks : %DELAY% ms
echo     [W]  Webhook            : %WEBHOOK%
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
if /i "%c%"=="W" goto :webhook
if /i "%c%"=="O" goto :open
if /i "%c%"=="R" goto :reset
if /i "%c%"=="Q" goto :end
goto :menu

:threads
set "t="
set /p "t=   Nombre de threads (1-60) [%THREADS%] : "
if not "%t%"=="" set "THREADS=%t%"
goto :menu

:delay
set "d="
set /p "d=   Delai en ms entre 2 verifications [%DELAY%] : "
if not "%d%"=="" set "DELAY=%d%"
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
echo   Preparation du script...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command "$f='%~f0'; $l=[IO.File]::ReadAllLines($f); $i=[Array]::IndexOf($l,'###PSSTART###'); if($i -lt 0){Write-Host 'marqueur introuvable'; exit 1}; [IO.File]::WriteAllLines('%PS1%', $l[($i+1)..($l.Length-1)])"

if not exist "%PS1%" (
    echo   Erreur : impossible de creer le script PowerShell.
    pause
    goto :menu
)

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
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -Length %1 -Charset %2 -Threads %THREADS% -DelayMs %DELAY% -Webhook "%WEBHOOK%"
goto :eof

:end
exit /b

###PSSTART###
param(
    [int]$Length = 3,
    [string]$Charset = 'L',
    [int]$Threads = 4,
    [int]$DelayMs = 2000,
    [string]$Webhook = '',
    [string]$Endpoint = 'https://discord.com/api/v9/unique-username/username-attempt-unauthed'
)

$SCRIPT_VERSION = 'v4-httpwebrequest'

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Net.ServicePointManager]::Expect100Continue = $false
[Net.ServicePointManager]::DefaultConnectionLimit = 100
[Net.WebRequest]::DefaultWebProxy = $null

if ($Threads -lt 1) { $Threads = 1 }
if ($DelayMs -lt 0) { $DelayMs = 0 }

$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'

$root = Join-Path $env:TEMP 'discord-name-checker'
[void][IO.Directory]::CreateDirectory($root)

$tag      = "$Length$Charset"
$listFile = Join-Path $root "liste_$tag.txt"
$okFile   = Join-Path $root "dispo_$tag.txt"
$logFile  = Join-Path $root "verif_$tag.txt"

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
        if ($p -gt 0) { [void]$checked.Add($line.Substring(0, $p)) }
    }
}

$queue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[string]'
$todo = 0
foreach ($n in $all) { if (-not $checked.Contains($n)) { $queue.Enqueue($n); $todo++ } }

Write-Host ""
Write-Host "  Script     : $SCRIPT_VERSION"
Write-Host "  PowerShell : $($PSVersionTable.PSVersion)"
Write-Host "  Cible      : $tag   ($($all.Length) pseudos au total)"
Write-Host "  A verifier : $todo"
if ($todo -eq 0) { Write-Host "  Tout est deja verifie."; return }
Write-Host "  Fichier    : $okFile"
Write-Host "  Cadence    : 1 verification toutes les $DelayMs ms  (threads: $Threads)"
if ($Webhook) { Write-Host "  Webhook    : actif" } else { Write-Host "  Webhook    : desactive" }
Write-Host ""

# ---------- webhook ----------
$script:nextSend = [DateTime]::UtcNow

function Send-Embed {
    param([string]$Title, [string]$Desc, [int]$Color)
    if (-not $Webhook) { return }

    $gap = ($script:nextSend - [DateTime]::UtcNow).TotalMilliseconds
    if ($gap -gt 0) { Start-Sleep -Milliseconds ([int]$gap) }

    $payload = @{
        content = "**$Title** disponible"
        embeds  = @(@{
            title       = $Title
            description = $Desc
            color       = $Color
            timestamp   = (Get-Date).ToUniversalTime().ToString('o')
            footer      = @{ text = "Discord Name Checker" }
        })
    } | ConvertTo-Json -Depth 6 -Compress

    for ($t = 0; $t -lt 5; $t++) {
        try {
            $bytes = [Text.Encoding]::UTF8.GetBytes($payload)
            $req = [System.Net.HttpWebRequest]::Create($Webhook)
            $req.Method = 'POST'
            $req.ContentType = 'application/json'
            $req.UserAgent = 'DiscordNameChecker'
            $req.Timeout = 20000
            $req.ReadWriteTimeout = 20000
            $req.KeepAlive = $false
            $req.Proxy = $null
            $req.ContentLength = $bytes.Length

            $st = $req.GetRequestStream()
            $st.Write($bytes, 0, $bytes.Length)
            $st.Close()

            $resp = $null
            try { $resp = $req.GetResponse() }
            catch [System.Net.WebException] {
                if ($_.Exception.Response) { $resp = $_.Exception.Response } else { throw }
            }

            $code = 0
            $body = ''
            if ($resp) {
                $code = [int]$resp.StatusCode
                $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
                $body = $sr.ReadToEnd()
                $sr.Close()
                $resp.Close()
            }

            if ($code -eq 429) {
                $ms = 2500
                if ($body -match '"retry_after"\s*:\s*([0-9.]+)') { $ms = [int]([double]$matches[1] * 1000) + 300 }
                Start-Sleep -Milliseconds $ms
                continue
            }
            break
        } catch {
            Start-Sleep -Milliseconds 800
        }
    }
    $script:nextSend = [DateTime]::UtcNow.AddSeconds(2)
}

if ($Webhook) { Send-Embed -Title "Demarrage" -Desc "Verification des pseudos **$tag** en cours..." -Color 3447003 }

# ---------- regulateur global : 1 requete toutes les DelayMs ----------
$sync = @{ lock = (New-Object System.Object); next = [DateTime]::UtcNow }

# ---------- moteur ----------
$results = New-Object 'System.Collections.Concurrent.ConcurrentQueue[string]'
$hits    = New-Object 'System.Collections.Concurrent.ConcurrentQueue[string]'
$done    = New-Object 'System.Collections.Concurrent.ConcurrentQueue[int]'
$pool    = [runspacefactory]::CreateRunspacePool(1, $Threads)
$pool.Open()

$sb = {
    param($queue, $results, $hits, $done, $endpoint, $delay, $sync, $ua, $idx)
    $lockObj = $sync['lock']
    $item    = ''
    try {
        while ($queue.TryDequeue([ref]$item)) {

            # -- reservation du creneau : exactement 1 envoi toutes les $delay ms
            $wait = 0
            [System.Threading.Monitor]::Enter($lockObj)
            try {
                $now = [DateTime]::UtcNow
                $nxt = [DateTime]$sync['next']
                if ($nxt -gt $now) { $wait = [int](($nxt - $now).TotalMilliseconds) }
                $sync['next'] = $now.AddMilliseconds($wait + $delay)
            } finally { [System.Threading.Monitor]::Exit($lockObj) }
            if ($wait -gt 0) { Start-Sleep -Milliseconds $wait }

            $name   = $item
            $status = 'err'

            for ($t = 0; $t -lt 8; $t++) {
                try {
                    $bytes = [Text.Encoding]::UTF8.GetBytes('{"username":"' + $name + '"}')

                    $req = [System.Net.HttpWebRequest]::Create($endpoint)
                    $req.Method = 'POST'
                    $req.ContentType = 'application/json'
                    $req.UserAgent = $ua
                    $req.Accept = 'application/json'
                    $req.Referer = 'https://discord.com/register'
                    try { $req.Headers.Add('Origin', 'https://discord.com') } catch { }
                    $req.Timeout = 25000
                    $req.ReadWriteTimeout = 25000
                    $req.KeepAlive = $false
                    $req.Proxy = $null
                    $req.ContentLength = $bytes.Length

                    $st = $req.GetRequestStream()
                    $st.Write($bytes, 0, $bytes.Length)
                    $st.Close()

                    $resp = $null
                    try { $resp = $req.GetResponse() }
                    catch [System.Net.WebException] {
                        if ($_.Exception.Response) { $resp = $_.Exception.Response } else { throw }
                    }

                    $code = 0
                    $txt  = ''
                    if ($resp) {
                        $code = [int]$resp.StatusCode
                        $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
                        $txt = $sr.ReadToEnd()
                        $sr.Close()
                        $resp.Close()
                    }

                    if ($txt -match '"taken"\s*:\s*true')  { $status = 'pris';  break }
                    if ($txt -match '"taken"\s*:\s*false') { $status = 'dispo'; break }

                    if ($code -eq 429) {
                        $ms = 1500
                        if ($txt -match '"retry_after"\s*:\s*([0-9.]+)') { $ms = [int]([double]$matches[1] * 1000) + 250 }
                        Start-Sleep -Milliseconds $ms
                        continue
                    }
                    if ($code -eq 200) { $status = 'dispo'; break }
                    $status = "http$code"
                    break
                } catch {
                    Start-Sleep -Milliseconds 700
                }
            }

            if ($status -eq 'dispo') { $hits.Enqueue($name) }
            $results.Enqueue($name + [char]9 + $status)
        }
    } catch {
        $results.Enqueue("ERREUR_WORKER$idx" + [char]9 + "err")
    } finally {
        $done.Enqueue($idx)
    }
}

$handles = New-Object System.Collections.ArrayList
for ($i = 0; $i -lt $Threads; $i++) {
    $ps = [powershell]::Create()
    $ps.RunspacePool = $pool
    [void]$ps.AddScript($sb).AddArgument($queue).AddArgument($results).AddArgument($hits).AddArgument($done).AddArgument($Endpoint).AddArgument($DelayMs).AddArgument($sync).AddArgument($UA).AddArgument($i)
    try { [void]$handles.Add([pscustomobject]@{ PS = $ps; H = $ps.BeginInvoke() }) }
    catch { $done.Enqueue($i) }
}

$okW  = New-Object System.IO.StreamWriter($okFile, $true)
$logW = New-Object System.IO.StreamWriter($logFile, $true)

$processed = 0
$found     = 0
$sw        = [Diagnostics.Stopwatch]::StartNew()
$line      = ''
$hitName   = ''

try {
    while ($done.Count -lt $Threads) {
        $n = 0
        while ($n -lt 4000 -and $results.TryDequeue([ref]$line)) {
            $p = $line.IndexOf([char]9)
            $logW.WriteLine($line)
            if ($p -gt 0 -and $line.Substring($p + 1) -eq 'dispo') { $okW.WriteLine($line.Substring(0, $p)); $found++ }
            $processed++; $n++
        }
        if ($n -gt 0) { $logW.Flush(); $okW.Flush() }

        # un embed par pseudo trouve, espace de 2 s (limite webhook Discord)
        if ($hits.TryDequeue([ref]$hitName)) {
            Send-Embed -Title $hitName -Desc "Pseudo disponible : **$hitName**" -Color 5763719
        }

        $pct = [math]::Round($processed * 100 / $todo, 2)
        $spd = [math]::Round($processed / [math]::Max($sw.Elapsed.TotalSeconds, 0.001), 1)
        if ($spd -gt 0) { $eta = [TimeSpan]::FromSeconds(($todo - $processed) / $spd).ToString('hh\:mm\:ss') } else { $eta = '--:--:--' }
        Write-Host -NoNewline ("`r  {0} / {1}  ({2}%)   dispo: {3}   {4}/s   ETA {5}        " -f $processed, $todo, $pct, $found, $spd, $eta)
        Start-Sleep -Milliseconds 250
    }
    while ($results.TryDequeue([ref]$line)) {
        $p = $line.IndexOf([char]9)
        $logW.WriteLine($line)
        if ($p -gt 0 -and $line.Substring($p + 1) -eq 'dispo') { $okW.WriteLine($line.Substring(0, $p)); $found++ }
        $processed++
    }
    while ($hits.TryDequeue([ref]$hitName)) {
        Send-Embed -Title $hitName -Desc "Pseudo disponible : **$hitName**" -Color 5763719
    }
} finally {
    $logW.Flush(); $logW.Close(); $okW.Flush(); $okW.Close()
    foreach ($h in $handles) { try { [void]$h.PS.EndInvoke($h.H) } catch { }; try { $h.PS.Dispose() } catch { } }
    try { $pool.Close() } catch { }
    try { $pool.Dispose() } catch { }
}

Write-Host ""
Write-Host ""
Write-Host "  Termine : $processed verifies, $found disponibles."
Write-Host "  Disponibles : $okFile"
Write-Host "  Journal     : $logFile"

if ($Webhook) {
    Send-Embed -Title "Termine" -Desc "**$tag** : $processed pseudos verifies, **$found** disponibles." -Color 10181046
}
