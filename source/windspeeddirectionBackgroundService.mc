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
        makeRequestOpenWeather();
    }

    // runs when makeWebRequest receives data
    function onReceiveOpenWeatherResponse(responseCode, responseData) {

        // TODO: wind data processing here

        // TODO: process data based on source

        System.println("Background - onReceive");
        System.println(responseCode);
        // check response and data
        if (responseCode == 200 && responseData != null) {
            var data = {
                "wind_speed" => responseData["current"]["wind_speed"],
                "wind_deg" => responseData["current"]["wind_deg"],
                "wind_gust" => responseData["current"]["wind_gust"],
                "current_time" => responseData["current"]["dt"]
            };
            Background.exit(data);
        } else {
            System.println("Background - onReceive - noData");
            Background.exit(-1);
        }

    }

    function makeRequestOpenWeather() {
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
        
        var apiKey = Storage.getValue("apikey");

        System.println(apiKey);
        Test.assert(apiKey != null);
        
        var positionInfo = Position.getInfo().position.toDegrees();
        
        // OpenWeather
        if (positionInfo != null ) {

            url = "https://api.openweathermap.org/data/2.5/onecall";
            
            params = {
                // API DOC: https://openweathermap.org/api/one-call-api
                "lat" => positionInfo[0],
                "lon" => positionInfo[1],
                "exclude" => "minutely,hourly,daily,alerts",
                "units" => "imperial",
                // api-key stored in resources.xml
                "appid" => apiKey

            };
        }

        Communications.makeWebRequest(url, params, options, responseCallBack);
    }
}