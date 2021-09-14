import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:simple_chat/pages/chat.dart';
import 'package:simple_chat/services/auth_service.dart';
import 'package:simple_chat/widgets/chat_widget.dart';

class ConversationPage extends StatefulWidget {
  const ConversationPage({Key? key}) : super(key: key);

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: firebaseFirestore.collection("friends").where("uid", isEqualTo: (appData.userUid.toString())).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        // has error
        if (snapshot.hasError) {
          return const Center(
            child: Text("Something went wrong!"),
          );
        }

        // has data
        if (snapshot.hasData) {
          var docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (BuildContext context, int index) {
              // get user data
              return FutureBuilder(
                future: firebaseFirestore.collection("users").doc(docs[index]['peerId']).get(),
                builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.hasData) {
                    var user = snapshot.data;
                    return ListTile(
                      leading: getavatar(displayName: user!['displayName']),
                      title: Text(user['displayName']),
                      onTap: () {
                        // goto chat page
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(peerId: user['uid'], displayName: user['displayName'])));
                      },
                    );
                  }
                  return Container();
                },
              );
            },
          );
        }

        // loading
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}
