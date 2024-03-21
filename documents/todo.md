# TODO
- Kirill - promote

- Keep working with Sandbox for now (no saving in common locations with one click, system saver needed)
- iCloud fix link
  - Show error that failed to save
- Drag and drop does not work for all things
- Simplify or decouple the screenshot view - its currently massive with too many stacks and overlays
- Onboarding. Similar to cleanshot x
  - First one should be how to create a screenshot, and should appear in the stack and show the key keyboard combination, or say to select from the menu bar
  - Suggest drag and drop
  - Exponential backoff showing the hint above the screenshot
- Multi-display fix [later]
  - Have the preview follow the cursor (like on cleanshot)
  - Be able to screenshot on any display (not just the main / current one)

# Technical decisions
- Persistence - how to implement?
  - AppStorage in SwiftUI
  - SwiftData

# Later


- Analytics PostHog - 1 million events free

- Save to cloud 
  - ICloud - research
  - [Later] Google drive - research
  - If user is not logged in into iCloud - show error the user

- Onboarding (assume they have the native screenshot app)
  - Do we target to remove the default shortcuts? 
    - maybe just target shift cmd 4?
    - shoft cmd 3 - also easy to replace - its a subset 
    - shift cmd 5 - for video - we don't touch it - no support :D
  - We need to show to the user how to replace the system shortcuts - cleanshot did it reaaaaly well

- Quick actions [no-sandbox]
  - Share menu
    - [verdict] the easiest way to 
    - List of 'blessed apps' - telegram, slack, gmail (web app, we would need google drive integration to add attachments), etc.
    - Edit the list manually 
    - Research - can we extract individual items from the list of apps that support sharing?
      - Re-implement - see if anyone did this?
  - Save to common folders (for example icloud?)
    - Can we get path where we ended up saving the file?
    - Persistence for the list of folder user likes to use
    - They should be able to edit / pin them manually

# Distribution 
- Open source
- Brew
- https://www.irradiatedsoftware.com/help/accessibility/index.php
- Similar websites for distribution (there is one that cleanshot is bundled with)

- Create user stories / flows
  - Create an example 'story' of how the user would interact with the app and how they use screenshots