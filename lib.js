/**
 * Utilities for turning on/off and waiting for fail points.
 */

var configureFailPoint;
var kDefaultWaitForFailPointTimeout;

(function() {
"use strict";

if (configureFailPoint) {
	return;  // Protect against this file being double-loaded.
}

kDefaultWaitForFailPointTimeout = 5 * 60 * 1000;

configureFailPoint = function(conn, failPointName, data = {}, failPointMode = "alwaysOn") {
	return {
		conn: conn,
		failPointName: failPointName,
		timesEntered: assert
		.commandWorked(conn.adminCommand(
			{configureFailPoint: failPointName, mode: failPointMode, data: data}))
		.count,
		wait:
		function(maxTimeMS = kDefaultWaitForFailPointTimeout) {
			// Can only be called once because this function does not keep track of the
			// number of times the fail point is entered between the time it returns
			// and the next time it gets called.
			assert.commandWorked(conn.adminCommand({
				waitForFailPoint: failPointName,
				timesEntered: this.timesEntered + 1,
				maxTimeMS: maxTimeMS
			}));
		},
		off:
		function() {
			assert.commandWorked(
				conn.adminCommand({configureFailPoint: failPointName, mode: "off"}));
		}
	};
};
})();

/**
 * Forces 'node' to sync from 'syncSource' without using the 'replSetSyncFrom' command. The
 * 'forceSyncSourceCandidate' failpoint will be returned. The node will continue to sync from
 * 'syncSource' until the caller disables the failpoint.
 *
 * This function may result in a sync source cycle, even with the 'nodeAllowedToSyncFromSource'
 * check (for example, if the topology changes while the check is running). The caller of this
 * function should be defensive against this case.
 */
const forceSyncSourceOriginal = (primary, node, syncSource) => {
	assert.neq(primary, node);

	jsTestLog(`Forcing node ${node} to sync from ${syncSource}`);

	// Stop replication on the node, so that we can advance the optime on the sync source.
    const stopReplProducer = configureFailPoint(node, "stopReplProducer");
    const forceSyncSource =
        configureFailPoint(node, "forceSyncSourceCandidate", {"hostAndPort": syncSource});

    const primaryDB = primary.getDB("forceSyncSourceDB");
    const primaryColl = primaryDB["forceSyncSourceColl"];

    // The node will not replicate this write. This is necessary to ensure that the sync source
    // is ahead of us, so that we can accept it as our sync source.
    assert.commandWorked(primaryColl.insert({"forceSyncSourceWrite": "1"}));
    // rst.awaitReplication(null, null, [syncSource]);
    sleep(1000)

    stopReplProducer.wait();
    stopReplProducer.off();

    // Verify that the sync source is correct.
    forceSyncSource.wait();
    // rst.awaitSyncSource(node, syncSource, 60 * 1000);

    return forceSyncSource;
};
