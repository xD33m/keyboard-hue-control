#SingleInstance, Force

httpRequest := ComObjCreate("WinHTTP.WinHttpRequest.5.1")
#Persistent
brightness := 100 ; set initial brightness to 100%
brightnessSpots := 100
brightnessStehlampe := 100
lastBrightnessSentDeckenlampe := -1
lastBrightnessSentSpots := -1
lastBrightnessSentStehlampe := -1
increment := 12 ; set the increment to 12%
hue_ip := "192.168.0.137" ; set the IP address of your Hue bridge
hue_username := "Z0xVW0E-aR4ahQvgJ42hA6ndrCb8D7ZVEDWgfcY5" ; set your Hue API key
sendDelay := 100 ; set delay time between requests (in milliseconds)
deckenlampe := 1
spots := 3
stehlampe := 2

#If GetKeyState("F13", "P")

SC12E::
    brightness := Max(brightness - increment, 0)
    ControlHueLight(brightness, deckenlampe, "lastBrightnessSentDeckenlampe")
return

SC130::
    brightness := Min(brightness + increment, 100)
    ControlHueLight(brightness, deckenlampe, "lastBrightnessSentDeckenlampe")
return

#If GetKeyState("F14", "P")

SC12E:: ; F14 decrease brightness key for "spots"
    brightnessSpots := Max(brightnessSpots - increment, 0)
    ControlHueLight(brightnessSpots, spots, "lastBrightnessSentSpots")
return

SC130:: ; F14 increase brightness key for "spots"
    brightnessSpots := Min(brightnessSpots + increment, 100)
    ControlHueLight(brightnessSpots, spots, "lastBrightnessSentSpots")
return

#If GetKeyState("F15", "P")

SC12E:: ; F15 decrease brightness key for "stehlampe"
    brightnessStehlampe := Max(brightnessStehlampe - increment, 0)
    ControlHueLight(brightnessStehlampe, stehlampe, "lastBrightnessSentStehlampe")
return

SC130:: ; F15 increase brightness key for "stehlampe"
    brightnessStehlampe := Min(brightnessStehlampe + increment, 100)
    ControlHueLight(brightnessStehlampe, stehlampe, "lastBrightnessSentStehlampe")
return

#If

Alt & F13::
    ToggleHueLight(deckenlampe)
return

Alt & F14::
    ToggleHueLight(spots)
return

Alt & F15::
    ToggleHueLight(stehlampe)
return

ControlHueLight(brightness, lightId, lastBrightnessVar) {
    global hue_ip
    global hue_username
    global httpRequest
    global sendDelay
    
    ; Check current state of the light to see if it is on or off
    stateUrl := "http://" . hue_ip . "/api/" . hue_username . "/groups/" . lightId
    httpRequest.Open("GET", stateUrl, false)
    httpRequest.Send()
    lightStateResponse := httpRequest.ResponseText
    
    ; If the light is off, turn it on first
    if (InStr(lightStateResponse, """on"":false")) {
        ToggleHueLight(lightId, "true")
    }

    
    ; convert the brightness level to a scale of 0-254 (the range used by the Hue API)
    hue_brightness := Round((brightness / 100) * 254)
    
    ; check if the brightness level has changed since the last request was sent
    if (hue_brightness != %lastBrightnessVar%) {
        FileAppend, Brightness set to %brightness%`n, log.txt
        
        ; construct the URL to set the brightness of your Hue light(s)
        url := "http://" . hue_ip . "/api/" . hue_username . "/groups/" . lightId . "/action"
        
        ; construct the JSON payload to set the brightness of your Hue light(s)
        payload := "{""bri"": " . hue_brightness . "}"
        
        ; send an HTTP PUT request to set the brightness of your Hue light(s)
        httpRequest.Open("PUT", url, 0)
        httpRequest.Send(payload)
        
        ; Update the specific last brightness variable for the light
        %lastBrightnessVar% := hue_brightness
        
        ; wait for the specified delay time before allowing the next request to be sent
        Sleep sendDelay
    }
}

ToggleHueLight(lightId, desiredState := "toggle") {
    global hue_ip
    global hue_username
    global httpRequest

    ; If a desired state is provided (true or false), use it; otherwise, toggle the current state
    if (desiredState == "true" or desiredState == "false") {
        newState := desiredState
    } else {
        ; Get the current state of the light
        stateUrl := "http://" . hue_ip . "/api/" . hue_username . "/groups/" . lightId
        httpRequest.Open("GET", stateUrl, false)
        httpRequest.Send()
        lightStateResponse := httpRequest.ResponseText
        if (InStr(lightStateResponse, """on"":true")) {
            newState := "false"
        } else {
            newState := "true"
        }
    }

    ; Construct the JSON payload to set the "on" state of the light
    payload := "{""on"": " . newState . "}"
    FileAppend, Light %lightId% turned %newState%`n, log.txt

    ; The URL should target the "state" resource of an individual light
    url := "http://" . hue_ip . "/api/" . hue_username . "/groups/" . lightId . "/action"
    
    httpRequest.Open("PUT", url, 0)
    httpRequest.Send(payload)
}

