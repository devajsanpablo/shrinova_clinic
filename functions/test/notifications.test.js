const {test} = require("node:test");
const assert = require("node:assert/strict");
const {notifyAssignedDoctor} = require("../notifications");

function fixture(tokens = ["device-a", "device-b"]) {
  const inboxes = new Map();
  const removed = [];
  const sent = [];
  const doctor = {
    get: async () => ({exists: true}),
    collection: (name) => name === "notifications" ? {
      doc: (id) => ({
        create: async (data) => {
          if (inboxes.has(id)) throw Object.assign(new Error(), {code: 6});
          inboxes.set(id, data);
        },
        get: async () => ({data: () => inboxes.get(id)}),
        update: async (data) => Object.assign(inboxes.get(id), data),
      }),
    } : {
      get: async () => ({docs: tokens.map((token) => ({
        data: () => ({token}), ref: {delete: async () => removed.push(token)},
      }))}),
    },
  };
  return {inboxes, sent, removed,
    db: {collection: (name) => {
      assert.equal(name, "doctor");
      return {doc: (uid) => {
        assert.equal(uid, "assigned-doctor"); return doctor;
      }};
    }},
    messaging: {sendEachForMulticast: async (message) => {
      sent.push(message);
      return {responses: tokens.map(() => ({success: true}))};
    }},
  };
}
const ticket = {status: "sent", doctorUid: "assigned-doctor", priority: "urgent"};

test("sent ticket targets assigned doctor devices and retries do not duplicate completed delivery", async () => {
  const f = fixture();
  await notifyAssignedDoctor(f.db, f.messaging, "ticket-1", ticket);
  await notifyAssignedDoctor(f.db, f.messaging, "ticket-1", ticket);
  assert.equal(f.inboxes.size, 1);
  assert.equal(f.sent.length, 1);
  assert.deepEqual(f.sent[0].tokens, ["device-a", "device-b"]);
  assert.equal(f.sent[0].data.doctorUid, "assigned-doctor");
  assert.equal(f.sent[0].data.ticketId, "ticket-1");
});
test("draft and legacy unassigned tickets do not notify", async () => {
  const f = fixture();
  await notifyAssignedDoctor(f.db, f.messaging, "draft", {...ticket, status: "draft"});
  await notifyAssignedDoctor(f.db, f.messaging, "legacy", {...ticket, doctorUid: ""});
  assert.equal(f.inboxes.size, 0);
  assert.equal(f.sent.length, 0);
});
test("doctor without devices still receives a persistent inbox item", async () => {
  const f = fixture([]);
  await notifyAssignedDoctor(f.db, f.messaging, "ticket-1", ticket);
  assert.equal(f.inboxes.size, 1);
  assert.equal(f.sent.length, 0);
});
test("invalid device tokens are removed", async () => {
  const f = fixture(["expired"]);
  f.messaging.sendEachForMulticast = async () => ({responses: [{success: false,
    error: {code: "messaging/registration-token-not-registered"}}]});
  await notifyAssignedDoctor(f.db, f.messaging, "ticket-1", ticket);
  assert.deepEqual(f.removed, ["expired"]);
});
test("transient delivery failures are retried without duplicating inbox items", async () => {
  const f = fixture(["retry"]);
  f.messaging.sendEachForMulticast = async () => ({responses: [{success: false,
    error: {code: "messaging/server-unavailable"}}]});
  await assert.rejects(notifyAssignedDoctor(f.db, f.messaging, "ticket-1", ticket));
  assert.equal(f.inboxes.get("ticket-1").pushSent, false);
  f.messaging.sendEachForMulticast = async () => ({responses: [{success: true}]});
  await notifyAssignedDoctor(f.db, f.messaging, "ticket-1", ticket);
  assert.equal(f.inboxes.size, 1);
  assert.equal(f.inboxes.get("ticket-1").pushSent, true);
});
