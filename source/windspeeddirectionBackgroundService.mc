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
        
        // TODO: implement additional api request options: ClimaCell, YahooWeather

        // TODO: pass API request options as arguments on makeRequest()
        
        // TODO: implement ToyBox.Weather call if available, ConnectIQ 3.2 Required
        // Edge 530 requires Firmware 7 for CIQ 3.2 support

        makeRequest();
    }

    // runs when makeWebRequest receives data
    function onReceive(responseCode, data) {

        // TODO: wind data processing here

        // TODO: process data based on source

        System.println("Background - onReceive");
        // check response and data
        if (responseCode == 200 && data != null) {
            Background.exit(data);
        } else {
            Background.exit(null);
        }

    }

    // get weather data
    function makeRequest() {
        System.println("Background - makeRequest");

        // TODO: implement function parameters for url, params, options, responseCallBack

        // location from gps
        var positionInfo = Position.getInfo().position.toDegrees();

        if (positionInfo != null) {
            var url = "https://api.openweathermap.org/data/2.5/onecall";

            var params = {
                // API DOC: https://openweathermap.org/api/one-call-api
                "lat" => positionInfo[0],
                "lon" => positionInfo[1],
                "exclude" => "minutely,hourly,daily,alerts",
                "units" => "imperial",
                // api-key stored in resources.xml
                "appid" => Application.loadResource(Rez.Strings.apikey)
            };

            // JSON
            var options = {
                :method => Communications.HTTP_REQUEST_METHOD_GET,
                :headers => {
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON},
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON	
            };

            // call this method when response is received
            var responseCallBack = method(:onReceive);

            Communications.makeWebRequest(url, params, options, responseCallBack);
        } else {
            return;
        }

    }
}