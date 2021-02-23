HOST=ip-10-0-0-168
if [ -n "$1" ]
then
  HOST=$1
fi

echo ------------
date

mongo --host $HOST --eval "JSON.stringify(rs.status(), null, 2)" --quiet | jq '.members[] | (._id | tostring) + " --> " + (.syncSourceId | tostring)'

