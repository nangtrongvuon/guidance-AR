//
//  HttpHandler .swift
//  httpRequest
//
//  Created by hai nguyen on 12/4/17.
//  Copyright © 2017 hai nguyen. All rights reserved.
//

import Foundation
import UIKit

enum HttpMethod : String {
    case  GET
    case  POST
    case  DELETE
    case  PUT
}

class HttpHandler{
    //TODO: remove app transport security arbitary constant from info.plist file once we get API's
    var request : URLRequest?
    var session : URLSession?
    var responseDataString: String?
    var responseDataJson: [String]?
    init() {
        responseDataString = ""
    }
    
    func updateLabel(label: UILabel) -> Void {
        label.text = responseDataString
    }
    
    func makeAPICall(url: String,params: Dictionary<String, Any>?, method: HttpMethod,
                     success:@escaping ( String?, NSError? ) -> Void,
                     failure:@escaping ( String?, NSError? )-> Void) {
        
        var request: URLRequest
        if(method == .GET) {
            var processedUrl = url
            processedUrl.append("?")
            for (key, value) in params!{
                processedUrl.append("\(key)=\(value)&")
            }
            print("URL = \(processedUrl)")
            request = URLRequest(url: URL(string: processedUrl)!)
        } else {
            print("URL = \(url)")
            request = URLRequest(url: URL(string: url)!)
            if let params = params {
                let  jsonData = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
                
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = jsonData
                request.httpMethod = method.rawValue
            }
        }
        
        
        let configuration = URLSessionConfiguration.default
//        configuration.timeoutIntervalForRequest = 10
//        configuration.timeoutIntervalForResource = 10
        
        session = URLSession(configuration: configuration)
    
        session?.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
            
            if let data = data {

                print(data)
                let resData = String(data: data, encoding: String.Encoding.utf8)!
                self.responseDataString = resData
                print(resData)
                
                if let response = response as? HTTPURLResponse, 200...299 ~= response.statusCode {
                    success(resData, error as NSError?)
                } else {
                    failure(resData, error as NSError?)
                }
            }else {
                failure("-", error as NSError?)
            }
        }.resume()
    }
}
