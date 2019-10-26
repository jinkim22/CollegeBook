const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const apiKey = "AIzaSyAkJR94YsEoZ2yGKf0-aocbfBZ63dfzR64";
const https = require('https');

exports.isbnAutofill = functions.https.onCall((data, context) => {
  const isbnPassed = data.text;
  //var returnTitle;
  //isbnPassed = (isbnPassed.replace(" ", "")).replace("-", "");
  const request = require('request-promise');
  return request("https://www.googleapis.com/books/v1/volumes?q=isbn:" + isbnPassed + "&country=US" + "&maxResults=10&key=" + apiKey)
    .then((body) => {
    	return { text: JSON.parse(body) };
  	})
});

exports.getSchoolFromDomain = functions.https.onCall((data, context) => {
  const domainPassed = data.text;

  const request = require('request-promise');
  return request("http://universities.hipolabs.com/search?domain=" + domainPassed)
    .then((body) => {
    	return { text: JSON.parse(body) };
  	})
});

exports.sendNotification = functions.firestore.document('Schools/{school}/Channels/{channelId}/thread/{id}').onCreate(async (docSnapshot, context) => {
  const school = context.params.school;
  const channelId = context.params.channelId;
  const message = docSnapshot.data();
  const senderID = message['senderID'];
  const senderName = message['senderName'];
  const recipientID = message['recipientID'];
  const notificationBody = message['content'];
  const sentTime = message['created'];


   return admin.firestore().collection('Schools/' + school + '/Channels').doc(channelId).set({lastMessage: notificationBody, lastMessageTime: sentTime, lastMessageSenderID: senderID, read: false}, {merge: true}).then( response => {

   	return admin.firestore().doc('Schools/' + school + '/Users/' + recipientID).get().then(userDoc => {
      const fcmToken = userDoc.get('fcmToken')

      const notificationBody = message['content']
      const payload = {
        notification: {
          title: senderName,
          body: notificationBody,
          sound: "default",
          badge: "1"
        },
        data: {
          USER_ID: senderID,
          channel_id: channelId
        }
      }

      return admin.messaging().sendToDevice(fcmToken, payload).then( response => {
        return
      })
    })
  })
});

/**
 * Initiate a recursive delete of documents at a given path.
 *
 * The calling user must be authenticated and have the custom "admin" attribute
 * set to true on the auth token.
 *
 * This delete is NOT an atomic operation and it's possible
 * that it may fail after only deleting some documents.
 *
 * @param {string} data.path the document or collection path to delete.
 */
exports.recursiveDelete = functions
  .runWith({
    timeoutSeconds: 540,
    memory: '2GB'
  })
  .https.onCall((data, context) => {
    // Only allow admin users to execute this function.
    if (!(context.auth && context.auth.token && context.auth.token.admin)) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Must be an administrative user to initiate delete.'
      );
    }

    const path = data.path;
    console.log(
      `User ${context.auth.uid} has requested to delete path ${path}`
    );

    // Run a recursive delete on the given document or collection path.
    // The 'token' must be set in the functions config, and can be generated
    // at the command line by running 'firebase login:ci'.
    return firebase_tools.firestore
      .delete(path, {
        project: process.env.GCLOUD_PROJECT,
        recursive: true,
        yes: true,
        token: functions.config().fb.token
      })
      .then(() => {
        return {
          path: path
        };
      });
  });
