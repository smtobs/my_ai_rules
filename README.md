# my_ai_rules

바이브 코딩을 위한 Cursor Project Rules 모음

## Rules

| 파일 | 설명 |
|------|------|
| [rules/eyl_enc_rules.mdc](rules/eyl_enc_rules.mdc) | EYL ENC C 코딩 스타일 (`mcr_` 네이밍, 블록 주석) |

## 사용법

### 1. 프로젝트에 복사

```bash
mkdir -p .cursor/rules
curl -o .cursor/rules/eyl_enc_rules.mdc \
  https://raw.githubusercontent.com/smtobs/my_ai_rules/main/rules/eyl_enc_rules.mdc
```

### 2. Cursor Remote Rule (GitHub 연동)

1. Cursor → **Settings** → **Rules**
2. **+ New** → **Remote Rule (GitHub)**
3. URL 입력: `https://github.com/smtobs/my_ai_rules`

## eyl_enc_rules 적용 대상

- `**/*.c`, `**/*.h`, `**/Makefile`
