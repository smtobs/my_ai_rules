# 19000N MCR overlay 동기화

> **관련 문서**: [[CODING_STYLE]] · [[BUILD_GUIDE]]  
> **AI skill**: `.cursor/skills/mcr-platform/SKILL.md`

---

## 언제

`linux-mediatek_mt7988/` 아래 **MCR 패치를 마친 뒤**, 실제 빌드 트리(`mcr_platform`)에 반영할 때.  
**수정한 소스 파일만** copy — 전체 디렉토리 sync 금지.

---

## 경로

| | 절대 경로 |
|---|-----------|
| **작업 (cursor)** | `/home2/bsoh/nonplume/0714/cursor/linux-mediatek_mt7988/` |
| **빌드 overlay** | `/home2/bsoh/nonplume/0714/mcr_platform/mt7988-0002-mediatek-package-folder/` |

---

## WiFi overlay (빌드에 실제 사용)

`mtk/drivers/mt_wifi7/Makefile`:

```makefile
PKG_MCR_SOURCE:=mcr_mt_wifi7_20250226
```

Build/Compile 시 `$(PKG_MCR_SOURCE)/*` → `build_dir/mt_wifi7/` 로 copy.  
**driver 패치 copy 대상 = `mcr_mt_wifi7_20250226/`** (20251204 아님).

---

## 대상별 copy 규칙

| cursor 소스 | mcr_platform 대상 |
|-------------|-------------------|
| `linux-5.4.281/**` | `linux-5.4.281/**` (동일 상대 경로) |
| `mt_wifi7/mt_wifi/**` | `mtk/drivers/mt_wifi7/mcr_mt_wifi7_20250226/mt_wifi/**` |
| `mt_wifi7/wlan_hwifi/**` | `mtk/drivers/mt_wifi7/mcr_mt_wifi7_20250226/wlan_hwifi/**` |

- kernel: `#ifdef CONFIG_MCR_PLATFORM` 패치
- driver: `#if defined(MCR_WIRELESS_EXTEND)` 패치
- overlay에 **파일 없으면** `mkdir -p` 후 copy

---

## 절차

1. 이번 작업에서 **변경된 파일 목록**만 확정 (git diff / grep `2026.` / `[MCR]` / `CONFIG_MCR_PLATFORM`)
2. 위 매핑表로 대상 경로 계산 (`mcr_mt_wifi7_20250226`)
3. `cp` 로 **해당 파일만** overwrite
4. marker grep으로 반영 확인

```bash
DST=/home2/bsoh/nonplume/0714/mcr_platform/mt7988-0002-mediatek-package-folder
grep -E '\[MCR\]|CONFIG_MCR_PLATFORM|2026\.08' "$DST/<copied-file>"
```

---

## 빌드 흐름

1. `mt_wifi7` compile → `mcr_mt_wifi7_20250226/*` overlay copy
2. `wlan_hwifi` compile → `build_dir/mt_wifi7/wlan_hwifi/` (overlay 반영본 사용)

copy 완료 후 → [[BUILD_GUIDE]]

---

## 하지 말 것

- `cursor/linux-mediatek_mt7988` 전체를 mcr_platform에 rsync
- `docs/`, `.cursor/` 를 mcr_platform에 copy
- 수정 없는 SDK 원본 파일 copy
- **`mcr_mt_wifi7_20251204/`에만 copy하고 20250226 누락**

---

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-08-08 | overlay copy 규칙 (20250226), skill로 이전 |
