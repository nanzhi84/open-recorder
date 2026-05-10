#!/bin/zsh

set -euo pipefail

usage() {
	cat <<'EOF'
Usage: zsh scripts/create-macos-release-artifacts.zsh --app PATH --output-dir DIR --artifact-stem NAME

Creates a ZIP and compressed DMG for a macOS .app bundle.
EOF
}

app_path=""
output_dir=""
artifact_stem=""
volume_name="${OPEN_RECORDER_DMG_VOLUME_NAME:-Open Recorder}"

while (( $# > 0 )); do
	case "$1" in
		--app)
			(( $# >= 2 )) || { print -u2 -- "--app requires a value"; exit 2; }
			app_path="$2"
			shift 2
			;;
		--output-dir)
			(( $# >= 2 )) || { print -u2 -- "--output-dir requires a value"; exit 2; }
			output_dir="$2"
			shift 2
			;;
		--artifact-stem)
			(( $# >= 2 )) || { print -u2 -- "--artifact-stem requires a value"; exit 2; }
			artifact_stem="$2"
			shift 2
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			print -u2 -- "Unknown argument: $1"
			usage >&2
			exit 2
			;;
	esac
done

if [[ -z "$app_path" || -z "$output_dir" || -z "$artifact_stem" ]]; then
	usage >&2
	exit 2
fi

if [[ ! -d "$app_path" ]]; then
	print -u2 -- "App bundle not found: $app_path"
	exit 1
fi

if ! command -v hdiutil >/dev/null 2>&1; then
	print -u2 -- "Missing required command: hdiutil"
	exit 1
fi

mkdir -p "$output_dir"

zip_path="$output_dir/${artifact_stem}.zip"
dmg_path="$output_dir/${artifact_stem}.dmg"
dmg_root="$(mktemp -d)"
trap 'rm -rf "$dmg_root"' EXIT

rm -f "$zip_path" "$dmg_path"
ditto -c -k --sequesterRsrc --keepParent "$app_path" "$zip_path"

ditto "$app_path" "$dmg_root/$(basename "$app_path")"
ln -s /Applications "$dmg_root/Applications"
hdiutil create \
	-volname "$volume_name" \
	-srcfolder "$dmg_root" \
	-ov \
	-format UDZO \
	"$dmg_path" >/dev/null

print -- "Created $zip_path"
print -- "Created $dmg_path"
