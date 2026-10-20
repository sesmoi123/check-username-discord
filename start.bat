@echo off
setlocal EnableExtensions
set "VER=6"
title Checker pseudo Discord - 3L 3C 4L 4C
color 0B

set "THREADS=20"
set "DELAY=80"
set "WEBHOOK=https://discord.com/api/webhooks/1545887085351804928/OhHVPWM-XwGM8eWg8mUahPLarLolhkSj_63oNyFr1Q0FDWxROzn5MQG9bDBqsWIIHLee"
set "PS1=%TEMP%\discord_name_checker.ps1"
set "OUTDIR=%TEMP%\discord-name-checker"

:menu
cls
echo.
echo   ============================================================
echo     CHECKER DE PSEUDO DISCORD     (sans token, sans proxy)
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
echo     [D]  Ecart de depart (ms)   : %DELAY%     (0 = plein gaz)
echo     [W]  Webhook                : %WEBHOOK%
echo     [O]  Ouvrir le dossier des resultats
echo     [R]  Repartir de zero (efface la progression)
echo     [Q]  Quitter
echo.
echo   Astuce : si la fenetre se fige, desactive le "Mode selection rapide"
echo            dans les proprietes de la console (clic droit sur la barre).
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
set /p "t=   Nombre de threads (1-64) [%THREADS%] : "
if not "%t%"=="" set "THREADS=%t%"
goto :menu

:delay
set "d="
set /p "d=   Ecart de depart en ms (0 = plein gaz) [%DELAY%] : "
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
echo   [ start.bat v%VER% ]
echo.
echo   Preparation du script PowerShell...
echo.

if exist "%PS1%" del /f /q "%PS1%" >nul 2>&1

powershell -NoProfile -ExecutionPolicy Bypass -Command "$f='%~f0'; $l=[IO.File]::ReadAllLines($f); $i=-1; for($k=0;$k -lt $l.Length;$k++){ if($l[$k].Trim() -eq '###PSSTART###'){ $i=$k; break } }; if($i -lt 0){ Write-Host '  EXTRACTION : marqueur ###PSSTART### introuvable'; exit 1 }; [IO.File]::WriteAllLines('%PS1%', $l[($i+1)..($l.Length-1)]); Write-Host ('  EXTRACTION : OK - lignes ' + ($i+1) + ' a ' + $l.Length)"

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
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -Length %1 -Charset %2 -Threads %THREADS% -DelayMs %DELAY% -Webhook "%WEBHOOK%"
goto :eof

:end
exit /b

###PSSTART###
param(
    [int]$Length = 3,
    [string]$Charset = 'L',
    [int]$Threads = 20,
    [int]$DelayMs = 80,
    [string]$Webhook = '',
    [string]$Endpoint = 'https://discord.com/api/v9/unique-username/username-attempt-unauthed'
)

$SCRIPT_VERSION = 'v6-adaptive'

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Net.ServicePointManager]::Expect100Continue = $false
[Net.ServicePointManager]::DefaultConnectionLimit = 200
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
Write-Host "  Ecart base : $DelayMs ms   threads: $Threads   (auto-adapte sur 429)"
if ($Webhook) { Write-Host "  Webhook    : actif (thread separe)" } else { Write-Host "  Webhook    : desactive" }
Write-Host ""

# ---------- etat partage ----------
$sync = @{
    lock      = (New-Object System.Object)
    next      = [DateTime]::UtcNow
    gap       = $DelayMs
    gapMin    = 20
    clean     = 0
    lastAdapt = [DateTime]::UtcNow
    c429      = 0
    stop      = $false
}

# ---------- envoi webhook simple (demarrage / fin) ----------
function Send-Embed {
    param([string]$Title, [string]$Desc, [int]$Color)
    if (-not $Webhook) { return }
    $payload = @{
        content = "**$Title**"
        embeds  = @(@{
            title       = $Title
            description = $Desc
            color       = $Color
            timestamp   = (Get-Date).ToUniversalTime().ToString('o')
            footer      = @{ text = "Discord Name Checker" }
        })
    } | ConvertTo-Json -Depth 6 -Compress

    for ($t = 0; $t -lt 4; $t++) {
        try {
            $bytes = [Text.Encoding]::UTF8.GetBytes($payload)
            $req = [System.Net.HttpWebRequest]::Create($Webhook)
            $req.Method = 'POST'
            $req.ContentType = 'application/json'
            $req.UserAgent = 'DiscordNameChecker'
            $req.Timeout = 12000
            $req.ReadWriteTimeout = 12000
            $req.Proxy = $null
            $req.ContentLength = $bytes.Length
            $st = $req.GetRequestStream(); $st.Write($bytes, 0, $bytes.Length); $st.Close()
            $resp = $null
            try { $resp = $req.GetResponse() }
            catch [System.Net.WebException] { if ($_.Exception.Response) { $resp = $_.Exception.Response } else { throw } }
            $code = 0; $body = ''
            if ($resp) {
                $code = [int]$resp.StatusCode
                $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
                $body = $sr.ReadToEnd(); $sr.Close(); $resp.Close()
            }
            if ($code -eq 429) {
                $ms = 2000
                if ($body -match '"retry_after"\s*:\s*([0-9.]+)') { $ms = [int]([double]$matches[1] * 1000) + 300 }
                Start-Sleep -Milliseconds $ms
                continue
            }
            break
        } catch { Start-Sleep -Milliseconds 700 }
    }
}

