![WeatherKit: A simple concise kit for weather](https://cloud.githubusercontent.com/assets/13768613/18399821/5bfcc264-76a9-11e6-8dd1-f83e7ea3c34b.png)
![Cocoapods](https://img.shields.io/badge/Cocoapods-1.1.0rc2-green.svg)
![Swift2.3](https://img.shields.io/badge/Swift2.3-support-green.svg)
![Swift3.x](https://img.shields.io/badge/Swift3.x-support-green.svg)
<br>
WeatherKit is simple kit for weather information in Swift
<br>
## Features:
- Weather/Forecasts for locations
- Weather/Forecasts for cities by name
- Unit conversions
- City searching and location parsing

## Requirements:
- iOS 9.0+
- Xcode 7.3+

## Installation:
WeatherKit can be installed through Cocoapods or manual import. 
### Cocoapods:
```bash
$ gem install cocoapods
```
After installation of cocoapods, create a file named `Podfile` at the root directory of the project:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'WeatherKit'
end
```

Then, run the following command:

```bash
$ pod install
```
## Usage:
Kit imports
``` swift
import WeatherKit
```
### WeatherStation.swift
WeatherStation is the interface which retrieves weather/forecast information<br>
The contructor accepts 4 units parameters with default values, which will be used to convert weather/forecast information<br>

``` swift
public init(temperatureUnit tunit: TemperatureUnit = .celsius, distanceUnit: DistanceUnit = .mi, directionUnit: DirectionUnit = .direction, speedUnit: SpeedUnit = .mph)
```

#### Load weather/forecasts for a location
``` swift
let station = WeatherStation()
station.weather(location: someLocation) { result in 
     switch result {
     case .Success(let json): // Get a single weather json
          // Do something
     case .Failure(let error):
          // Error handling
     }
}
station.forecast(location: someLocation) { result in
     switch result {
     case .Success(let jsons): // Get an array of forecast json
          // Do something
     case .Failure(let error):
          // Error handling
     }
}
```

#### Load weather/forecasts for a city
With default values for province and country, so the two parameters can be skipped<br>
But searching with those two parameters can increase the accuracy of search
``` swift
let station = WeatherStation()
station.weather(city: "cityName", province: "provinceName", country: "countryName") { result in
     switch result {
     case .Success(let json): // Get a single weather json
          // Do something
     case .Failure(let error):
          // Error handling
     }
}
station.weather(city: "cityName") { result in  // The province and country can be skipped
     switch result {
     case .Success(let json): // Get a single weather json
          // Do something
     case .Failure(let error):
          // Error handling
     }
}
station.forecast(city: "cityName", province: "provinceName", country: "countryName") { result in
     switch result {
     case .Success(let jsons): // Get an array of forecast json
          // Do something
     case .Failure(let error):
          // Error handling
     }
}
```

##### Content of JSON:
There are two JSON types: weather& forecast. The details are listed below
``` swift
/*weather json*/
weatherJSON["temperature"] // Double value about the weather temperature
weatherJSON["condition"] // String value about the weather condition
weatherJSON["conditionCode"] // Int value, code of the condition
weatherJSON["windChill"] // Double value about the wind temperature
weatherJSON["windSpeed"] // Double value about the wind speed
weatherJSON["windDirection"] // Double value about the direction of winds
weatherJSON["humidity"] // String value about the humidity
weatherJSON["visibility"] // Double value about the visibility
weatherJSON["pressure"] // String value about the pressure
weatherJSON["trend"] // String value about the pressure trend
weatherJSON["sunrise"] // NSDateComponents value
weatherJONS["sunset"] // NSDateComponents value

/*forecast json*/
forecastJSON["high"] // Double value about the highest temperature
forecastJSON["low"] // Double value about the lowest temperature
forecastJSON["date"] // String value about the forecast date
forecastJSON["text"] // String value about the forecast condition
forecastJSON["day"] // String value about the weekday the forecast is for
forecastJSON["code"] // String value about the weather condition code
```

#### Cache clear:
By default, weather station keeps caches which speed up the loading process<br>
Normally, caches will be replaced and auto-cleared<br>
But weather station also offers the option to clear cache manually<br>
``` swift
let station = WeatherStation()
station.clearCache()
```

### CityLoader.swift
CityLoader is the main access for loading city information and parsing location information<br>
The constructor accepts no parameters, which makes CityLoader easier to be instanced<br>
#### Load city information:
With default values for province and country, so the two parameters can be skipped<br>
But searching with those two parameters can increase the accuracy of search
``` swift
let loader = CityLoader()
loader.loadCity(city: "cityName", province: "provinceName", country: "countryName") { result in
     // result is an array of city JSONs
     // If no city matches the description, or any error happens, result is empty
}
```
Another way to load a city is searching by WOEID, which is a unique value used to locate a city
``` swift
let loader = CityLoader()
loader.loadCity(woeid: "SomeWOEID") { result in 
     // result is an optional typed JSON (Dictionary<String, AnyObject>?)
     // If no city matches the woeid, or any error happens, then the result == nil
}

#### Load sunrise& sunset information:
City loader can also check sunrise& sunset time for a city with the woeid, the result will be given back as a tuple of two optional NSDateComponents <br>
``` swift
let loader = CityLoader()
loader.dayNight(woeid: "someWOEID") { sunrise, sunset in
     // sunrise and sunset can be nil
}
```

#### Location parse:
City loader can parse the information of a CLLocation value, and return a city json back.
``` swift
let loader = CityLoader()
loader.locationParse(location: someLocation) { city in 
     // city can be nil
     // if city is not nil, city is a Dictionary<String, AnyObject>
}
```

##### Content of JSON:
Below is the content of a city json
``` swift
cityJSON["name"] //String value about the name of the city
cityJSON["admin1"] //String value about the name of the province or state
cityJSON["country"] //String  value about the name of the country
cityJSON["woeid"] //String value about the woeid of the city
cityJSON["centroid"]?["latitude"] //String value about the latitude information of the city
cityJSON["centroid"]?["longitude"] //String value about the longitude information of the city
cityJSON["timezone"] //String value about the timezone label of the city
```

## License

WeatherKit is released under the MIT license. See LICENSE for details.
