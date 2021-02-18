using Toybox.Application.Storage;
using Toybox.Background;
using Toybox.Communications;
using Toybox.System;
using Toybox.Position;

(:background)
class windBGService extends System.ServiceDelegate {

    var data = {};
    var dataSource = Storage.getValue("dataSource");
    var positionInfo = Position.getInfo().position.toDegrees();
    var apiKey = Storage.getValue(dataSource);
    var options = {
        :method => Communications.HTTP_REQUEST_METHOD_GET,
        :headers => {
            "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
            },
        :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON	
    };

    function initialize() {
        System.ServiceDelegate.initialize();
    }

    function onTemporalEvent() {
        requestWeatherData();
    }

    function requestWeatherData() {
        if (!System.getDeviceSettings().connectionAvailable) {Background.exit(-1);}

        data = {};


        if (positionInfo != null && apiKey != null && dataSource != null) {
            var url = null;
            var params = null;

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
                    "timesteps" => ($.isCaching) ? "30m" : "current",
                    "apikey" => apiKey
                };
                responseCallBack = method(:onReceiveClimaCellResponse);
            } else if (dataSource.equals("weatherBitAPI")) {
                //  API DOC: https://www.weatherbit.io/api/weather-current

                // TODO: hourly forecast does not return current weather conditions
                
                url = "https://api.weatherbit.io/v2.0/current";        
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
            data.put(0, {
                "wind_speed" => responseData["current"]["wind_speed"],
                "wind_gust" => responseData["current"]["wind_gust"],
                "wind_deg" => responseData["current"]["wind_deg"]
            });

            Background.exit(data);
        } else {
            Background.exit(-1);
        }
    }

    function onReceiveClimaCellResponse(responseCode, responseData) {
        if (responseCode == 200 && responseData != null) {
            var current = responseData["data"]["timelines"][0]["intervals"];

            for (var i = 0; i < current.size(); i++) {
                data.put(i, {
                    "wind_speed" => current[i]["values"]["windSpeed"] * 2.236936,
                    "wind_gust" => current[i]["values"]["windGust"] * 2.236936,
                    "wind_deg" => current[i]["values"]["windDirection"]
                });
            }

            Background.exit(data);
        } else {
            Background.exit(-1);
        }
    }

    function onReceiveWeatherBitResponse(responseCode, responseData) {
        if (responseCode == 200 && responseData != null) {
            var current = responseData["data"];

            for (var i = 0; i < current.size(); i++) {
                data.put(i, {
                    "wind_speed" => current[i]["wind_spd"],
                    "wind_deg" => current[i]["wind_dir"],
                    "wind_gust" => current[i]["wind_gust_spd"]
                });
            }

            if ($.isCaching) {
                var apiKey = Storage.getValue(dataSource);
                var url = "https://api.weatherbit.io/v2.0/forecast/hourly";
                var params = {
                    "lat" => positionInfo[0],
                    "lon" => positionInfo[1],
                    "units" => "I",
                    "key" => apiKey,
                    "hours" => 6
                };
                var responseCallBack = method(:onReceiveWeatherBitForecastResponse);
                
                Communications.makeWebRequest(url, params, options, responseCallBack);
            } else {
                Background.exit(data);
            }

        } else {
            Background.exit(-1);
        }
    }

    function onReceiveWeatherBitForecastResponse(responseCode, responseData) {
        if (responseCode == 200 && responseData != null && data.size() > 0) {
            var hourly = responseData["data"];
            for (var i = 0; i < hourly.size(); i++) {
                data.put(data.size(), {
                    "wind_speed" => hourly[i]["wind_spd"],
                    "wind_deg" => hourly[i]["wind_dir"],
                    "wind_gust" => hourly[i]["wind_gust_spd"]
                });
            }
        }
        Background.exit(data);
    }
}