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

    // TODO: implement settings from Garmin app for:
    // weather data source, update frequency, etc.

    function initialize() {
        System.println("App - Initialize");
        AppBase.initialize();
        loadUserSettings();
    }

    function loadUserSettings() {
        System.println("App - Load User Settings");
        try {
            Storage.setValue("openWeatherAPI", Application.loadResource(Rez.Strings.apikeyOpenWeather));
            Storage.setValue("climaCellAPI", Application.loadResource(Rez.Strings.apikeyClimaCell));

            var dataSource = Application.Properties.getValue("windDataSource");
            var dataSourceOptions = {
                1 => "openWeatherAPI",
                2 => "climaCellAPI"
            };
            Storage.setValue("dataSource", dataSourceOptions[dataSource]);

            // TODO: read apikey from user settings

            System.println("App - Settings added to Object Store");
        } catch (exception instanceof ObjectStoreAccessException) {
            System.println("BG - not allowed to modify object store");
        } catch (exception) {
                exception.printStackTrace();
        }
    }

    function onStart(state) {
        // System.println("App - Start Up");
    }

    function onStop(state) {
        // System.println("App - Stopping");
    }

    function getInitialView() {
        // System.println("App - Get Initial View");
        if (Toybox.System has :ServiceDelegate) {
            Background.registerForTemporalEvent(new Time.Duration(5 * 60));
            // System.println("App - registerTemporalEvent");
        } else {
            System.println("Device doesn't support background service");
            System.exit();
        }
        return [ new windspeeddirectionView() ];
    }

    function onBackgroundData(data) {
        System.println("App - OnBackgroundData");
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