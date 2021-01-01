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
        // TODO: makeWebRequest based on user setting
        
        // var dataSource = Storage.getProperty(dataSource);
        // System.println(dataSource);
        
        requestWeatherData("climaCellAPI");
        // requestWeatherData("openWeatherAPI");
    }

    function requestWeatherData(dataSource) {
        var positionInfo = Position.getInfo().position.toDegrees();
        var apiKey = Storage.getValue(dataSource);

        if (positionInfo != null && apiKey != null) {
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
                url = "https://api.openweathermap.org/data/2.5/onecall";
                params = {
                    // API DOC: https://openweathermap.org/api/one-call-api
                    "lat" => positionInfo[0],
                    "lon" => positionInfo[1],
                    "exclude" => "minutely,hourly,daily,alerts",
                    "units" => "imperial",
                    "appid" => apiKey
                };
                responseCallBack = method(:onReceiveOpenWeatherResponse);
            } else if (dataSource.equals("climaCellAPI")) {
                url = "https://data.climacell.co/v4/timelines";
                params = {
                    // API DOC: https://docs.climacell.co/reference/api-overview
                    "location" => positionInfo[0] + "," + positionInfo[1],
                    "fields" => "windSpeed,windDirection,windGust",
                    // TODO: update timestep to "current" when API is updated
                    "timesteps" => "15m",
                    "apikey" => apiKey
                };
                responseCallBack = method(:onReceiveClimaCellResponse);
            } else {
                System.println("Not a valid data source");
                Background.exit(-1);
            }

            Communications.makeWebRequest(url, params, options, responseCallBack);

        } else {
            Background.exit(-1);
        }
    }

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