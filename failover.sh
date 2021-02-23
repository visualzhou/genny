
# Check argument is given
# [ -z "$1" ] && echo "No argument supplied" && exit 1

echo rm -rf build/genny-metrics/
rm -rf build/genny-metrics/

HOST=10.0.0.168

# mongo --host $HOST failover-setup.js   || exit 1
mongo --host $HOST failover-setup-chaining.js   || exit 1
./show-sync-source.sh
 
HOST_URL="mongodb://ip-10-0-0-168,ip-10-0-0-50,ip-10-0-0-153,ip-10-0-0-127,ip-10-0-0-80/?replicaSet=repl"
echo running workload
./scripts/genny run -u $HOST_URL  workload.yml &
LOCAL_PID=$!

ssh $HOST << END
  RED='\033[0;31m'
  echo -e ${RED}sleep 10
  date --iso-8601=ns
  sleep 180

  echo -e ${RED} killall -9 mongod
  date --iso-8601=ns
  killall -9 mongod

  echo -e ${RED} sleep 20 then restart
  sleep 180
  date --iso-8601=ns
  nohup /data/mci/mongodb-linux-x86_64-ubuntu1804-4.4.2/bin/mongod --replSet repl --bind_ip_all --setParameter enableTestCommands=1  --logpath /data/db/mongod.log 2>&1 &

  echo -e ${RED} sleep 30
  date --iso-8601=ns
  sleep 140

  echo -e ${RED} failover finish
  date --iso-8601=ns
  exit
END

echo waiting for workload to finish
wait $LOCAL_PID
