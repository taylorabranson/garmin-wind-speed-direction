using Toybox.Application;
using Toybox.Background;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi;

var windSpeed = 0;
var windGust = 0;
var windDirection = 0;
var unitsType = null;
var mostRecentData = {
    "wind_speed" => null,
    "wind_gust" => null,
    "wind_deg" => null,
    "last_updated" => null
};

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

        if ($.mostRecentData["last_updated"] != null) {   
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

            $.mostRecentData["wind_speed"] = data["wind_speed"];
            $.mostRecentData["wind_gust"] = data["wind_gust"];
            $.mostRecentData["wind_deg"] = data["wind_deg"];
            $.mostRecentData["last_updated"] = new Time.Moment(Time.now().value());

            loadData(data);
        } else {
            System.println("App - No Data from BG");
        }
        WatchUi.requestUpdate();
    }

    function getServiceDelegate(){
        return [new windSpeedServiceDelegate()];
    }

    function convertData(windspeed, windgust) {       
        System.println("Convert Data to : " + $.unitsType);
        var returnData = {};
        if ($.unitsType.equals("imperial")) {
            returnData.put("wind_speed", windspeed);
            returnData.put("wind_gust", windgust);
        } else if ($.unitsType.equals("metric")) {
            returnData.put("wind_speed", (windspeed / 2.2369363));
            if (windgust != null) {
                returnData.put("wind_gust", (windgust / 2.2369363));
            } else {
                returnData.put("wind_gust", 0);
            }
        }
        return returnData;
    }

    function loadData(data) {
        var convertedData = convertData(data["wind_speed"], data["wind_gust"]);
        convertedData.put("wind_deg", data["wind_deg"]);

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