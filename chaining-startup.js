load("lib.js");

db.adminCommand({replSetStepUp: 1});

db.setProfilingLevel(0, 10000);

print("Enabling chaining")
let conf = rs.conf()
if (conf.settings.chainingAllowed === false) {
	conf.settings.chainingAllowed = true
	rs.reconfig(conf)
}

function getId(s, index) {
  return s.members[index]._id;
}

function getSId(s, index) {
  return s.members[index].syncSourceId;
}

function checkSyncSource() {
    s = rs.status();
    if (getSId(s, 1) !== getId(s, 0)) return false;
    if (getSId(s, 2) !== getId(s, 0)) return false;
    if (getSId(s, 3) !== getId(s, 0)) return false;
    if (getSId(s, 4) !== getId(s, 3)) return false;
    if (s.members.length <= 5) return true;
    if (getSId(s, 5) !== getId(s, 1)) return false;
    if (getSId(s, 6) !== getId(s, 2)) return false;
    return true;
}

// Make sure nodes are forming a chain.
let s = rs.status();
assert(s.members[0].stateStr === "PRIMARY");

// Make sure the rest are all secondaries.
s.members.forEach(function(sec) { 
	if (sec._id === 0) return;
	assert(sec.stateStr === "SECONDARY", tojson(sec))
});

const forceSyncSourceLib = (nodeId, syncSourceId) => {
	node = s.members[nodeId].name
	syncSource = s.members[syncSourceId].name
	m = new Mongo(node);
  m.adminCommand( { setParameter: 1, maxNumSyncSourceChangesPerHour: 10000000})
  forceSyncSourceOriginal(db.getMongo(), m, syncSource);
}


if (!checkSyncSource()) {
    // Only one connection between east and west
    // // 1 -> 0
    // forceSyncSourceLib(1, 0);
    // // 2 -> 0
    // forceSyncSourceLib(2, 0);
    // // 3 -> 1
    // forceSyncSourceLib(3, 1);
    // // 4 -> 2
    // forceSyncSourceLib(4, 2);
    
    // West secondaries sync from east secondaries.
    forceSyncSourceLib(1, 0);
    forceSyncSourceLib(2, 0);
    forceSyncSourceLib(3, 0);
    forceSyncSourceLib(4, 3);
    if (s.members.length > 5) {
        forceSyncSourceLib(5, 1);
        forceSyncSourceLib(6, 2);
    }
}

db.foo.insert({text: "noop", t: Date.now()});

sleep(2000);

s = rs.status();
assert(getSId(s, 1) === getId(s, 0));
assert(getSId(s, 2) === getId(s, 0), tojson(s.members[2]));
assert(getSId(s, 3) === getId(s, 0), tojson(s.members[3]));
assert(getSId(s, 4) === getId(s, 3), tojson(s.members[4]));
if (s.members.length > 5) {
    assert(getSId(s, 5) === getId(s, 1), tojson(s.members[5]));
    assert(getSId(s, 6) === getId(s, 2), tojson(s.members[6]));
}
