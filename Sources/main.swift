import Foundation
import CwlUtils
import Sword
import Then
import SwiftyJSON

extension DispatchTime: Then {}
extension SecureElements: Then {}

let dateFormatter = DateFormatter().then {
    $0.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
}

let version = dateFormatter.string(from: Date())

let PrivateVariables = SecureElements()
var Prefix = (UserDefaults.standard.string(forKey: "prefix") != nil) ? UserDefaults.standard.string(forKey: "prefix")! : "s!"

let client = Sword(token: PrivateVariables.token)

let messages = Texts()
let cache = Caches()
let function = Functions()
let document = Documents.shared
var timer = Timer()

var uptimeDate: Date! = nil

func continuousAction() {
    print("continuousAction")
    function.checkCenoXServer {
        if $0 { client.getChannel(for: PrivateVariables.meuChatID!)?.send(
            "<@\(PrivateVariables.cenoxID)>, 서버를 확인하는 중에 오류가 발생했어! 한번 확인해봐야 할 것 같아"
            )
        }
    }
}

client.disconnect()

client.on(.ready) { [unowned client] _ in
    print("Ready to launch. triggering messages")
    
    let message =   "<@\(PrivateVariables.cenoxID)>, 기동을 완료했어요 아빠!\n" +
                    "실행 시간은 \(version), \(Sysctl.osType) \(Sysctl.machine) 기반의 \(Sysctl.hostName)에서 기동중이에요!\n\n"
    
    DispatchQueue.main.asyncAfter(deadline: client.deadline(of: 1.0)) {
        if #available(OSX 10.12, *) {
            continuousAction()
            client.getChannel(for: PrivateVariables.meuChatID!)?.send(message)
            timer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { _ in continuousAction() }
            uptimeDate = Date()
            print(uptimeDate)
        } else {
            client.getChannel(for: PrivateVariables.meuChatID!)?.send("<@\(PrivateVariables.cenoxID)>, 실행환경의 제약으로 인해, 서버상태를 확인할 수 없어. 미안해!")
        }
    }
}

