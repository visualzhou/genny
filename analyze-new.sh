# ./scripts/genny run -u mongodb://10.0.0.168:27017  ./src/workloads/docs/ParallelInsert.yml
# Check argument is given
[ -z "$1" ] && echo "No argument supplied" && exit 1

METRICS_PATH=/data/mci/genny/build/genny-metrics
LOCAL_CLIENT_2_METRICS=./build/genny-metrics-client-2
LOCAL_CLIENT_3_METRICS=./build/genny-metrics-client-3

if [[ $1 -ge 2 ]]
then
    # Remove local copy of client 2 metrics and copy the latest ones. 
    rm -rf $LOCAL_CLIENT_2_METRICS
    scp -r client-2:$METRICS_PATH/ $LOCAL_CLIENT_2_METRICS
fi

if [[ $1 -ge 3 ]]
then
    # Remove local copy of client 3 metrics and copy the latest ones. 
    rm -rf $LOCAL_CLIENT_3_METRICS
    scp -r client-3:$METRICS_PATH/ $LOCAL_CLIENT_3_METRICS
fi

for file in $METRICS_PATH/Parallel*.ftdc
do
  echo ./curator/curator ftdc export csv --input "$file"
  ./curator/curator ftdc export csv --input "$file" > "$file.csv"
done

# Get start time
stat $METRICS_PATH/start_time.txt > $METRICS_PATH/start_time_report.txt

# Get primary data
scp ip-10-0-0-168:iftop.txt $METRICS_PATH/iftop.txt

if [[ $1 -ge 2 ]]
then
    for file in $LOCAL_CLIENT_2_METRICS/Parallel*.ftdc
    do
        echo ./curator/curator ftdc export csv --input "$file"
        ./curator/curator ftdc export csv --input "$file" > "$file-client_2.csv"
    done
fi

if [[ $1 -ge 3 ]]
then
    for file in $LOCAL_CLIENT_3_METRICS/Parallel*.ftdc
    do
        echo ./curator/curator ftdc export csv --input "$file"
        ./curator/curator ftdc export csv --input "$file" > "$file-client_3.csv"
    done
fi

DATE=$(TZ=America/New_York date +"%F-%H-%M-%S")
echo copying the results to genny-metrics-$DATE
DRIVE_DIR=/data/drive/genny-metrics-$DATE
mkdir $DRIVE_DIR
cp $METRICS_PATH/Parallel*.csv $METRICS_PATH/start_time_report.txt $METRICS_PATH/iftop.txt $DRIVE_DIR
if [[ $1 -ge 2 ]]
then
    cp $LOCAL_CLIENT_2_METRICS/Parallel*.csv $DRIVE_DIR
fi
if [[ $1 -ge 3 ]]
then
    cp $LOCAL_CLIENT_3_METRICS/Parallel*.csv $DRIVE_DIR
fi
