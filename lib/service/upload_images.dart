import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

Future<String> uploadImageToFirebase(File image) async {
  final storageRef = FirebaseStorage.instance.ref();
  final imageRef = storageRef.child('opportunities/${DateTime.now()}.png');
  final uploadTask = imageRef.putFile(image);
  final snapshot = await uploadTask.whenComplete(() => null);
  final imageUrl = await snapshot.ref.getDownloadURL();
  return imageUrl;
}
