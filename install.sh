#!/bin/bash
# my_ai_rules → 프로젝트에 rules/docs 설치
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-.}"
RULE_PKG="${2:-eyl_enc_proj}"

SRC_RULES="$REPO_DIR/rules/$RULE_PKG"
DST_RULES="$TARGET/.cursor/rules/$RULE_PKG"

if [ ! -d "$SRC_RULES" ]; then
	echo "error: rules pack not found: $SRC_RULES" >&2
	echo "usage: $0 [target_dir] [rule_pack]" >&2
	exit 1
fi

mkdir -p "$DST_RULES" "$TARGET/docs"

cp "$SRC_RULES/"*.mdc "$DST_RULES/"
cp "$REPO_DIR/docs/CODING_STYLE.md" "$TARGET/docs/"

if [ ! -f "$TARGET/docs/CALL_FLOW.md" ]; then
	cp "$REPO_DIR/docs/CALL_FLOW.template.md" "$TARGET/docs/CALL_FLOW.md"
	echo "Created docs/CALL_FLOW.md from template"
else
	echo "docs/CALL_FLOW.md already exists — skipped"
fi

echo "Installed pack '$RULE_PKG' to $TARGET:"
echo "  .cursor/rules/$RULE_PKG/CODING_STYLE.mdc"
echo "  .cursor/rules/$RULE_PKG/CALL_FLOW.mdc"
echo "  docs/CODING_STYLE.md"
