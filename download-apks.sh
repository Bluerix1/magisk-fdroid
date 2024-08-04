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

echo '' > urls.txt
fdroid_url="$(curl --silent https://f-droid.org/en/packages/org.fdroid.fdroid/ | grep --only-matching --perl-regexp 'https://f-droid.org/repo/org.fdroid.fdroid_\d+.apk' | sort --reverse | head -n 1)"
version=$(echo "$fdroid_url" | grep -oP '(?<=_)\d+(?=.apk)')
if [ -z "$fdroid_url" ]; then
  echo "Error: fdroid_url is empty"
  exit 1
fi
if [ -z "$version" ]; then
  echo "Error: version is empty"
  exit 1
fi
echo "fdroid_url: $fdroid_url"
echo "version: $version"
echo "$fdroid_url" >> urls.txt

fdroid_ext_url="$(curl --silent https://f-droid.org/en/packages/org.fdroid.fdroid.privileged/ | grep --only-matching --perl-regexp 'https://f-droid.org/repo/org.fdroid.fdroid.privileged_.+.apk' | sort --reverse | head -n 1)"
if [ -z "$fdroid_ext_url" ]; then
  echo "Error: fdroid_ext_url is empty"
  exit 1
fi
echo "fdroid_ext_url: $fdroid_ext_url"
echo "$fdroid_ext_url" >> urls.txt

rm -f ./system/app/*.apk || true
aria2c -i urls.txt -d system/app -j 10 -x 10

# Produce metadata
echo '' > module.prop
# shellcheck disable=SC2129
echo "id=fdroid_system_app_installer" >> module.prop
echo "name=Fdroid System App Installer" >> module.prop
echo "versionCode=${version}" >> module.prop
echo "author=Frank_Lan" >> module.prop
echo "description=This module installs F-Droid as a system app." >> module.prop

cat module.prop
