---
name: mcr-platform
description: Applies MCR patches from cursor to mcr_platform overlay, builds OpenWrt firmware (sysupgrade), partial packages/daemons, kernel and mt_wifi7, and verifies on device. Use when the user asks to apply, sync, copy overlay, build, compile, firmware, daemon, flash, or verify MCR/19000N/MT7988 WiFi kernel patches.
---

# MCR Platform Workflow

19000N MT7988 MCR 패치: **패치 → overlay copy → 빌드 → 검증**

상세 문서:
- overlay copy → [docs/19000N_proj/APPLY_MCR_PLATFORM_SYNC.md](../../docs/19000N_proj/APPLY_MCR_PLATFORM_SYNC.md)
- 빌드 → [docs/19000N_proj/BUILD_GUIDE.md](../../docs/19000N_proj/BUILD_GUIDE.md)
- 코딩 규칙 → rule `CODING_STYLE.mdc` / [docs/19000N_proj/CODING_STYLE.md](../../docs/19000N_proj/CODING_STYLE.md)

## 경로

| | 절대 경로 |
|---|-----------|
| cursor 작업 | `/home2/bsoh/nonplume/0714/cursor/linux-mediatek_mt7988/` |
| mcr_platform overlay | `/home2/bsoh/nonplume/0714/mcr_platform/mt7988-0002-mediatek-package-folder/` |
| OpenWrt TOPDIR | `/home2/bsoh/nonplume/0714/mt7988/` (실제 빌드 루트) |

WiFi overlay: `PKG_MCR_SOURCE:=mcr_mt_wifi7_20250226` (**20251204 아님**)

## Checklist

```
- [ ] 1. 변경 파일 목록 확정 (git diff / grep [MCR] / CONFIG_MCR_PLATFORM)
- [ ] 2. mcr_platform overlay copy (수정 파일만)
- [ ] 3. copy marker grep 확인
- [ ] 4. 빌드 (firmware: kmod reset + mt_wifi7/clean + target/linux/compile + make V=s)
- [ ] 5. flash (sysupgrade.bin 또는 커널 + WiFi 모듈)
- [ ] 6. 장비 검증 (kallsyms, dmesg [MCR])
```

## Step 1–2: overlay copy

| cursor | mcr_platform |
|--------|--------------|
| `linux-5.4.281/**` | 동일 상대 경로 |
| `mt_wifi7/mt_wifi/**` | `mtk/drivers/mt_wifi7/mcr_mt_wifi7_20250226/mt_wifi/**` |
| `mt_wifi7/wlan_hwifi/**` | `mtk/drivers/mt_wifi7/mcr_mt_wifi7_20250226/wlan_hwifi/**` |
| (데몬) `apps/<pkg>/` | `mcr_platform/apps/<pkg>/` (Step 4b) |

```bash
SRC=/home2/bsoh/nonplume/0714/cursor/linux-mediatek_mt7988
DST=/home2/bsoh/nonplume/0714/mcr_platform/mt7988-0002-mediatek-package-folder
OVR=$DST/mtk/drivers/mt_wifi7/mcr_mt_wifi7_20250226

# 예: 수정 파일만 cp (mkdir -p 후 overwrite)
cp "$SRC/<rel-path>" "$DST/<rel-path>"
```

**하지 말 것:** 전체 rsync, `20251204`에만 copy, docs/rules copy

## Step 3: verify copy

```bash
grep -E '\[MCR\]|CONFIG_MCR_PLATFORM|mtk_trigger_whole_chip_reset' "$DST/<copied-file>"
```

## Step 4: build

### 빌드 의도 분기 (에이전트)

| 사용자 요청 | 실행 |
|-------------|------|
| **「빌드해줘」** (별도 지정 없음) | **firmware image** (sysupgrade) — 아래 기본 명령 |
| 「firmware 빌드해줘」「sysupgrade」 | firmware image |
| 「`<pkg>`만 빌드해줘」「데몬만」 | **package 부분 빌드** — 아래 Step 4b |
| 「커널/WiFi만」「모듈만 flash」 | 모듈 빌드 (firmware·kmod reset **생략**) |

**기본 = firmware.** 「빌드해줘」만으로 모듈-only·oldconfig 실행하지 않는다.

**`make clean` 불필요.** `make V=s`만으로는 커널·WiFi 스킵 가능.

