# EYL ENC 코딩 스타일

> Cursor rule: `.cursor/rules/eyl_enc_proj/CODING_STYLE.mdc`  
> call flow 문서: [[CALL_FLOW]]

코드 작성·수정 시 적용하는 C 코딩 규칙.

---

## 기본

| 항목 | 규칙 |
|------|------|
| 들여쓰기 | **탭** |
| 중괄호 | K&R (`if (x) {`) |
| 네이밍 | 함수/타입/매크로 → **`mcr_` 접두사** |
| 반환값 | 성공 `0`, 실패 `-1` |
| 로그 | `[sender]`, `[receiver]` 등 tag 접두사 |
| 수정 범위 | grep으로 유사 코드 확인 후, 요청 범위만 수정 |

---

## 파일 헤더 (모든 .c / .h)

```c
/*
 * 파일 한 줄 설명.
 *
 * Usage: (해당 시)
 *   ./binary [args]
 */
```

---

## 함수 블록 주석 (모든 함수 필수)

```c
/**
 *	NAME	: mcr_sendPayload
 * ----------------------------------------------------------------------------
 *	RANGE	: public
 *	PARAM
 *			@param sock : [in] 연결된 소켓 fd
 *			@param data : [in] 전송할 payload
 *			@param len : [in] payload 길이
 *			@return : 0 - 성공, -1 - 실패
 *	NOTE
 *			와이어 포맷: [uint32_be len][payload]
 */
```

| 필드 | 값 |
|------|-----|
| RANGE | `public` (.h), `private` (static) |
| PARAM | `[in]` / `[out]` / `[in,out]` + 한 줄 설명 |
| NOTE | wire format, 암호화, 버퍼 제한 등 **불명확할 때만** |

---

## 함수 내부 주석

의미 있는 **단계마다** 바로 위에 주석.

| 상황 | 형식 |
|------|------|
| 한 줄 | `/* 설명 */` 또는 `// 설명` |
| 여러 줄 | `/*` … `*/` 블록 |

### 한 줄 예시

```c
/* 대상 서버 TCP 연결 */
if (mcr_senderConnect(host, port, &sock) != 0)
	return -1;
```

### 여러 줄 예시

```c
/*
 * payload 길이 검증
 * - 0 또는 MCR_MAX_PAYLOAD 초과 시 거부
 * - buf cap보다 큰 경우 거부 (버퍼 오버플로 방지)
 */
if (payload_len == 0 || payload_len > MCR_MAX_PAYLOAD ||
    payload_len > cap)
	return -1;
```

### 달지 않는 경우

- `i = 0`, `close(sock)` 등 **자명한 코드**

---

## 네이밍 예시

| 종류 | 예시 |
|------|------|
| 함수 | `mcr_sendPayload`, `mcr_receiverInit` |
| 타입 | `mcr_crypto_t` |
| 매크로 | `MCR_DEFAULT_HOST`, `MCR_MAX_PAYLOAD` |
| 외부 API | `eyl_initmodule` — **sample.c 참조, 리네임 금지** |

---

## Rule pack

| Rule | 경로 | 용도 |
|------|------|------|
| 코딩 스타일 | `.cursor/rules/eyl_enc_proj/CODING_STYLE.mdc` | 코드 작성 **중** |
| Flow 문서 | `.cursor/rules/eyl_enc_proj/CALL_FLOW.mdc` | [[CALL_FLOW]] 갱신 |

출처: `~/my_ai_rules/rules/eyl_enc_proj/`

---

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-08-07 | 초안 작성 |
| 2026-08-07 | rules/eyl_enc_proj/ 구조 반영 |
