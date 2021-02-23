coll = db.myIndexedUpdateCollection;

function getRandomInt(max) {
  return Math.floor(Math.random() * Math.floor(max));
}

bigStr = "a".repeat(1000);
BULK_SIZE = 1000;
BULK_NUM = 1000;
MAX_ID = BULK_SIZE * BULK_NUM;
MAX_NUMBER = 10000000;

function getRandomDoc(id) {
    doc = {_id: id,
           text: bigStr,
           // a: id,
           a: getRandomInt(MAX_NUMBER),
           b: getRandomInt(MAX_NUMBER),
           c: getRandomInt(MAX_NUMBER),
           d: getRandomInt(MAX_NUMBER),
           e: getRandomInt(MAX_NUMBER),
           // f: getRandomInt(MAX_NUMBER),
           // g: getRandomInt(MAX_NUMBER),
           // h: getRandomInt(MAX_NUMBER),
           // i: getRandomInt(MAX_NUMBER),
           // j: getRandomInt(MAX_NUMBER)
    };
    return doc;
}

coll.drop({ writeConcern: {w: "majority"}});
let id = 0;

// insert 1000 * 1000 = 1M docs.
for (let i = 0; i < BULK_NUM; i++) {
    bulk = coll.initializeUnorderedBulkOp();
    for (let j = 0; j < BULK_SIZE; j++) {
        bulk.insert(getRandomDoc(id));
        id++;
    }
    bulk.execute();
    print("Inserted " + BULK_SIZE + " docs, " + i + " / " + BULK_NUM);
}

// coll.createIndex({a: 1});
// coll.createIndex({b: 1});
// coll.createIndex({c: 1});
// coll.createIndex({d: 1});
// coll.createIndex({e: 1});

