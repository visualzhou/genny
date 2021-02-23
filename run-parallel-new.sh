# Check argument is given
[ -z "$1" ] && echo "No argument supplied" && exit 1
[ -z "$2" ] && echo "Client number is needed" && exit 1

if [[ $2 -eq 2 ]] || [[ $2 -eq 3 ]]
then
    echo running #2 clients
else
    echo expect 2 or 3 clients 
    exit 1
fi

CLIENT_NUM=$2
RED='\033[0;31m'
NC='\033[0m' # No Color

killall ./dist/bin/genny_core
echo -------  rm -rf build/genny-metrics/
rm -rf build/genny-metrics/

HOST=10.0.0.168:27017

mongo --host $HOST $1    || exit 1
 
HOST_URL=mongodb://$HOST
echo -e ${RED}client-1 running workload on $HOST ${NC}

cat >client.sh << END
ulimit -n 64000
cd /data/mci/genny
killall ./dist/bin/genny_core
rm -rf build/genny-metrics/
echo client running workload on $HOST
./scripts/genny run -u $HOST_URL workload.yml
END

scp workload.yml client.sh client-2:/data/mci/genny
if [[ $2 -eq 3 ]]
then
    scp workload.yml client.sh client-3:/data/mci/genny
fi

echo -------  Collect primary data
nohup ssh ip-10-0-0-168 "sudo killall iftop; sudo iftop -t -L 20 > iftop.txt" &
COLLECT_PRIMARY_PID=$!

./scripts/genny run -u $HOST_URL  workload.yml &
LOCAL_PID=$!

ssh client-2 'bash /data/mci/genny/client.sh' &
CLIENT_2_PID=$!

if [[ $2 -eq 3 ]]
then
    ssh client-3 'bash /data/mci/genny/client.sh' &
    CLIENT_3_PID=$!
fi

wait $CLIENT_2_PID
echo -e ${RED}client-2 finishes. waiting for other tests to finish${NC}
if [[ $2 -eq 3 ]]
then
    wait $CLIENT_3_PID
    echo -e ${RED}client-3 finishes. waiting for other tests to finish${NC}
fi
wait $LOCAL_PID
kill $COLLECT_PRIMARY_PID
ssh ip-10-0-0-168 "sudo killall iftop"
