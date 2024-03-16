# What is The Mirror and why?

![image](https://github.com/the-mirror-gdp/the-mirror/assets/11920077/13ffc0bd-bef2-4c1d-a12d-f11fdedf7b11)

**_Freedom to own_**: The Mirror is a Roblox & UEFN alternative giving you the freedom to own what you create: an all-in-one game development platform built on Godot.

If you build on others like Roblox, UEFN/Unreal/Fortnite, and Unity, you don't actually own the full stack of what you build because you don't own the engine.

_We're here to change that_. 3D is arguably the next step of the internet and we can't let it be beholden to an oligopoly of companies that want to own your data and creations.

Akin to "Figma" for game development, The Mirror is both tool and editor that let's you edit a game with friends in real-time. It's intended use can be extended because you have the source code. It can be used as a complete game base, to build what you want on top, you can use this to accelerate your game, get it built and released. This saves you time: imagine not having to write pesky things like infrastructure, backend code, asset management, and various systems from scratch.

This repo is The Mirror's source code: the Godot app (client/server), the web server, and the docs in one place. We've included everything we can provide to help you build your games as fast as possible.

**1. Join our [Discord](https://discord.com/invite/CK6fH3Cynk)**

**2. Check out our [Roadmap](https://github.com/orgs/the-mirror-gdp/projects)**

**3. Read our docs: [Site](https://docs.themirror.space), [monorepo `/mirror-docs`](https://github.com/the-mirror-gdp/the-mirror/tree/dev/mirror-docs)**

**4. Check out our [open-source announcement post](https://www.themirror.space/blog/freedom-to-own-open-sourcing-the-mirror)**

**5. Follow us on [X/Twitter](https://twitter.com/themirrorgdp)**

# Features

- All-in-one game development: The Mirror is both the editor and the game, providing everything you need out-of-the-box to quickly create and play games, digital experiences, virtual worlds, and more.
- Editor: Built-in and networked: A lightweight, real-time, multiplayer editor to build in real-time.
- Physics via [Jolt](https://github.com/jrouwe/JoltPhysics), a AAA physics engine used by Horizon Zero Dawn.
- Advanced networking: Keep your game in sync and rewind when things get out of sync.
- Visual scripting: Even if you don't know how to code, you can implement game logic quickly and easily.
- Traditional coding: GDScript in-world editor so you can live edit your game code.
- Material editor and in-game shader editing.
- An entire asset system built around GLTF, supporting seats, lights, and custom physics shapes all direct from blender.
- We have our own UI elements, including a table class which can easily map _any_ data to UI elements without duplicating state in a performant way.
- Asset imports using GLTFs at runtime in your game.
- Collision shape generation handling: Convex and concave supported.
- Easily add audio to your game in real-time without opening the Godot editor.
- Player controllers out-of-the-box: FPS, TPS, and VR.
- VR-ready: Tested on Oculus Quest 2.
- A simple game object abstraction called SpaceObject (this will be refactored with the aim of supporting **any** type of Godot node).

# Get Started

1. Git clone the repository (you do **not** need to clone with submodules; they are optional)
2. Download the precompiled Mirror fork of Godot engine (required to use)

- Windows: [Download](https://storage.googleapis.com/mirror_native_client_builds/Engine/41ba769a/MirrorGodotEditorWindows.exe)
- Mac: **v buggy**; taking contributions for fixes :) [Download](https://storage.googleapis.com/mirror_native_client_builds/Engine/41ba769a/MirrorGodotEditorMac.app.zip). On Mac you will see a zip file; extract it and open the editor binary with CMD + Right-Click then select the Open option.
- Linux: [Download](https://storage.googleapis.com/mirror_native_client_builds/Engine/41ba769a/MirrorGodotEditorLinux.x86_64)

3. Open the Godot editor (The Mirror fork), click import, and choose the `project.godot` from the `/mirror-godot-app` folder.
4. Hit play once it loads!

## Godot Fork

The Mirror is built on a custom fork of Godot and required to use The Mirror's code. The fork is open source and can be found [here](https://github.com/the-mirror-gdp/godot).

# Documentation

[The docs site](https://docs.themirror.space/docs/open-source-code/get-started) (`/mirror-docs`) is our primary source of truth for documentation, not this README. We intend to keep this README slim since documentation is and will continue to be extensive.

_Analytics Disclaimer: We use posthog and it automatically collects analytics in the open source repo. You can disable this manually by commenting out the `mirror-godot-app/scripts/autoload/analytics/analytics.gd` file methods. We will make this easier in the future to disable. The Mirror Megaverse Inc., a US Delaware C Corp, is the data controller of the Posthog instance. You are free to disable the analytics and even plug in your own Posthog API key to capture the analytics yourself for your games!_
