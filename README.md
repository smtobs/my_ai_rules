# my_ai_rules

바이브 코딩을 위한 Cursor Project Rules 모음

GitHub: https://github.com/smtobs/my_ai_rules

## 디렉터리 구조

```
my_ai_rules/
├── install.sh
├── rules/
│   └── eyl_enc_proj/          ← 프로젝트별 rule pack
│       ├── CODING_STYLE.mdc       (코딩 스타일)
│       └── CALL_FLOW.mdc          (flow 문서 작성)
└── docs/
    ├── CODING_STYLE.md        ← Obsidian용
    └── CALL_FLOW.template.md
```

rule 파일명 = docs 파일명과 동일 (`.md` ↔ `.mdc`)

---

## Rules (eyl_enc_proj)

| 파일 | 용도 | 적용 시점 |
|------|------|-----------|
| `CODING_STYLE.mdc` | C 코딩 스타일 (`mcr_` 네이밍, 주석) | 코드 작성 **중** |
| `CALL_FLOW.mdc` | call flow 문서 작성 | 코드 **완료 후** |

---

## 사용법

### 1. install.sh (권장)

```bash
git clone https://github.com/smtobs/my_ai_rules.git ~/my_ai_rules
~/my_ai_rules/install.sh /path/to/your/project
```

설치 결과:

```
your-project/
├── .cursor/rules/eyl_enc_proj/
│   ├── CODING_STYLE.mdc
│   └── CALL_FLOW.mdc
└── docs/
    ├── CODING_STYLE.md
    └── CALL_FLOW.md
```

### 2. Cursor Remote Rule (GitHub)

1. Cursor → **Settings** → **Rules**
2. **+ New** → **Remote Rule (GitHub)**
3. URL: `https://github.com/smtobs/my_ai_rules`

### 3. 수동 복사

```bash
mkdir -p .cursor/rules/eyl_enc_proj docs
cp ~/my_ai_rules/rules/eyl_enc_proj/*.mdc .cursor/rules/eyl_enc_proj/
cp ~/my_ai_rules/docs/CODING_STYLE.md docs/
```

---

## Rule 역할

```
코드 작성 중  →  CODING_STYLE.mdc  ↔  docs/CODING_STYLE.md
코드 완료 후  →  CALL_FLOW.mdc      →  docs/CALL_FLOW.md (Mermaid)
```
