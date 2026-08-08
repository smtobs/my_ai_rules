# 19000N 프로젝트 코딩 스타일

> AI rule: `.cursor/rules/19000N_proj/CODING_STYLE.mdc`  
> call flow: [[CALL_FLOW]]  
> apply / 빌드: skill `mcr-platform` · [[BUILD_GUIDE]] · [[APPLY_MCR_PLATFORM_SYNC]]

---

## MCR 패치 (MediaTek SDK)

원본 코드 삭제·리팩터 금지. `#if` / `#else` 로 MCR 수정분과 원본을 공존시킨다.

### 매크로

| 영역 | 매크로 | enable |
|------|--------|--------|
| Linux kernel | `CONFIG_MCR_PLATFORM` | Kconfig / `.config` |
| WiFi driver | `MCR_WIRELESS_EXTEND` | `config_ap.mk` 또는 `wlan_hwifi/Makefile` (`CONFIG_MCR_PLATFORM=y` 시) |

### Driver 형식

```c
#if defined(MCR_WIRELESS_EXTEND)
	/* 2026.08.08 - warm reboot GPIO strap 진단 */
	dev_info(dev->dev, "[MCR] CBTOP_GPIO raw=0x%08x\n", val);
#else // MCR_WIRELESS_EXTEND
	/* 원본 코드 */
#endif // MCR_WIRELESS_EXTEND
```

MCR-only (원본에 대응 없음):

```c
#if defined(MCR_WIRELESS_EXTEND)
	MTWF_PRINT("[MCR] mtk_mac_chip_reset: chip_id=0x%x\n", chip_id);
#endif // MCR_WIRELESS_EXTEND
```

### Kernel 형식

boot 경로는 원본 유지. runtime 추가만 `#ifdef CONFIG_MCR_PLATFORM` 로 감싼다.

```c
#ifdef CONFIG_MCR_PLATFORM
static struct mtk_pcie_port *mcr_pcie_wifi_reset_port;

bool mtk_trigger_whole_chip_reset(unsigned int chip_id)
{
	dev_info(port->dev, "[MCR] whole chip reset (chip_id=0x%x)\n", chip_id);
	/* wifi-reset GPIO pulse */
}
EXPORT_SYMBOL(mtk_trigger_whole_chip_reset);
#endif // CONFIG_MCR_PLATFORM
```

### 규칙 요약

| 항목 | 규칙 |
|------|------|
| `#if` | driver: `#if defined(MCR_WIRELESS_EXTEND)` |
| `#else` / `#endif` | `// MCR_WIRELESS_EXTEND` 또는 `// CONFIG_MCR_PLATFORM` 주석 필수 |
| `#if` 위 주석 | **한글** 한 줄 (날짜·이슈, 기술 용어 영문 OK) |
| 네이밍 | kernel MCR **내부** static → `mcr_` / SDK export → `mtk_*` 유지 |
| MCR 로그 | `MTWF_PRINT` / `dev_info` / `pr_warn` + **`[MCR]`** tag |
| 확인 | `dmesg \| grep '\[MCR\]'` |

### 하지 말 것

- 원본 삭제 후 MCR만 남기기
- `#if !defined(MCR_WIRELESS_EXTEND)` 로 MCR/원본 순서 뒤바꾸기
- SDK 전체 파일을 `#if` 로 감싸기
- 기존 SDK 심볼 rename

---

## 기본

| 항목 | 규칙 |
|------|------|
| 들여쓰기 | 탭, K&R 중괄호 |
| 네이밍 | 신규 → `mcr_` |
| 반환값 | 성공 `0`, 실패 `-1` |
| 수정 범위 | grep 후 요청 범위만 |

---

## 함수 주석 (모든 함수 필수)

신규 `mcr_` 코드 및 MCR로 추가하는 함수.

```c
/**
 *	NAME	: mcr_sendPayload
 * ----------------------------------------------------------------------------
 *	RANGE	: public
 *	PARAM
 *			@param sock : [in] 연결 fd
 *			@param data : [in] payload
 *			@param len  : [in] payload 길이
 *			@return : 0 - 성공, -1 - 실패
 *	NOTE
 *			와이어 포맷: [uint32_be len][payload]
 */
```

| 필드 | 규칙 |
|------|------|
| RANGE | `public` (.h), `private` (static) |
| PARAM | `[in]` / `[out]` / `[in,out]` + 한 줄 설명 |
| NOTE | wire format, 암호화, 버퍼 제한 등 **불명확할 때만** |

---

## 함수 내부 주석

의미 있는 **단계마다** 바로 위에 작성.

| 상황 | 형식 |
|------|------|
| 한 줄 | `/* 설명 */` |
| 여러 줄·TODO·제약 | `/*` … `*/` 블록 |

```c
/* 대상 서버 TCP 연결 */
if (mcr_senderConnect(host, port, &sock) != 0)
	return -1;

/*
 * payload 길이 검증
 * - 0 또는 MCR_MAX_PAYLOAD 초과 시 거부
 */
if (payload_len == 0 || payload_len > MCR_MAX_PAYLOAD)
	return -1;
```

- 분기/반복/초기화/정리 등 **단계가 바뀔 때** 추가
- skip 조건, TODO, 알려진 제약 → **여러 줄 블록**
- `i = 0`, `close(sock)` 등 **자명한 코드** → 생략

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
| 2026-08-08 | MCR 패턴, kernel/driver 매크로, `[MCR]` 로그, 슬림화 (주석 규칙 유지) |
