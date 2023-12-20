TODO: Add parsing compile errors, and possibly run in the background in watch mode

It seems like swift go to definition is not working. sourcekit language server is not able to find the compilation database. It's pretty likely has to do with the fact that I'm building this with xcodebuild and not xcode. The exact errors I'm getting is 'could not open compilation database for <file name>'

The hardcore way to debug those would be to run sourcekit-lsp locally and debug what is happening. https://github.com/apple/sourcekit-lsp/blob/25a1b4543d3d3f7431c5ae0e2bd2eb9f665445fb/Sources/SKCore/CompilationDatabaseBuildSystem.swiftL145

Output from Swift vscode extension
https://marketplace.visualstudio.com/items?itemName=sswg.swift-lang
```log
17:39:07: SourceKit-LSP setup
17:39:07: Apple Swift version 5.9.2 (swiftlang-5.9.2.2.56 clang-1500.1.0.2.5)
17:39:07: Failed to find /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/lldb-vscode
17:39:08: focus: undefined
```

Output from source kit language server
https://github.com/apple/sourcekit-lsp
```log
could not open compilation database for /Users/kirilldubovitskiy/projects/macos-share-shot/CaptureSample/GlobalOverlayPanel.swift
```

# On swift forms people mention that execute projects what source kit is not supported
https://forums.swift.org/t/xcode-project-support/20927/3
https://forums.swift.org/t/whats-the-plan-for-index/18441/4

It was also mentioned that people have extracted compilation database out of Xcode, which is roughly what I'm trying to do. But I should really ask myself if it's worth it.

Because it supports swift package manager, I wonder if I can just create the entire project outside of Xcode? This will also simplify adding new files, as I would be able to do this outside of ex code.

It seems like other people are linking app kit using the package manager.
https://github.com/Cocoanetics/BarCodeKit/blob/abaaa023982eb1b16705dd564e537e46d8bfb2a5/Package.swift#L28.

False alarm, that project actually uses Xcode. 

Maybe I can create the new right click menu application using vscode only?
So yeah that makes sense, you cannot do it https://forums.swift.org/t/use-swiftpm-to-build-ios-target/25436/6.

I think I should just cut the losses and keep using Xcode for new file creation and whenever I need to go to definition and stuff like that. But actually coding within a single file, debugging and running the application I can do in vscode.

At least that path seems less likely to work than extracting compilation database out of Xcode. But I have not found any simple way to configure source kit to look for the compilation database in not the default location, so thus # sounds like a waste of time.

# Conclusion - I'm going to use Xcode for configuring the project overall, new file creation, jumping to definition and exploring documentation, and vscode for coding and debugging the application
- Building a macos application with swift package manager is not supported. And will likely not be supported anytime soon as this will require to re implement a lot of Xcode functionality. Remember the custom bazel rules from Facebook?
- Source kit it does not currently support Xcode projects https://forums.swift.org/t/whats-the-plan-for-index/18441/4
    - I think it has sporadically worked once to jump to definition, and has not worked since. I don't think it's worth relying on it, or investing the time to find where Xcode stores the compilation database and then configuring source kit to look for it there.