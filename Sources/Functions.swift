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
                let message = (error != nil) ? "사용할 수 없어요.." : "작동중이에요!"
                results.append("\(server.alias)님의 서버는 지금 \(message)")
                if results.count == 4 { callback(results) }
            }.resume()
        }
    }
}
