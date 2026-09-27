const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {notifyAssignedDoctor} = require("./notifications");

initializeApp();
exports.notifyDoctorOnTicket = onDocumentCreated({
  document: "tickets/{ticketId}", region: "us-central1",
  retry: true, maxInstances: 10,
}, (event) => notifyAssignedDoctor(
    getFirestore(), getMessaging(), event.params.ticketId, event.data.data()));
