#!/usr/bin/env bash

# Types one clause of the quote out a character at a time, holds it, erases it,
# then moves to the next clause. The script is re-run on every status redraw and
# keeps no state: the frame is derived entirely from the wall clock, so any
# redraw rate produces the same animation.
#
# The text comes from a cache that quote-rotate.sh refills in the background from
# quotes.txt, keeping recent quotes out of the rotation. A pass through the whole
# quote ends by asking for the next one, so no quote is typed out twice in a row.
# This path falls back to FALLBACK_QUOTE whenever the cache is absent, empty or
# unwritten, and spawns no subprocess in the steady state, which matters at twenty
# renders a second.

readonly FALLBACK_QUOTE='Make it work, make it right, make it fast.'
readonly CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/tmux/quote"
# Milliseconds per typed character, per erased character, how long a finished
# clause is held, and the cursor blink period. Every value must be a multiple of
# the ticker's sleep in tmux.conf (50ms), or a character is held for an uneven
# number of redraws and the typing looks jittery. TYPE_MS is two ticks per
# character, so 10 characters a second; erasing runs a tick per character.
readonly TYPE_MS=100
readonly ERASE_MS=50
readonly HOLD_MS=2000
readonly BLINK_MS=400
# Shown while typing and erasing, and blinking while a clause is held. Keep it
# and the quote ASCII: the padding below counts bytes, not characters, so a
# multi-byte glyph would shorten the field and jitter the status bar.
readonly CURSOR='_'
# The field is always exactly this wide, whatever the quote, so the clock and the
# window list beside it never shift. Raising it widens the clauses too; keep it
# under status-right-length (100) minus the clock segment, and inside the
# narrowest terminal you use.
readonly WIDTH=56
# Anything longer is split again at a word boundary so it still fits the field.
readonly MAX_CLAUSE=$((WIDTH - ${#CURSOR}))

# Milliseconds since the epoch. EPOCHREALTIME is a bash builtin with a fixed
# six-digit fraction, so this needs no subprocess. Do not switch to
# `date +%s%3N`: this box ships uutils coreutils, whose date ignores the %3N
# width and returns a variable-length nanosecond field, which made the frame
# jump to a random point in the animation on every redraw.
now=$(( ${EPOCHREALTIME/[.,]/} / 1000 ))

# Cache layout is "<epoch milliseconds>\n<quote>\n", the timestamp being when the
# quote was installed, which is also the animation's origin. A file read costs no
# subprocess.
quote=$FALLBACK_QUOTE
stamp=0
if [[ -s $CACHE ]]; then
  { read -r stamp; read -r cached; } < "$CACHE"
  case $stamp in '' | *[!0-9]*) stamp=0 ;; esac
  [[ -n ${cached:-} ]] && quote=$cached
fi

# A quote that fits the field is typed out whole. Only when it does not fit is it
# broken at its punctuation marks, and only a clause that still does not fit is
# broken again at a word boundary.
segments=()
push() {
  local text=$1 head
  while ((${#text} > MAX_CLAUSE)); do
    head=${text:0:MAX_CLAUSE}
    if [[ ${text:MAX_CLAUSE:1} != ' ' && $head == *' '* ]]; then
      head=${head% *}
    fi
    segments+=("$head")
    text=${text:${#head}}
    text=${text# }
  done
  [[ -n $text ]] && segments+=("$text")
}

if ((${#quote} <= MAX_CLAUSE)); then
  segments+=("$quote")
else
  buf=''
  for ((i = 0; i < ${#quote}; i++)); do
    ch=${quote:i:1}
    buf+=$ch
    case $ch in
      [,.\;:!?])
        buf=${buf#"${buf%%[![:space:]]*}"}
        push "$buf"
        buf=''
        ;;
    esac
  done
  buf=${buf#"${buf%%[![:space:]]*}"}
  [[ -n $buf ]] && push "$buf"
fi

# How long one pass over every clause takes.
cycle=0
for seg in "${segments[@]}"; do
  ((cycle += ${#seg} * TYPE_MS + HOLD_MS + ${#seg} * ERASE_MS))
done

# The quote has been typed out and erased once, so ask for the next one. The
# rotator takes a lock and stamps the cache whether or not it finds a quote, so
# this cannot turn into a spawn per redraw. The child is fully detached because
# tmux reads this script's stdout until every writer closes it: a child holding
# the pipe open would stall the status bar for as long as it ran.
if [[ ! -e $CACHE.lock ]] && ((stamp == 0 || now - stamp >= cycle)); then
  rotator="${BASH_SOURCE[0]%/*}/quote-rotate.sh"
  if [[ ! -x $rotator ]]; then
    self=$(readlink -f "${BASH_SOURCE[0]}")
    rotator="${self%/*}/quote-rotate.sh"
  fi
  [[ -x $rotator ]] && ("$rotator" "$CACHE" >/dev/null 2>&1 </dev/null &)
fi

if ((stamp > 0)); then
  # Time the animation from when this quote was installed, so a new one starts on
  # its first character instead of somewhere in the middle.
  elapsed=$((now - stamp))
  ((elapsed < 0)) && elapsed=0
else
  # Nothing cached to time against: loop the fallback rather than freeze.
  elapsed=$((now % cycle))
fi

# Between the last frame of the erase and the new quote landing, hold the blank
# field the erase ended on.
if ((elapsed >= cycle)); then
  printf '%-*.*s' "$WIDTH" "$WIDTH" "$CURSOR"
  exit 0
fi

# Walk the clauses to find the one this frame belongs to, then its phase.
for seg in "${segments[@]}"; do
  len=${#seg}
  typing=$((len * TYPE_MS))
  erasing=$((len * ERASE_MS))
  span=$((typing + HOLD_MS + erasing))
  if ((elapsed >= span)); then
    ((elapsed -= span))
    continue
  fi
  if ((elapsed < typing)); then
    shown=$((elapsed / TYPE_MS + 1))
    cursor=$CURSOR
  elif ((elapsed < typing + HOLD_MS)); then
    shown=$len
    # Blink only while the finished clause sits on screen.
    if (((elapsed / BLINK_MS) % 2 == 0)); then cursor=$CURSOR; else cursor=' '; fi
  else
    shown=$((len - (elapsed - typing - HOLD_MS) / ERASE_MS - 1))
    ((shown < 0)) && shown=0
    cursor=$CURSOR
  fi
  printf '%-*.*s' "$WIDTH" "$WIDTH" "${seg:0:shown}$cursor"
  exit 0
done
