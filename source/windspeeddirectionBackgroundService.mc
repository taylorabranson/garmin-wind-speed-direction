using Toybox.Application.Storage;
using Toybox.Background;
using Toybox.Communications;
using Toybox.System;
using Toybox.Position;

(:background)
class windSpeedServiceDelegate extends System.ServiceDelegate {

    function initialize() {
        System.ServiceDelegate.initialize();
        // System.println("BG - Initialize");
    }

    function onTemporalEvent() {
        // System.println("BG - onTemporalEvent");
        requestWeatherData();
    }

    function requestWeatherData() {
        // System.println("BG - requestWeatherData");
        var dataSource = Storage.getValue("dataSource");
        var positionInfo = Position.getInfo().position.toDegrees();
        var apiKey = Storage.getValue(dataSource);

        if (positionInfo != null && apiKey != null && dataSource != null) {
            var url = null;
            var params = null;
            var options = {
                :method => Communications.HTTP_REQUEST_METHOD_GET,
                :headers => {
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
                    },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON	
            };
            var responseCallBack = null;

            if (dataSource.equals("openWeatherAPI")) {
                // API DOC: https://openweathermap.org/api/one-call-api
                url = "https://api.openweathermap.org/data/2.5/onecall";
                params = {
                    "lat" => positionInfo[0],
                    "lon" => positionInfo[1],
                    "exclude" => "minutely,hourly,daily,alerts",
                    "units" => "imperial",
                    "appid" => apiKey
                };
                responseCallBack = method(:onReceiveOpenWeatherResponse);
            } else if (dataSource.equals("climaCellAPI")) {
                // API DOC: https://docs.climacell.co/reference/api-overview
                url = "https://data.climacell.co/v4/timelines";
                params = {
                    "location" => positionInfo[0] + "," + positionInfo[1],
                    "fields" => "windSpeed,windDirection,windGust",
                    "timesteps" => "current",
                    "apikey" => apiKey
                };
                responseCallBack = method(:onReceiveClimaCellResponse);
            } else if (dataSource.equals("weatherBitAPI")) {
                //  API DOC: https://www.weatherbit.io/api/weather-current
                url = "http://api.weatherbit.io/v2.0/current";
                params = {
                    "lat" => positionInfo[0],
                    "lon" => positionInfo[1],
                    "units" => "I",
                    "key" => apiKey
                };
                responseCallBack = method(:onReceiveWeatherBitResponse);
            } else {
                Background.exit(-1);
            }

            Communications.makeWebRequest(url, params, options, responseCallBack);
        } else {
            Background.exit(-1);
        }
    }

    function onReceiveOpenWeatherResponse(responseCode, responseData) {
        if (responseCode == 200 && responseData != null) {
            var data = {
                "wind_speed" => responseData["current"]["wind_speed"],
                "wind_gust" => responseData["current"]["wind_gust"],
                "wind_deg" => responseData["current"]["wind_deg"]
            };
            Background.exit(data);
        } else {
            Background.exit(-1);
        }
    }

    function onReceiveClimaCellResponse(responseCode, responseData) {
        if (responseCode == 200 && responseData != null) {
            var current = responseData["data"]["timelines"][0]["intervals"][0]["values"];
            var data = {
                "wind_speed" => current["windSpeed"] * 2.236936,
                "wind_gust" => current["windGust"] * 2.236936,
                "wind_deg" => current["windDirection"]
            };
            Background.exit(data);
        } else {
            Background.exit(-1);
        }
    }

    function onReceiveWeatherBitResponse(responseCode, responseData) {
        if (responseCode == 200 && responseData != null) {
            var current = responseData["data"][0];
            var data = {
                "wind_speed" => current["wind_spd"],
                "wind_deg" => current["wind_dir"],
                "wind_gust" => 0
            };
            Background.exit(data);
        } else {
            Background.exit(-1);
        }
    }
}