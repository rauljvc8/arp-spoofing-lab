# arp-spoofing-lab
ARP Spoofing lab: MITM attack, detection and mitigation on an isolated network (Kali, Wireshark). Bilingual report (EN/ES).

# 🛡️ Laboratorio de ARP Spoofing — ARP Spoofing Lab

**Ataque, detección y mitigación de un Man-in-the-Middle en una red local aislada**
*Attack, detection and mitigation of a Man-in-the-Middle on an isolated LAN*

**Autor / Author:** Raul Velasquez ([@rauljvc8](https://github.com/rauljvc8)) · Cybersecurity Consultant — South Florida

---

> ⚠️ **Aviso ético / Ethical notice**
> Todas las pruebas se realizaron sobre máquinas virtuales propias, en una red **Host-Only totalmente aislada**, sin acceso a internet ni a redes de terceros. El ARP Spoofing contra equipos o redes sin autorización es **ilegal**. Este material es exclusivamente **educativo**.
> *All testing was performed on the author's own virtual machines, on a fully isolated Host-Only network with no internet or third-party access. ARP Spoofing against systems or networks without authorization is **illegal**. This material is strictly **educational**.*

---

## 📄 Informe completo / Full report

El informe detallado, con **todas las capturas de pantalla** paso a paso, está en los PDFs de este repositorio:
*The detailed report, with **all step-by-step screenshots**, is in the PDFs in this repository:*

- 📘 **`informe-arp-spoofing-ES.pdf`** — informe completo en español
- 📗 **`informe-arp-spoofing-EN.pdf`** — full report in English

---

<a name="español"></a>
# 🇪🇸 Español

## 📌 Resumen

Este laboratorio demuestra, de principio a fin, un ataque de **ARP Spoofing** (envenenamiento de la caché ARP). Un atacante situado en la misma red local se interpone entre dos equipos (ataque **Man-in-the-Middle**), intercepta su tráfico y **captura credenciales que viajan sin cifrar**. El proyecto incluye además el análisis defensivo: **cómo detectar** y **cómo mitigar** el ataque.

## 🧩 Topología del laboratorio

| Rol | Sistema | IP | MAC |
|---|---|---|---|
| Atacante | Kali Linux | `192.168.56.102` | `08:00:27:63:B0:05` |
| Víctima | Debian Linux | `192.168.56.103` | `08:00:27:D1:65:C7` |
| "Gateway" del lab | Windows (host) | `192.168.56.101` | `0A:00:27:00:00:0E` |

```
   [ Víctima ]                      [ "Gateway" / Host ]
   Debian  192.168.56.103           Windows  192.168.56.101
            \                                 /
             \   ARP falso         ARP falso /
              \                             /
            [ Atacante · Kali · 192.168.56.102 ]
              Envenena la caché ARP en ambos sentidos
              → todo el tráfico pasa por él (MITM)
```

## 🛠️ Herramientas

VirtualBox (red Host-Only aislada) · Kali Linux · `arpspoof` (paquete *dsniff*) · `nmap` · **Wireshark** · `ettercap` (opcional)

## 🚀 Fases del laboratorio

**Fase 1 — Montaje (red aislada).** VMs en modo **Host-Only** (`192.168.56.0/24`). El modo NAT **no** permite ARP Spoofing porque aísla las VMs en capa 3; Host-Only crea un segmento de capa 2 real.

**Fase 2 — Por qué ARP es vulnerable.** ARP traduce IP (capa 3) → MAC (capa 2) y **no tiene autenticación**. Cualquier equipo puede responder "esa IP es mía", incluso mintiendo.

**Fase 3 — Reconocimiento.**
```bash
sudo nmap -sn 192.168.56.0/24     # descubrir hosts vivos
ip neigh                          # caché ARP "antes": .101 → MAC real del host
```

**Fase 4 — Ejecución del ataque (en Kali).**
```bash
sudo sysctl -w net.ipv4.ip_forward=1                      # MITM sigiloso
sudo arpspoof -i eth0 -t 192.168.56.103 192.168.56.101    # engañar a la víctima
sudo arpspoof -i eth0 -t 192.168.56.101 192.168.56.103    # engañar al host
```
Resultado: la caché ARP de la víctima cambia → `.101 → 08:00:27:63:B0:05` (MAC de Kali). ✅

**Fase 5 — Demostración del MITM.** Tras ajustar el reenvío (`rp_filter`, `send_redirects`, `iptables FORWARD`), cada paquete aparece en Wireshark **duplicado** con el TTL decrementado en 1 (`64→63`, `128→127`): la huella de un intermediario. Con un portal HTTP sin cifrar, las credenciales se capturan en texto plano: `username=admin&password=Secreto123`. 🔓 Con **HTTPS/TLS** esto no habría sido posible.

## 🔍 Detección (Blue Team / SOC)

Entradas ARP duplicadas (dos IP, misma MAC) · cambio brusco de MAC para una IP conocida · ráfagas de *ARP reply* no solicitados · el TTL que ve la víctima baja 1 · herramientas como `arpwatch`, XArp, Suricata/Snort · monitoreo SOC de la tabla ARP de activos críticos.

## 🛡️ Mitigación

Entradas **ARP estáticas** en gateways críticos · **Dynamic ARP Inspection (DAI)** con DHCP snooping en switches gestionados (principal defensa empresarial) · **Port Security** · **cifrado de extremo a extremo** (HTTPS/TLS, SSH, VPN) · segmentación de red (VLANs).

## 📁 Contenido del repositorio

- `README.md` — este resumen
- `informe-arp-spoofing-ES.pdf` — informe completo en español (con capturas)
- `informe-arp-spoofing-EN.pdf` — informe completo en inglés (con capturas)

---

<a name="english"></a>
# 🇬🇧 English

## 📌 Overview

This lab demonstrates, end to end, an **ARP Spoofing** attack (ARP cache poisoning). An attacker on the same LAN places itself between two hosts (**Man-in-the-Middle**), intercepts their traffic and **captures credentials sent in clear text**. The project also covers the defensive side: **how to detect** and **how to mitigate** the attack.

## 🧩 Lab topology

| Role | System | IP | MAC |
|---|---|---|---|
| Attacker | Kali Linux | `192.168.56.102` | `08:00:27:63:B0:05` |
| Victim | Debian Linux | `192.168.56.103` | `08:00:27:D1:65:C7` |
| Lab "gateway" | Windows (host) | `192.168.56.101` | `0A:00:27:00:00:0E` |

## 🛠️ Tools

VirtualBox (isolated Host-Only network) · Kali Linux · `arpspoof` (dsniff) · `nmap` · **Wireshark** · `ettercap` (optional)

## 🚀 Lab phases

1. **Setup** — isolated Host-Only network (`192.168.56.0/24`). NAT does **not** allow ARP spoofing (layer-3 isolation); Host-Only provides a real layer-2 segment.
2. **Why ARP is vulnerable** — ARP maps IP→MAC and has **no authentication**; any host can reply, even dishonestly.
3. **Recon** — `sudo nmap -sn 192.168.56.0/24`; capture the victim's ARP cache "before".
4. **Attack** — enable IP forwarding, then run `arpspoof` in both directions. The victim's ARP entry for the gateway flips to the attacker's MAC.
5. **MITM proof** — after tuning forwarding, every packet appears **twice** in Wireshark with TTL decremented by 1 (`64→63`, `128→127`). Clear-text credential capture: `username=admin&password=Secreto123`. With **HTTPS/TLS** this would not be possible.

## 🔍 Detection (Blue Team / SOC)

Duplicate ARP entries (two IPs, same MAC) · sudden MAC change for a known IP · bursts of unsolicited ARP replies · TTL decrement seen by the victim · tools like `arpwatch`, XArp, Suricata/Snort · SOC monitoring of ARP tables for critical assets.

## 🛡️ Mitigation

Static ARP entries for critical gateways · **Dynamic ARP Inspection (DAI)** with DHCP snooping on managed switches (main enterprise defense) · Port Security · **end-to-end encryption** (HTTPS/TLS, SSH, VPN) · network segmentation (VLANs).

## 📁 Repository contents

- `README.md` — this summary
- `informe-arp-spoofing-ES.pdf` — full report in Spanish (with screenshots)
- `informe-arp-spoofing-EN.pdf` — full report in English (with screenshots)

---

### 📝 Key takeaway

ARP Spoofing remains a **low-cost, high-impact** attack on poorly protected LANs: full traffic interception and clear-text credential theft. Defense combines technical controls (DAI, static ARP, port security) and — above all — **encrypting traffic**, which neutralizes the value of interception.

---
*Hecho con fines educativos · Built for educational purposes — Raul Velasquez (@rauljvc8)*
