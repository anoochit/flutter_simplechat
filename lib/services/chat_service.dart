import 'package:simple_chat/services/auth_service.dart';

String getMessageId({required String uid, required String peerId}) {
  if (uid.compareTo(peerId) == 1) {
    return uid + "_" + peerId;
  } else {
    return peerId + "_" + uid;
  }
}

sendMessage({required String uid, required String peerId, required int type, required int timestamp, required String content, required String messageId}) {
  // insert data to firestore
  firebaseFirestore.collection("messages").doc(messageId).collection(messageId).doc((timestamp.toString())).set({
    'uid': uid,
    'peerId': peerId,
    'timestamp': timestamp,
    'type': type,
    'content': content,
  });
}
