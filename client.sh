ulimit -n 64000
cd /data/mci/genny
killall ./dist/bin/genny_core
rm -rf build/genny-metrics/
echo client running workload on 10.0.0.168:27017
./scripts/genny run -u mongodb://10.0.0.168:27017 workload.yml
