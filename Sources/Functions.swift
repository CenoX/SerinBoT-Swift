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

class Functions {
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
}

func getAnime(_ msg: Message) {
    var urls = [AniURL]()
    
    for i in 0...6 {
        let url = AniURL(url: URL(string: "http://www.anissia.net/anitime/list?w=\(i)")!, day: AniDays(rawValue: i)!)
        urls.append(url)
    }
    
    urls.forEach { aniurl in
        URLSession.shared.dataTask(with: aniurl.url) {
            if let error = $2 {
                client.getChannel(for: PrivateVariables.meuChatID!)?.send(error.localizedDescription)
                return
            }
            if let data = $0 {
                let json = JSON(data: data)
                
                var totalMessage = ""
                
                json.forEach {
                    if  let name = $0.1["s"].string,
                        let genre = $0.1["g"].string {
                        totalMessage += "제목: \(name)\n장르: \(genre)\n\n"
                    }
                }
                
                let embedData: [String:Any] = ["title":"\(aniurl.day.day()) 애니메이션 편성표",
                    "color":aniurl.day.color(),
                    "description":"\(totalMessage)"]
                
                msg.channel.send(["embed":embedData])
                msg.channel.send("\n\n")
            }
            }.resume()
    }
}