client.on(.messageCreate) { data in
    if let msg = data as? Message {
        let content = msg.content.lowercased()
        let id = msg.author?.id
        
        if let _ = msg.author?.isBot { return }
        
        if msg.mentions.first?.id == PrivateVariables.botID {
            msg.reply(with: Texts.chooseOne(from: messages.hello))
        }
        
        if content.contains("<@\(PrivateVariables.botID)>"), content.hasSuffix("-currentprefix") {
            msg.reply(with: "현재 Prefix는 `\(Prefix)`에요!")
        }
        
        if msg.content.contains("히토미") || msg.content.lowercased().contains("hitomi") {
            msg.add(reaction: "\\:hitomi:337513243859746816") { print($0 as Any) }
        }
        
        if msg.content.characters.contains("미"), msg.content.characters.contains("쿠")
            || msg.content.lowercased().contains("miku")
            || msg.content.contains("39") {
            msg.add(reaction: "\\:nadenade:337525787907588097") { print($0 as Any) }
        }
        
        if msg.content.contains("| -serin --d ") {
            if  let original = msg.content.components(separatedBy: "| -serin --d ").first,
                let time = msg.content.components(separatedBy: "| -serin --d ").last,
                let toInt = Int(time) {
                
                msg.delete()
                msg.channel.send(original) { message, _ in
                    DispatchQueue.main.asyncAfter(deadline: client.deadline(of: Double(toInt))) {
                        message?.delete()
                    }
                }
            }
        }
        
        // ===== 일반 명령어 정의 구간 ===== //
        // 도움말 표시
        if  content.hasPrefix(Prefix + "help") {
            if let arg = content.components(separatedBy: Prefix + "help ").last {
                msg.channel.send(HelpIndex(rawValue: arg).docs())
            } else if content == Prefix + "help" {
                msg.channel.send(HelpIndex(rawValue: "unknown").docs())
            }
        }
        
        // uwu
        if content == Prefix + "uwu"    { msg.channel.send("uwu") }
        // 농담
        if content == Prefix + "joke"   { msg.channel.send(Texts.chooseOne(from: messages.jokes)) }
        
        // 오버래피드 서버 검증
        if content == Prefix + "orvalidation" {
            msg.channel.send(Texts.chooseOne(from: messages.validationStart)) { org, _ in
                function.checkServers {
                    org?.delete()
                    var message = ""; $0.forEach { message += $0 + "\n" };
                    let embedData: [String:Any] = ["title":"OverRapid Validation Server Status",
                                                   "color":0x65b3e6,
                                                   "description":message]
                    msg.channel.send(["embed":embedData])
                }
            }
        }
        
        // 집 서버 검증
        if content == Prefix + "cenoxvalidation" {
            function.checkCenoXServer { msg.reply(with: $0 ? "아빠 서버는 지금 죽은 것 같아요 ㅠㅠㅠ" : "아빠 서버는 지금 살아있어요!") }
        }
        
        // 해민이 숙청
        if content == Prefix + "숙청" {
            let param: [String:Any] = ["delete-message-days":7]
            client.ban(PrivateVariables.banUser1!, from: msg.channel.id, for: "너도 아는 누군가가 너랑 엮이기 싫데요!", with: param) { err in
                if let error = err {
                    msg.reply(with: error.message)
                } else {
                    msg.reply(with: "Done^^")
                }
            }
        }
        
        if content.hasPrefix(Prefix + "rm") {
            if  let component = msg.content.components(separatedBy: "rm ").last,
                let count = Int(component) {
                let params: [String : Any] = ["limit"   :count,
                                              "before"  :msg.id]
                client.getMessages(from: msg.channel.id, with: params) {
                    if let error = $1 {
                        msg.reply(with: "처리하는데 오류가 발생했어.")
                        return
                    }
                    if let messages = $0 {
                        messages.forEach { $0.delete() }
                        msg.add(reaction: "✅")
                    }
                }
            } else {
                msg.reply(with: "시간을 모르겠어, 다시 이야기해줘")
            }
        }
        
        // 말 따라하기 || 말 대신 하기
        if content.hasPrefix(Prefix + "say") || content.hasPrefix(Prefix + "dsay") {
            if content.hasPrefix(Prefix + "dsay") { msg.delete() }
            msg.channel.send(
                content.replacingOccurrences(of: content.hasPrefix(Prefix + "dsay") ? Prefix + "dsay" : Prefix + "say", with: "")
            )
        }
    }
}

