; OS Version ...: Windows 10 x64 and Above (Support not guaranteed on Windows 7)
;;@Ahk2Exe-SetName elModo7's WebHook Notifier
;;@Ahk2Exe-SetDescription Sends POST messages to different Messaging Apps
;;@Ahk2Exe-SetVersion 1.0.0
;;@Ahk2Exe-SetCopyright Copyright (c) 2023`, elModo7
;;@Ahk2Exe-SetOrigFilename webhook_notify
; This is a custom class for Tunnel Manager that will send push notifications through Telegram, Discord, Teams, PushBullet, IRC...
; Currently Teams and IRC are discarded, teams because this is not a corporate tool (yet) and I wouldn't use it, IRC because it requires an open connection and 
; I just don't like keeping a connection open, much less for just monitoring this 😅
global sendNotificationOnce := 0
;~ global discord_notify := 1, push_notify := 1, telegram_notify := 1 ; Per service toggle (only global setting implemented)
;~ sendNotifications("Tunnel Manager", "Test message")

sendNotifications(title, message){
    if(notificationsData.enabled && trim(notificationsData.discord_webhook) != ""){
        SendDiscordMessage(title, message, notificationsData.discord_webhook)
    }
    if(notificationsData.enabled && trim(notificationsData.pushbullet_token) != ""){
        SendPushMessage(notificationsData.pushbullet_token, title, message)
    }
    if(notificationsData.enabled && trim(notificationsData.telegram_token) != "" && trim(notificationsData.telegram_chat_id) != ""){
        SendTelegramMessage(notificationsData.telegram_token, title, message, notificationsData.telegram_chat_id)
    }
}

SendDiscordMessage(Title, Message, WebhookURL="")
{
    if(WebhookURL != ""){
        try{
            json_str ={"content":"%Title%\n``````%Message%``````"}
            WebClient := ComObjCreate("WinHttp.WinHttpRequest.5.1")
            WebClient.Open("POST", WebhookURL, false)
            WebClient.SetRequestHeader("Content-Type", "application/json")
            WebClient.Send(json_str)
        }
    }
}

SendPushMessage(token, title, msg)
{
    try{
        WinHTTP := ComObjCreate("WinHTTP.WinHttpRequest.5.1")
        WinHTTP.Open("POST", "https://api.pushbullet.com/v2/pushes", 0)
        WinHTTP.SetCredentials(token, "", 0)
        WinHTTP.SetRequestHeader("Content-Type", "application/json")
        PB_Body := "{""type"": ""note"", ""title"": """ title """, ""body"": """ msg """}"
        WinHTTP.Send(PB_Body)
    }
}

SendTelegramMessage(token, title, text, from_id, replyMarkup="",  parseMode="" )
{
    try{
        url := "https://api.telegram.org/bot" token "/sendmessage?chat_id=" from_ID "&text=" title "\n" text "&reply_markup=" replyMarkup "&parse_mode=" parseMode
        hObject:=ComObjCreate("WinHttp.WinHttpRequest.5.1")
        hObject.Open("GET",url)
        hObject.Send()
    }
}