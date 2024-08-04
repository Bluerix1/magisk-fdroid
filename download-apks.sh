#!/usr/bin/env bash
set -eo pipefail
cd "$(dirname "$0")" || exit 1

if [ -z "${CI:-}" ] && [ -f '.env' ]; then
  source .env
fi

# Use gnu utils if available
if [ -d "/opt/homebrew/opt/grep/libexec/gnubin" ]; then
  PATH="/opt/homebrew/opt/grep/libexec/gnubin:$PATH"
fi

getReleaseUrls() {
  local owner repo apiUrl githubAuthArg regex result
  if [[ -n "$GH_TOKEN" ]]; then
    githubAuthArg="-u tlan16:$GH_TOKEN"
  fi

  owner="$1"
  repo="$2"
  regex="$(echo "$3" | xargs)"
  apiUrl="https://api.github.com/repos/$owner/$repo/releases/latest"
  # shellcheck disable=SC2086
  result="$(curl --fail --silent $githubAuthArg "$apiUrl")"
  result="$(echo "$result" | grep browser_)"
  result="$(echo "$result" | cut -d\" -f4)"
  if [[ -n "$regex" ]]; then
    result="$(echo "$result" | grep --perl-regexp "$regex")"
  fi
  echo "$result" | head -n 1
}

url=$(getReleaseUrls "f-droid" "fdroidclient" 'org\.fdroid\.fdroid_.+.apk')
version=$(echo "$url" | grep -oP '(?<=_)\d+(?=.apk)')
if [ -z "$url" ]; then
  echo "Error: url is empty"
  exit 1
fi
if [ -z "$version" ]; then
  echo "Error: version is empty"
  exit 1
fi
echo "url: $url"
echo "version: $version"

rm -f ./system/app/*.apk || true
aria2c "$url" -d system/app -j 10 -x 10

echo '' > module.prop
# shellcheck disable=SC2129
echo "id=fdroid_system_app_installer" >> module.prop
echo "name=Fdroid System App Installer" >> module.prop
echo "versionCode=${version}" >> module.prop
echo "author=hc841" >> module.prop
echo "description=This module installs F-Droid as a system app." >> module.prop

cat module.prop
