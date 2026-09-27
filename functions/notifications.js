const {FieldValue} = require("firebase-admin/firestore");

/**
 * Persist an assigned ticket alert and deliver it to the doctor's devices.
 * @param {object} db Firestore client.
 * @param {object} messaging Firebase Messaging client.
 * @param {string} ticketId Stable inbox and notification ID.
 * @param {object} ticket Newly created ticket.
 */
async function notifyAssignedDoctor(db, messaging, ticketId, ticket) {
  if (ticket.status !== "sent" || !ticket.doctorUid) return;
  const doctor = db.collection("doctor").doc(ticket.doctorUid);
  if (!(await doctor.get()).exists) return;
  const inbox = doctor.collection("notifications").doc(ticketId);
  try {
    await inbox.create({
      ticketId, title: "New consultation ticket",
      body: "A consultation has been assigned to you. Open your queue to review it.",
      priority: ticket.priority, createdAt: FieldValue.serverTimestamp(),
      read: false, pushSent: false,
    });
  } catch (error) {
    if (error.code !== 6 && error.code !== "already-exists") throw error;
  }
  if ((await inbox.get()).data().pushSent) return;
  const devices = await doctor.collection("devices").get();
  for (let i = 0; i < devices.docs.length; i += 500) {
    const batch = devices.docs.slice(i, i + 500);
    const result = await messaging.sendEachForMulticast({
      tokens: batch.map((doc) => doc.data().token),
      notification: {title: "New consultation ticket",
        body: "A consultation has been assigned to you. Open your queue to review it."},
      data: {ticketId, doctorUid: ticket.doctorUid},
      android: {priority: "high", collapseKey: ticketId,
        notification: {channelId: "consultation_tickets", tag: ticketId, icon: "ic_notification"}},
    });
    let retry = false;
    await Promise.all(result.responses.map(async (response, index) => {
      if (response.success) return;
      if (["messaging/registration-token-not-registered", "messaging/invalid-registration-token"]
          .includes(response.error.code)) {
        await batch[index].ref.delete();
      } else {
        retry = true;
      }
    }));
    if (retry) throw new Error("Some notification deliveries need retrying.");
  }
  await inbox.update({pushSent: true});
}

module.exports = {notifyAssignedDoctor};
