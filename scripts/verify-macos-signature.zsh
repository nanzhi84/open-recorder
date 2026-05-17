#!/bin/zsh

set -euo pipefail

bundle_dir="${1:-}"
expected_team_id="${APPLE_TEAM_ID:-}"
swift_binary="$bundle_dir/Contents/MacOS/OpenRecorderMac"
frameworks_rpath="@executable_path/../Frameworks"

if [[ -z "$bundle_dir" || ! -d "$bundle_dir" ]]; then
	print -u2 -- "Usage: zsh scripts/verify-macos-signature.zsh PATH_TO_APP"
	exit 2
fi

binary_has_rpath() {
	local binary="$1"
	local expected_rpath="$2"

	otool -l "$binary" | awk '
		$1 == "cmd" && $2 == "LC_RPATH" { in_rpath = 1; next }
		in_rpath && $1 == "path" { print $2; in_rpath = 0 }
	' | grep -Fxq "$expected_rpath"
}

verify_sparkle_linkage() {
	if [[ ! -f "$swift_binary" ]]; then
		print -u2 -- "App executable not found: $swift_binary"
		exit 1
	fi

	if ! otool -L "$swift_binary" | grep -Fq "@rpath/Sparkle.framework/"; then
		return
	fi

	if [[ ! -d "$bundle_dir/Contents/Frameworks/Sparkle.framework" ]]; then
		print -u2 -- "OpenRecorderMac links Sparkle.framework, but Contents/Frameworks/Sparkle.framework is missing."
		exit 1
	fi

	if ! binary_has_rpath "$swift_binary" "$frameworks_rpath"; then
		print -u2 -- "OpenRecorderMac links Sparkle.framework, but is missing rpath: $frameworks_rpath"
		exit 1
	fi
}

signature_details="$(codesign -dv --verbose=4 "$bundle_dir" 2>&1)"
print -- "$signature_details"

codesign --verify --strict --verbose=2 "$bundle_dir"
verify_sparkle_linkage

if print -- "$signature_details" | grep -Fq "Signature=adhoc"; then
	print -u2 -- "Expected a Developer ID signature, got an ad-hoc signature."
	exit 1
fi

if ! print -- "$signature_details" | grep -Fq "Authority=Developer ID Application:"; then
	print -u2 -- "Expected a Developer ID Application authority."
	exit 1
fi

if [[ -n "$expected_team_id" ]] && ! print -- "$signature_details" | grep -Fq "TeamIdentifier=$expected_team_id"; then
	print -u2 -- "Expected TeamIdentifier=$expected_team_id."
	exit 1
fi

print -- "Verified Developer ID signature for $bundle_dir"
