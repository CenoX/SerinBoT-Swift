import Foundation
import CwlUtils
import Sword

let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd HH:MM:SS Z"

let version = dateFormatter.string(from: Date())

let PrivateVariables = SecureElements()
let Prefix = "s!"
let client = Sword(token: PrivateVariables.token)
let messages = Texts()
let cache = Caches()
let document = Documents.shared

client.disconnect()

client.on(.ready) { [unowned client] _ in
    print("Ready to launch. triggering messages")
    
    let message =   "<@\(PrivateVariables.cenoxID)>, 기동을 완료했어요 아빠!\n" +
                    "실행 시간은 \(version), \(Sysctl.osType) \(Sysctl.machine) 기반의 \(Sysctl.hostName)에서 기동중이에요!\n\n"
    
    DispatchQueue.main.asyncAfter(deadline: client.deadline(of: 1.0)) {
        client.getChannel(for: PrivateVariables.meuChatID!)?.send(message)
    }
}

client.on(.messageCreate) { data in
    if let msg = data as? Message {
        let content = msg.content.lowercased()
        let id = msg.author?.id
        
        if msg.content.contains("탑랭"), msg.content.contains(PrivateVariables.cenoxID) {
            msg.delete()
            return
        }
        
        if let _ = msg.author?.isBot { return }
        
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
                Functions().checkServers {
                    org?.delete()
                    var message = ""
                    $0.forEach { message += $0 + "\n" }
                    msg.reply(with: message)
                }
            }
        }
        
        // 말 따라하기 || 말 대신 하기
        if content.hasPrefix(Prefix + "say") || content.hasPrefix(Prefix + "dsay") {
            let isNeedToDelete = content.hasPrefix(Prefix + "dsay")
            if isNeedToDelete { msg.delete() }
            msg.channel.send(
                content.replacingOccurrences(of: isNeedToDelete ? Prefix + "dsay" : Prefix + "say", with: "")
            )
        }
        
        // == 아빠 전용 명령어 정의 구간 == //
        if id == PrivateVariables.cenoxID {
            let prefix = Prefix + "papa."
            // 플레이 중 변경
            if content == prefix + "changegame" {
                msg.channel.send(Texts.chooseOne(from: messages.changeGame)) {
                    if $1 == nil { cache.changeGame = $0! }
                }
            }
            
            if content.hasPrefix("*"), cache.isChangingGame {
                (cache.changeGame as? Message)?.delete()
                client.editStatus(to: "Online", playing: msg.content.components(separatedBy: "*").last)
                msg.add(reaction: "✅")
                cache.changeGame = nil
                cache.isChangingGame = false
            }
            
            // 레벨테이블 보기
            if content == prefix + "leveltable" {
                msg.channel.send(Texts.chooseOne(from: messages.annoying) + "\nhttps://jb.v.anil.la/t/?id=\(PrivateVariables.jbRivalID)&level=10")
            }
        }
        
        // ===== 개발 명령어 정의 구간 ===== //
        if content.hasPrefix("s!dev.") {
            let prefix = Prefix + "dev."
            if content == prefix + "version" { msg.channel.send(version) }
            if content == prefix + "info" {
                let message =   "**Serin BoT** - ported to Swift version.\n\n" +
                                "**Current hardware**: \(Sysctl.model)\n" +
                                "**HostName**: \(Sysctl.hostName)\n" +
                                "**Total RAM**: \(Sysctl.memSize / 1024 / 1024)MB\n" +
                                "**Kernel**: \(Sysctl.version)\n"
                msg.channel.send(message)
            }
            if content == prefix + "reaction" {
                msg.add(reaction: "\\:meu:337513217485963264") { print($0 as Any) }
                msg.add(reaction: "\\:nadenade:337525787907588097") { print($0 as Any) }
                msg.add(reaction: "\\:hitomi:337513243859746816") { print($0 as Any) }
                msg.add(reaction: "✅") { print($0 as Any) }
            }
        }
    }
}

client.connect()
