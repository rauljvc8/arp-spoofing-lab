# servidor-login-vulnerable.ps1  -  SOLO PARA LABORATORIO
# ============================================================
# Servidor de login por HTTP SIN cifrado (sin HTTPS). Las credenciales
# viajan en texto plano por la red, de modo que un atacante en posicion
# Man-in-the-Middle (ARP spoofing) puede capturarlas con un sniffer.
#
# Objetivo didactico: demostrar el peligro del trafico sin cifrar.
# NO USAR EN PRODUCCION NI EN REDES REALES.
#
# USO (en el host Windows):
#   1. Abrir PowerShell COMO ADMINISTRADOR
#   2. Permitir scripts en esta sesion:
#        Set-ExecutionPolicy -Scope Process Bypass
#   3. Ejecutar:
#        .\servidor-login-vulnerable.ps1
# ============================================================

$puerto = 8000

# Abrir el puerto en el firewall de Windows (ignora si ya existe)
try {
    New-NetFirewallRule -DisplayName "Lab Login $puerto" -Direction Inbound `
        -Action Allow -Protocol TCP -LocalPort $puerto -ErrorAction Stop | Out-Null
    Write-Host "Regla de firewall creada para el puerto $puerto."
} catch {
    Write-Host "Regla de firewall ya existe o no se pudo crear (continuo)."
}

$pagina = @'
<!doctype html>
<html lang="es"><head><meta charset="utf-8"><title>Portal Interno</title></head>
<body style="font-family:sans-serif;max-width:360px;margin:60px auto;color:#222">
  <h2>Portal Interno - Acceso</h2>
  <p style="color:#777;font-size:14px">Sistema de la empresa (laboratorio)</p>
  <form method="POST" action="/login">
    <p>Usuario:<br><input name="username" style="width:100%;padding:6px"></p>
    <p>Contrasena:<br><input name="password" type="password" style="width:100%;padding:6px"></p>
    <button type="submit" style="padding:8px 16px">Entrar</button>
  </form>
</body></html>
'@

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:$puerto/")
try {
    $listener.Start()
} catch {
    Write-Host "ERROR: no se pudo iniciar el servidor." -ForegroundColor Red
    Write-Host "Asegurate de abrir PowerShell COMO ADMINISTRADOR." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Servidor de login (texto plano) escuchando en http://0.0.0.0:$puerto/"
Write-Host "Desde la victima, abrir:  http://192.168.56.101:$puerto/"
Write-Host "Presiona Ctrl+C para detener."
Write-Host ""

while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $req = $ctx.Request
    $res = $ctx.Response
    if ($req.HttpMethod -eq "POST") {
        $reader = New-Object System.IO.StreamReader($req.InputStream, $req.ContentEncoding)
        $body = $reader.ReadToEnd()
        $reader.Close()
        Write-Host "[LOGIN RECIBIDO]  $body" -ForegroundColor Yellow
        $salida = "<p style='font-family:sans-serif'>Bienvenido.</p>"
    } else {
        $salida = $pagina
    }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($salida)
    $res.ContentType = "text/html; charset=utf-8"
    $res.ContentLength64 = $bytes.Length
    $res.OutputStream.Write($bytes, 0, $bytes.Length)
    $res.OutputStream.Close()
}
