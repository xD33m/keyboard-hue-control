#SingleInstance, Force

httpRequest := ComObjCreate("WinHTTP.WinHttpRequest.5.1")
#Persistent
brightness := 100 ; set initial brightness to 100%
lastBrightnessSent := -1 ; set last brightness sent to an impossible value
increment := 10 ; set the increment to 10%
hue_ip := "192.168.0.137" ; set the IP address of your Hue bridge
hue_username := "AbGTyPNFZhAuATZex0GKwJal8KoR9JHIU4htnQWj" ; set your Hue API key
sendDelay := 100 ; set delay time between requests (in milliseconds)
deckenlampe := 1
spots := 3
stehlampe := 2

#If GetKeyState("F13", "P")

SC12E::
    brightness := Max(brightness - increment, 0) ; decrease brightness by the increment amount, but don't go below 0%
    ControlHueLight(brightness, deckenlampe)
return

SC130::
    brightness := Min(brightness + increment, 100) ; increase brightness by the increment amount, but don't go above 100%
    ControlHueLight(brightness, deckenlampe)
return

#If

; if ctrl + f13 is pressed, toggle the Hue light on or off
Alt & F13::
    ToggleHueLight(deckenlampe)
return

Alt & F14::
    ToggleHueLight(spots)
return

Alt & F15::
    ToggleHueLight(stehlampe)
return

ControlHueLight(brightness, lightId) {
    global hue_ip
    global hue_username
    global httpRequest
    global lastBrightnessSent
    global sendDelay
    
    ; convert the brightness level to a scale of 0-254 (the range used by the Hue API)
    hue_brightness := Round((brightness / 100) * 254)
    
    ; check if the brightness level has changed since the last request was sent
    if (hue_brightness != lastBrightnessSent) {
        FileAppend, Brightness increased to %brightness%`n, log.txt
        
        ; construct the URL to set the brightness of your Hue light(s)
        url := "http://" . hue_ip . "/api/" . hue_username . "/groups/" . lightId . "/action"
        
        ; construct the JSON payload to set the brightness of your Hue light(s)
        payload = {"bri" : %hue_brightness%}
        
        ; send an HTTP PUT request to set the brightness of your Hue light(s)
        httpRequest.Open("PUT", url, 0)
        httpRequest.Send(payload)
        
        ; set the last brightness sent to the current brightness
        lastBrightnessSent := hue_brightness
        
        ; wait for the specified delay time before allowing the next request to be sent
        Sleep sendDelay
    }
}

ToggleHueLight(lightId) {
    global hue_ip
    global hue_username
    global httpRequest

    ; construct the URL to get the state of the first Hue light
    url := "http://" . hue_ip . "/api/" . hue_username . "/groups/" . lightId

    ; send an HTTP GET request to get the state of the first Hue light
    httpRequest.Open("GET", url, 0)
    httpRequest.Send()
    responseBody := httpRequest.ResponseText

    ; extract the "on" state of the first Hue light using a regular expression
    pattern := """on"":(true|false),"
    stateMatch := RegExMatch(responseBody, pattern, state)

    ; toggle the Hue light on or off based on its current state
    if (state1 = "true") {
        newState := "false"
    } else {
        newState := "true"
    }

    ; construct the JSON payload to set the "on" state of the first Hue light
    payload := "{""on"": " . newState . "}"
    FileAppend, Lights turned %newState%`n, log.txt


    ; construct the URL to set the state of the first Hue light
    url := "http://" . hue_ip . "/api/" . hue_username . "/groups/" . lightId . "/action"

    ; send an HTTP PUT request to set the "on" state of the first Hue light
    httpRequest.Open("PUT", url, 0)
    
    httpRequest.Send(payload)
}