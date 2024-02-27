# Detailed functionality and implementation notes

## Upon startup
- [library added, user not prompted though] Prompt user to launch at login (startup item)
- [done] Add a keybinding to (Shift + Cmd + 7) to start selecting an area for screenshot
- [Later] Remove stock keybindings for screenshoting on macOS in settings
  - How to find the settings
  - https://share.cleanshot.com/y0jMlvfP
  - https://share.cleanshot.com/ynnnL0mm

## When user uses the keyboard shortcut
- [Done] We present an invisible window over the entire screen, hide the mouse an show a selection rectangle
  - If the user clicks escape - we dismiss the window and do nothing
  - Once the area is selected - we just kind of show the area and thats it
- [done] We take the screenshot of the selected area and show it in the bottom left corner of the screen
  - Originally the project I started with was this tutorial by apple on how to use screen capture api https://developer.apple.com/documentation/screencapturekit/capturing_screen_content_in_macos
  - Most of the code from that is in this project, just inactive under /SampleCodeFromCaptureExample
  - You most likely will use this API to capture a screenshot: https://developer.apple.com/documentation/screencapturekit/scscreenshotmanager
  - You might run into some issues with coordinate systems in swiftui vs appkit, not matching - use ChatGPT + google + talk to me if you run into issues. There is a function `convertToSwiftUICoordinates` that deals with the issue.
  - To start off - just add the single screeshot to the same window - bottom left corner. Escape will dismiss similarly.

## Window behavior
The rule of thumb:
- we should not interfere with anything that the user is doing
- the screenshot stack should stay visible until the user explicitly dismisses it
- the ideal experience is clean shot - our differentiation from them will be in the shortcuts, and probably making this open source

- The screen / space should not switch due to us taking the screenshot.
- The screen we are taking a picture of (where the blue are window appears) should follow the mouse. Alternatively we can place the area on every single screen, we should think about which one is easier to implement. Basically if I invoke the shortcut while one screen is in focus, I should be able to move to another screen and take a screenshot there
- When we move the mouse to a different screen, the screenshot stack should follow 

## Stack of Screenshot Cards
How it looks like: ![Alt text](./assets/cleanshot-screenshot-examples.png)

- Have a sticky stack of screenshots on the left bottom that stays there until explicitly dismissed by the user, see examples of cleanshot
  - The difficult thing here is to make it sticky, but not take focus from other applications. I think we can use the same exact approach as we do with the window for screenshot selection. We can just create a similar window to that one with roughly the same configurations, but only show on the left column of the screen. The windows will never be active at the same time.
  - As you take more screenshots, they should be pushed on top of the stack
  - Restore mouse pointer
  - Make sure its on a different window - we don't want to keep blocking the user's view
- You can drag the screenshot to drop it into another applications like telegram, gmail, etc.
- As you hover the mouse over the screenshot in the stack
  - Top left shows a close button - it will remove the screenshot from the stack
  - Center shows quick actions
    - [done] copy
    - save
      - [done] save to arbitrary folder using the system picker
      - save to desktop shortcut
      - [innovation] allow users to configure shortcuts to save to specific folders
      - [innovation] send to chat gpt (paird with a chrome extension)
    - [innovation] share through google drive
      - We would need to use the API, this needs more research
- The screenshot can be immediately edited with annotations - arrows, shapes - the usual annotation tooling functionality. Cleanshot also has it
  - Edit button will be added top right on the screenshot card

## Shortcut actions
- The value add is to be able to do things you often do. For example when I save a screenshot I sometimes want to save it to desktop, other times I want to save it to a specific folder. I want to be able to add shortcuts to locations where save them.
- Automatically name the screenshot - We can do this with vision API
- Re-impelement share menu on macos. I want as a quick action to have send to Isaiah, Steve, Max etc.
  - Telegram
    - Move share menu to top overlay where copy / save is 
    - https://talk.automators.fm/t/sending-a-message-from-shortcuts-to-telegram/13551
    - Macos for instance does not have telegram shortcut. So accessibility integration becomes even more important. Technically we can record any action on the screen and replay it.
    - Deep links don't support opening a chat with a specific user and adding attachments to it. https://core.telegram.org/api/links
      - Create a PR to telegram MacOS app
    - [Dead 8 years] telegram-cli https://www.omgubuntu.co.uk/2016/10/use-telegram-cli-in-terminal-ubuntu
    - [Gucii] https://github.com/xtrime-ru/TelegramApiServer
      - But would have to ask the user to login ... thats a lot to ask lol. Maybe if we are fully open source? Still deeplinks would be preferred
  - Upload to drive
    - Sales point - security, don't trust us, trust google / apple
  - Icloud - save to some folder
    - Oleg to check if we can create a link
  - Slack - probably more important :D
    - slack://user?team={TEAM_ID}&id={USER_ID}
    - https://api.slack.com/reference/deep-linking
  - Teams
  - Gmail
    - https://stackoverflow.com/a/8852679
    - We can upload to google drive and then send a link to the file in the body easily, or just use share google drive API ... but they have to be a google user I think

- Sending to my contacts on telegram for example, would be another benefit. Basically invoking a shortcut action on the screenshot.
  - https://talk.automators.fm/t/sending-a-message-from-shortcuts-to-telegram/13551
  - Macos for instance does not have telegram shortcut. So accessibility integration becomes even more important. Technically we can record any action on the screen and replay it.

## Annotations

### Libraries that already implement drawing on the screen we can use
- https://github.com/maxchuquimia/quickdraw
  - The best one - supports circles, arroes, squares
  - UIKit :(
  - Is not ment to be used as a library, adopting it by copying over relevant code will take effort (3 days?)
  - Can be used as a reference
  - [notes] Render happens nicely here: https://github.com/maxchuquimia/quickdraw/blob/b9732eeef42869c88927a640d8c128affd3c19f4/QuickDraw/Views/DrawingView/DrawingView.swift#L105
  - Majority of the code seems to be bookkeeping as always :D, tool selection, coordinate translation, mouse tracking, etc.
  - Was rejected from AppStore repeatedly :(

- Telegram drawing contest https://github.com/Serfodi/MediaEditing/tree/main

- SwiftUI 10+ stars, not researched further https://github.com/gahntpo/DrawingApp-Youtube-tutorial/tree/main
- SwiftUI 16 stars, simple, but better looking than below https://github.com/gahntpo/DrawingApp
- SwiftUI 26 stars, very simple drawing https://github.com/Ytemiloluwa/DrawingApp

- [Later] Automatically name the screenshot - We can do this with vision API
- [Later] Automatically add annotations to the screenshot - We can do this with vision API
  - Well this doesn't work for shit with vision / dale API https://chat.openai.com/c/786492b8-c66e-4193-84bd-daa30562b9b1 (private link because image conversations sharing are not supported yet)
  - Automatically remove background, do segmetation

- The fact that I'm struggling to come up with things I do often with screenshots is not a good sign. I might be coming up with a fake problem.
