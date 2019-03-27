import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'authProvider.dart';
import 'auth.dart';

bool createUser(String uid, String email, String name, String username) {
  var batch = Firestore.instance.batch();

  var currUser = Firestore.instance.collection('users').document(uid);
  batch.setData(currUser, {
    'email': email,
    'name': name,
    'username': username,
    'bio': '',
    'rating': -1,
    'picture': ''
  });

  batch.commit().then((val) {
    return true; // successful
  }).catchError((err){
    print('Error: $err');
    return false;
  });
}

class EmailFieldValidator {
  static String validate(String value) {
    //TODO: check if the email is already associated with an account, if it is, tell user to sign in
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = new RegExp(pattern);

//    bool exist = false;
//    Stream<QuerySnapshot> users = Firestore.instance.collection('users').where('email', isEqualTo: value).snapshots();
////    Future<QuerySnapshot> users = Firestore.instance.collection('users').getDocuments().then(user)
//    users.forEach( (user) {
//      print(user.documents);
//    });
//    if(users.isEmpty != null){
//      exist = true;
//    }

    if (value.trim().isEmpty) {
      return 'Email is required';
//    }else if(exist) {
//      return 'This email already has an account';
    }else if (!regex.hasMatch(value)) {
      return 'Enter Valid Email';
    }else{
      return null;
    }
  }
}

class PasswordFieldValidator {
  static String validate(String value) {
    Pattern pattern = r'^(?=.*[0-9]+.*)(?=.*[a-zA-Z]+.*)[0-9a-zA-Z]{6,}$';
    RegExp regex = new RegExp(pattern);

    if(value.trim().isEmpty){
      return 'Password is required';
    }else if(!regex.hasMatch(value)){
      return 'Must contain at least 1 number and be at least 6 characters';
    }else{
      return null;
    }
  }
}

class UsernameFieldValidator {
  static String validate(String value) {
    //TODO: also check if the username exists already by searching through DB


    if (value.trim().isEmpty) {
      return 'Username is required';
//    }else if () {
//      return 'Username already exists';
    }else {
      return null;
    }
  }
}

class NameFieldValidator {
  static String validate(String value) {
    if (value.trim().isEmpty) {
      return 'Name is required';
    } else if (value.length < 3) {
      return 'Name must be more than 2 charater';
    } else {
      return null;
    }
  }
}

class Login extends StatefulWidget {
  Login({this.onSignedIn});
  // a voidCallback takes no parameters and returns no parameters
  final VoidCallback onSignedIn;

  @override
  State<StatefulWidget> createState() => new _Login();
}

enum FormType{
  login,
  register
}

class _Login extends State<Login>{
  final GlobalKey<FormState> formKey = new GlobalKey<FormState>();

  FormType _formType = FormType.login; // initially at the login form
  String _email;
  String _password;
  String _name;
  String _username;

  String _authHint = '';

  bool validateAndSave(){
    final form = formKey.currentState; // gets the form state
    if(form.validate()){
      form.save(); // save the state of the form
      return true;
    }
    return false;
  }

  //asynchronous function
  Future<void> validateAndSubmit() async{
    if(validateAndSave()){
      try{
        final BaseAuth auth = AuthProvider.of(context).auth;
        String userId;
        if(_formType == FormType.login){
          userId = await auth.signInWithEmailAndPassword(_email, _password);
          print('SignedIn: $userId');

        }else{
          userId = await auth.createUserWithEmailAndPassword(_email, _password);
          print('Registered User: $userId');
          createUser(userId, _email, _name, _username);
        }
        setState(() {
          _authHint = 'Signed In successfully';
        });
        // after we either sign in or create an account, we want to be signed in
        widget.onSignedIn(); // ensure the rootPage receives message we are signedIn
      }catch(e){
        setState(() {
          _authHint = 'Problem signing in or registering account';
        });
        print('Error: $e');
      }
    }else {
      setState(() {
        _authHint = '';
      });
    }
  }

