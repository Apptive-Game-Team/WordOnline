#!/usr/bin/env bash
#
# A/B: the same session counts measured on two builds, alternating, so that anything drifting
# on the box (database growth, host state, thermal) hits both arms rather than whichever ran
# second. The statistics tables are truncated before every trial so each starts from the same
# database size.
#
#   A = ac-loadtest-game:mainref   main at a0312ff, no performance work
#   B = ac-loadtest-game:perfint   the same tree plus the merged performance branches

set -u
SP="$(cd "$(dirname "$0")" && pwd)"
OUT="$SP/ab-results.csv"
TARGETS="${TARGETS:-64 96 128}"

# Wait for the box to go quiet: the container is capped at one core, but a busy host delays
# the loop threads' wake-ups and the numbers come out low.
wait_for_quiet() {
    local waited=0
    while :; do
        local load busy
        load=$(awk '{print int($1)}' /proc/loadavg)
        busy=$(pgrep -c -f "Unity|gradle|dotnet|il2cpp" 2>/dev/null || true); busy=${busy:-0}
        if [ "$load" -lt 3 ] && [ "$busy" -lt 2 ]; then
            [ "$waited" -gt 0 ] && echo "host quiet after ${waited}s"
            return
        fi
        [ "$waited" = 0 ] && echo "waiting for the host to go quiet (load $load, $busy build process(es))"
        sleep 30; waited=$((waited + 30))
    done
}

reset_statistics() {
    docker exec ac-loadtest-postgres psql -U loadtest -d wordonline -qc \
        "TRUNCATE statistic_game_sessions, statistic_game_cards, statistic_game_magics, statistic_games CASCADE;" \
        >/dev/null 2>&1
}

run_one() { # run_one <arm> <image> <target>
    reset_statistics
    echo "=== arm $1  image $2  target $3"
    ROW_BEFORE=$(wc -l <"$OUT" 2>/dev/null || echo 0)
    "$SP/scripts/capacity-search.sh" --single --image "$2" --start "$3" --max "$3" \
        --cpus 1 --memory 1g --fps-pass 15 --out "$SP/.one.csv" >"$SP/trial-$1-$3.log" 2>&1
    tail -1 "$SP/.one.csv" | sed "s/^/$1,$3,/" >>"$OUT"
    tail -1 "$OUT"
}

docker start ac-loadtest-postgres >/dev/null 2>&1
until docker exec ac-loadtest-postgres pg_isready -U loadtest >/dev/null 2>&1; do sleep 2; done

echo "arm,session_target,target,verdict,p10_fps,mean_fps,worst_session_fps,avg_sessions,stalled,mem_mib,note" >"$OUT"

flip=0
for target in $TARGETS; do
    wait_for_quiet
    if [ "$flip" = 0 ]; then
        run_one A ac-loadtest-game:mainref "$target"
        run_one B ac-loadtest-game:perfint "$target"
        flip=1
    else
        run_one B ac-loadtest-game:perfint "$target"
        run_one A ac-loadtest-game:mainref "$target"
        flip=0
    fi
done

echo "########## A/B DONE"
column -s, -t "$OUT"
