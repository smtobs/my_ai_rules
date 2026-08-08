# 19000N MCR 빌드 가이드

> **관련 문서**: [[CODING_STYLE]] · [[CALL_FLOW]] · [[APPLY_MCR_PLATFORM_SYNC]]  
> **AI skill**: `.cursor/skills/mcr-platform/SKILL.md`

---

## 경로

| | 절대 경로 |
|---|-----------|
| **작업 (cursor)** | `/home2/bsoh/nonplume/0714/cursor/linux-mediatek_mt7988/` |
| **빌드 overlay** | `/home2/bsoh/nonplume/0714/mcr_platform/mt7988-0002-mediatek-package-folder/` |
| **OpenWrt 빌드 루트** | `/home2/bsoh/nonplume/0714/mt7988/` (예시 — 실제 TOPDIR 사용) |

WiFi overlay: `PKG_MCR_SOURCE:=mcr_mt_wifi7_20250226` (`mtk/drivers/mt_wifi7/Makefile`)

---

## 전체 흐름

```
cursor 패치 → mcr_platform copy → 빌드 → flash → 장비 검증
```

1. `linux-mediatek_mt7988/` 에서 MCR 패치 작성 ([[CODING_STYLE]] 참고)
2. 수정 파일만 `mcr_platform` overlay에 copy ([[APPLY_MCR_PLATFORM_SYNC]])
3. 아래 **빌드 명령** 실행
4. 커널 모듈 + WiFi 모듈 flash
5. **장비 검증** (`dmesg`, `kallsyms`)

---

## clean 이 필요한가?

| 상황 | 전체 `make clean` | 필요한 작업 |
|------|-------------------|-------------|
| `.c` 소스만 수정 (이번 warm reboot 패치) | **불필요** | 패키지/커널 **부분 재빌드** |
| Kconfig / `.config` 변경 | 경우에 따라 | `make kernel_menuconfig` 후 linux 재빌드 |
| Makefile / patch / tarball 변경 | 권장 | 해당 패키지 `clean` |
| overlay만 수정 (`mcr_mt_wifi7_20250226/`) | 불필요 | **`mt_wifi7` package clean 필수** |

### OpenWrt가 rebuild를 스킵하는 이유

| 대상 | OpenWrt stamp 추적 | `.c`만 바꾸면 `make V=s`만으로 재빌드? |
|------|-------------------|----------------------------------------|
| **커널** (`linux-5.4.281/`) | config, Makefile, patch | **⚠️ 스킵될 수 있음** → `target/linux/compile` 명시 |
| **mt_wifi7** | PKG_SOURCE tarball | **⚠️ overlay는 tarball 밖** → `package/mt_wifi7/clean` 필수 |

---

## 권장 빌드 명령

OpenWrt TOPDIR에서 실행 (`cd /home2/bsoh/nonplume/0714/mt7988` 등).

### 표준 (MCR 패치 반영 후)

```bash
# 1) WiFi overlay 반영분 재빌드
make package/mt_wifi7/clean

# 2) 커널 소스 패치 반영 (pcie-mediatek-gen3 등)
make target/linux/compile V=s

# 3) 전체 firmware (또는 WiFi만)
make V=s
# 또는 WiFi만:
# make package/mt_wifi7/compile V=s
```

### WiFi만 빠르게 (커널 패치 없을 때)

```bash
make package/mt_wifi7/clean
make package/mt_wifi7/compile V=s
```

### 커널만 (WiFi 패치 없을 때)

```bash
make target/linux/compile V=s
```

---

## 변경 파일별 rebuild 대상

| cursor 소스 | overlay 대상 | 재빌드 대상 | 산출물 |
|-------------|--------------|-------------|--------|
| `linux-5.4.281/drivers/pci/controller/pcie-mediatek-gen3.c` | 동일 경로 | `target/linux/compile` | `pcie-mediatek-gen3.ko` |
| `mt_wifi7/mt_wifi/hw_ctrl/hwifi_main.c` | `mcr_mt_wifi7_20250226/mt_wifi/hw_ctrl/` | `package/mt_wifi7/clean compile` | `mt_wifi.ko` |
| `mt_wifi7/wlan_hwifi/chips/mt7990/mt7990.c` | `mcr_mt_wifi7_20250226/wlan_hwifi/chips/mt7990/` | `package/mt_wifi7/clean compile` | `mt7990.ko` |

> `mt_wifi7` Build/Compile 시 `mcr_mt_wifi7_20250226/*` → `build_dir/.../mt_wifi7/` 로 copy 후 kbuild.

---

## flash 주의

커널 + WiFi **둘 다** 올려야 warm reboot 패치가 완전히 동작한다.

- 커널: `mtk_trigger_whole_chip_reset` kallsyms export (`pcie-mediatek-gen3.ko`)
- WiFi: `[MCR]` 로그, chip reset 경로 (`hwifi_main.c`, `mt7990.c`)

한쪽만 flash하면 kallsyms lookup 실패 또는 `[MCR]` 로그 미출력 가능.

---

## overlay 반영 확인 (copy 후)

```bash
DST=/home2/bsoh/nonplume/0714/mcr_platform/mt7988-0002-mediatek-package-folder
OVR=$DST/mtk/drivers/mt_wifi7/mcr_mt_wifi7_20250226

grep -c 'mtk_trigger_whole_chip_reset\|mcr_pcie_wifi_reset_port' \
  $DST/linux-5.4.281/drivers/pci/controller/pcie-mediatek-gen3.c

grep -c '\[MCR\]' $OVR/mt_wifi/hw_ctrl/hwifi_main.c
grep '\[MCR\] CBTOP_GPIO' $OVR/wlan_hwifi/chips/mt7990/mt7990.c
```

---

## 장비 검증

```bash
# kallsyms export 확인
grep mtk_trigger_whole_chip_reset /proc/kallsyms

# MCR 로그
dmesg | grep '\[MCR\]'

# warm reboot 후 인터페이스 (3-band: ra0/rax0/rai0 등)
dmesg | grep physical_device_add_mac_adapter
```

---

## 하지 말 것

- 전체 `make clean` (불필요하게 오래 걸림)
- `make V=s`만 실행하고 `target/linux/compile` / `mt_wifi7/clean` 생략
- overlay를 `mcr_mt_wifi7_20251204/`에만 copy하고 `20250226` 누락
- cursor 전체 디렉토리 rsync

---

## AI pack

| 종류 | 경로 |
|------|------|
| 코딩 스타일 (rule) | `.cursor/rules/19000N_proj/CODING_STYLE.mdc` |
| apply / 빌드 (skill) | `.cursor/skills/mcr-platform/SKILL.md` |
| Flow (rule) | `.cursor/rules/19000N_proj/CALL_FLOW.mdc` |

원본: `my_ai_rules/` (rules + skills)

---

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-08-08 | MCR 패치 후 부분 rebuild 가이드 (kernel skip, mt_wifi7 overlay clean) |