  // move from login page to register page
  void moveToRegister(){
    formKey.currentState.reset(); // reset the values that were saved previously in form fields
    // new UI -> new state
    setState(() {
      _formType = FormType.register;
      _authHint = '';
    });
  }
  // move from register page to login page
  void moveToLogin(){
    setState(() {
      _formType = FormType.login;
      _authHint = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return
      Scaffold(
        appBar: AppBar(
          title: Text('Login Page'),
          automaticallyImplyLeading: false,
        ),
        body: new ListView(
          shrinkWrap: true,
          children: <Widget>[
            SizedBox(width: 20.0,height: 20.0),
            new Container(
              height: 100.0,
              width: 80.0,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    'assets/gem.png',
                  ),
                  fit: BoxFit.scaleDown,
                ),
              ),
            ),
            new Center(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                    child: new Form(
                      key: formKey,
                      child: new Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                          children: buildInputs() + buildSubmitButtons(),
                      ),
                    )
              ),
            ),
          ]
        )
      );
  }

  List<Widget> buildInputs(){
    // email and password fields - in both forms
    if(_formType == FormType.login){
      return [
        new TextFormField(
          key: Key('email'),
          keyboardType: TextInputType.emailAddress,
          decoration: new InputDecoration(
            labelText: 'Email',
            contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 20.0),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0)
            ),
          ),
          validator: EmailFieldValidator.validate,
          onSaved: (String value) => _email = value,
        ),
        SizedBox(width: 20.0,height: 20.0),
        new TextFormField(
          key: Key('password'),
          keyboardType: TextInputType.text,
          decoration: new InputDecoration(
            labelText: 'Password',
            contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 20.0),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0)
            ),
          ),
          obscureText: true,
          validator: PasswordFieldValidator.validate,
          onSaved: (String value) => _password = value,
        ),
      ];
    }else{
      return [
        new TextFormField(
          key: Key('email'),
          keyboardType: TextInputType.emailAddress,
          decoration: new InputDecoration(
            labelText: 'Email',
            contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 20.0),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0)
            ),
          ),
          validator: EmailFieldValidator.validate,
          onSaved: (String value) => _email = value,
        ),
        SizedBox(width: 20.0,height: 20.0),
        new TextFormField(
          key: Key('name'),
          keyboardType: TextInputType.text,
          decoration: new InputDecoration(
              labelText: 'Name',
              contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 20.0),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0)
              )
          ),
          validator: NameFieldValidator.validate,
          onSaved: (String value) => _name = value,
        ),
        SizedBox(width: 20.0,height: 20.0),
        new TextFormField(
          key: Key('username'),
          keyboardType: TextInputType.text,
          decoration: new InputDecoration(
            labelText: 'Username',
            contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 20.0),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0)
            ),
          ),
          validator: UsernameFieldValidator.validate,
          onSaved: (String value) => _username = value,
        ),
        SizedBox(width: 20.0,height: 20.0),
        new TextFormField(
          key: Key('password'),
          keyboardType: TextInputType.text,
          decoration: new InputDecoration(
            labelText: 'Password',
            contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 20.0),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0)
            ),
          ),
          obscureText: true,
          validator: PasswordFieldValidator.validate,
          onSaved: (String value) => _password = value,
        ),
      ];
    }
  }

  List<Widget> buildSubmitButtons(){
    if(_formType == FormType.login){
      return [
        hintText(),
        SizedBox(width: 20.0,height: 10.0),
        new OutlineButton(
          padding: EdgeInsets.only(left: 40.0, top: 20.0, right: 40.0, bottom: 20.0),
          child: new Text(
            'Login',
            style: new TextStyle(
              fontSize: 20.0,
            ),
          ),
          onPressed: validateAndSubmit,
        ),
        new FlatButton(
          child: new Text(
            'Create New Account',
            style: new TextStyle(
              fontSize: 15.0,
            ),
          ),
          onPressed: moveToRegister,
        )
      ];
    }else{
      return [
        hintText(),
        SizedBox(width: 20.0,height: 10.0),
        new OutlineButton(
          padding: EdgeInsets.only(left: 40.0, top: 20.0, right: 40.0, bottom: 20.0),
          child: new Text(
            'Register',
            style: new TextStyle(
              fontSize: 20.0,
            ),
          ),
          onPressed: validateAndSubmit,
        ),
        new FlatButton(
          child: new Text(
            'Have an Account? Login',
            style: new TextStyle(
              fontSize: 15.0,
            ),
          ),
          onPressed: moveToLogin,
        )
      ];
    }
  }

  Widget hintText() {
    return new Container(
      //height: 80.0,
//        padding: const EdgeInsets.all(32.0),
        child: new Text(
            _authHint,
            key: new Key('hint'),
            style: new TextStyle(fontSize: 18.0, color: Colors.grey),
            textAlign: TextAlign.center)
    );
  }

}