| 변경 파일 | rebuild |
|-----------|---------|
| `pcie-mediatek-gen3.c` | `target/linux/compile` |
| `hwifi_main.c`, `wlan_hwifi/.../mt7990.c` | `package/mt_wifi7/clean compile` |
| `mcr_platform/apps/<pkg>/` | `package/<pkg>/clean compile` (Step 4b) |

### Firmware image (sysupgrade.bin) — **기본 빌드**

**산출물** (`bin/targets/mediatek/mt7988/`):

| 프로필 | 파일 |
|--------|------|
| dsa-10g | `openwrt-mediatek-mt7988-mediatek_mt7988a-dsa-10g-spim-nand-squashfs-sysupgrade.bin` |
| gsw-10g | `openwrt-mediatek-mt7988-mediatek_mt7988a-gsw-10g-spim-nand-squashfs-sysupgrade.bin` |

#### vermagic 불일치 (package/install 실패)

`target/linux/compile` 후 커널 config hash(vermagic)가 바뀌면, **7월 등 구버전 `kmod-*.ipk`** 가 새 kernel ipk와 맞지 않아 `package/install` 실패:

```
cannot find dependency kernel (= 5.4.281-1-<old-hash>) for kmod-...
```

**해결:** 커널 재빌드 후 kmod ipk + rootfs stamp 정리 → `make V=s`로 kmod 전체 재빌드.

```bash
TOPDIR=/home2/bsoh/nonplume/0714/mt7988
rm -f $TOPDIR/bin/targets/mediatek/mt7988/packages/kmod-*.ipk
rm -f $TOPDIR/staging_dir/target-aarch64_cortex-a53_musl/stamp/.package_install
rm -rf $TOPDIR/staging_dir/target-aarch64_cortex-a53_musl/root-*
```

#### 하지 말 것 (firmware 빌드)

| 금지 | 이유 |
|------|------|
| `make oldconfig` | `CONFIG_EXTERNAL_KERNEL_TREE`를 비워 vanilla kernel tarball 추출 → MCR overlay·`.config` merge 깨짐 |
| `target/linux/install` 단독 실행 | 위와 같이 build_dir kernel이 tarball로 교체될 수 있음 |

`.config` 필수값 (`.config.old` 참고):

```
CONFIG_EXTERNAL_KERNEL_TREE="$(TOPDIR)/package/linux-5.4.281"
```

#### build_dir 복구 (oldconfig/tarball 추출 후)

```bash
TOPDIR=/home2/bsoh/nonplume/0714/mt7988
cp $TOPDIR/.config.old $TOPDIR/.config
KBD=$TOPDIR/build_dir/target-aarch64_cortex-a53_musl/linux-mediatek_mt7988
rm -rf "$KBD/linux-5.4.281"
ln -s "$TOPDIR/package/linux-5.4.281" "$KBD/linux-5.4.281"
```

#### pcie built-in (=y) 주의

`CONFIG_PCIE_MEDIATEK_GEN3=y` → `target/linux/compile`의 `modules` 타깃만으로는 pcie 재링크 안 됨. vmlinux/Image 필요 시 OpenWrt 경로로 재빌드하거나 firmware `make V=s` 사용.

### Agent 실행 규칙 (토큰 절약)

`make V=s` 로그는 수만 줄 → **터미널/Read로 전체 읽지 않는다.** 30분 대기 자체는 토큰을 거의 쓰지 않음.

1. 로그를 파일로 리다이렉트 (`build_logs/`)
2. **백그라운드** 실행 (`block_until_ms: 0`) — 완료 알림까지 대기
3. 빌드 중 **반복 폴링·출력 Read 금지**
4. **성공** (exit 0): exit code만 보고, 로그 파일 읽지 않음
5. **실패** (exit ≠ 0): `tail -100` + `grep -iE 'error:|fatal|failed|Collected errors' | tail -30` 만

**하지 말 것:** 터미널 stdout 전체 수집, 성공 시 로그 분석, 중간 진행률 확인용 Read

### 빌드 명령 — firmware image (**「빌드해줘」 기본**)

