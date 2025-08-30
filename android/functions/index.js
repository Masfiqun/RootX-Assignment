const functions = require("firebase-functions/v2");
const admin = require("firebase-admin");
admin.initializeApp();

exports.notifyOnIncomingCall = functions.firestore.document("calls/{callId}")
  .onCreate(async (event) => {
    const data = event.data.data();
    const calleeId = data.calleeId;
    const calleeDoc = await admin.firestore().collection("users").doc(calleeId).get();
    const token = calleeDoc.get("fcmToken");
    if (!token) return;

    await admin.messaging().send({
      token,
      notification: {
        title: "Incoming call",
        body: `${data.callerName || 'Someone'} is calling you`,
      },
      data: {
        type: "incoming_call",
        callId: event.params.callId,
      },
      android: { priority: "high" },
      apns: { payload: { aps: { sound: "default" } } },
    });
  });