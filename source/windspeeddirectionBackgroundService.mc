using Toybox.Application.Storage;
using Toybox.Background;
using Toybox.Communications;
using Toybox.System;
using Toybox.Position;

(:background)
class windSpeedServiceDelegate extends System.ServiceDelegate {

    function initialize() {
        System.ServiceDelegate.initialize();
        System.println("Background - Initialize");
    }

    function onTemporalEvent() {
        var positionInfo = Position.getInfo().position.toDegrees();

        // TODO: makeWebRequest based on user setting
        makeRequestClimaCell(positionInfo);
        // makeRequestOpenWeather(positionInfo);
    }

    // runs when makeWebRequest receives data
    function onReceiveOpenWeatherResponse(responseCode, responseData) {
        System.println("Background - onReceive");
        System.println(responseCode);
        
        if (responseCode == 200 && responseData != null) {
            var data = {
                "wind_speed" => responseData["current"]["wind_speed"],
                "wind_gust" => responseData["current"]["wind_gust"],
                "wind_deg" => responseData["current"]["wind_deg"]
            };
            Background.exit(data);
        } else {
            System.println("Background - onReceive - noData");
            Background.exit(-1);
        }

    }

    function makeRequestOpenWeather(positionInfo) {
        if (positionInfo != null ) {
            var url = null;
            var params = null;
            var options = {
                :method => Communications.HTTP_REQUEST_METHOD_GET,
                :headers => {
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
                    },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON	
            };
            var responseCallBack = method(:onReceiveOpenWeatherResponse);
            
            var apiKey = Storage.getValue("apikeyOpenWeather");

            System.println(apiKey);
                
            url = "https://api.openweathermap.org/data/2.5/onecall";
            System.println("url");
            params = {
                // API DOC: https://openweathermap.org/api/one-call-api
                "lat" => positionInfo[0],
                "lon" => positionInfo[1],
                "exclude" => "minutely,hourly,daily,alerts",
                "units" => "imperial",
                "appid" => apiKey
            };
            System.println("params");

            Communications.makeWebRequest(url, params, options, responseCallBack);
        } else {
            Background.exit(-1);
        }
    }

    function makeRequestClimaCell(positionInfo) {
        var url = null;
        var params = null;
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
                },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        var responseCallBack = method(:onReceiveClimaCellResponse);

        var apiKey = Storage.getValue("apikeyClimaCell");

        System.println(apiKey);

        url = "https://data.climacell.co/v4/timelines";

        params = {
            // API DOC: https://docs.climacell.co/reference/api-overview
            "location" => positionInfo[0] + "," + positionInfo[1],
            "fields" => "windSpeed,windDirection,windGust",
            // TODO: update timestep to "current" when API is updated
            "timesteps" => "15m",
            "apikey" => apiKey
        };

        Communications.makeWebRequest(url, params, options, responseCallBack);
    }

    function onReceiveClimaCellResponse(responseCode, responseData) {
        System.println("Background - onReceive");
        System.println(responseCode);

        if (responseCode == 200 && responseData != null) {
            var currentWeather = responseData["data"]["timelines"][0]["intervals"][0]["values"];
            var data = {
                "wind_speed" => currentWeather["windSpeed"] * 2.236936,
                "wind_gust" => currentWeather["windGust"] * 2.236936,
                "wind_deg" => currentWeather["windDirection"]
            };
            Background.exit(data);
        } else {
            System.println("Background - onReceive - noData");
            Background.exit(-1);
        }
    }
}