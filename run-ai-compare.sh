#!/usr/bin/env bash
# Хэрэглээ (repo-ийн root-оос, Git Bash/Linux):  bash ai/run-ai-compare.sh
# AI-ийн тестийг түр хуулбар төсөл дээр 2 хувилбар кодын эсрэг ажиллуулна:
#   BUGGY = score > 60 (анхны алдаатай код), FIXED = score >= 60 (одоогийн код)
# Гаралт: ai/ai-results.txt  (src/test болон үндсэн results/-д НӨЛӨӨЛӨХГҮЙ)
set -u
ROOT="$(pwd)"
OUT="$ROOT/ai/ai-results.txt"
TMP="$(mktemp -d)"
SRC=src/main/java/mn/edu/must/sqat/ScholarshipCalculator.java
TST=src/test/java/mn/edu/must/sqat
: > "$OUT"

run_variant() {
  local label="$1" mode="$2"
  rm -rf "$TMP/p" && mkdir -p "$TMP/p/$TST"
  cp "$ROOT/pom.xml" "$TMP/p/" && cp -r "$ROOT/src/main" "$TMP/p/src/"
  cp "$ROOT/ai/AiScholarshipCalculatorTest.java.txt" "$TMP/p/$TST/AiScholarshipCalculatorTest.java"
  if [ "$mode" = "buggy" ]; then
    sed -i 's/if (score >= 60) return "D";/if (score > 60)  return "D";/' "$TMP/p/$SRC"
  fi
  echo "== $label ==" | tee -a "$OUT"
  grep -n 'return "D"' "$TMP/p/$SRC" | tee -a "$OUT"
  ( cd "$TMP/p" && mvn verify 2>&1 ) > "$TMP/$label.log"
  grep -E "Tests run:.*Fail|BUILD|FAILURE\]|expected:" "$TMP/$label.log" | tee -a "$OUT"
  CSV="$TMP/p/target/site/jacoco/jacoco.csv"
  if [ -f "$CSV" ]; then
    awk -F, 'NR==2{printf "BRANCH_MISSED=%s BRANCH_COVERED=%s LINE_MISSED=%s LINE_COVERED=%s\n",$6,$7,$8,$9}' "$CSV" | tee -a "$OUT"
    cp "$CSV" "$ROOT/ai/ai-jacoco-$label.csv"
  else
    echo "jacoco.csv үүсээгүй (тест унасан)" | tee -a "$OUT"
  fi
  echo | tee -a "$OUT"
}

run_variant buggy buggy
run_variant fixed fixed
