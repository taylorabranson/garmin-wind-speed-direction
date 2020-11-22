using Toybox.Application;
using Toybox.Background;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi as Ui;

// wind data for view
var windSpeed = 0;
var windGust = 0;
var windDirection = 0;
var lastUpdated = null;

(:background)
class windspeeddirectionApp extends Application.AppBase {

    // TODO: implement settings from Garmin app for:
    // weather data source, update frequency, etc.

    function initialize() {
        System.println("App - Initialize");
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
        System.println("App - Start Up");
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
        System.println("App - Stopping");
    }

    //! Return the initial view of your application here
    function getInitialView() {
        System.println("App - Get Initial View");
        if(Toybox.System has :ServiceDelegate) {
            // starts Temporal Event
            Background.registerForTemporalEvent(new Time.Duration(5 * 60));
            System.println("App - registerTemporalEvent");
        }
        return [ new windspeeddirectionView() ];
    }

    // receives data from background process
    function onBackgroundData(data) {
        // TODO: change data handling in line with upcoming background service changes
        System.println("App - OnBackgroundData");
        if (data != null) {
            System.println("App - Good data from BG");

            // process weather data
            $.windSpeed = data["current"]["wind_speed"];
            if ($.windSpeed == null) {
                $.windSpeed = 0;
            }
            $.windDirection = data["current"]["wind_deg"];
            if ($.windDirection == null) {
                $.windDirection = 0;
            }
            $.windGust = data["current"]["wind_gust"];
            if ($.windGust == null) {
                $.windGust = 0;
            }

            $.lastUpdated = new Time.Moment(data["current"]["dt"]);
        } else {
            System.println("App - No Data from BG");
        }
        Ui.requestUpdate();
    }

    // starts background service
    function getServiceDelegate(){
        return [new windSpeedServiceDelegate()];
    }

}