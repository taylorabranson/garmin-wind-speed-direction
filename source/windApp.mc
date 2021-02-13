using Toybox.Application;
using Toybox.Background;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi;

var windSpeed = 0;
var windGust = 0;
var windDirection = 0;

var isCaching = true;

var lastUpdated = null;
var unitsType = "mph";

(:background)   
class windApp extends Application.AppBase {

    var forecast = {};
    var interval = 30;
    
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
        loadWindData();
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

            isCaching = getProperty("cacheClimaCell");

        } catch (exception instanceof ObjectStoreAccessException) {
            // exception.printStackTrace();
        } catch (exception) {
            // exception.printStackTrace();
        }
    }

    function getInitialView() {
        loadUserSettings();
        return [ new windView() ];
    }

    function onBackgroundData(data) {
        if (!data.equals(-1)) {
            for (var i = 0; i < data.size(); i++) {
                if (data[i]["wind_speed"] == null) {
                    data[i]["wind_speed"] = 0;
                }
                if (data[i]["wind_gust"] == null) {
                    data[i]["wind_gust"] = 0;
                }
                if (data[i]["wind_deg"] == null) {
                    data[i]["wind_deg"] = 0;
                }
            }

            cacheWindData(data);
        }

        loadWindData();
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
        $.lastUpdated = new Time.Moment(Time.now().value());
        forecast = {};

        for (var i = 0; i < data.size(); i++) {
            forecast.put(i, data[i]);
        }
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

    function loadWindData() {
        if ($.lastUpdated == null) {
            return;
        }

        var sec = $.lastUpdated.subtract(Time.now()).value();
        var entry = (sec / 60) / interval;
        entry = entry.toNumber();
        if (forecast.hasKey(entry)) {
            var current = forecast.get(entry);
            var converted = convertWindData(current["wind_speed"], current["wind_gust"]);

            $.windSpeed = converted["wind_speed"];
            $.windGust = converted["wind_gust"];
            $.windDirection = current["wind_deg"];
        } else {
            var converted = convertWindData(forecast[0]["wind_speed"], forecast[0]["wind_gust"]);
            $.windSpeed = converted["wind_speed"];
            $.windGust = converted["wind_gust"];
            $.windDirection = forecast[0]["wind_deg"];
        }
    }

}