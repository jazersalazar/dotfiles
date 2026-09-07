#!/usr/bin/env bash
#
# Render a URL or a local HTML file in headless Chrome and write a PNG.
#
# Usage:
#   js-screenshot.sh <url|file> <output.png> [width] [height]
#
#   js-screenshot.sh https://stgxjs.wpenginepowered.com/ /tmp/nav.png 1440 320
#   js-screenshot.sh harness.html /tmp/widget.png 375 800
#
# Why this exists: the browser is the Windows Chrome under /mnt/c, reached from
# WSL. Invoking chrome.exe straight from bash returns before Chrome has finished
# — the interop parent detaches — so the next command looks for the PNG while
# Chrome is still starting and finds nothing, which reads exactly like a failed
# render. Going through Start-Process -Wait blocks until Chrome exits.
#
# Every run gets its own --user-data-dir and removes it afterwards, so a run
# that outlives its shell can't hold the profile and silently break the next
# one. Write the harness and the PNG to a temp directory, never into a repo.

set -euo pipefail

CHROME='C:\Program Files\Google\Chrome\Application\chrome.exe'

if [ $# -lt 2 ]; then
	sed -n '3,10p' "$0" >&2
	exit 64
fi

target=$1
out=$2
width=${3:-1440}
height=${4:-900}

if [ ! -e "$(dirname "$out")" ]; then
	echo "screenshot: output directory does not exist: $(dirname "$out")" >&2
	exit 66
fi

# A local file has to reach Chrome as a Windows path: \\wsl.localhost\... as a
# file:// URL with forward slashes. Anything with a scheme is passed through.
case $target in
	*://*)
		url=$target
		;;
	*)
		if [ ! -f "$target" ]; then
			echo "screenshot: no such file: $target" >&2
			exit 66
		fi
		url="file:///$(wslpath -w "$(readlink -f "$target")" | tr '\\' '/')"
		;;
esac

# Chrome writes the PNG itself, so the destination also has to be a Windows
# path. It may not exist yet, hence resolving the directory and appending.
out_dir=$(cd "$(dirname "$out")" && pwd)
out_win="$(wslpath -w "$out_dir")\\$(basename "$out")"

profile="C:\\Users\\$(powershell.exe -NoProfile -Command 'Write-Output $env:USERNAME' | tr -d '\r')\\AppData\\Local\\Temp\\js-shot-$$"

# Single quotes are the PowerShell string delimiter, so double any in the
# arguments rather than letting them end the string.
psquote() { printf "%s" "$1" | sed "s/'/''/g"; }

# Chrome will not open a window narrower than ~500px: ask for 375 and it lays
# the page out at ~526 and clips the image to 375, which looks exactly like a
# site overflowing its viewport. Media queries inside an iframe evaluate
# against the iframe, so that is the way to render a real phone width.
if [ "$width" -lt 500 ]; then
	cat >&2 <<-WARN
	screenshot: WARNING — Chrome clamps windows to ~500px wide, so a $width px
	  window renders at ~526px and clips. The layout you get is NOT $width px.
	  For a true narrow viewport, point this at a wrapper page instead:
	    <iframe src="page.html" width="$width" height="1200" scrolling="no"></iframe>
	  and screenshot the wrapper at a width above 500.
	WARN
fi

rm -f "$out"

powershell.exe -NoProfile -Command "
	\$ErrorActionPreference = 'Stop'
	try {
		Start-Process -FilePath '$(psquote "$CHROME")' -ArgumentList @(
			'--headless=new',
			'--disable-gpu',
			'--hide-scrollbars',
			'--window-size=$width,$height',
			'--user-data-dir=$(psquote "$profile")',
			'--screenshot=$(psquote "$out_win")',
			'$(psquote "$url")'
		) -Wait -NoNewWindow
	} finally {
		Remove-Item -LiteralPath '$(psquote "$profile")' -Recurse -Force -ErrorAction SilentlyContinue
	}
" >/dev/null 2>&1 || true

if [ ! -s "$out" ]; then
	echo "screenshot: Chrome produced no image for $url" >&2
	echo "screenshot: if headless runs are stuck, clear only those with:" >&2
	echo "  powershell.exe -NoProfile -Command \"Get-CimInstance Win32_Process -Filter \\\"Name='chrome.exe'\\\" | Where-Object { \\\$_.CommandLine -like '*--headless*' } | ForEach-Object { Stop-Process -Id \\\$_.ProcessId -Force }\"" >&2
	exit 70
fi

echo "$out"
