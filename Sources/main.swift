import Foundation
import Sword

let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd HH:MM:SS Z"

let version = dateFormatter.string(from: Date())

let PrivateVariables = SecureElements()
var Prefix = (UserDefaults.standard.string(forKey: "prefix") != nil) ? UserDefaults.standard.string(forKey: "prefix")! : "s!"

let client = Sword(token: PrivateVariables.token)

let messages = Texts()
let cache = Caches()
let function = Functions()
let document = Documents.shared
var timer = Timer()

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
                    "실행 시간은 \(version), \(ProcessInfo().hostName)에서 기동중이에요!\n\n"
    
    DispatchQueue.main.asyncAfter(deadline: client.deadline(of: 1.0)) {
        client.getChannel(for: PrivateVariables.meuChatID!)?.send(message)
        
        if #available(OSX 10.12, *) {
            continuousAction()
            timer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { _ in continuousAction() }
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
                    var message = ""; $0.forEach { message += $0 + "\n" }; msg.reply(with: message)
                }
            }
        }
        
        if content == Prefix + "cenoxvalidation" {
            function.checkCenoXServer { msg.reply(with: $0 ? "아빠 서버는 지금 죽은 것 같아요 ㅠㅠㅠ" : "아빠 서버는 지금 살아있어요!") }
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
            
            // 플레이 중 변경
            if content == prefix + "changegame" {
                msg.channel.send(Texts.chooseOne(from: messages.changeGame)) { if $1 == nil { cache.changeGame = $0! } }
            }
            
            if content.hasPrefix("*"), cache.isChangingGame {
                (cache.changeGame as? Message)?.delete()
                client.editStatus(to: "Online", playing: msg.content.components(separatedBy: "*").last)
                msg.add(reaction: "✅"); cache.changeGame = nil; cache.isChangingGame = false
            }
            
            // 레벨테이블 보기
            if content == prefix + "leveltable" {
                msg.channel.send(Texts.chooseOne(from: messages.annoying) + "\nhttps://jb.v.anil.la/t/?id=\(PrivateVariables.jbRivalID)&level=10")
            }
            
            // 서버 Prefix 바꾸기
            if content.hasPrefix(prefix + "changePrefix") {
                if let contents = content.components(separatedBy: "changePrefix ").last {
                    msg.reply(with: "입력된 새 prefix는 \(contents)야. 정말로 변경할까?")
                    cache.prefixCache = contents
                    cache.changePrefix = true
                }
            }
            
            if content.hasPrefix("*"), cache.changePrefix {
                if let contents = content.lowercased().components(separatedBy: "*").last {
                    if contents == "y" {
                        UserDefaults.standard.set(cache.prefixCache, forKey: "prefix")
                        UserDefaults.standard.synchronize()
                        Prefix = cache.prefixCache!
                        msg.add(reaction: "✅"); msg.reply(with: "변경됐어! 앞으로 날 호출할 땐 앞에 \(cache.prefixCache!)를 붙여줘!")
                        cache.prefixCache = nil; cache.changePrefix = false
                    } else { msg.reply(with: "명령어를 확인할 수 없어서 취소됐어."); cache.prefixCache = nil; cache.changePrefix = false }
                }
            }
            
            // Prefix 초기화
            if content == prefix + "resetPrefix" {
                UserDefaults.standard.set("s!", forKey: "prefix")
                UserDefaults.standard.synchronize()
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
        }
        
    }
}

client.connect()
