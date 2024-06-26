Lets continue working with Sandbox for now.

# TODO Oleg
  - will also take care of the reactivity to changes in capture history
  - Make draggable
    - Try doing draggable using paths instead of data - or in addition to data
    - Lets try avoiding dropping to old school draggable if possible. If you think thats the only way, send evidence you found to Kirill so we can double check
- Get the first test flight out


# TODO Kirill
- Test flight - Oleg will let Kirill know when ready to test, Kirill will deploy

- Kirill is now writing all screenshots to the app's container /Data/screenshots. Can we try opening preview and pointing to the matching screenshot file? I hope this will allow us to allow preview to directly modify the file in place and read that data once the user hits save in Preview. Unlikely though. tmp is probably also within sandbox and Preview is declining to write to that path.

- Promote

# Later
- Multi-display fix [later, Oleg does not have 2 displays to test with at this time]
  - Have the preview follow the cursor (like on cleanshot)
  - Be able to screenshot on any display (not just the main / current one)
  
- Compression
  - ? Does cleanshot x already have this?

- iCloud fix link or abandon for now
  - Might not be possible

We are storing captured images in two places it seems - here and ScreenshotStackPanel
We should have a shared model on app delegate level that the ScreenshotStackPanel will
also consume / mutate

- Save to cloud
  - ICloud - research
    - [impossible] https://stackoverflow.com/a/27934969/5278310
  - [Later] Google drive - research
  - If user is not logged in into iCloud - show error the user

- Analytics PostHog - 1 million events free

# Distribution 
- Open source
- Brew
- https://www.irradiatedsoftware.com/help/accessibility/index.php
- Similar websites for distribution (there is one that cleanshot is bundled with)

- Create user stories / flows
  - Create an example 'story' of how the user would interact with the app and how they use screenshots
  
# Done
- Implement Cmd+Shift+8 to show history - last 5 probably?
  - Show history in the menu bar - maybe even make draggable?
  - NSMenuItem.view can be set and this can be a draggable view

- Show error that failed to save 
- Simplify or decouple the screenshot view - its currently massive with too many stacks and overlays
- First one should be how to create a screenshot, and should appear in the stack and show the key keyboard combination, or say to select from the menu bar
- Exponential backoff showing the hint above the screenshot
- Drag and drop does not work for all things
- Add show onboarding button as one of the menu items
- Fix: share menu appears connected to our invisible stack view, not the screenshot being shared
- Onboarding. Similar to cleanshot x
- Fix: Panel for onboarding sometimes disappears
- Add login item to menu bar - needed to launch the app on startup
- Ditch the separate history panel for now
- Maybe "close all" translucent button when multiple screenshots are shown?
- Update screenshot history
- close all should simply close all individual screenshots in stack, not just collapse
- refactor to have swiftUI in the entire status bar

# Archive

- Quick actions [no-sandbox]
  - Share menu
    - [verdict] the easiest way to 
    - List of 'blessed apps' - telegram, slack, gmail (web app, we would need google drive integration to add attachments), etc.
      - [impossible] 
    - Edit the list manually 
    - Research - can we extract individual items from the list of apps that support sharing?
      - Re-implement - see if anyone did this?
  - Save to common folders (for example icloud?)
    - Can we get path where we ended up saving the file?
    - Persistence for the list of folder user likes to use
    - They should be able to edit / pin them manually
    
