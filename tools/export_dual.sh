#!/bin/bash
# Campus Days — multi-platform export procedure (documented, repeatable).
# ONE project, THREE separate builds (user decision, fix round item 6):
#   Windows .exe -> Forward+ (the PC version: desktop controls/quality,
#                   no mobile UI behaviour at all)
#   Web demo     -> GL Compatibility (secondary demo)
#   Android .apk -> GL Compatibility + the preset's "mobile" feature tag
#                   (the separate mobile version: touch layer + mobile
#                   quality defaults activate only in this build)
#
# The project file on disk ALWAYS stays on GL Compatibility (the web-safe
# renderer), so the web/Android exports and the editor default never
# break. This script temporarily flips the project to Forward+ for the
# Windows export only, then restores Compatibility for the other two.
#
# Usage:  bash tools/export_dual.sh
# Output: build/windows/CampusDays.exe + .pck, build/web/index.html + .pck,
#         build/android/CampusDays.apk, plus a RENDERER.txt in each dir
#         recording what shipped.
# Android needs the SDK/JDK + debug keystore configured in the Godot
# editor settings (see PHASES.md, fix round item 6); if they are missing
# the Android step reports the blocker and the PC/web exports still ship.
# Safety: the original project.godot is backed up and restored on ANY exit
# (trap), so a failed export can never leave the project on Forward+.
# GitHub rejects single files over 100 MB; the script aborts if any
# exported file exceeds that limit (the ~1 GB export-templates .tpz and
# tool downloads are never inside build/ and are gitignored).

set -u
cd "$(dirname "$0")/.." || exit 1
GODOT="${GODOT:-$HOME/workspace/tools/godot/Godot_v4.3-stable_linux.x86_64}"

if ! grep -q '^renderer/rendering_method="gl_compatibility"' project.godot; then
	echo "ABORT: project.godot is not on gl_compatibility — refusing to guess."
	echo "Restore it first (it must read: renderer/rendering_method=\"gl_compatibility\")."
	exit 1
fi

cp project.godot .project.godot.phase5.bak
restore() { mv -f .project.godot.phase5.bak project.godot 2>/dev/null || true; }
trap restore EXIT

echo "=== Windows export (Forward+) ==="
sed -i 's/^renderer\/rendering_method="gl_compatibility"/renderer\/rendering_method="forward_plus"/' project.godot
grep '^renderer/rendering_method=' project.godot
"$GODOT" --headless --export-release "Windows Desktop" build/windows/CampusDays.exe
printf 'renderer=forward_plus\nbuild=Windows Desktop (release)\nexported=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > build/windows/RENDERER.txt

restore
trap - EXIT
echo "=== project.godot restored to: ==="
grep '^renderer/rendering_method=' project.godot

echo "=== Web export (GL Compatibility) ==="
"$GODOT" --headless --export-release "Web" build/web/index.html
printf 'renderer=gl_compatibility\nbuild=Web (release, threads off)\nexported=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > build/web/RENDERER.txt

echo "=== Android export (GL Compatibility, separate mobile build) ==="
# apksigner is a shell script that shells out to `java` — the JDK must
# be on PATH or the export silently produces an UNSIGNED apk.
if [ -d "$HOME/workspace/tools/jdk17/bin" ]; then
	export JAVA_HOME="$HOME/workspace/tools/jdk17"
	export PATH="$JAVA_HOME/bin:$PATH"
fi
mkdir -p build/android
if "$GODOT" --headless --export-release "Android" build/android/CampusDays.apk; then
	printf 'renderer=gl_compatibility\nbuild=Android (release, mobile feature tag, touch layer + Low default quality)\nexported=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > build/android/RENDERER.txt
else
	echo "ANDROID EXPORT FAILED in this environment — PC/Web builds unaffected."
	echo "Record the exact blocker in PHASES.md (fix round item 6); do not fake an APK."
fi

echo "=== Size check (GitHub 100 MB single-file limit) ==="
oversize="$(find build/windows build/web build/android -type f -size +100M -print)"
if [ -n "$oversize" ]; then
	echo "ABORT: files over 100 MB:"
	echo "$oversize"
	exit 1
fi
ls -la build/windows/ build/web/ build/android/
echo "EXPORTS DONE: Windows=Forward+ (PC), Web=GL Compatibility (demo), Android=GL Compatibility (mobile, if SDK present)."
