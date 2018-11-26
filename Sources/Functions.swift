//
//  Functions.swift
//  Serin
//
//  Created by CenoX on 2017. 7. 20..
//
//

import Foundation
import Then
import SwiftyJSON
import Sword

func checkServers(callback: @escaping (_ fields: [[String:Any]]) -> ()) {
    var fields: [[String:Any]] = []
    var results = [Texts.chooseOne(from: messages.validationResult)]
    
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 3
    
    let session = URLSession(configuration: config)
    
    PrivateVariables.orServers.forEach { server in
        session.dataTask(with: server.url) { data, response, error in
            let message = (error != nil) ? "사용 불가능" : "사용 가능"
            results.append("**\(server.alias)**님의 서버는 지금 \(message)")
            fields.append(["name":"\(server.alias) 님의 서버:", "value":message])
            if results.count == PrivateVariables.orServers.count + 1 { callback(fields) }
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

func continuousAction() {
    print("Checking CenoX Server.")
    checkCenoXServer {
        if $0 { client.getChannel(for: PrivateVariables.meuChatID)?.send(
            "<@\(PrivateVariables.cenoxID)>, 서버를 확인하는 중에 오류가 발생했어! 한번 확인해봐야 할 것 같아"
            )
        }
    }
}

func makeEmbed(with field: [[String:Any]], description: String = "ported to Swift version") -> [String:Any] {
    let formatter = DateFormatter().then {
        $0.timeZone = TimeZone(secondsFromGMT: 9)
        $0.dateFormat = "yyyy-MM-dd HH:mm:ss"
    }
    
    let embedData: [String:Any] = ["title":"**Serin BoT**\n",
                                   "footer":["icon_url":client.user?.avatarUrl(format: .png),
                                             "text":"Developed by CenoX"],
                                   "timestamp":formatter.string(from: Date()),
                                   "color":0x65b3e6,
                                   "description":description,
                                   "fields":field,
                                   "url":"https://cenox.co/serin.html"]
    
    return embedData
}

func calcExp(from a: Int, to b: Int) -> (isError: Bool, totalExp: Int) {
    var result = 0
    var errorCount = 0
    for i in a...b {
        guard let value =  PrivateVariables.table!.object(forKey: "\(i)") as? Int else { errorCount += 1; continue }
        result += value
    }
    if errorCount != 0 { print("Value Error. \(result), \(errorCount), \(a), \(b)") }
    return (errorCount != 0, result)
}
