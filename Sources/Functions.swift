//
//  Functions.swift
//  Serin
//
//  Created by CenoX on 2017. 7. 20..
//
//

import Foundation

class Functions {
    func checkServers(callback: @escaping (_ result: [String]) -> ()) {
        var results = [Texts.chooseOne(from: messages.validationResult)]
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 3
        
        let session = URLSession(configuration: config)
        
        PrivateVariables.orServers.forEach { server in
            session.dataTask(with: server.url) { data, response, error in
                let message = (error != nil) ? "사용 불가능" : "사용가능"
                results.append("\(server.alias)님의 서버는 지금 \(message)")
                if results.count == 4 { callback(results) }
            }.resume()
        }
    }
    
    func checkCenoXServer(callback: @escaping (_ isError: Bool) -> ()) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 3
        
        let session = URLSession(configuration: config)
        
        session.dataTask(with: URL(string: "https://cenox.co")!) { data, response, error in
            if error != nil { callback(true) } else { callback(false) }
        }.resume()
    }
}
