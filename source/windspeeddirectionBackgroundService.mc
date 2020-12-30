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
        System.println("Background - onTemporalEvent");
        var url = null;
        var params = null;
        
        // TODO: implement additional api request options: ClimaCell, YahooWeather
        var apiKey = Storage.getValue("apikey");

        System.println(apiKey);
        Test.assert(apiKey != null);
        
        // TODO: implement ToyBox.Weather call if available, ConnectIQ 3.2 Required
        // Edge 530 requires Firmware 7 for CIQ 3.2 support

        // location from gps
        var positionInfo = Position.getInfo().position.toDegrees();
        System.println(positionInfo);
        
        // OpenWeather
        if (positionInfo != null ) {
            System.println("Background - onTemporalEvent - posNotNull");

            // TODO: add check for api choice in settings
            if (true) {
                url = "https://api.openweathermap.org/data/2.5/onecall";
                System.println("Background - onTemporalEvent - posNotNull - urlSet");
                
                params = {
                    // API DOC: https://openweathermap.org/api/one-call-api
                    "lat" => positionInfo[0],
                    "lon" => positionInfo[1],
                    "exclude" => "minutely,hourly,daily,alerts",
                    "units" => "imperial",
                    // api-key stored in resources.xml
                    "appid" => apiKey
                };
                System.println("Background - onTemporalEvent - posNotNull - paramsSet");
            }
            System.println("Background - onTemporalEvent - posNotNull - makeRequest");
            makeRequest(url, params);
        }

        if (url != null && params != null) {
            System.println("Background - onTemporalEvent - makeRequest");
            makeRequest(url, params);
        }

    }

    // runs when makeWebRequest receives data
    function onReceive(responseCode, data) {

        // TODO: wind data processing here

        // TODO: process data based on source

        System.println("Background - onReceive");
        System.println(responseCode);
        // check response and data
        if (data != null) {
            System.println("Background - onReceive - dataNotNull");
            Background.exit(data);
        } else {
            System.println("Background - onReceive - dataNull");
            Background.exit(-1);
        }

    }

    // get weather data
    function makeRequest(url, params) {
        System.println("Background - makeRequest");

        // JSON
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON},
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON	
        };
        System.println("Background - makeRequest - optionsSet");

        // call this method when response is received
        var responseCallBack = method(:onReceive);
        System.println("Background - makeRequest - callbackSet");

        Communications.makeWebRequest(url, params, options, responseCallBack);
    }
}