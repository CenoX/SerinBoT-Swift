import Foundation
import AVFoundation
import CwlUtils
import Sword
import Then
import SwiftyJSON

extension DispatchTime: Then {}
extension SecureElements: Then {}
extension Message: Then {}

/*
 TODO: 사용 가능한 명령어를 바로 정리할 수 있게 하는 것을 만들어야함 ( how )
 FIXME: 보이스 챗 들어와도 아무것도 못하는거 고치세여;;
 */

let dateFormatter = DateFormatter().then {
    $0.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
}

let version = dateFormatter.string(from: Date())

let PrivateVariables = SecureElements()
var Prefix = (UserDefaults.standard.string(forKey: "prefix") != nil) ? UserDefaults.standard.string(forKey: "prefix")! : "s!"

let messages = Texts()
let cache = Caches()
let document = Documents.shared
var timer = Timer()
var uptimeDate: Date! = nil

let client = Sword(token: PrivateVariables.token)

client.on(.ready) { [unowned client] _ in
    print("Ready to launch. triggering messages")
    
    let message =   "<@\(PrivateVariables.cenoxID)>, 기동을 완료했어요 아빠!\n" +
                    "실행 시간은 \(version), \(Sysctl.osType) \(Sysctl.machine) 기반의 \(Sysctl.hostName)에서 기동중이에요!\n\n"
    
    DispatchQueue.main.asyncAfter(deadline: client.deadline(of: 1.0)) {
        if #available(OSX 10.12, *) {
            continuousAction()
            client.getChannel(for: PrivateVariables.logChatID)?.send(message)
            timer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { _ in continuousAction() }
            Timer.scheduledTimer(withTimeInterval: 7200, repeats: true) { _ in
                client.disconnect()
                client.connect()
            }
            uptimeDate = Date()
            print(uptimeDate)
        }
    }
}

client.on(.messageCreate) {
    guard let msg = $0 as? Message else { return }
    if msg.content.hasPrefix(Prefix) {
        print("Input: \(msg.content)")
        print("Author: \(msg.author?.id as Any) isBot: \(msg.author?.isBot ?? false)")
    }
}

