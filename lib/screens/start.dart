import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:memories/model.dart';
import 'package:memories/screens/camera.dart';

class StartScreen extends StatefulWidget {
  @override
  State createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  Status status = Status.loading;
  Animation<double> logoSizeAnim;
  AnimationController logoAnimCtrl;
  Map<String, double> currentLocation;
  List<Event> events;
  Event currentEvent;

  bool isAnimPending() {
    return !logoAnimCtrl.isCompleted &&
        !logoAnimCtrl.isAnimating &&
        !logoAnimCtrl.isDismissed;
  }


  void refreshLocationAndEvents() async {
    print("Querying location...");
    setState(() {
      status = Status.querying_location;
    });
    try {
      var location = await Location().getLocation();
      setState((){
        currentLocation = location;
        status = Status.querying_events;
      });

      var client = new http.Client();
      client.get(eventsUrl).then((response) => handleEventsResponse(response));

    } on PlatformException catch(e) {
      print("Error querying location: $e");
      setState((){
        currentLocation = null;
        status = Status.query_location_failed;
      });
    }
  }

  void handleEventsResponse(http.Response response) {
    if (response.statusCode == 200) {
      print("statusCode: ${response.statusCode}\nbody: ${response.body}");
      print("Events: $events");
      setState(() {
        events = Event.listFromJson(json.decode(response.body));
        status = Status.query_events_success;
      });
    } else {
      print("Error fetching events: ${response.statusCode} - ${response.body}");
      setState(() {
        status = Status.query_events_failed;
      });
    }
  }

  void startAnim(){
    setState(() {
      status = Status.event_selection_anim;
    });
  }


  @override
  void initState() {
    print('START INIT STATE');
    super.initState();
    refreshLocationAndEvents();
    logoAnimCtrl = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    logoSizeAnim = Tween(begin: 200.0, end: 120.0).animate(logoAnimCtrl)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    if (Status.query_events_success == status) {
      Timer(Duration(seconds: 1), startAnim);
    } else if (Status.event_selection_anim == status) {
      if (!logoSizeAnim.isCompleted) {
        logoAnimCtrl.forward();
      } else {
        setState(() {
          status = Status.event_selection;
        });
      }
    }

    Widget bottomWidget;
    switch (status) {
      case Status.event_selection_anim:
        bottomWidget = Text("");
        break;
      case Status.event_selection:
        bottomWidget = EventSelectionWidget(events: events);
        break;
      default:
        bottomWidget = LocationStatusWidget(status: status);
    }

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(
                top: 50.0, bottom: 20.0, left: 20.0, right: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SvgPicture.asset(
                  'assets/friendship.svg',
                  width: logoSizeAnim.value,
                  height: logoSizeAnim.value,
                ),
                Text('Memories Brand',
                    style: TextStyle(fontSize: 32.0),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
          Expanded (
           child: bottomWidget,
          ),
        ],
      ),
    );
  }
}

class LocationStatusWidget extends StatelessWidget {

  LocationStatusWidget({Key key, @required this.status}): super(key: key);

  final Status status;

  @override
  Widget build(BuildContext context) {
    return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 0.0),
                child: SvgPicture.asset(
                  'assets/location.svg',
                  width: 80.0,
                  height: 80.0,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                    top: 20.0, bottom: 50.0, left: 20.0, right: 20.0),
                child: Text(
                  locationStatusText(status),
                  style: TextStyle(fontSize: 24.0),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
  }

  String locationStatusText(Status locationStatus) {
    switch (locationStatus) {
      case Status.loading:
        return 'Loading...\n';
      case Status.query_location_failed:
        return 'Unable to get location.\nPlease check your settings.';
      case Status.querying_events:
        return 'Looking for nearby events...\n';
      case Status.query_events_failed:
        return 'Error finding events.\nPlease try again later.';
      case Status.query_events_success:
        return 'Looking for nearby events...\nSuccess!';
      case Status.querying_location:
        return 'Querying location...\n';
      default:
        return '';
    }
  }
}

class EventSelectionWidget extends StatelessWidget {

  EventSelectionWidget({Key key, @required this.events}): super(key: key);

  final List<Event> events;

  String getSwipeText() {
    return (events.length > 1) ? "(swipe for more events)" : "";
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Column (
          children: <Widget>[
            Text('Are you attending',
                style: TextStyle(fontSize: 16.0),
                textAlign: TextAlign.center),
            Text("${events[0].name}?",
                style: TextStyle(fontSize: 32.0),
                textAlign: TextAlign.center),
          ],
        ),
        Column(
          children: <Widget>[
            RaisedButton(
                shape: StadiumBorder(),
                onPressed: () => CameraScreen.startForEvent(context, events[0]),
                child: Padding(
                  padding: EdgeInsets.only(left: 50.0, right: 50.0, top:10.0, bottom:10.0),
                  child: Text("Yep!",
                      style: TextStyle(fontSize:28.0),
                      textAlign: TextAlign.center),
                )
            ),
            Padding(
              padding: EdgeInsets.only(top:10.0),
              child: Text(getSwipeText(),
                  style: TextStyle(fontSize: 16.0),
                  textAlign: TextAlign.center),
            ),
          ],
        ),
        Column(
          children: <Widget>[
            IconButton(
              onPressed: () => {},
              icon: Icon(Icons.autorenew, size: 48.0,),
              color: Colors.black,
            ),
            Padding(
              padding: EdgeInsets.only(top:10.0),
              child: Text("Nope, please check again.",
                  style: TextStyle(fontSize: 16.0),
                  textAlign: TextAlign.center),
            ),
          ],
        ),
      ],
    );
  }
}


enum Status {
  loading,
  querying_location,
  query_location_failed,
  querying_events,
  query_events_failed,
  query_events_success,
  event_selection_anim,
  event_selection
}
