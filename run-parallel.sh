# Check argument is given
[ -z "$1" ] && echo "No argument supplied" && exit 1

RED='\033[0;31m'
NC='\033[0m' # No Color

killall ./dist/bin/genny_core
echo -------  rm -rf build/genny-metrics/
rm -rf build/genny-metrics/

HOST=10.0.0.168:27017

mongo --host $HOST $1    || exit 1
 
HOST_URL=mongodb://$HOST
echo -e ${RED}client-1 running workload on $HOST ${NC}

scp workload.yml client-2:/data/mci/genny

echo -------  Collect primary data
nohup ssh ip-10-0-0-168 "sudo killall iftop; sudo iftop -t -L 20 > iftop.txt" &
COLLECT_PRIMARY_PID=$!

./scripts/genny run -u $HOST_URL  workload.yml &
LOCAL_PID=$!

ssh client-2 << END
ulimit -n 64000
cd /data/mci/genny
killall ./dist/bin/genny_core
rm -rf build/genny-metrics/
echo client-2 running workload on $HOST
./scripts/genny run -u $HOST_URL workload.yml
END

echo -e ${RED}client-2 finishes. waiting for local test to finish${NC}
wait $LOCAL_PID
kill $COLLECT_PRIMARY_PID
ssh ip-10-0-0-168 "sudo killall iftop"