client.on(.messageCreate) { data in
    guard let msg = data as? Message else { return }
    
    let content = msg.content.lowercased()
    
    if let _ = msg.author?.isBot { return }
    
    if content == "<@\(PrivateVariables.botID)>" {
        msg.reply(with: Texts.chooseOne(from: messages.hello))
    }
    
    if content.contains("<@\(PrivateVariables.botID)>"), content.hasSuffix("-currentprefix") {
        msg.reply(with: "현재 Prefix는 `\(Prefix)`에요!")
    }
    
    // ===== 일반 명령어 정의 구간 ===== //
    // 도움말 표시
    if content.hasPrefix(Prefix + "help") {
        if let arg = content.components(separatedBy: Prefix + "help ").last {
            msg.channel.send(HelpIndex(rawValue: arg).docs())
        } else if content == Prefix + "help" {
            msg.channel.send(HelpIndex(rawValue: "unknown").docs())
        }
    }
    
    // uwu
    if content == Prefix + "uwu"    { msg.channel.send("\(content) uwu") }
    // 농담
    if content == Prefix + "joke"   { msg.channel.send(Texts.chooseOne(from: messages.jokes)) }
    
    // 오버래피드 서버 검증
    if content == Prefix + "orvalidation" {
        msg.channel.send(Texts.chooseOne(from: messages.validationStart)) { org, _ in
            checkServers {
                org?.delete()
                print($0)
                let embedData: [String:Any] = ["title":"OverRapid Validation Server Status",
                                               "color":0x65b3e6,
                                               "description":Texts.chooseOne(from: messages.validationResult),
                                               "fields":$0]
                msg.channel.send(["embed":embedData])
            }
        }
    }
    
    // 집 서버 검증
    if content == Prefix + "cenoxvalidation" {
        checkCenoXServer { msg.reply(with: $0 ? "아빠 서버는 지금 죽은 것 같아요 ㅠㅠㅠ" : "아빠 서버는 지금 살아있어요!") }
    }
    
    // 소전 경험치 계산
    if content.hasPrefix(Prefix + "gfexp") {
        if let value = content.components(separatedBy: "\(Prefix)gfexp").last?.components(separatedBy: "to"),
            value.count == 2 {
            guard let first = Int(value[0].trimmingCharacters(in: .whitespaces)),
                let second = Int(value[1].trimmingCharacters(in: .whitespaces)) else {
                    msg.reply(with: "`\(Prefix)gfexp 기준 to 어디까지`의 형식으로 입력해주세요!\nex)`\(Prefix)gfexp 1 to 30`")
                    return
            }
            let result = calcExp(from: first, to: second - 1)
            if result.isError {
                msg.do {
                    $0.reply(with: "DEBUG MESSAGE - \(first), \(second), \(result)")
                    $0.reply(with: "계산에 실패했어요. 값이 잘못되지 않았는지 확인해주세요.")
                }
                print("DEBUG MESSAGE - \(first), \(second), \(result)")
            } else {
                let numberOfItem = result.totalExp / 3000 + 1
                let fields: [[String:Any]] = [["name":"**필요 경험치**",   "value":"총 \(result.totalExp)경험치"],
                                              ["name":"**필요 작전보고서**",   "value":"약 \(numberOfItem)개"]]
                let desc = "레벨 \(first)부터 레벨 \(second)까지 필요한 경험치 정보를 가져왔어요!\n필요한 작전보고서의 갯수는, 필요경험치/3000 + 1로 계산했어요!"
                msg.channel.send(["embed":makeEmbed(with: fields, description: desc)])
            }
        } else {
            msg.reply(with: "`\(Prefix)gfexp 기준 to 어디까지`의 형식으로 입력해주세요!\nex)`\(Prefix)gfexp 1 to 30`")
        }
    }
    
    if content.hasPrefix(Prefix + "rm") {
        if  let component = msg.content.components(separatedBy: "rm ").last,
            let count = Int(component) {
            let params: [String : Any] = ["limit"   :count,
                                          "before"  :msg.id]
            client.getMessages(from: msg.channel.id, with: params) {
                if let error = $1 {
                    msg.reply(with: "처리하는데 오류가 발생했어.\n\(error.localizedDescription)")
                    return
                }
                if let messages = $0 {
                    let ids = messages.flatMap { $0.id }
                    client.deleteMessages(ids, from: msg.channel.id)
                }
            }
        } else {
            msg.reply(with: "갯수를 모르겠어, 다시 이야기해줘")
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
                    file.waitForDataInBackgroundAndNotify()
                    
                    let task = Process().then {
                        $0.launchPath = "/bin/sh"
                        $0.arguments = args
                        $0.standardOutput = pipe
                        $0.standardError = pipe
                    }
                    
                    var progressObserver : NSObjectProtocol!
                    progressObserver = NotificationCenter.default.addObserver(
                        forName: NSNotification.Name.NSFileHandleDataAvailable,
                        object: file, queue: nil)
                    {
                        notification -> Void in
                        let data = file.availableData
                        
                        if data.count > 0 {
                            if let str = String(data: data, encoding: String.Encoding.utf8) {
                                msg.channel.send(str)
                            }
                            file.waitForDataInBackgroundAndNotify()
                        } else {
                            NotificationCenter.default.removeObserver(progressObserver)
                        }
                    }
                    
                    var terminationObserver : NSObjectProtocol!
                    terminationObserver = NotificationCenter.default.addObserver(
                        forName: Process.didTerminateNotification,
                        object: task, queue: nil)
                    {
                        notification -> Void in
                        let formatter = DateFormatter().then {
                            $0.timeZone = TimeZone(secondsFromGMT: 9)
                            $0.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        }
                        let embedData: [String:Any] = ["title":"**Serin BoT**\n",
                                                       "footer":["icon_url":client.user?.avatarUrl(format: .png),
                                                                 "text":"Developed by CenoX"],
                                                       "timestamp":formatter.string(from: Date()),
                                                       "color":0x65b3e6,
                                                       "description":"Process Ends!",
                                                       "url":"https://cenox.co/serin.html"]
                        msg.channel.send(["embed":embedData]) { msg, error in
                            DispatchQueue.main.asyncAfter(deadline: client.deadline(of: 1.0)) {
                                msg?.delete()
                            }
                        }
                        NotificationCenter.default.removeObserver(terminationObserver)
                    }
                    
                    task.launch()
                }
            }
            
            // 플레이 중 변경
            if content == prefix + "changegame" {
                msg.channel.send(Texts.chooseOne(from: messages.changeGame)) { if $1 == nil { cache.changeGame = $0! } }
            }
            
            if content.hasPrefix("*"), cache.isChangingGame {
                (cache.changeGame as? Message)?.delete()
                client.editStatus(to: "Online", playing: ["name": msg.content.components(separatedBy: "*").last ?? "Fetch error", "type": 0])
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
                client.deadline(of: 3.0).do {
                    DispatchQueue.main.asyncAfter(deadline: $0) {
                        client.disconnect()
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
                msg.channel.send(["embed":makeEmbed(with: fields)])
            }
            
            if content == prefix + "uptime" {
                let interval = Date().timeIntervalSince(uptimeDate)
                let date = Date(timeIntervalSince1970: interval)
                let formatter = DateFormatter().then {
                    $0.timeZone = TimeZone(secondsFromGMT: 0)
                    $0.dateFormat = "HH:mm:ss"
                }
                let fields: [[String:Any]] = [["name":"**Current uptime**",   "value":"\(formatter.string(from: date))"]]
                msg.channel.send(["embed":makeEmbed(with: fields)])
            }
        }
    }
}

client.connect()
