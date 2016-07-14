
failure_file=`mktemp`
restart_file=`mktemp`
echo "Failure file $failure_file"
echo "restart file $restart_file"
echo $0

function stackwatch {
    # bit grotty: stack build --dry-run needs a stdin.
    sleep 100000000000 | stack build --dry-run --file-watch 2>&1 | sed -u 's/ExitSuccess/\x0/g' | while read -d $'\0' x; do
        echo "================" >> stacklog
        echo "$x" >> stacklog
        echo "$x" | grep -v "hestia" | grep -q "database=local"
        if [ $? -eq 0 ]; then
            echo -n "restarting at " >> stacklog
            date >> stacklog
            echo 1 > $restart_file;
        fi;
    done > stacklog
}


stackwatch &
watcher=$!

echo "watcher is $watcher"

function finish {
    rm $failure_file
    rm $restart_file
    kill -- -$PGID
#    reset
}


ghcid --command="HSPEC_FAILURES_FILE=$failure_file ./scripts/current_ghci $restart_file --test --   -isrc -itest test/SpecWrapper.hs"  --test ':main --rerun --color' --restart $restart_file

finish
trap finish EXIT

