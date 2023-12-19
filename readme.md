The gist of the problem

## Desired behavior
- Anywhere I will be able to use a keyboard shortcut to create a overlay over my entire screen
    - It will block interactions with existing applications while the user is selecting the range to screenshot
    - We will use this overly to draw the cursor and the selection rectangle
    - We want the application not to take focus, so everything else on screen remains exacly the same

## Issues I'm running into

- When making a window key and ordering you to front while the application is inactive results in the swift ui view nominally appearing (on appear is cold)
- Somehow pixel capture works, which is the code I'm trying to replicate

- My next thing to try is to try activating the window while the application is active (so first time the computer starts up), and then see if I can redraw content when the window is already there.
- This seems like a sucky solution because I don't think it's gonna work for multiple screens (for example cleanshot works just fine on multiple screens)

## Well shit the solution was to use the right styleMask on super.init ...
That was pretty much it.
Reading code again and looking at each line and asking - is it suspicious could have worked.
Its a hard one to notice though in my opinion, not blaming myself ;D