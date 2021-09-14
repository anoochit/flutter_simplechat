String getMessageId({required String uid, required String peerId}) {
  if (uid.compareTo(peerId) == 1) {
    return uid + "_" + peerId;
  } else {
    return peerId + "_" + uid;
  }
}