# ---------- thread dedie aux trouvailles : ne bloque jamais la boucle principale ----------
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
                    title       = $item
                    description = "Pseudo disponible : **$item**"
                    color       = 5763719
                    timestamp   = (Get-Date).ToUniversalTime().ToString('o')
                    footer      = @{ text = "Discord Name Checker" }
                })
            } | ConvertTo-Json -Depth 6 -Compress

            for ($t = 0; $t -lt 5; $t++) {
                try {
                    $bytes = [Text.Encoding]::UTF8.GetBytes($payload)
                    $req = [System.Net.HttpWebRequest]::Create($webhook)
                    $req.Method = 'POST'
                    $req.ContentType = 'application/json'
                    $req.UserAgent = 'DiscordNameChecker'
                    $req.Timeout = 12000
                    $req.ReadWriteTimeout = 12000
                    $req.Proxy = $null
                    $req.ContentLength = $bytes.Length
                    $st = $req.GetRequestStream(); $st.Write($bytes, 0, $bytes.Length); $st.Close()
                    $resp = $null
                    try { $resp = $req.GetResponse() }
                    catch [System.Net.WebException] { if ($_.Exception.Response) { $resp = $_.Exception.Response } else { throw } }
                    $code = 0; $body = ''
                    if ($resp) {
                        $code = [int]$resp.StatusCode
                        $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
                        $body = $sr.ReadToEnd(); $sr.Close(); $resp.Close()
                    }
                    if ($code -eq 429) {
                        $ms = 2000
                        if ($body -match '"retry_after"\s*:\s*([0-9.]+)') { $ms = [int]([double]$matches[1] * 1000) + 300 }
                        Start-Sleep -Milliseconds $ms
                        continue
                    }
                    break
                } catch { Start-Sleep -Milliseconds 700 }
            }
            $next = [DateTime]::UtcNow.AddMilliseconds(1400)
        } elseif ([bool]$sync['stop']) {
            break
        } else {
            Start-Sleep -Milliseconds 120
        }
    }
}

if ($Webhook) { Send-Embed -Title "Demarrage" -Desc "Verification des pseudos **$tag** en cours..." -Color 3447003 }

$results = New-Object 'System.Collections.Concurrent.ConcurrentQueue[string]'
$hits    = New-Object 'System.Collections.Concurrent.ConcurrentQueue[string]'
$done    = New-Object 'System.Collections.Concurrent.ConcurrentQueue[int]'

if ($Webhook) {
    $whRS = [runspacefactory]::CreateRunspace()
    $whRS.Open()
    $whPS = [powershell]::Create()
    $whPS.Runspace = $whRS
    [void]$whPS.AddScript($whSb).AddArgument($hits).AddArgument($Webhook).AddArgument($sync)
    $whHandle = $whPS.BeginInvoke()
}

# ---------- moteur ----------
$pool = [runspacefactory]::CreateRunspacePool(1, $Threads)
$pool.Open()

