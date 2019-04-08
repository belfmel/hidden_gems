import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_functions/cloud_functions.dart';

class ShowHideTextField extends StatefulWidget {
  @override
  NewPost createState() {
    return new NewPost();
  }
}
class CustomForm extends StatefulWidget {
  @override
  NewPost createState() => NewPost();
}
class NewPost extends State<CustomForm> {
  @override
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _useridController = TextEditingController();
  final _pictureController = TextEditingController();
  var uuid = new Uuid();
  File image;
  var imgUrl;

  bool _isTextFieldVisible = false;
  bool finished = true;

  List <String> tags = new List();
  Geolocator geolocator = Geolocator();
  Position userLocation;

  Future selectImage() async {
    var img = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      image = img;
    });
  }

  removeImage() {
    setState(() {
      image = null;
    });
  }

  uploadGem() async {
    //Upload Image to Storage and get download URL
    var imgUrl = "";
    if (image != null) {
      String imgTitle = uuid.v1() + ".jpg";
      final StorageReference firebaseStorRef = FirebaseStorage.instance.ref()
          .child(imgTitle);
      final StorageUploadTask task = firebaseStorRef.putFile(image);
      imgUrl = await(await task.onComplete).ref.getDownloadURL();
    }

    try {
      final dynamic resp = await CloudFunctions.instance.call(
        functionName: 'writeTest',
        parameters: <String, dynamic>{
          'name': _nameController.text,
          'description': _descriptionController.text,
          'finished': finished,
          'latitude': userLocation.latitude,
          'longitude': userLocation.longitude,
          'picture': imgUrl,
          'tags': tags,
          'userid': 'auser',
        },
      );
      _nameController.clear();
      _descriptionController.clear();
      _tagsController.clear();
      Navigator.pop(context);
    } on CloudFunctionsException catch (e) {
      print('caught firebase functions exception');
      print(e.code);
      print(e.message);
      print(e.details);
    } catch (e) {
      print('caught generic exception');
      print(e);
    }
  }

  @override
  void dispose() {
    // Clean up the controller when the Widget is disposed
    _nameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<Position> locateUser() async {
    return Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((location) {
      if (location != null) {
        print("Location: ${location.latitude},${location.longitude}");
      }
      return location;
    });
  }


  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(title: Text('Add a New Gem!')),
      body: Container(
        margin: EdgeInsets.all(15.0),
        alignment: Alignment.center,
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.0),
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.0),
              child: TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.0),
              child: TextField(
                controller: _tagsController,
                decoration: InputDecoration(labelText: 'Tags'),
              ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: RaisedButton(
                  shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
                  onPressed: (){
                  tags.add(_tagsController.text);
                  this.setState(() {
                    _tagsController.clear();
                  });
                },
                //tooltip: 'Add tag',
                child: new Icon(Icons.add)
              ),
            ),
            Text(
              'Tags: $tags',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 25.0, vertical: 0.0),
                    child: FloatingActionButton(
                        onPressed: selectImage,
                        tooltip: 'Upload Image',
                        child: new Icon(Icons.add_a_photo)
                    ),
                  ),

                  image != null ? Text("Picture Uploaded!") : SizedBox(),

                  image != null ? FlatButton(
                    onPressed: removeImage,
                    child: new Icon(
                        Icons.cancel, color: Color.fromRGBO(255, 0, 0, 1)),
                    //color: Color.fromRGBO(0, 0, 0, 0),
                  ) : SizedBox(),

                ]),

            _isTextFieldVisible ?
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.0),
              child: TextField(
                controller: _useridController,
                decoration: InputDecoration(labelText: 'UserId'),
              ),
            ) : SizedBox(),

            _isTextFieldVisible ?
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.0),
              child: TextField(
                controller: _pictureController,
                decoration: InputDecoration(labelText: 'Picture'),
              ),
            ) : SizedBox(),


            SizedBox(
              height: 25.0,
            ),

            RaisedButton(
              child: Text('Add'),
              onPressed: () {
                locateUser().then((value) {
                  setState(() {
                    userLocation = value;
                  });
                  finished = true;
                  uploadGem();
                });
                  }),

            RaisedButton(
              child: Text('Save as Draft'),
              onPressed: () {
                locateUser().then((value) {
                  setState(() {
                    userLocation = value;
                  });
                  finished = false;
                  uploadGem();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
