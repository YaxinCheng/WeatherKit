//
//  WeatherSourceSQL.swift
//  Weather
//
//  Created by Yaxin Cheng on 2016-08-12.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

enum WeatherSourceSQL: String {
	/**
	The SQL used for loading weather information
	*/
	case weather = "select wind, atmosphere, item.condition, astronomy from weather.forecast where woeid = \"%@\""
	/**
	The SQL used for loading forecast information
	*/
	case forecast = "select item.forecast from weather.forecast where woeid = \"%@\""
	/**
	The SQL for city information by city name
	*/
	case cityFromName = "select name, country.content,admin1.content,woeid,centroid,timezone.content from geo.places where text=\"%@\""
	/**
	The SQL for city information by WOEID
	*/
	case cityFromWoeid = "select name, country.content,admin1.content,woeid,centroid,timezone.content from geo.places where woeid=\"%@\""
	/**
	The SQL for day time information by WOEID
	*/
	case daytime = "select astronomy from weather.forecast where woeid = \"%@\""
	
	/**
	Execute the SQL with extra information to download related JSON. At the end of the function, the function bypasses calls to a delegate method
	- Parameter info: Extra information needed for the SQL
	- Parameter ignoreCache: 
		A boolean value decides if skipping the local cache.
		false by default
	- Parameter complete: 
		A delegate method used to call at the end of the function.
		Result can contain a generic type or an ErrorType
	*/
	func execute(information info: String, ignoreCache: Bool = false, completion: @escaping (Result<Dictionary<String, AnyObject>>) -> Void) {
		let api = "https://query.yahooapis.com/v1/public/yql?q="
		let endPoint = "&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys"
		let sql = String(format: rawValue, info)
		guard
			let encodedString = (api + sql + endPoint).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed),
			let requestURL = URL(string: encodedString)
		else {
			completion(Result<Dictionary<String, AnyObject>>(error: WeatherSourceSQLError.urlError))
			return
		}
		let request = URLRequest(url: requestURL, cachePolicy: ignoreCache ? .reloadIgnoringLocalCacheData : .useProtocolCachePolicy, timeoutInterval: ignoreCache ? 0 : 10 * 60)
		URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
			if error != nil {
				let errorResult = Result<Dictionary<String, AnyObject>>(error: error!)
				completion(errorResult)
			} else {
				do {
					guard let responseData = data,
						let JSON = try JSONSerialization.jsonObject(with: responseData, options: .mutableLeaves) as? Dictionary<String, AnyObject> , JSON["error"] == nil else {
							let errorResult = Result<Dictionary<String, AnyObject>>(error: WeatherSourceSQLError.internalError)
							completion(errorResult)
							return
					}
					let result = Result<Dictionary<String, AnyObject>>(value: JSON)
					completion(result)
				} catch {
					let errorResult = Result<Dictionary<String, AnyObject>>(error: WeatherSourceSQLError.jsonSerializeError)
					completion(errorResult)
				}
			}
		}).resume()
	}
}

enum WeatherSourceSQLError: Error {
	case urlError
	case internalError
	case jsonSerializeError
}
