# TODO
- Open source
- [kirill] Release on the app store

- Getting users
- We can ask Maccy to do a shout out if we will be open source

- Quick actions
  - Design - [kirill] Figma create intial design, Oleg + Kirill brainstorm
  - Share menu
    - List of 'blessed apps' - telegram, slack, gmail (web app, we would need google drive integration to add attachments), etc.
    - Edit the list manually 
    - Research - can we extract individual items from the list of apps that support sharing?
      - Re-implement - see if anyone did this?
  - Save to common folders (for example icloud?)
    - Can we get path where we ended up saving the file?
    - Persistence for the list of folder user likes to use
    - They should be able to edit / pin them manually
  - Save to cloud 
    - ICloud - research
    - [Later] Google drive - research
- Persistence - how to implement?
  - Swift Data - lets give the shity tech a try :D
  - We can go the 'easy' route and just use UserDefaults

- Create user stories / flows
Create an example 'story' of how the user would interact with the app and how they use screenshots.

PostHog - 1 million events free

- Onboarding (assume they have the native screenshot app)
  - Do we target to remove the default shortcuts? 
    - maybe just target shift cmd 4?
    - shoft cmd 3 - also easy to replace - its a subset 
    - shift cmd 5 - for video - we don't touch it - no support :D
  - We need to show to the user how to replace the system shortcuts - cleanshot did it reaaaaly well


# Later
- Tutorials - suggest drag and drop
  - Some global persistent state to know for example the user dragged 3+ times - so don't show the hint anymore


## Distribution 
- Open source
- Brew
- https://www.irradiatedsoftware.com/help/accessibility/index.php
- Similar websites for distribution (there is one that cleanshot is bundled with)
