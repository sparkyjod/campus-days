#!/bin/bash
# Campus Days — Phase 5 dual-renderer export procedure (documented, repeatable).
#
# The project file on disk ALWAYS stays on GL Compatibility (the web-safe
# renderer), so the web demo and the editor default never break. This script
# temporarily flips the project to Forward+ for the Windows export only,
# then restores Compatibility and exports the web demo:
#   Windows  -> Forward+ (SDFGI + bloom, see main.gd _build_environment)
#   Web      -> GL Compatibility (ColorRect colour grade, see _build_ui)
#
# Usage:  bash tools/export_dual.sh
# Output: build/windows/CampusDays.exe + .pck, build/web/index.html + .pck,
#         plus a RENDERER.txt in each dir recording what shipped.
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

echo "=== Size check (GitHub 100 MB single-file limit) ==="
oversize="$(find build/windows build/web -type f -size +100M -print)"
if [ -n "$oversize" ]; then
	echo "ABORT: files over 100 MB:"
	echo "$oversize"
	exit 1
fi
ls -la build/windows/ build/web/
echo "DUAL EXPORT DONE: Windows=Forward+, Web=GL Compatibility."
