using Toybox.Application;
using Toybox.Background;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi;

var windSpeed = 0;
var windGust = 0;
var windDirection = 0;
var lastUpdated = null;

(:background)   
class windspeeddirectionApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
        // System.println("App - Initialize");
        loadUserSettings();
    }

    // function onStart(state) {
    // }

    // function onStop(state) {
    // }

    function onSettingsChanged() {
        loadUserSettings();
    }

    // TODO: implement settings from Garmin app for:
    // weather data source, update frequency, etc.
    function loadUserSettings() {
        // TODO: read apikey from user settings
        try {
            var windDataSource = getProperty("windDataSource");
            var options = {1 => "openWeatherAPI", 2 => "climaCellAPI"};
            Storage.setValue("dataSource", options[windDataSource]);
            Storage.setValue("openWeatherAPI", Application.loadResource(Rez.Strings.apikeyOpenWeather));
            Storage.setValue("climaCellAPI", Application.loadResource(Rez.Strings.apikeyClimaCell));
        } catch (exception instanceof ObjectStoreAccessException) {
            System.println(exception.getErrorMessage());
        } catch (exception) {
            System.println(exception.printStackTrace());
        }
    }

    function getInitialView() {
        if (Toybox.System has :ServiceDelegate) {
            Background.registerForTemporalEvent(new Time.Duration(5 * 60));
        } else {
            System.println("Device doesn't support background service");
            System.exit();
        }
        return [ new windspeeddirectionView() ];
    }

    function onBackgroundData(data) {
        if (!data.equals(-1)) {
            System.println("App - Good data from BG");

            $.windSpeed = data["wind_speed"];
            if ($.windSpeed == null) {
                $.windSpeed = 0;
            }
            $.windGust = data["wind_gust"];
            if ($.windGust == null) {
                $.windGust = 0;
            }
            $.windDirection = data["wind_deg"];
            if ($.windDirection == null) {
                $.windDirection = 0;
            }

            $.lastUpdated = new Time.Moment(Time.now().value());
        } else {
            System.println("App - No Data from BG");
        }
        WatchUi.requestUpdate();
    }

    function getServiceDelegate(){
        return [new windSpeedServiceDelegate()];
    }

}