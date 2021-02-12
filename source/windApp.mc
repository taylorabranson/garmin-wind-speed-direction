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
class windApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
        loadUserSettings();
    }

    // function onStop(state) {
    // }

    function onSettingsChanged() {
        loadUserSettings();
    }

    function loadUserSettings() {
        try {
            var userUnitsChoice = getProperty("unitsType");
            var unitsOptions = {1 => "mph", 2 => "m/s"};
            $.unitsType = unitsOptions[userUnitsChoice];

            var windDataSource = getProperty("windDataSource");
            var apiOptions = {
                1 => "openWeatherAPI", 
                2 => "climaCellAPI", 
                3 => "weatherBitAPI"
                };
            Storage.setValue("dataSource", apiOptions[windDataSource]);

            Storage.setValue("openWeatherAPI", getProperty("OpenWeatherKey"));
            Storage.setValue("climaCellAPI", getProperty("ClimaCellKey"));
            Storage.setValue("weatherBitAPI", getProperty("WeatherBitKey"));

            setBackgroundUpdate(getProperty("updateFrequency"));

        } catch (exception instanceof ObjectStoreAccessException) {
            // exception.printStackTrace();
        } catch (exception) {
            // exception.printStackTrace();
        }

        if ($.mostRecentData["last_updated"] != null) {   
            loadWindData($.mostRecentData);
        }
    }

    function getInitialView() {
        loadUserSettings();
        return [ new windView() ];
    }

    function onBackgroundData(data) {
        if (!data.equals(-1)) {
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
        }
        WatchUi.requestUpdate();
    }

    function getServiceDelegate(){
        return [new windBGService()];
    }

    function setBackgroundUpdate(minutes) {
        if (Toybox.System has :ServiceDelegate) {
            Background.registerForTemporalEvent(new Time.Duration(minutes * 60));
        } else {
            System.exit();
        }
    }

    function cacheWindData(data) {
        $.mostRecentData["wind_speed"] = data["wind_speed"];
        $.mostRecentData["wind_gust"] = data["wind_gust"];
        $.mostRecentData["wind_deg"] = data["wind_deg"];
        $.mostRecentData["last_updated"] = new Time.Moment(Time.now().value());
    }

    function convertWindData(windspeed, windgust) {       
        var returnData = {};
        if ($.unitsType.equals("mph")) {
            returnData.put("wind_speed", windspeed);
            returnData.put("wind_gust", windgust);
        } else if ($.unitsType.equals("m/s")) {
            returnData.put("wind_speed", (windspeed / 2.2369363));
            returnData.put("wind_gust", (windgust / 2.2369363));
        }

        return returnData;
    }

    function loadWindData(data) {
        var convertedData = convertWindData(data["wind_speed"], data["wind_gust"]);

        $.windSpeed = convertedData["wind_speed"];
        $.windGust = convertedData["wind_gust"];
        $.windDirection = data["wind_deg"];
    }

}