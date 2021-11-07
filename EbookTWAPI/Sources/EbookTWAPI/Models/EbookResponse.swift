//
//  EbookResponse.swift
//
//
//  Created by Denken Chen on 2021/8/18.
//

import Foundation

public struct EbookResponse : Codable, Equatable {

    public let results : [Result]

    /// Bookstores
    public struct Result : Codable, Equatable {
       public let bookstore : Bookstore
       public let books : [Book]
       public let isOkay : Bool
       public let status : String
    }

    public struct Bookstore : Codable, Equatable {
       public let id : String
       public let displayName : String
       public let isOnline : Bool
    }

    public struct Book : Codable, Equatable {
       public let thumbnail : String
       public let title : String
       public let link : String
       public let priceCurrency : String
       public let price : Float?
    }
}

public struct EbookResultError : Codable, Error {

    public let message : String
}
