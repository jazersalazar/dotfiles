#!/usr/bin/env bash

# Picks the next quote for quote.sh to type out. Spawned detached by quote.sh
# whenever the cache goes stale, so it is free to be slow. It writes the cache
# exactly once per run in every outcome: the file is "<epoch ms>\n<quote>\n", the
# timestamp doubling as the animation's origin, and an empty second line tells
# quote.sh to fall back to its built-in quote.
# Always leaving a fresh timestamp behind is what stops a failed run from being
# retried on every status redraw.
#
# Byte-wise pattern matching, so the non-ASCII check below cannot be fooled by
# the locale's collation order.
LC_ALL=C
set -u

readonly CACHE="${1:?usage: quote-rotate.sh <cache-file>}"
readonly LOCK="$CACHE.lock"
readonly HISTORY="$CACHE.history"
readonly CORPUS="${BASH_SOURCE[0]%/*}/quotes.txt"
# How many recent quotes to keep out of the rotation.
readonly HISTORY_MAX=10
# Longer quotes make the typewriter cycle drag on for minutes.
readonly MAX_LEN=100

mkdir -p "${CACHE%/*}" 2>/dev/null || exit 0

# Atomic create: if another run is already going, leave it to it.
set -C
: > "$LOCK" 2>/dev/null || exit 0
set +C
trap 'rm -f "$LOCK"' EXIT

corpus=$CORPUS
[[ -r $corpus ]] || corpus=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/quotes.txt

quote=''
pool=()
if [[ -r $corpus ]]; then
  recent=''
  [[ -r $HISTORY ]] && recent=$(<"$HISTORY")
  while IFS= read -r line; do
    [[ -z ${line// } || $line == '#'* ]] && continue
    ((${#line} > MAX_LEN)) && continue
    # Non-ASCII would break the byte-counted padding in quote.sh.
    case $line in *[!\ -~]*) continue ;; esac
    # Skip anything still inside the no-repeat window.
    [[ $'\n'$recent$'\n' == *$'\n'"$line"$'\n'* ]] && continue
    pool+=("$line")
  done < "$corpus"

  # Every usable quote has been shown recently: clear the window and start over.
  if ((${#pool[@]} == 0)); then
    : > "$HISTORY"
    while IFS= read -r line; do
      [[ -z ${line// } || $line == '#'* ]] && continue
      ((${#line} > MAX_LEN)) && continue
      case $line in *[!\ -~]*) continue ;; esac
      pool+=("$line")
    done < "$corpus"
  fi

  ((${#pool[@]} > 0)) && quote=${pool[RANDOM % ${#pool[@]}]}
fi

if [[ -n $quote ]]; then
  printf '%s\n' "$quote" >> "$HISTORY"
  # Trim the window to its last HISTORY_MAX entries.
  if kept=$(tail -n "$HISTORY_MAX" "$HISTORY"); then
    printf '%s\n' "$kept" > "$HISTORY.new" && mv -f "$HISTORY.new" "$HISTORY"
  fi
fi

# Milliseconds, from the same bash builtin quote.sh reads, so the animation can
# start from the moment the quote was installed. See the note there about why
# `date` is not used for this.
now=$(( ${EPOCHREALTIME/[.,]/} / 1000 ))
printf '%s\n%s\n' "$now" "$quote" > "$CACHE.new" && mv -f "$CACHE.new" "$CACHE"