$sb = {
    param($queue, $results, $hits, $done, $endpoint, $delay, $sync, $ua, $idx)
    $lockObj = $sync['lock']
    $item    = ''
    try {
        while ($queue.TryDequeue([ref]$item)) {

            # -- reservation du creneau global (ecart auto-adapte)
            $wait = 0
            [System.Threading.Monitor]::Enter($lockObj)
            try {
                $now = [DateTime]::UtcNow
                $nxt = [DateTime]$sync['next']
                if ($nxt -gt $now) { $wait = [int](($nxt - $now).TotalMilliseconds) }
                $sync['next'] = $now.AddMilliseconds($wait + [int]$sync['gap'])
            } finally { [System.Threading.Monitor]::Exit($lockObj) }
            if ($wait -gt 0) { Start-Sleep -Milliseconds $wait }

            $name   = $item
            $status = 'err'

            for ($t = 0; $t -lt 6; $t++) {
                try {
                    $bytes = [Text.Encoding]::UTF8.GetBytes('{"username":"' + $name + '"}')

                    $req = [System.Net.HttpWebRequest]::Create($endpoint)
                    $req.Method = 'POST'
                    $req.ContentType = 'application/json'
                    $req.UserAgent = $ua
                    $req.Accept = 'application/json'
                    $req.Referer = 'https://discord.com/register'
                    try { $req.Headers.Add('Origin', 'https://discord.com') } catch { }
                    $req.Timeout = 12000
                    $req.ReadWriteTimeout = 12000
                    $req.KeepAlive = $true
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
                        $ms = 1200
                        if ($txt -match '"retry_after"\s*:\s*([0-9.]+)') { $ms = [int]([double]$matches[1] * 1000) + 200 }

                        # on ralentit l'ecart global (une seule fois par rafale)
                        [System.Threading.Monitor]::Enter($lockObj)
                        try {
                            $n2 = [DateTime]::UtcNow
                            if (($n2 - [DateTime]$sync['lastAdapt']).TotalSeconds -gt 1.0) {
                                $g = [int]$sync['gap']
                                if ($g -lt 40) { $g = 40 }
                                $sync['gap'] = [int][math]::Min(3000, [int]($g * 1.7))
                                $sync['lastAdapt'] = $n2
                                $sync['clean'] = 0
                            }
                            $sync['c429'] = [int]$sync['c429'] + 1
                        } finally { [System.Threading.Monitor]::Exit($lockObj) }

                        Start-Sleep -Milliseconds $ms
                        continue
                    }

                    if ($code -eq 200) { $status = 'dispo'; break }
                    $status = "http$code"
                    break
                } catch {
                    Start-Sleep -Milliseconds 400
                }
            }

            # -- accélération progressive quand tout est propre
            $c = [int]$sync['clean'] + 1
            if ($c -ge 400) {
                $c = 0
                $g = [int]$sync['gap']
                if ($g -gt [int]$sync['gapMin']) {
                    $sync['gap'] = [int][math]::Max([int]$sync['gapMin'], [int]($g * 0.85))
                }
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
$idle      = 0
$lastDraw  = [DateTime]::MinValue
$lastTitle = [DateTime]::MinValue
$titreBase = "Checker Discord $tag"

try {
    while ($done.Count -lt $Threads) {

        $n = 0
        while ($n -lt 6000 -and $results.TryDequeue([ref]$line)) {
            $p = $line.IndexOf([char]9)
            $logW.WriteLine($line)
            if ($p -gt 0 -and $line.Substring($p + 1) -eq 'dispo') { $okW.WriteLine($line.Substring(0, $p)); $found++ }
            $processed++; $n++
        }
        if ($n -gt 0) { $logW.Flush(); $okW.Flush() }

        # anti-blocage : si plus rien ne bouge nulle part, on sort
        if ($queue.Count -eq 0 -and $results.Count -eq 0 -and $hits.Count -eq 0) { $idle++ } else { $idle = 0 }
        if ($idle -gt 200) { break }

        $spd = $processed / [math]::Max($sw.Elapsed.TotalSeconds, 0.001)
        $pct = [math]::Round($processed * 100 / $todo, 2)
        if ($spd -gt 0) { $eta = [TimeSpan]::FromSeconds(($todo - $processed) / $spd).ToString('hh\:mm\:ss') } else { $eta = '--:--:--' }
        $txt = "  $processed / $todo  ($pct%)   dispo: $found   429: $($sync['c429'])   $([math]::Round($spd,1))/s   ecart: $($sync['gap'])ms   ETA $eta"

        # titre : mise a jour frequente, non bloquee par la selection console
        $nt = [DateTime]::UtcNow
        if (($nt - $lastTitle).TotalMilliseconds -ge 400) {
            $lastTitle = $nt
            try { [Console]::Title = "$titreBase  |  $pct%  |  $found dispo  |  $([math]::Round($spd,1))/s" } catch { }
        }

        # ligne console : 1 fois par seconde seulement
        if (($nt - $lastDraw).TotalMilliseconds -ge 1000) {
            $lastDraw = $nt
            Write-Host -NoNewline ("`r" + $txt + "        ")
        }

        Start-Sleep -Milliseconds 120
    }

    while ($results.TryDequeue([ref]$line)) {
        $p = $line.IndexOf([char]9)
        $logW.WriteLine($line)
        if ($p -gt 0 -and $line.Substring($p + 1) -eq 'dispo') { $okW.WriteLine($line.Substring(0, $p)); $found++ }
        $processed++
    }
} finally {
    $logW.Flush(); $logW.Close(); $okW.Flush(); $okW.Close()

    $sync['stop'] = $true
    if ($whPS) { try { [void]$whPS.EndInvoke($whHandle) } catch { }; try { $whPS.Dispose() } catch { } }
    if ($whRS) { try { $whRS.Close() } catch { }; try { $whRS.Dispose() } catch { } }

    foreach ($h in $handles) { try { [void]$h.PS.EndInvoke($h.H) } catch { }; try { $h.PS.Dispose() } catch { } }
    try { $pool.Close() } catch { }
    try { $pool.Dispose() } catch { }
}

Write-Host ""
Write-Host ""
Write-Host "  Termine : $processed verifies, $found disponibles."
Write-Host "  Disponibles : $okFile"
Write-Host "  Journal     : $logFile"

try { [Console]::Title = "$titreBase  |  termine" } catch { }

if ($Webhook) {
    Send-Embed -Title "Termine" -Desc "**$tag** : $processed pseudos verifies, **$found** disponibles." -Color 10181046
}
