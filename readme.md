# Share Shot

This project implements extended screenshot functionality of native macOS Shift+Cmd+4:
- Sticky screenshot stack always visible until dismissed
- 
Basically I want to implement the most sought after features of clean shot.

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
- [Next] We take the screenshot of the selected area and add it to the stack of screenshots

## Stack of Screenshot Cards
How it looks like: ![Alt text](assets/cleanshot-screenshot-examples.png)

- [Next] Have a sticky stack of screenshots on the left bottom that stays there until explicitly dismissed by the user, see examples of cleanshot
  - The difficult thing here is to make it sticky, but not take focus from other applications. I think we can use the same exact approach as we do with the window for screenshot selection. We can just create a similar window to that one with roughly the same configurations, but only show on the left column of the screen. The windows will never be active at the same time.
- You can drag the screenshot to drop it into another applications like telegram, gmail, etc.
- As you hover over the screenshot 
  - [Next] Top left shows a close button
  - Top right shows edit button
  - Center shows quick actions
    - [Next] copy (trivial)
    - [Next] save (trivial - just save to Desktop)
      - ideally we can save to the same folder thats configured for screenshots in macOS, not sure how to get that
    - link symbol
      - creates a unique id to create the link
      - copies the link to clipboard
      - compresses the image
      - uploads the screenshot to S3
- The screenshot can be immediately edited with annotations - arrows, shapes - the usual annotation tooling functionality. Cleanshot also has it

# Ideas to differentiate
- Distribute on app store - distribution
- Price - cleanshot is 30$ - one time, no free tier
  - We can do free tier with up to 100 screenshots (this is what Awesome Screenshot does)
  - We can do .99$ / month for upload to cloud feature
    - 1GB of S3 storage is 0.023$ / month, so give up to 5GB of storage with basic plan
- Open source - so like Maccy - go after github clout instead of money. This being fully in SwiftUI could have a good reception and likely contributors.
- Allow you to configure upload to your own url for ... god knows for what
  - Custom domains is actually a nice feature from CleanShot - but thats more enterprisey - and they will always have more features, so we should not compete on that front
- As part of sending to other things - maybe we can have quick actions. For example I mostly send screnshots to Isaiah on Telegram. This is too custom though ... Maybe if integrated with shortcuts
- I was exploring a cute angle of customizing the screeshotting experience - like having a pacman like icon and animate the process of creating the screenshot.
- Target audience - ?? maybe developers .. as usual lol

# Clean Shot X
Demo: https://youtu.be/FZbICrBKWIU

# Pricing

## Basic: 29 one-time payment
The Mac app — yours to keep, forever
- You will receive a license key to activate the app.
- One year of updates
- Stay up to date with new features and improvements.
- 1 GB of Cloud storage
- Upload your captures and instantly get a shareable link.

## Pro: 8 per user/mo, billed annually or $10/mo, billed monthly
- Access to the Mac app for all users
- You will activate the app via Cloud account.
- Always get the latest version of CleanShot
- Stay up to date with new features and improvements.
- Unlimited Cloud storage
- Upload your captures and instantly get a shareable link.
- Custom domain & branding
- Add your own domain and logo and use it for sharing.
- Advanced security features
- Self destruct control, password protected links.
- Advanced team features
- Effortless team management, SSO login.

## Packaged with Setapp - https://setapp.com/how-it-works
Neat idea too
10$ / month for all apps

# Conclusion - There is lower hanging fruit - 