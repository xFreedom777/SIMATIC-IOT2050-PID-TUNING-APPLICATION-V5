# SIMATIC IOT2050 PID Tuning Application — V5

> **[ภาษาไทย 🇹🇭 อยู่ด้านล่าง / Thai version below ⬇️]**

---

<div align="center">

```
███████╗██╗ █████╗ ███╗   ███╗ █████╗ ████████╗██╗ ██████╗
██╔════╝██║██╔══██╗████╗ ████║██╔══██╗╚══██╔══╝██║██╔════╝
███████╗██║███████║██╔████╔██║███████║   ██║   ██║██║     
╚════██║██║██╔══██║██║╚██╔╝██║██╔══██║   ██║   ██║██║     
███████║██║██║  ██║██║ ╚═╝ ██║██║  ██║   ██║   ██║╚██████╗
╚══════╝╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝
```

**Siemens SIMATIC IOT2050 × S7-1200 PLC × PIDCompact V2**

*Gate Valve Control & Monitoring System — Mitr Phol Pin Mill Plant*

![Node.js](https://img.shields.io/badge/Node.js-18%2B-green?logo=node.js)
![Siemens](https://img.shields.io/badge/Siemens-S7--1200-009999?logo=siemens)
![Platform](https://img.shields.io/badge/Platform-IOT2050%20Debian-blue)
![Protocol](https://img.shields.io/badge/Protocol-S7%20over%20TCP%2FIP-orange)
![Stability](https://img.shields.io/badge/Stability-24%2F7%20Industrial%20V5-brightgreen)
![Author](https://img.shields.io/badge/Author-xFreedom777-purple)

</div>

---

## 📑 Table of Contents (สารบัญ)

- [Overview (ภาพรวมระบบ)](#-overview)
- [System Architecture (สถาปัตยกรรมโครงสร้างระบบ)](#-system-architecture)
- [What's New in Version 5 (ฟีเจอร์เด่นในเวอร์ชัน 5)](#-whats-new-in-version-5)
- [24/7 Industrial Stability System (ระบบความเสถียร 24/7)](#-247-industrial-stability-system)
- [Offline USB Dashboard & Analytics (ระบบดูกราฟออฟไลน์ผ่าน USB)](#-offline-usb-dashboard--analytics)
- [OT Layer — PLC Control System (ระบบควบคุม PLC)](#-ot-layer--plc-control-system)
- [Hardware & Software Requirements (ข้อกำหนดฮาร์ดแวร์และซอฟต์แวร์)](#-hardware--software-requirements)
- [Deployment Guide (คู่มือการติดตั้งและ Deploy)](#-deployment-guide)
- [API Reference (เอกสาร REST API)](#-api-reference)
- [🇹🇭 เอกสารภาษาไทย (Thai Documentation)](#-เอกสารภาษาไทย-thai-version)

---

## 🌐 Overview

**SIMATIC IOT2050 PID Tuning Application V5** is an enterprise-grade industrial edge SCADA application developed specifically for the **Siemens SIMATIC IOT2050** platform running Debian Industrial Linux. It bridges the OT (Operational Technology) realm of Siemens S7-1200 PLCs with modern IT analytics, featuring real-time HMI touch controls, remote PID parameter tuning, 24/7 localized logging, automated report generation, and standalone offline USB data visualization.

This application was engineered for the **Mitr Phol Pin Mill Plant** Gate Valve Control & Monitoring Project, orchestrating multiple PID control loops for valve positioning with seamless Auto, Manual, and Inactive operational modes.

---

## 🏗️ System Architecture

```
                    ┌────────────────────────────────────────────────────────┐
                    │            SIEMENS S7-1200 PLC (PIDCompact V2)         │
                    │               IP: 192.168.121.211 (DB322)              │
                    └───────────────────────────▲────────────────────────────┘
                                                │ S7comm Protocol (TCP Port 102)
                                                ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                SIEMENS SIMATIC IOT2050 (Debian Linux)                                  │
│                                                                                                        │
│  ┌──────────────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │                                LAYER 1: 24/7 STABILITY & OS GUARDS                               │  │
│  │  • save-last-time.service (Offline Clock Persistence) • journald 100MB Cap (Disk Full Guard)     │  │
│  │  • kiosk-watchdog.service (3s UI Auto-Recovery)       • pid-usb-backup.timer (Midnight Cron)     │  │
│  │  • Disable Console Blanking & Sleep                   • tmpfs Volatile Caching (eMMC Wear Guard) │  │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                │                                                       │
│  ┌─────────────────────────────────────────────▼────────────────────────────────────────────────────┐  │
│  │                                LAYER 2: BACKEND ENGINE (Node.js / Express)                       │  │
│  │  • nodes7 Driver: Asynchronous Polling 100ms (10Hz) Read/Write DB322                             │  │
│  │  • 24/7 Local CSV Logger: Internal eMMC (/opt/pid-tuning-app/logs) with YYYY-MM-DD HH:mm:ss      │  │
│  │  • Storage Diversion Guard: Auto-redirects /media/usb paths to local eMMC to prevent data loss   │  │
│  │  • WebSocket Server: High-speed real-time data broadcasting (SP, PV, Out, Mode)                  │  │
│  │  • Multi-FS USB Engine: Calls usb-mount-helper.sh (FAT32, NTFS, exFAT auto-detection)          │  │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                │                                                       │
│  ┌─────────────────────────────────────────────▼────────────────────────────────────────────────────┐  │
│  │                                LAYER 3: KIOSK UI & OPERATOR EXPERIENCE                           │  │
│  │  • Smart IDLE Engine: 5-minute memory-clearing reload when idle (Prevents V8 Heap Leaks)         │  │
│  │  • 2-Way Manual Output: Real-time sync between touch slider and numeric input (0-100% Clamping) │  │
│  │  • Corporate Engineering PDF: High-contrast white engineering theme with official Mitr Phol logo│  │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────┬───────────────────────────────────────────────────────┘
                                                 │ 1-Click Save / Midnight Backup
                                                 ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                 FLASH DRIVE USB (FAT32 / NTFS)                                         │
│                                                                                                        │
│  📂 PID_Logs_Backup/2026-08-26/                                                                        │
│   ├── 📄 log_CV_101_2026-08-26.csv (Raw Clean CSV Data)                                               │
│   ├── 📄 log_TIC_201_2026-08-26.csv                                                                    │
│   └── 🌐 Click_To_View_Chart.html (🌟 Double-click in browser: Multi-Loop & Multi-Date Interactive UI)│
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 What's New in Version 5

| Feature | Description |
|---|---|
| 🌐 **Offline USB Dashboard (`Click_To_View_Chart.html`)** | Standalone HTML5 Canvas SCADA viewer auto-generated in USB backup folder. Features 2 dropdowns (Loop Selector + Date Selector), summary KPI cards, and embedded Mitr Phol branding. |
| ⏱️ **Offline Real-Time Clock Persistence** | Built-in systemd services (`save-last-time`, `save-time-on-shutdown`) saving system clock every 20s. Eliminates time rollback to year 2019 on isolated industrial networks without NTP. |
| 🔢 **2-Way Synchronized Manual Output** | Full bidirectional sync between proportional slider and numeric input field with 0.0% – 100.0% boundary clamping and parameter lock bypass for operators. |
| 📑 **Corporate Engineering PDF Report** | Ink-efficient, high-contrast white background theme formatted for A4 landscape printing and official management audits. |
| 🛡️ **Storage Diversion Safety Guard** | Automatically diverts any accidental `/media/usb` logging paths to local internal eMMC `/opt/pid-tuning-app/logs/` to prevent log corruption when USB is detached. |
| 🕒 **Clean Universal Timestamps** | Formats all CSV logs and HTML tables cleanly as `YYYY-MM-DD HH:mm:ss` (Asia/Bangkok UTC+7), stripping milliseconds and ISO `T/Z` notations. |
| 🔌 **Multi-Filesystem USB Auto-Mounter** | Dedicated kernel helper script (`usb-mount-helper.sh`) supporting FAT32, NTFS (with dirty-flag clearing), and multi-partition flash drives. |

---

## 🛡️ 24/7 Industrial Stability System

The V5 release integrates a multi-layered stability shield designed for harsh plant environments:

1. **5-Minute Smart Idle Auto-Refresh:** Reloads the Kiosk browser when untouched for 5 minutes with locked parameters, completely wiping Chromium V8 heap memory to prevent long-term sluggishness.
2. **100ms (10Hz) Asynchronous PLC Polling:** High-speed, non-blocking DB communication loop ensuring rapid response without thread starvation.
3. **Canvas CPU Throttling (200ms / 5Hz):** UI charts update smoothly via `update('none')`, reducing CPU software rendering load by over 70%.
4. **Self-Healing Watchdog:** Background monitor (`kiosk-watchdog.service`) checks X11 display, Chromium, and Node.js every 10 seconds, auto-recovering failed services within 3 seconds.
5. **eMMC Disk Wear Protection:** Capped `systemd-journald` size at 100MB and mounted `/tmp` to `tmpfs` RAM disk to preserve flash memory longevity.

---

## 📊 Offline USB Dashboard & Analytics

When an operator clicks **"📥 Save Log to USB"** or when the midnight auto-backup triggers:
1. The USB drive is auto-mounted via `usb-mount-helper.sh`.
2. All historical `.csv` files are copied into `PID_Logs_Backup/YYYY-MM-DD/`.
3. `generate-usb-viewer.js` dynamically compiles and outputs **`Click_To_View_Chart.html`**.
4. The USB drive is synced and safely unmounted.

**Opening `Click_To_View_Chart.html` on any PC provides:**
* Dual dropdowns to select any PID Loop and historical date.
* Interactive zoomable Canvas trend graph (SP, PV, Output%).
* Automated statistics: Max PV, Min PV, Average PV, Average SP Error.
* Paginated tabular log sample preview.
* 1-Click Print / Save as PDF capability.

---

## ⚙️ OT Layer — PLC Control System

### Supported Controller & Algorithm
* **PLC:** Siemens S7-1200 (CPU 1214C / 1215C / 1217C)
* **PID Function Block:** Siemens `PIDCompact` (Technology Object V2.x)
* **Default Data Block:** `DB322` (Configurable via UI)

### Standard DB Memory Offsets
| Tag Name | Data Type | Default Offset | Description |
|---|---|---|---|
| `Setpoint` | Real (Float32) | `0.0` | Target Setpoint value |
| `ProcessValue` | Real (Float32) | `4.0` | Current Process Value (PV) |
| `Output` | Real (Float32) | `8.0` | Controller Output (0.0 – 100.0%) |
| `ManualValue` | Real (Float32) | `12.0` | Manual Output target |
| `ManualEnable` | Bool | `16.0` | Toggle Manual Mode |
| `Reset` | Bool | `16.1` | Fault Reset Command |
| `Gain` (Kp) | Real (Float32) | `18.0` | Proportional Gain |
| `Ti` | Real (Float32) | `22.0` | Integral Time (seconds) |
| `Td` | Real (Float32) | `26.0` | Derivative Time (seconds) |
| `State` | Int (Int16) | `30.0` | PID Controller State (0=Inactive, 3=Auto, 4=Manual) |
| `ErrorBits` | DWord (Word32) | `32.0` | Diagnostic Error Flags |

---

## 💻 Hardware & Software Requirements

### Hardware
* **Edge Gateway:** Siemens SIMATIC IOT2050 (Basic / Advanced)
* **Storage:** 16GB+ eMMC or High-Endurance MicroSD
* **PLC:** Siemens S7-1200 / S7-1500 with Ethernet interface
* **Touchscreen:** HDMI/DisplayPort 1080p Touch Monitor

### Software
* **OS:** Siemens Industrial OS / Debian 11/12 (ARM64)
* **Runtime:** Node.js v18.x or v20.x LTS
* **Browser:** Chromium in Kiosk mode with hardware acceleration flags

---

## 🚀 Deployment Guide

Deploying patches from your engineering PC to the IOT2050 is fully automated via PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\Deploy-Patch.ps1
```

### What `Deploy-Patch.ps1` executes:
1. Transfers core application files (`server.js`, `public/`, `src/`, `generate-usb-viewer.js`, `usb-mount-helper.sh`, `usb-unmount-helper.sh`).
2. Configures executable file permissions (`chmod +x`).
3. Executes `setup-247-stability.sh` to install systemd services and timers.
4. Gracefully restarts `pid-app.service` and `kiosk.service`.

---

<br>

---

# 🇹🇭 เอกสารภาษาไทย (Thai Version)

## 🌐 ภาพรวมระบบ (Overview)

**SIMATIC IOT2050 PID Tuning Application V5** เป็น Web Application อุตสาหกรรมแบบ Full-Stack ที่ทำงานบน **Siemens SIMATIC IOT2050 Edge Gateway** โดยตรง พัฒนาเพื่อ **โครงการควบคุมและตรวจสอบ Gate Valve ของโรงงาน Mitr Phol Pin Mill Plant** โดยเฉพาะ เชื่อมต่อตรงกับ **Siemens S7-1200 PLC** ผ่านพอร์ตแลนโรงงานแบบ Real-time ตลอด 24 ชม. 365 วัน

---

## 🌟 ฟีเจอร์เด่นในเวอร์ชัน 5 (V5 New Features)

### 1. 🌐 ระบบดูกราฟออฟไลน์ผ่าน USB (`Click_To_View_Chart.html`)
* เมื่อกดปุ่ม **"📥 Save Log to USB"** ระบบจะคัดลอกไฟล์ Log ทั้งหมดลง Flash Drive พร้อมสร้างไฟล์ Dashboard HTML ให้อัตโนมัติ
* **เปิดดูบนคอมพิวเตอร์เครื่องไหนก็ได้:** ดับเบิ้ลคลิกเปิดผ่าน Google Chrome / Microsoft Edge ได้ทันทีโดยไม่ต้องติดตั้งโปรแกรม Excel
* **2 Dropdown System:** เลือกดูข้อมูลแยกตาม Loop (เช่น `CV-101`, `TIC-201`) และเลือกดูตามวันที่ย้อนหลังได้ทุกไฟล์
* **สถิติ & กราฟ Interactive:** สรุปค่า Max/Min/Avg, ค่า Error, ตารางข้อมูล, และกราฟซูมเลื่อนเมาส์ดูค่าได้อย่างละเอียด พร้อมปุ่มพิมพ์รายงานออกทางเครื่องพิมพ์

### 2. ⏱️ ระบบจำเวลาออฟไลน์ (Offline Time Persistence)
* แก้ปัญหา IOT2050 ที่ไม่มีแบตเตอรี่ RTC และไม่มีสัญญาณอินเทอร์เน็ต/NTP ซึ่งในอดีตทำให้เวลาเด้งกลับไปปี 2019 เมื่อไฟดับ
* ติดตั้ง Service `save-last-time` บันทึกเวลาลงชิปทุก 20 วินาที และดึงเวลากลับมาทันทีตอนบูตเครื่อง เวลาจึงเดินต่อเนื่องเสมอ ไม่ข้ามวัน

### 3. 🔢 ควบคุม Manual Output แบบ 2-Way Sync
* รองรับทั้งการเลื่อน Slider หรือพิมพ์ตัวเลขในช่อง Manual Input โดยค่าทั้งสองจะขยับตามกันทันที
* มีระบบจำกัดขอบเขตความปลอดภัย 0.0% – 100.0% และปลดล็อกให้ Operator คีย์ตัวเลขสั่งงานได้ทันที

### 4. 📑 ส่งออกรายงาน PDF สไตล์วิศวกรรมมาตรฐาน (Corporate Theme)
* รายงานแบบ A4 แนวนอน พื้นหลังสีขาวสะอาดตา ปริ้นต์ง่าย ไม่เปลืองหมึก พร้อมกราฟความละเอียดสูงและตารางข้อมูลที่เป็นทางการ

### 5. 🛡️ ระบบป้องกันความปลอดภัย Storage Diversion Guard
* ป้องกันกรณีผู้ใช้เผลอตั้ง Path บันทึกลง `/media/usb` โดยระบบจะดักจับและเปลี่ยนมาเขียนลงหน่วยความจำ eMMC ของเครื่องอัตโนมัติ เพื่อป้องกันไฟล์เสียหายเมื่อถอด Flash Drive

---

## 🛡️ ระบบความเสถียร 24/7 (24/7 Industrial Stability)

1. **Smart IDLE Auto-Refresh (5 นาที):** รีเฟรชหน้าจอเบื้องหลังทุก 5 นาทีเมื่อไม่มีคนใช้งาน เพื่อคืน RAM ให้ระบบ ป้องกันอาการ Browser อืดหรือแรมรั่ว
2. **100ms (10Hz) High-Speed Real-Time Polling:** อ่านข้อมูลจาก PLC ด้วยความถี่ 10 ครั้ง/วินาที รวดเร็ว แม่นยำ
3. **Canvas CPU Throttling:** ปรับการวาดกราฟที่ความถี่ 200ms (5Hz) ช่วยลดภาระ CPU Rendering ลง 70% หน้าจอวิ่งลื่นไหลไม่กระตุก
4. **Self-Healing Watchdog:** ตรวจสอบทั้ง X11 Server, Chromium Kiosk และ Node.js ตลอด 24 ชม. หากมีจุดใดดับ จะกู้คืนกลับมาให้อัตโนมัติใน 3 วินาที
5. **eMMC Wear Protection:** จำกัดขนาด Log ของระบบ Linux ไม่เกิน 100MB และโยกย้ายไฟล์แคชชั่วคราวไปไว้บน RAM (tmpfs) เพื่อยืดอายุการใช้งานฮาร์ดแวร์

---

## 🚀 ขั้นตอนการ Deploy ขึ้น IOT2050

รันคำสั่งเดียวใน PowerShell:
```powershell
powershell -ExecutionPolicy Bypass -File .\Deploy-Patch.ps1
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    SIEMENS S7-1200 PLC (192.168.121.211)                    │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │ DB322: Non-Optimized Contiguous Struct (<240 Bytes = 1 Single PDU)    │  │
│  │  • Read: PV, SP, Output, Mode, Status, PLC_DateTime (DTL 12B)         │  │
│  │  • Write: CMD_Manual_Out, CMD_Mode, Heartbeat_In (Toggle Word)        │  │
│  ├───────────────────────────────────────────────────────────────────────┤  │
│  │ Safety Watchdog Logic (OB30 / 100ms Cyclic Interrupt):                │  │
│  │  • TON Timer (3.0s): ถ้า Heartbeat นิ่ง > 3s ➔ สั่ง Fallback Auto/Safe│  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────▲──────────────────────────────────────┘
                                       │
                        S7comm Protocol (TCP Port 102)
                   100ms Single PDU Read / 500ms Heartbeat
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                    SIEMENS SIMATIC IOT2050 (Debian Linux)                   │
│                                                                             │
│ ┌─────────────────────────────────────────────────────────────────────────┐ │
│ │ LAYER 1: HARDWARE & OS INTEGRITY GUARDS                                 │ │
│ │  • Hardware RTC (CR2032 Battery) + Startup PLC Clock Auto-Sync          │ │
│ │  • Linux Hardware Watchdog (/dev/watchdog via systemd 30s)              │ │
│ │  • eMMC Wear Guard: tmpfs (RAM Disk @ /tmp/pid_buffer)                  │ │
│ │  • Disk Full Guard: journald capped @ 100MB + Daily Gzip Logrotate      │ │
│ │  • udev Engine: Hotplug USB Auto-mount (FAT32, NTFS, exFAT)             │ │
│ └────────────────────────────────────┬────────────────────────────────────┘ │
│                                      │                                      │
│ ┌────────────────────────────────────▼────────────────────────────────────┐ │
│ │ LAYER 2: BACKEND CORE ENGINE (Node.js Event-Driven)                     │ │
│ │  • nodes7 Driver: 10Hz Single-PDU Polling + 500ms Deadman Heartbeat     │ │
│ │  • High-Speed Data Ingestion: Push 10Hz data into In-Memory Buffer      │ │
│ │  • Storage Engine: SQLite (WAL Mode) Flush ทุก 5 วินาที (Zero eMMC Wear)│ │
│ │  • WebSocket Gateway: Broadcast telemetry (PV, SP, Out, Comm_Status)    │ │
│ │  • Command Validator: 0-100% Clamping & Command Ack Echo                │ │
│ └────────────────────────────────────┬────────────────────────────────────┘ │
│                                      │                                      │
│ ┌────────────────────────────────────▼────────────────────────────────────┐ │
│ │ LAYER 3: INDUSTRIAL KIOSK HMI (Client-Side Chromium)                    │ │
│ │  • High-Perf WebGL/Canvas Chart: Fixed Circular Buffer (600 Points/1min)│ │
│ │  • Zero Memory Leak: ไม่ต้อง Reload หน้าจอ (รันต่อเนื่อง 24/7 ไม่ค้าง)   │ │
│ │  • 2-Way Interlocked Controls: Manual Slider + Input + Echo Verification│ │
│ │  • Client-Side PDF Generator (jsPDF): เรนเดอร์บน Browser ไม่กิน CPU บอร์ด│ │
│ │  • Disconnect Safety Banner: แจ้งเตือนสีแดงทันทีถ้า Network ขาด > 1 วิ  │ │
│ └─────────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                        Midnight Timer / 1-Click Export
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                  USB FLASH DRIVE / MITR PHOL ERP-SCADA                      │
│       • Daily Auto-Export: Compressed CSV (/media/usb/logs_YYYYMMDD.csv.gz) │
│       • Engineering Step Test PDF Report (High-Contrast Mitr Phol Theme)   │
└─────────────────────────────────────────────────────────────────────────────┘


---

### 👨‍💻 ผู้พัฒนาและดูแลระบบ (Developer & Maintainer)
* **ผู้พัฒนา:** Dream Piyapong ([@xFreedom777](https://github.com/xFreedom777))
* **GitHub Repository:** [SIMATIC-IOT2050-PID-TUNING-APPLICATION-V5](https://github.com/xFreedom777/SIMATIC-IOT2050-PID-TUNING-APPLICATION-V5)
* **โรงงาน:** Mitr Phol Pin Mill Plant (Gate Valve Control Project)
