#!/usr/bin/env python3
"""
Servidor de login VULNERABLE - SOLO PARA LABORATORIO
=====================================================
Sirve una pagina de login por HTTP SIN cifrado (sin HTTPS). Las credenciales
viajan en texto plano por la red, de modo que un atacante en posicion
Man-in-the-Middle (ARP spoofing) puede capturarlas con un sniffer.

Objetivo didactico: demostrar por que el trafico sin cifrar es peligroso.
NO USAR EN PRODUCCION NI EN REDES REALES.

Uso:
    python servidor-login-vulnerable.py
Luego, desde la victima, abrir en el navegador:
    http://<IP-del-host>:8000/
"""
from http.server import BaseHTTPRequestHandler, HTTPServer
import urllib.parse

PUERTO = 8000

PAGINA = """<!doctype html>
<html lang="es">
<head><meta charset="utf-8"><title>Portal Interno</title></head>
<body style="font-family:sans-serif;max-width:360px;margin:60px auto;color:#222">
  <h2>Portal Interno - Acceso</h2>
  <p style="color:#777;font-size:14px">Sistema de la empresa (laboratorio)</p>
  <form method="POST" action="/login">
    <p>Usuario:<br><input name="username" style="width:100%;padding:6px"></p>
    <p>Contrasena:<br><input name="password" type="password" style="width:100%;padding:6px"></p>
    <button type="submit" style="padding:8px 16px">Entrar</button>
  </form>
</body>
</html>"""


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self._html(200, PAGINA)

    def do_POST(self):
        largo = int(self.headers.get("Content-Length", 0))
        cuerpo = self.rfile.read(largo).decode("utf-8", "replace")
        datos = urllib.parse.parse_qs(cuerpo)
        usuario = datos.get("username", [""])[0]
        clave = datos.get("password", [""])[0]
        print(f"[LOGIN RECIBIDO]  usuario={usuario!r}  contrasena={clave!r}")
        self._html(200, f"<p style='font-family:sans-serif'>Bienvenido, {usuario}.</p>")

    def _html(self, codigo, cuerpo):
        self.send_response(codigo)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(cuerpo.encode("utf-8"))

    def log_message(self, *args):
        pass  # silenciar el log por defecto


if __name__ == "__main__":
    print(f"Servidor de login (texto plano) escuchando en http://0.0.0.0:{PUERTO}")
    print("Presiona Ctrl+C para detener.\n")
    try:
        HTTPServer(("0.0.0.0", PUERTO), Handler).serve_forever()
    except KeyboardInterrupt:
        print("\nServidor detenido.")
