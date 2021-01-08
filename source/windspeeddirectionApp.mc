using Toybox.Application;
using Toybox.Background;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi;

var windSpeed = 0;
var windGust = 0;
var windDirection = 0;
var lastUpdated = null;
var unitsType = null;
var mostRecentData = null;

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
            var userUnitsChoice = getProperty("unitsType");
            var unitsOptions = {1 => "imperial", 2 => "metric"};
            $.unitsType = unitsOptions[userUnitsChoice];

            var windDataSource = getProperty("windDataSource");
            var apiOptions = {1 => "openWeatherAPI", 2 => "climaCellAPI"};
            Storage.setValue("dataSource", apiOptions[windDataSource]);

            Storage.setValue("openWeatherAPI", Application.loadResource(Rez.Strings.apikeyOpenWeather));
            Storage.setValue("climaCellAPI", Application.loadResource(Rez.Strings.apikeyClimaCell));
        } catch (exception instanceof ObjectStoreAccessException) {
            System.println(exception.getErrorMessage());
        } catch (exception) {
            System.println(exception.printStackTrace());
        }

        if ($.lastUpdated != null && $.mostRecentData != null) {
            loadData($.mostRecentData);
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

            $.mostRecentData = data;

            loadData(data);

            $.lastUpdated = new Time.Moment(Time.now().value());
        } else {
            System.println("App - No Data from BG");
        }
        WatchUi.requestUpdate();
    }

    function getServiceDelegate(){
        return [new windSpeedServiceDelegate()];
    }

    function convertData(data) {
        var unitsType = Storage.getValue("unitsType");
        
        if (unitsType.equals("imperial")) {
            return data;
        } else if (unitsType.equals("metric")) {
            data["wind_speed"] = data["wind_speed"] / 2.2369363;
            if (data["wind_gust"] != null) {
                data["wind_gust"] = data["wind_gust"] / 2.2369363;
            }
        } else {
            System.println("Unit Type Property - invalid or not set");
        }
        return data;
    }

    function loadData(data) {
        var convertedData = convertData(data);

        $.windSpeed = convertedData["wind_speed"];
        if ($.windSpeed == null) {
            $.windSpeed = 0;
        }
        $.windGust = convertedData["wind_gust"];
        if ($.windGust == null) {
            $.windGust = 0;
        }
        $.windDirection = convertedData["wind_deg"];
        if ($.windDirection == null) {
            $.windDirection = 0;
        }
    }

}