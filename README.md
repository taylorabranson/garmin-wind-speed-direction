# garmin-wind-speed-direction
ConnectIQ Datafield for Garmin Edge devices, shows wind direction and speed.

### Setup:
Create an account for one or more weather API:

  - OpenWeather https://openweathermap.org/api
  - ClimaCell https://docs.climacell.co/reference/api-overview
  - YahooWeather https://developer.yahoo.com/weather/

Enter API Keys in settings.xml

Then enter the API key(s) in settings on Garmin Connect. (API keys sometimes take a few hours before they become active) (Not implemented)

Create a build for your device using Garmin Connect IQ SDK.

Side load application on device.

NOTE: Settings (in the Garmin Connect mobile app) are only available for apps downloaded from the Garmin Connect Store. And so, entering API keys, selecting data source, etc. are unavailable when side loading.

## Features
  - User selects unit type for wind speed (m/s, mph, kph)
  - User selects data source
  - User inputs api-key
  - Show connection info if no connection available
  
### TODO


### Planned Features
  - Use ClimaCell's wind forecast to provide wind data in absence of data connection
