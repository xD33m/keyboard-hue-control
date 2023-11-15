#SingleInstance Force
#Persistent

ReadEnv(key) {
    FileRead, content, .env
    Loop, parse, content, `n, `r
    {
        if (A_LoopField != "") {
            keyValue := StrSplit(A_LoopField, "=")
            if (keyValue[1] == key)
                return keyValue[2]
        }
    }
    return ""
}

httpRequest := ComObjCreate("WinHTTP.WinHttpRequest.5.1")

; Configuration
brightness := 100
increment := 12
hue_ip := "192.168.0.137"
hue_username := ReadEnv("HUE_USERNAME")
sendDelay := 100
deckenlampe := 1
spots := 3
stehlampe := 2
enableLogging := true

; Track the last brightness level sent and light states
lastBrightness := {deckenlampe: -1, spots: -1, stehlampe: -1}
lightStates := {deckenlampe: "unknown", spots: "unknown", stehlampe: "unknown"}

; Keybindings
#If GetKeyState("F13", "P")
    SC12E::AdjustBrightness(deckenlampe, -increment)
    SC130::AdjustBrightness(deckenlampe, increment)
#If GetKeyState("F14", "P")
    SC12E::AdjustBrightness(spots, -increment)
    SC130::AdjustBrightness(spots, increment)
#If GetKeyState("F15", "P")
    SC12E::AdjustBrightness(stehlampe, -increment)
    SC130::AdjustBrightness(stehlampe, increment)
#If

; Alt + Function keys to toggle lights
Alt & F13::ToggleHueLight(deckenlampe)
Alt & F14::ToggleHueLight(spots)
Alt & F15::ToggleHueLight(stehlampe)

AdjustBrightness(lightId, change) {
    global brightness, lightStates
    brightness += change
    brightness := Clamp(brightness, 0, 100)
    if (lightStates[lightId] != "false") {
        ControlHueLight(brightness, lightId)
    } else {
        ToggleAndSetBrightness(lightId, brightness)
    }
}

ControlHueLight(brightness, lightId) {
    global lastBrightness, enableLogging
    hue_brightness := Round((brightness / 100) * 254)
    if (hue_brightness != lastBrightness[lightId]) {
        payload := "{""bri"": " . hue_brightness . "}"
        SendHueRequest(lightId, payload)
        lastBrightness[lightId] := hue_brightness
    }
}

ToggleAndSetBrightness(lightId, brightness) {
    ToggleHueLight(lightId, "true")
    ControlHueLight(brightness, lightId)
}

ToggleHueLight(lightId, desiredState := "toggle") {
    global lightStates
    newState := desiredState != "toggle" ? desiredState : (lightStates[lightId] == "true" ? "false" : "true")
    lightStates[lightId] := newState
    payload := "{""on"": " . newState . "}"
    SendHueRequest(lightId, payload)
    LogIfEnabled("Light " . lightId . " turned " . newState, enableLogging)
}

SendHueRequest(lightId, data) {
    global httpRequest, sendDelay, enableLogging
    url := BuildURL(lightId)
    httpRequest.Open("PUT", url, false)
    httpRequest.Send(data)
    Sleep sendDelay
}

BuildURL(lightId) {
    global hue_ip, hue_username
    return "http://" . hue_ip . "/api/" . hue_username . "/groups/" . lightId . "/action"
}

Clamp(value, min, max) {
    return (value < min) ? min : (value > max) ? max : value
}

LogIfEnabled(message, loggingEnabled) {
    if (loggingEnabled) {
        FileAppend, %message%`n, log.txt
    }
}
