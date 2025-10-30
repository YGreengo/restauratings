#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://http://172.17.0.1:80}"

# ── HTTP helper: returns "<body>\n<code>"
request() {
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

# ── on fail: show resp + exit
fail() {
  echo "error $1"
  echo "    Response:"
  echo "$resp" | sed 's/^/      /'
  exit 1
}

echo "Simple E2E Smoke Tests"
echo "=========================="

# 1) Health
echo -n "Health: "
resp=$(request GET "$BASE_URL/health")
code=${resp##*$'\n'}; body=${resp%$'\n'*}
[[ $code -eq 200 && $body == *healthy* ]] || fail "Health check failed (expected 200 + healthy)"
echo "OK"

# 2) Create
echo -n "Create restaurant: "
payload='{"name":"E2E Cafe","address":"123 Test St","latitude":32.0,"longitude":34.0,"style":"cafe","description":"E2E smoke test"}'
resp=$(request POST "$BASE_URL/api/restaurants" "$payload")
code=${resp##*$'\n'}; body=${resp%$'\n'*}
[[ $code -eq 201 ]] || fail "Create failed (expected 201)"
ID=$(grep -Po '"id"\s*:\s*"\K[^"]+' <<<"$body")
[[ -n $ID ]] || fail "No id in create response"
echo "OK (id=$ID)"

# 3) Read
echo -n "Read by id: "
resp=$(request GET "$BASE_URL/api/restaurants/$ID")
code=${resp##*$'\n'}; body=${resp%$'\n'*}
[[ $code -eq 200 && $body == *"E2E Cafe"* ]] || fail "Read failed (expected 200 + E2E Cafe)"
echo "OK"

# 4) Delete
echo -n "Delete: "
resp=$(request DELETE "$BASE_URL/api/restaurants/$ID")
code=${resp##*$'\n'}; body=${resp%$'\n'*}
[[ $code -eq 200 ]] || fail "Delete failed (expected 200)"
echo "OK"

echo
echo "All E2E smoke tests passed!"
exit 0
