using Toybox.Application;
using Toybox.Background;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi;

var windSpeed = 0;
var windGust = 0;
var windDirection = 0;
var unitsType = "mph";
var mostRecentData = {
    "wind_speed" => 0,
    "wind_gust" => 0,
    "wind_deg" => 0,
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
            var unitsOptions = {1 => "mph", 2 => "m/s"};
            $.unitsType = unitsOptions[userUnitsChoice];

            var windDataSource = getProperty("windDataSource");
            var apiOptions = {1 => "openWeatherAPI", 2 => "climaCellAPI"};
            Storage.setValue("dataSource", apiOptions[windDataSource]);

            Storage.setValue("openWeatherAPI", getProperty("OpenWeatherKey"));
            Storage.setValue("climaCellAPI", getProperty("ClimaCellKey"));
        } catch (exception instanceof ObjectStoreAccessException) {
            exception.printStackTrace();
        } catch (exception) {
            exception.printStackTrace();
        }

        if ($.mostRecentData["last_updated"] != null) {   
            loadWindData($.mostRecentData);
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

            if (data["wind_speed"] == null) {
                data["wind_speed"] = 0;
            }
            if (data["wind_gust"] == null) {
                data["wind_gust"] = 0;
            }
            if (data["wind_deg"] == null) {
                data["wind_deg"] = 0;
            }

            cacheWindData(data);
            loadWindData(data);
        } else {
            System.println("App - No Data from BG");
        }
        WatchUi.requestUpdate();
    }

    function getServiceDelegate(){
        return [new windSpeedServiceDelegate()];
    }

    function cacheWindData(data) {
        // System.println("Save wind data");
        $.mostRecentData["wind_speed"] = data["wind_speed"];
        $.mostRecentData["wind_gust"] = data["wind_gust"];
        $.mostRecentData["wind_deg"] = data["wind_deg"];
        $.mostRecentData["last_updated"] = new Time.Moment(Time.now().value());
    }

    function convertWindData(windspeed, windgust) {       
        // System.println("Convert Data to : " + $.unitsType);
        var returnData = {};
        if ($.unitsType.equals("mph")) {
            returnData.put("wind_speed", windspeed);
            returnData.put("wind_gust", windgust);
        } else if ($.unitsType.equals("m/s")) {
            returnData.put("wind_speed", (windspeed / 2.2369363));
            returnData.put("wind_gust", (windgust / 2.2369363));
        }
        System.println("Data converted");
        return returnData;
    }

    function loadWindData(data) {
        // System.println("Load Wind Data");

        var convertedData = convertWindData(data["wind_speed"], data["wind_gust"]);
        convertedData.put("wind_deg", data["wind_deg"]);

        $.windSpeed = convertedData["wind_speed"];
        $.windGust = convertedData["wind_gust"];
        $.windDirection = convertedData["wind_deg"];
    }

}