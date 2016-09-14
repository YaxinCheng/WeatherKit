//
//  Result.swift
//  Weather
//
//  Created by Yaxin Cheng on 2016-07-29.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

public enum Result<ElementType> {
	case success(ElementType)
	case failure(Error)
	
	init(error: Error) {
		self = Result.failure(error)
	}
	
	init(value: ElementType) {
		self = Result.success(value)
	}
}
