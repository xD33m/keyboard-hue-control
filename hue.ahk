#SingleInstance Force

httpRequest := ComObjCreate("WinHTTP.WinHttpRequest.5.1")
#Persistent

; Configuration
brightness := 100
increment := 12
hue_ip := "192.168.0.137"
hue_username := "Z0xVW0E-aR4ahQvgJ42hA6ndrCb8D7ZVEDWgfcY5"
sendDelay := 100
deckenlampe := 1
spots := 3
stehlampe := 2
enableLogging := true

; Track the last brightness level sent
lastBrightness := {deckenlampe: -1, spots: -1, stehlampe: -1}

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
    global brightness
    brightness += change
    brightness := Clamp(brightness, 0, 100)
    ControlHueLight(brightness, lightId)
}

ControlHueLight(brightness, lightId) {
    global sendDelay, enableLogging, lastBrightness
    EnsureLightOn(lightId)
    
    hue_brightness := Round((brightness / 100) * 254)
    if (hue_brightness != lastBrightness[lightId]) {
        LogIfEnabled("Brightness set to " . brightness, enableLogging)
        payload := "{""bri"": " . hue_brightness . "}"
        SendHueRequest(lightId, payload)
        lastBrightness[lightId] := hue_brightness
    }
}

EnsureLightOn(lightId) {
    lightState := GetLightState(lightId)
    if (lightState == "false") {
        ToggleHueLight(lightId, "true")
    }
}

GetLightState(lightId) {
    stateUrl := BuildURL(lightId)
    httpRequest.Open("GET", stateUrl, false)
    httpRequest.Send()
    LogIfEnabled("Light " . lightId . " is " . stateUrl, true)
    return InStr(httpRequest.ResponseText, """on"":true") ? "true" : "false"
}

ToggleHueLight(lightId, desiredState := "toggle") {
    global enableLogging
    newState := DetermineNewState(lightId, desiredState)
    payload := "{""on"": " . newState . "}"
    LogIfEnabled("Light " . lightId . " turned " . newState, enableLogging)
    SendHueRequest(lightId, payload)
}

DetermineNewState(lightId, desiredState) {
    return (desiredState == "toggle") ? (GetLightState(lightId) == "true" ? "false" : "true") : desiredState
}

LogIfEnabled(message, loggingEnabled) {
    if (loggingEnabled) {
        FileAppend, %message%`n, log.txt
    }
}

SendHueRequest(lightId, data) {
    global httpRequest, sendDelay
    url := BuildURL(lightId)
    httpRequest.Open("PUT", url, false)
    httpRequest.Send(data)
    LogIfEnabled("Request to " . url . " with data " . data . "`nResponse: " . httpRequest.ResponseText . "`n", true)
    Sleep sendDelay
}

BuildURL(lightId) {
    global hue_ip, hue_username
    return "http://" . hue_ip . "/api/" . hue_username . "/groups/" . lightId . "/action"
}

Clamp(value, min, max) {
    return (value < min) ? min : (value > max) ? max : value
}
