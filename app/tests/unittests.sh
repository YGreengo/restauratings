#!/usr/bin/env bash
set -euo pipefail

BASE="http://172.17.0.1:80"
API="${BASE}/api"

# ── Simple HTTP helper ─────────────────────────────────────────────────────────
# Returns "<body>\n<code>"
function request() {
  local method=$1 url=$2 data=${3:-}
  if [[ -n $data ]]; then
    curl -s -X "$method" \
         -H "Content-Type:application/json" \
         -d "$data" \
         "$url" \
         -w $'\n'%{http_code}
  else
    curl -s "$url" -w $'\n'%{http_code}
  fi
}

# ── Fail helper ────────────────────────────────────────────────────────────────
function fail() {
  echo "error $1"
  echo "    Response:"
  echo "$resp" | sed 's/^/      /'
  exit 1
}

echo "Restaurant API smoke tests"
echo "=============================="

# ── 1) Health check ─────────────────────────────────────────────────────────────
echo -n "Health: "
resp=$(request GET "$BASE/health")
code=${resp##*$'\n'}; body=${resp%$'\n'*}
[[ $code -eq 200 && $body == *healthy* ]] || fail "Health failed (expected 200 + healthy)"
echo "OK"

# ── 2) Create a random “Test Cafe” ──────────────────────────────────────────────
echo -n "Create Test Cafe: "
payload=$(
  cat <<EOF
{"name":"Smoke Test Cafe",
 "address":"123 Random St, Tel Aviv, Israel",
 "latitude":32.0850,
 "longitude":34.7800,
 "style":"cafe",
 "description":"A lovely test cafe for smoke testing",
 "phone":"+972-3-999-9999",
 "website":"https://testcafe.example.com"}
EOF
)
resp=$(request POST "$API/restaurants" "$payload")
code=${resp##*$'\n'}; body=${resp%$'\n'*}
[[ $code -eq 201 ]] || fail "Create failed (expected 201)"
REST_ID=$(grep -Po '"id"\s*:\s*"\K[^"]+' <<< "$body")
[[ -n $REST_ID ]] || fail "No id returned"
echo "OK (id=$REST_ID)"

# ── 3) Read back by ID ─────────────────────────────────────────────────────────
echo -n "Read Test Cafe: "
resp=$(request GET "$API/restaurants/$REST_ID")
code=${resp##*$'\n'}; body=${resp%$'\n'*}
[[ $code -eq 200 && $body == *"Smoke Test Cafe"* ]] || fail "Read failed (expected 200 + Smoke Test Cafe)"
echo "OK"

# ── 4) Delete it ────────────────────────────────────────────────────────────────
echo -n "Delete Test Cafe: "
resp=$(request DELETE "$API/restaurants/$REST_ID")
code=${resp##*$'\n'}; body=${resp%$'\n'*}
[[ $code -eq 200 ]] || fail "Delete failed (expected 200)"
echo "OK"

echo
echo "All smoke tests passed!"
exit 0
