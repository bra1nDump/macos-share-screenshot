# Share Shot

Screenshoting app for macOS. Prototype. 
SwiftUI, basic English and basic coding skills required.

This project implements extended screenshot functionality of native macOS screenshoting (try Shift+Cmd+4). We are trying to compete with clean shot X https://youtu.be/FZbICrBKWIU. To understand how hard it is to compete we are implementing a proof of concept with the main features from their product. I have already put together the basic infrastructure to implement the desired functionality.

Most tasks in the project will be:
- Pretty standard UI development using SwiftUI
- Using screen capture APIs I have pre-researched
- Some macOS window magic (which I think I have figured out already, so you don't have to figure it out, just use the existing approach)

The tasks are ordered by priority. Label [Task-*] has highest priority. Label [Next] has next highest priority. Label [Later] are just things to consider for later.

Task-1 also includes just getting the project running on your machine and making sure we are on the same page.

I estimate each task will take 2/3 work days. The full project is considered completed when Task-1, Task-2, Task-3 are completed.

# What you will be provided with 

# How the product will work:

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
- [Task-1] We take the screenshot of the selected area and show it in the bottom left corner of the screen
  - Originally the project I started with was this tutorial by apple on how to use screen capture api https://developer.apple.com/documentation/screencapturekit/capturing_screen_content_in_macos
  - Most of the code from that is in this project, just inactive under /SampleCodeFromCaptureExample
  - You most likely will use this API to capture a screenshot: https://developer.apple.com/documentation/screencapturekit/scscreenshotmanager
  - You might run into some issues with coordinate systems in swiftui vs appkit, not matching - use ChatGPT + google + talk to me if you run into issues. There is a function `convertToSwiftUICoordinates` that deals with the issue.
  - To start off - just add the single screeshot to the same window - bottom left corner. Escape will dismiss similarly.

## Stack of Screenshot Cards
How it looks like: ![Alt text](assets/cleanshot-screenshot-examples.png)

- [Task-2] Have a sticky stack of screenshots on the left bottom that stays there until explicitly dismissed by the user, see examples of cleanshot
  - The difficult thing here is to make it sticky, but not take focus from other applications. I think we can use the same exact approach as we do with the window for screenshot selection. We can just create a similar window to that one with roughly the same configurations, but only show on the left column of the screen. The windows will never be active at the same time.
  - As you take more screenshots, they should be pushed on top of the stack
  - Restore mouse pointer
  - Make sure its on a different window - we don't want to keep blocking the user's view
- As you hover the mouse over the screenshot in the stack
  - [Task-3] Top left shows a close button - it will remove the screenshot from the stack
  - Center shows quick actions
    - [Task-3] copy (trivial)
    - [Task-3] save (trivial - just save to Desktop)
      - ideally we can save to the same folder thats configured for screenshots in macOS, not sure how to get that
    - Link symbol
      - creates a unique id to create the link
      - copies the link to clipboard
      - compresses the image
      - uploads the screenshot to S3
- [Next] You can drag the screenshot to drop it into another applications like telegram, gmail, etc.
- The screenshot can be immediately edited with annotations - arrows, shapes - the usual annotation tooling functionality. Cleanshot also has it
  - Edit button will be added top right on the screenshot card

## Shortcut actions
- The value add is to be able to do things you often do. For example when I save a screenshot I sometimes want to save it to desktop, other times I want to save it to a specific folder. I want to be able to add shortcuts to locations where save them.
- Sending to my contacts on telegram for example, would be another benefit. Basically invoking a shortcut action on the screenshot.
  - https://talk.automators.fm/t/sending-a-message-from-shortcuts-to-telegram/13551
  - Macos for instance does not have telegram shortcut. So accessibility integration becomes even more important. Technically we can record any action on the screen and replay it.
- Automatically name the screenshot - We can do this with vision API
- [Later] Automatically add annotations to the screenshot - We can do this with vision API
  - Well this doesn't work for shit with vision / dale API https://chat.openai.com/c/786492b8-c66e-4193-84bd-daa30562b9b1 (private link because image conversations sharing are not supported yet)

- The fact that I'm struggling to come up with things I do often with screenshots is not a good sign. I might be coming up with a fake problem.