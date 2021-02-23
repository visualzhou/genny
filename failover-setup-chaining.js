load("lib.js");
db.adminCommand({replSetStepUp: 1});
db.setProfilingLevel(0, 10000);
// print("Disabling chaining")
// let conf = rs.conf()
// if (conf.settings.chainingAllowed === true) {
// 	conf.settings.chainingAllowed = false
// 	rs.reconfig(conf)
// }

print("Enable chaining")
let conf = rs.conf()
if (conf.settings.chainingAllowed === false) {
	conf.settings.chainingAllowed = true
	rs.reconfig(conf)
}

s = rs.status()
const forceSyncSourceLib = (nodeId, syncSourceId) => {
	node = s.members[nodeId].name
	syncSource = s.members[syncSourceId].name
	m = new Mongo(node);
  m.adminCommand( { setParameter: 1, maxNumSyncSourceChangesPerHour: 10000000})
  fp = forceSyncSourceOriginal(db.getMongo(), m, syncSource);
  fp.off();
}

// Force two secodnaries to sync from 0
// 1 -> 0
forceSyncSourceLib(1, 0);
// 3 -> 0
forceSyncSourceLib(3, 0);
forceSyncSourceLib(2, 1);
forceSyncSourceLib(4, 3);
