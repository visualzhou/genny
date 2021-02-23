load("lib.js");

assert.commandWorked(db.adminCommand({replSetStepUp: 1}));
assert.commandWorked(db.setProfilingLevel(0, 10000));
assert.commandWorked(db.adminCommand( { setParameter: 1, wiredTigerConcurrentWriteTransactions: NumberLong(1024) } ))
assert.commandWorked(db.adminCommand( { setParameter: 1, wiredTigerConcurrentReadTransactions: NumberLong(1024) } ))

// assert.eq(rs.conf().writeConcernMajorityJournalDefault, true);

function checkSyncSource(shouldAssert = true) {
    s = rs.status();
    seccuss = true;
    s.members.forEach(function(sec) { 
        if (sec._id === 0) return;
        if (sec.stateStr === "SECONDARY" && sec.syncSourceId === 0) return;  

        assert(!shouldAssert, tojson(sec));
        seccuss = false;
    });
    return seccuss;
}

// print("Disabling chaining")
// let conf = rs.conf()
// if (conf.settings.chainingAllowed === true) {
// 	conf.settings.chainingAllowed = false
// 	rs.reconfig(conf)
// }


// Make sure all nodes are syncing from the primary
let s = rs.status();
assert(s.members[0].stateStr === "PRIMARY");

const forceSyncSourceLib = (nodeId, syncSourceId) => {
	node = s.members[nodeId].name
	syncSource = s.members[syncSourceId].name
	m = new Mongo(node);
  m.adminCommand( { setParameter: 1, maxNumSyncSourceChangesPerHour: 10000000})
  forceSyncSourceOriginal(db.getMongo(), m, syncSource);
}

if (!checkSyncSource(false)) {
    forceSyncSourceLib(1, 0);
    forceSyncSourceLib(2, 0);
    forceSyncSourceLib(3, 0);
    forceSyncSourceLib(4, 0);
    if (s.members.length > 5) {
        forceSyncSourceLib(5, 0);
        forceSyncSourceLib(6, 0);
    }
}

db.foo.insert({text: "noop", t: Date.now()});

sleep(2000);

assert(checkSyncSource());

