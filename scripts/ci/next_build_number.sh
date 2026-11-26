#!/usr/bin/env bash
# 다음 빌드 번호를 정해 출력한다. (Codemagic에서 실행)
#
#   사용법: scripts/ci/next_build_number.sh ios|android
#
# 규칙: pubspec.yaml의 빌드 번호(+ 뒤 숫자)와 "스토어에 이미 올라간 가장 큰 번호 + 1" 중 큰 값.
#   - TestFlight 배포와 스토어 제출이 같은 버전을 각각 빌드해도 번호가 겹치지 않는다. (겹치면 업로드 거절)
#   - 스토어 번호를 못 읽으면(처음 · 설정 전) pubspec 번호를 그대로 쓴다.
set -u
platform="${1:-ios}"
pubspec_build=$(grep -E '^version:' pubspec.yaml | sed -E 's/.*\+([0-9]+).*/\1/')
latest=0

if [ "$platform" = "ios" ] && [ -n "${APP_STORE_APPLE_ID:-}" ]; then
  latest=$(app-store-connect get-latest-testflight-build-number "$APP_STORE_APPLE_ID" 2>/dev/null || echo 0)
elif [ "$platform" = "android" ] && [ -n "${GCLOUD_SERVICE_ACCOUNT_CREDENTIALS:-}" ]; then
  latest=$(google-play get-latest-build-number --package-name "${PACKAGE_NAME:-com.maeumbook.maeum_book}" 2>/dev/null || echo 0)
fi
case "$latest" in ''|*[!0-9]*) latest=0 ;; esac

next=$((latest + 1))
if [ "$pubspec_build" -gt "$next" ]; then next=$pubspec_build; fi
echo "$next"
