//
//  Libs.swift
//  Serin
//
//  Created by CenoX on 2017. 8. 6..
//
//

import Foundation
import Sword
import SwiftyJSON
import Then

enum AniDays: Int {
    case sunday
    , monday
    , tuesday
    , wednesday
    , thursday
    , friday
    , saturday
    
    func color() -> Int {
        switch self {
        case .sunday: return    0xffffff
        case .monday: return    0x65b3e6
        case .tuesday: return   0xfe213e
        case .wednesday: return 0xfe24a2
        case .thursday: return  0xff9bb7
        case .friday: return    0x239283
        case .saturday: return  0x289a02
        }
    }
    
    func day() -> String {
        switch self {
        case .sunday: return    "일요일"
        case .monday: return    "월요일"
        case .tuesday: return   "화요일"
        case .wednesday: return "수요일"
        case .thursday: return  "목요일"
        case .friday: return    "금요일"
        case .saturday: return  "토요일"
        }
    }
}

struct AniURL {
    var url: URL
    var day: AniDays
}

func getAnime() {
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
                
                client.getChannel(for: PrivateVariables.meuChatID!)?.send(["embed":embedData])
                client.getChannel(for: PrivateVariables.meuChatID!)?.send("\n\n")
            }
            }.resume()
    }
}

/*
 init(_ json: [String: Any]) {
 self.author = json["author"] as? [String: Any]
 self.color = json["color"] as? Int
 self.description = json["description"] as? String
 self.fields = json["fields"] as? [[String: Any]]
 self.footer = json["footer"] as? [String: Any]
 self.image = json["image"] as? [String: Any]
 self.provider = json["provider"] as? [String: Any]
 self.thumbnail = json["thumbnail"] as? [String: Any]
 self.title = json["title"] as? String
 self.type = json["type"] as! String
 self.url = json["url"] as? String
 self.video = json["video"] as? [String: Any]
 }
 */

// type = "rich"

/*
 [
 {
 "t" : "0000",
 "g" : "학원물 / 드라마",
 "l" : "koiuso-anime.com/   ",
 "i" : 3885,
 "a" : true,
 "sd" : "20170704",
 "s" : "사랑과 거짓말",
 "ed" : "00000000"
 },
 {
 "t" : "0135",
 "g" : "판타지 / 코미디",
 "l" : "isekai-shokudo.com/  ",
 "i" : 3953,
 "a" : true,
 "sd" : "20170704",
 "s" : "이세계 식당",
 "ed" : "00000000"
 },
 {
 "t" : "1755",
 "g" : "음악",
 "l" : "www.tv-tokyo.co.jp/anime/ipp/",
 "i" : 3869,
 "a" : true,
 "sd" : "20170404",
 "s" : "아이돌 타임 프리파라",
 "ed" : "00000000"
 },
 {
 "t" : "2030",
 "g" : "판타지 / 모험",
 "l" : "isesuma-anime.jp/  ",
 "i" : 3906,
 "a" : true,
 "sd" : "20170711",
 "s" : "이세계는 스마트폰과 함께.",
 "ed" : "00000000"
 },
 {
 "t" : "2130",
 "g" : "일상",
 "l" : "newgame-anime.com/    ",
 "i" : 3880,
 "a" : true,
 "sd" : "20170711",
 "s" : "NEW GAME!!",
 "ed" : "00000000"
 },
 {
 "t" : "2155",
 "g" : "SF / 모험",
 "l" : "www.dreamcreation.co.jp/musekinin/ ",
 "i" : 3990,
 "a" : true,
 "sd" : "20170711",
 "s" : "무책임 갤럭시☆타일러",
 "ed" : "00000000"
 },
 {
 "t" : "2300",
 "g" : "코미디 / 학원물",
 "l" : "www.ahogirl.jp/     ",
 "i" : 3876,
 "a" : true,
 "sd" : "20170704",
 "s" : "바보걸",
 "ed" : "00000000"
 },
 {
 "t" : "2315",
 "g" : "학원물 / 코미디",
 "l" : "tsuredure-project.jp/  ",
 "i" : 3879,
 "a" : true,
 "sd" : "20170704",
 "s" : "심심한 칠드런",
 "ed" : "00000000"
 }
 ]
 */
