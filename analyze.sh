# ./scripts/genny run -u mongodb://10.0.0.168:27017  ./src/workloads/docs/ParallelInsert.yml
# Check argument is given
[ -z "$1" ] && echo "No argument supplied" && exit 1
SINGLE_NODE=
if [[ $1 = "single" ]]
then
    SINGLE_NODE=true
    echo running single client mode
fi

METRICS_PATH=/data/mci/genny/build/genny-metrics
LOCAL_CLIENT_2_METRICS=./build/genny-metrics-client-2

if [[ -z $SINGLE_NODE ]]
then
    # Remove local copy of client 2 metrics and copy the latest ones. 
    rm -rf $LOCAL_CLIENT_2_METRICS

    scp -r client-2:$METRICS_PATH/ $LOCAL_CLIENT_2_METRICS
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

if [[ -z $SINGLE_NODE ]]
then
    for file in $LOCAL_CLIENT_2_METRICS/Parallel*.ftdc
    do
        echo ./curator/curator ftdc export csv --input "$file"
        ./curator/curator ftdc export csv --input "$file" > "$file-client_2.csv"
    done
fi

DATE=$(TZ=America/New_York date +"%F-%H-%M-%S")
echo copying the results to genny-metrics-$DATE
DRIVE_DIR=/data/drive/genny-metrics-$DATE
mkdir $DRIVE_DIR
cp $METRICS_PATH/Parallel*.csv $METRICS_PATH/start_time_report.txt $METRICS_PATH/iftop.txt $DRIVE_DIR
if [[ -z $SINGLE_NODE ]]
then
    cp $LOCAL_CLIENT_2_METRICS/Parallel*.csv $DRIVE_DIR
fi
