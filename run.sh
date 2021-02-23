# Check argument is given
[ -z "$1" ] && echo "No argument supplied" && exit 1

echo rm -rf build/genny-metrics/
rm -rf build/genny-metrics/

HOST=10.0.0.168:27017

mongo --host $HOST $1    || exit 1
 
HOST_URL=mongodb://$HOST
echo running parallel insert on $HOST
./scripts/genny run -u $HOST_URL  workload.yml