```bash
TOPDIR=/home2/bsoh/nonplume/0714/mt7988
LOGDIR=$TOPDIR/build_logs
mkdir -p "$LOGDIR"
TS=$(date +%Y%m%d_%H%M%S)
LOG="$LOGDIR/mcr_firmware_$TS.log"

cd "$TOPDIR" && {
  echo "=== prep: vermagic/kmod reset ==="
  rm -f bin/targets/mediatek/mt7988/packages/kmod-*.ipk
  rm -f staging_dir/target-aarch64_cortex-a53_musl/stamp/.package_install
  rm -rf staging_dir/target-aarch64_cortex-a53_musl/root-*

  echo "=== mt_wifi7/clean ==="
  make package/mt_wifi7/clean

  echo "=== target/linux/compile ==="
  make target/linux/compile V=s

  echo "=== make V=s (firmware) ==="
  make V=s
} > "$LOG" 2>&1
echo $? > "${LOG}.exit"
```

성공 시 `${LOG}.exit` = 0, `bin/targets/mediatek/mt7988/*sysupgrade*.bin` 타임스탬프 갱신 확인.

## Step 4b: package / daemon 부분 빌드

「`mcr-watchdog`만 빌드해줘」「데몬만」 등 **지정 패키지만** 빌드. firmware·kmod reset·`make V=s` **하지 않음**.

### 패키지 경로

| 소스 (overlay) | OpenWrt make 타깃 |
|----------------|-------------------|
| `mcr_platform/apps/<pkg>/` | `package/<pkg>/compile` |
| feed 예: `mcr-watchdog`, `mcr-connmon`, `mcr-goahead-public` | `make package/mcr-watchdog/compile V=s` |

`package/feeds/mcr_platform/` 아래 pkg — OpenWrt는 **`package/<pkg>/`** 로 invoke.

### 절차

1. 사용자가 지정한 `<pkg>` 목록 확정 (복수 가능)
2. 소스 수정 시 overlay copy (`mcr_platform/apps/<pkg>/`)
3. 해당 패키지만 `clean` + `compile` (Makefile/tarball 변경 시 clean)

### Agent 실행 규칙

firmware와 동일 — 로그 파일 + 백그라운드. **`make V=s`·kmod reset 금지.**

### 빌드 명령 — package only

`<pkg>`를 사용자 지정값으로 치환 (예: `mcr-watchdog mcr-connmon`).

```bash
TOPDIR=/home2/bsoh/nonplume/0714/mt7988
LOGDIR=$TOPDIR/build_logs
mkdir -p "$LOGDIR"
TS=$(date +%Y%m%d_%H%M%S)
LOG="$LOGDIR/mcr_pkg_${TS}.log"
PKGS="mcr-watchdog"   # ← 사용자 지정

cd "$TOPDIR" && {
  for pkg in $PKGS; do
    echo "=== package/$pkg/clean ==="
    make package/$pkg/clean
    echo "=== package/$pkg/compile ==="
    make package/$pkg/compile V=s
  done
} > "$LOG" 2>&1
echo $? > "${LOG}.exit"
```

**산출물:** `bin/packages/aarch64_cortex-a53/<pkg>/*.ipk` 또는 `bin/targets/.../packages/<pkg>_*.ipk`

소스만 살짝 바뀌고 Makefile 안 바뀌었으면 `clean` 생략 가능 — 사용자/변경 범위에 따라 판단.

### 빌드 명령 — 모듈만 (명시적 요청 시)

```bash
TOPDIR=/home2/bsoh/nonplume/0714/mt7988
LOGDIR=$TOPDIR/build_logs
mkdir -p "$LOGDIR"
TS=$(date +%Y%m%d_%H%M%S)
LOG="$LOGDIR/mcr_build_$TS.log"

cd "$TOPDIR" && {
  echo "=== mt_wifi7/clean ==="
  make package/mt_wifi7/clean
  echo "=== target/linux/compile ==="
  make target/linux/compile V=s
  echo "=== make V=s ==="
  make V=s
} > "$LOG" 2>&1
echo $? > "${LOG}.exit"
```

에이전트: 위를 **한 번에 백그라운드**로 실행 → 완료 후 `${LOG}.exit` 만 확인.

실패 시에만:

```bash
tail -100 "$LOG"
grep -iE 'error:|fatal|failed|Collected errors' "$LOG" | tail -30
```

## Step 5–6: flash & verify

커널 + WiFi **둘 다** flash.

```bash
grep mtk_trigger_whole_chip_reset /proc/kallsyms
dmesg | grep '\[MCR\]'
```