client.on(.messageCreate) { data in
    if let msg = data as? Message {
        let content = msg.content
        let id = msg.author?.id
        
        // == 아빠 전용 명령어 정의 구간 == //
        if id == PrivateVariables.cenoxID {
            let prefix = Prefix + "papa."
            
            // 명령어 실행
            if content.hasPrefix(prefix + "exec") {
                if let contents = content.components(separatedBy: "exec ").last {
                    let args = ["-c", contents]
                    let pipe = Pipe()
                    let file = pipe.fileHandleForReading
                    
                    let task = Process().then {
                        $0.launchPath = "/bin/sh"
                        $0.arguments = args
                        $0.standardOutput = pipe
                        $0.standardError = pipe
                    }
                    
                    task.launch()
                    
                    let data = file.readDataToEndOfFile()
                    
                    if let output = String(data: data, encoding: .utf8) {
                        msg.channel.send(output)
                    }
                }
            }
            
            
            // 플레이 중 변경
            if content == prefix + "changegame" {
                msg.channel.send(Texts.chooseOne(from: messages.changeGame)) { if $1 == nil { cache.changeGame = $0! } }
            }
            
            if content.hasPrefix("*"), cache.isChangingGame {
                (cache.changeGame as? Message)?.delete()
                client.editStatus(to: "Online", playing: msg.content.components(separatedBy: "*").last)
                msg.add(reaction: "✅"); cache.changeGame = nil; cache.isChangingGame = false
            }
                        
            // 서버 Prefix 바꾸기
            if content.hasPrefix(prefix + "changePrefix") {
                if let contents = content.components(separatedBy: "changePrefix ").last {
                    msg.reply(with: "입력된 새 prefix는 \(contents)야. 정말로 변경할까?")
                    cache.prefixCache = contents
                    cache.changePrefix = true
                }
            }
            
            // 봇 끄기
            if content == prefix + "halt" {
                msg.reply(with: "봇 종료 명령어 확인. 나중에봐!")
                client.disconnect()
                let deadline = client.deadline(of: 3.0).with {
                    DispatchQueue.main.asyncAfter(deadline: $0) {
                        exit(0)
                    }
                }
            }
            
            if content.hasPrefix("*"), cache.changePrefix {
                if let contents = content.lowercased().components(separatedBy: "*").last {
                    if contents == "y" {
                        UserDefaults.standard.do {
                            $0.set(cache.prefixCache, forKey: "prefix")
                            $0.synchronize()
                        }
                        Prefix = cache.prefixCache!
                        msg.add(reaction: "✅"); msg.reply(with: "변경됐어! 앞으로 날 호출할 땐 앞에 \(cache.prefixCache!)를 붙여줘!")
                        cache.prefixCache = nil; cache.changePrefix = false
                    } else { msg.reply(with: "명령어를 확인할 수 없어서 취소됐어."); cache.prefixCache = nil; cache.changePrefix = false }
                }
            }
            
            // Prefix 초기화
            if content == prefix + "resetPrefix" {
                UserDefaults.standard.do {
                    $0.set("s!", forKey: "prefix")
                    $0.synchronize()
                }
                Prefix = "s!"
                msg.add(reaction: "✅"); msg.reply(with: "Prefix가 처음으로 되돌려졌어. 앞으로 `s!`로 날 불러줘!")
            }
            
            // 서버 체크 타이머 관련 명령어
            if #available(OSX 10.12, *) {
                if content == prefix + "timerInvalidate" { timer.invalidate(); msg.add(reaction: "✅") }
                
                if content.hasPrefix(prefix + "timerReset") {
                    if let contents = content.components(separatedBy: "timerReset ").last, let toInt = Int(contents) {
                        timer.invalidate()
                        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(toInt), repeats: true) { _ in continuousAction() }
                        msg.add(reaction: "✅")
                    } else { msg.reply(with: "시간을 모르겠어, 다시 이야기해줘") }
                }
            }
        }
        
        // ===== 개발 명령어 정의 구간 ===== //
        if content.hasPrefix("s!dev.") {
            let prefix = Prefix + "dev."
            if content == prefix + "version" { msg.channel.send(version) }
            if content == prefix + "reaction" { PrivateVariables.reactions.forEach { msg.add(reaction: $0) {print($0 as Any)} } }
            if content == prefix + "info" {
                let fields: [[String:Any]] = [["name":"**Current hardware**",   "value":"\(Sysctl.model)"],
                                              ["name":"**Host Name**",          "value":"\(Sysctl.hostName)"],
                                              ["name":"**Total RAM**",          "value":"\(Sysctl.memSize / 1024 / 1024)MB"],
                                              ["name":"**Kernel**",             "value":"\(Sysctl.version)"]]
                
                let formatter = DateFormatter().then {
                    $0.timeZone = TimeZone(secondsFromGMT: 9)
                    $0.dateFormat = "yyyy-MM-dd HH:mm:ss"
                }
                
                let embedData: [String:Any] = ["title":"**Serin BoT**\n",
                                               "footer":["icon_url":client.user?.avatarUrl(format: .png),
                                                         "text":"Developed by CenoX"],
                                               "timestamp":formatter.string(from: Date()),
                                               "color":0x65b3e6,
                                               "description":"ported to Swift version",
                                               "fields":fields,
                                               "url":"https://cenox.co/serin.html"]
                
                msg.channel.send(["embed":embedData])
            }
            
            if content == prefix + "uptime" {
                let interval = Date().timeIntervalSince(uptimeDate)
                let date = Date(timeIntervalSince1970: interval)
                let formatter = DateFormatter().then {
                    $0.timeZone = TimeZone(secondsFromGMT: 0)
                    $0.dateFormat = "HH:mm:ss"
                }
                msg.channel.send("나는 지금 \(formatter.string(from: date)) 동안 켜져있었어!")
            }
        }
    }
}

client.connect()
