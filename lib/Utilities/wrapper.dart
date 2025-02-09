import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:intl/intl.dart';
import 'package:talk_of_the_town/Models/onboarding_response.dart';
import 'package:talk_of_the_town/Models/participant.dart';
import 'package:talk_of_the_town/Models/task_payload.dart';
import 'package:talk_of_the_town/Screens/Consent%20And%20Onboarding/consent.dart';
import 'package:talk_of_the_town/Screens/home.dart';
import 'package:talk_of_the_town/Screens/Auth/sign_in.dart';
import 'package:talk_of_the_town/Screens/loading.dart';
import 'package:talk_of_the_town/Screens/Consent%20And%20Onboarding/onboarding.dart';
import 'package:talk_of_the_town/Utilities/auth_utils.dart';
import 'package:talk_of_the_town/Utilities/client_manager.dart';
import 'package:talk_of_the_town/Utilities/database_manager.dart';
import 'package:talk_of_the_town/Utilities/geofence_manager.dart';
import 'package:talk_of_the_town/Utilities/secure_storage_manager.dart';
import 'package:talk_of_the_town/Utilities/shared_preferences_manager.dart';
import 'package:talk_of_the_town/Utilities/startup_manager.dart';
import 'package:talk_of_the_town/Utilities/task_activation_manager.dart';
import 'package:talk_of_the_town/main.dart';

import '../Models/bridge_dart_sdk/bridge_sdk.models.swagger.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  _WrapperState createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  final SecureStorageManager secureStorageManager = SecureStorageManager();
  bool _loading = true;
  String? _loadingMessage;
  String? _email;
  String? _password;
  dynamic target;

  @override
  void initState() {
    super.initState();
    manageStartupActivities();
    print("end of init state");
  }

  Future clientRequests() async {
    print("running startup function");
    await StartupManager().runStartupFunction();
    print("done running startup function");
  }

  Future<void> manageStartupActivities() async {
    // check if they have autologin
    bool autoLogin = await checkAutoLogin();
    // TODO: there is something gravely wrong with auto sign in
    if (autoLogin) {
      // reauth them

      //This needs to be inside of a try catch
      try {
        UserSessionInfo? loginInfo = await AuthUtils().autoSignIn().timeout(const Duration(seconds: 10));
        secureStorageManager.setSessionToken(loginInfo!.sessionToken!);

        print("after login info. Is loginInfo null?: ${loginInfo == null}");

        // check if they are consented, if not send them to consent
        print("About to check consented");
        bool consented = await checkConsented();
        print("checked consented, value: $consented");
        // if (!consented) {
        //   print("Inside the if...");
        //   setState(() => target = const Consent());
        //   return;
        // }

        // check if they are onboarded, if not send them to onboarding
        print("About to check onboarded");
        // dynamic onboardDynamic = await checkOnboarded();
        // print("onboardDynamic: $onboardDynamic");
        bool onboarded = await checkOnboarded();
        print("Checked onboarded, value: $onboarded");
        // if (!onboarded) {
        //   setState(() => target = const ToTOnboarding());
        //   return;
        // }

        //DO I NEED TO DO THIS?
        //await clientRequests();

        //send them to correct page
        setState(() => _loading = false);

          if (!consented) {
            setState(() => target = const Consent());
          } else if (!onboarded) {
              setState(() => target = const ToTOnboarding());
          } else {
              setState(() => target = const Home());
          }

        return;
        //setState(() => target = const Home());

      } catch (e) {

        print("Uh oh, the error was: ${e.toString()}");
        //Re-route to normal login page
        setState(() => _loading = false);
        setState(() => target = SignInPage(email: _email, password: _password));
      }

      //Going to do another try catch here maybe? What normally happens when you sign in?
      // try {
      //   print("Wrapper Second try catch Is loginInfo null?: ${loginInfo == null}");
      //   secureStorageManager.setSessionToken(loginInfo!.sessionToken!);
      // } catch (e) {
      //   print("Uh oh, the error was: ${e.toString()}");
      //   //I guess we can just re-route to normal login page for now here too
      //   setState(() => _loading = false);
      //   setState(() => target = SignInPage(email: _email, password: _password));
      // }


    } else {
      // they may not have auto login, but they may have saved their credentials
      await checkSavedCredentials();

      //Either way, they get sent to sign-in page - if no saved credentials, fields blank
      setState(() => target = SignInPage(email: _email, password: _password));
    }
    setState(() => _loadingMessage = null);
    print("end of manage startup");
  }

  Future<bool> checkAutoLogin() async {
    return await secureStorageManager.getAutoLoginPreference();
  }

  Future checkSavedCredentials() async {
    String? email = await secureStorageManager.getEmail();
    String? password = await secureStorageManager.getPassword();
    setState(() {
      _loading = false;
      _email = email;
      _password = password;
    });
  }

  Future<bool> checkConsented() async {
    return await SharedPreferencesManager().getConsentCompleted();
  }

  Future<bool> checkOnboarded() async {
    try {
      return await secureStorageManager.getOnboarded();
    } catch(e){
      print("error in checkOnboarded: $e");
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Loading(message: _loadingMessage);
    } else {
      return target;
    }
  }
}
