# MicrofoneMonitor
This macOS Software monitors your Microphone input and warns you, if it gets too loud.

## Scope
### Disclaimer
This Software is devolped for macOS. It was tested on macOS 15.7.1 and macOS 26.0.1 and is written in Swift.

### Purpose
This tool is designed to monitor the microphone input and measure it in -dB. This allows you to see if you are talking too loud in phone calls and probably disturbing your colleagues (or your wife/husband if available). It is set to -20 dB. but feel free to adjust the value to your liking. It can also recognize if the imput has been changed, e. g. if a headset has been connected or disconnected and it will level the audio level automatically.

### Limitations
The software of course can only measure the audio levels which are transferred by the microphones, so please be aware that in case the microphone of your headset has some magic noise cancellation, the values displyed in this software are wrong.
Unfortunately, it's just some code, not magic...

## Usage
Usage is quite simple, just open your terminal and put int
`swift micmon.swift` to start the software. In a nearly silent environment it will look like this:
![](https://github.com/oliverheinze/MicrofoneMonitor/blob/main/Microfone%20Monitor%20macOS%2018/Pasted%20image%2020251103232052.png?raw=true)

As soon as the configured (-20 dB) limit is exceeded it will prompt this:
![](https://github.com/oliverheinze/MicrofoneMonitor/blob/main/Microfone%20Monitor%20macOS%2018/Pasted%20image%2020251103232356.png?raw=true)

With this you will know that you (or your environment) are too loud.
The threashold can easily be adjusted by simply modifying the variable 
`let LOUD_THRESHOLD: Float = -20.0` to your liking.
Remember: The more you move to 0, the more tolerant it will get. In case of questions about digital signal processing, please visit: https://en.wikipedia.org/wiki/DBFS

## Call for contribution
Feel free to enhance this. I would be so happy to see some neat business software someday which would address the problem of too loud speaking colleagues.

## Sorry
English is not my first language. Please excuse spelling mistakes.

Thank you so much.

Happily programmed in 🇩🇪 Germany.