using Toybox.Background;
using Toybox.Communications;
using Toybox.System;
using Toybox.Position;

(:background)
class windSpeedServiceDelegate extends System.ServiceDelegate {
    // When a scheduled background event triggers, make a request to
    // a service and handle the response with a callback function
    // within this delegate.

    function initialize() {
        System.ServiceDelegate.initialize();
        System.println("Background - Initialize");
    }

    function onTemporalEvent() {
        System.println("Background - onTemporalEvent");
        makeRequest();
    }

    // runs when makeWebRequest receives data
    function onReceive(responseCode, data) {
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

            // GET JSON
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