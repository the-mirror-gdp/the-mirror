# Readme: Mirror Godot App

# Latest Godot editor builds:

- Linux : [https://github.com/the-mirror-megaverse/godot-soft-fork/actions/workflows/linux_builds.yml?query=branch%3Adev++](https://github.com/the-mirror-megaverse/godot-soft-fork/actions/workflows/linux_builds.yml?query=branch%3Adev++)
- Windows : [https://github.com/the-mirror-megaverse/godot-soft-fork/actions/workflows/windows_builds.yml?query=branch%3Adev++](https://github.com/the-mirror-megaverse/godot-soft-fork/actions/workflows/windows_builds.yml?query=branch%3Adev++)
- MacOS : [https://github.com/the-mirror-megaverse/godot-soft-fork/actions/workflows/macos_builds.yml?query=branch%3Adev++](https://github.com/the-mirror-megaverse/godot-soft-fork/actions/workflows/macos_builds.yml?query=branch%3Adev++)

## Editor Versions

When a new editor build is needed, we bump the package.json by a **minor** version.

# Public Download Links

The download link is currently added on the React app here. Ensure that the download link is set to public on Google Cloud via the below settings.

[https://github.com/the-mirror-megaverse/the-mirror-website/blob/dev/features/download/DownloadForm.tsx#L10-L14](https://github.com/the-mirror-megaverse/the-mirror-website/blob/dev/features/download/DownloadForm.tsx#L10-L14)

<img width="1149" alt="Untitled" src="https://user-images.githubusercontent.com/11920077/206995870-68d2a90c-3a28-4f6e-8221-6f8ef26fc901.png">

# Development: Getting Started

1. If you are on Mac, please run the Vulkan SDK Installer: [https://vulkan.lunarg.com/sdk/home](https://vulkan.lunarg.com/sdk/home) and **reboot your computer**
    1. Since Godot uses Vulkan Rendering, and MacOS only supports Metal Rendering, this takes care of the Vulkan → Metal conversion.
    2. If the latest sdk doesn’t work, the previous one might.

    [https://themirrormegaverse.slack.com/archives/C02URU4GX18/p1657291223203739?thread_ts=1657229202.075429&cid=C02URU4GX18](https://themirrormegaverse.slack.com/archives/C02URU4GX18/p1657291223203739?thread_ts=1657229202.075429&cid=C02URU4GX18)

2. Download and install Godot from here. We use a custom build to include the voxel terrain tool and some other C++ modules, so the standard official Godot download will **not** work.
[https://www.notion.so/the-mirror/How-to-compile-our-Godot-Editor-locally-130eef7cf8424470963cb892849f4576#04e9bc54bc2b4912bd131246a435dc67](https://www.notion.so/How-to-compile-our-Godot-Editor-locally-130eef7cf8424470963cb892849f4576)
3. Clone mirror-godot-app from Github: https://github.com/the-mirror-megaverse/mirror-client
    1. The Godot4 editor is here: [https://console.cloud.google.com/storage/browser/mirror_editor_builds/Godot4?project=the-[…]B%255D%22))&prefix=&forceOnObjectsSortingFiltering=false](https://console.cloud.google.com/storage/browser/mirror_editor_builds/Godot4?project=the-mirror-backend-dev&supportedpurview=project&pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))&prefix=&forceOnObjectsSortingFiltering=false)
4. Double check that you are using a `custom_build` :
If not, you will have some weird errors like “Unexpected end of line of X.tscn” and other missing “Voxel...”
It happens then you opened with a non-mirror

![Untitled 1](https://user-images.githubusercontent.com/11920077/206995758-ce4b90e1-f4b7-47a3-a4f1-e01f5a8e3727.png)
![Untitled 2](https://user-images.githubusercontent.com/11920077/206995759-9f67ea72-876b-4384-a4a7-9d0b61007c20.png)

5. Open `project.godot` and hit F5 to start the client. To set how many instances you would like to run, click Debug> Run Multiple Instances> Run ... to select the amount of clients you would like to run.

![Untitled 3](https://user-images.githubusercontent.com/11920077/206995785-daf13dbf-f972-4c31-9c25-79ea1afee1de.png)

**Note: you must run at least 2 instances to actually run the client - client 1 is always the server, client 2 is always the game**

## Install Git LFS

We use large file storage (LFS), so be sure to install it if it’s not already there.

1. Install this plugin: [https://git-lfs.github.com/](https://git-lfs.github.com/)
2. Run `git lfs install`

## Troubleshooting: Getting errors on the latest build?

1. Close the Godot editor
2. Delete the `.godot` folder
3. Reboot the editor and run again
    1. You can check if these user settings actually reset by going to Debug → Run Multiple Instances and it should be set back to 1
    2. You may have to do this a handful of times. It should be fixed with GD4 stability changes.

# Builds

[How to compile our Godot Editor locally](https://www.notion.so/How-to-compile-our-Godot-Editor-locally-130eef7cf8424470963cb892849f4576)

# Connecting to the Zone Server

## Deployed Zone Server

To configure the zone servers that the app can connect to, find the “dev.cfg” or “prod.cfg” in the project. These contain the IP addresses for the zone servers listed.

## Localhost Zone Server

To connect to the locally hosted zone server, run the game, running one client as a host, and as the client, select the “Localhost” space on the Space selection screen.

## Test Accounts

When logging in on dev, there is an options dropdown on the top-right.

![Untitled 4](https://user-images.githubusercontent.com/11920077/206996122-6cb82928-ccf1-45b5-ab3e-ced55b332154.png)

### Add a new test login on Firebase

*Note: This process may be adjusted when we add Discord login to the Godot app*

(Temp removed since the manual Firebase approach has issues)

### Add a new test login to the Godot app

If you’d like to add your own or a new test account for easy log in, open up “dev.cfg” in the Godot project. Find the “test_accounts” variable, which is an array of dicts, and follow the convention of adding a single dict with “email” and “password” to add this test account.

![Untitled 5](https://user-images.githubusercontent.com/11920077/206996141-54c98b58-00a1-4590-ab73-8c554acb5c1a.png)

*Do not use production accounts here for security purposes since we are committing a password.*

# Troubleshooting Setup

If you have cloned the repo and the project is still not running, here are some steps to take.

1. Go to Project Settings > Plugins, and ensure relevant plugins are enabled.
2. Quit to project list. Run “git stash” or “git restore .” to make sure working tree is clean before re-running. Ensure your project is up to date with dev and no extra changes were made, such as by Godot’s importing.
3. [https://www.loom.com/share/36adefe5f95743c1906c0ebbb1f22d7d](https://www.loom.com/share/36adefe5f95743c1906c0ebbb1f22d7d)
    1. In short, clear your cache which is the whole `.godot` folder, and make sure to wait for all the imports to be fully done before trying to run the game again :D
4. On Mac and Linux most errors from the engine will have stack traces, on windows builds from the CICD you won’t have debug symbols (due to the excessive size)
    1. This is a good way to debug your local editor for issues, if the above items don’t solve your issue.

# Code Style

[Decisions](https://www.notion.so/Decisions-481f0d0125eb4187b55c40eefeac915b)

# Features

### Deeplinking - Application Protocols

Allows launching of yourappname:// from a modern web browser, but also passes data to running instances when already open.

[Deep linking](https://www.notion.so/Deep-linking-98918f53719049f79727b53162fa6e81)

## `.tscn` imports

[Opening the app from a browser](https://www.notion.so/Opening-the-app-from-a-browser-451642431ca34237965415d62c01eb1f)

[DEPRECATED - Building the client with our export templates](https://www.notion.so/DEPRECATED-Building-the-client-with-our-export-templates-376e9b04a07c4bc7b293794283c447b2)

### File Import Types

- Supported image formats:
    - .jpeg
    - .jpg
    - .gif
    - .png
    - .bmp
    - .svg
    - .tiff
- Supported 3D formats:
    - .gltf
    - .glb
    - .pck (Godot packed scenes with dependencies)
- Supported formats coming soon:
    - .fbx
    - .obj

## Permissions System

 All Permissions client-side should validation from `ServerRequester.PLAYER_NETWORK_ID`

Current Systems that check ownership, assign ownership, or modified owner assets:

- `res://UI/ObjectInspectPopup.gd`
- `res://UI/InspectDetailPopup.gd`
- `res://asset.gd / set_instance_specific_data()`

## Export Templates (For building releases)

~~See [https://github.com/the-mirror-megaverse/mirror-docker-container/tree/master/export-templates](https://github.com/the-mirror-megaverse/mirror-docker-container/tree/master/export-templates)~~

~~They are on GCS (but currently out-of-sync with the latest Godot Editor builds):
[https://console.cloud.google.com/storage/browser/mirror-custom-templates/Godot4](https://console.cloud.google.com/storage/browser/mirror-custom-templates/Godot4)~~

[All Godot Packet types and subtypes](https://github.com/the-mirror-megaverse/mirror-client/blob/dev/global/server_requester.gd)

[Fixing Multirun on Windows and Mac (Google Meet Chat)](https://www.notion.so/Fixing-Multirun-on-Windows-and-Mac-Google-Meet-Chat-75dd8578b8fb48a8a322da5ac0b5fa1d)

# Feature Flags

See the PostHog dashboard for Feature Flags:

[PostHog](https://app.posthog.com/feature_flags)

[https://www.loom.com/share/58888fa7d3524769966d5af9c0f3c9f2](https://www.loom.com/share/58888fa7d3524769966d5af9c0f3c9f2)

[https://www.loom.com/share/dba2829d57d74ce09206942831711ec8](https://www.loom.com/share/dba2829d57d74ce09206942831711ec8)

# Godot 4 Upgrade Notes

## Editor Bugs

If you encounter a bug, add a [Godot Tasks](https://www.notion.so/Godot-Tasks-b3c407a483de4a5cb1d71ee4be8fc619)  with the Godot 4 bug template: [GD4 Bug Template (Core code, not our app) ](https://www.notion.so/GD4-Bug-Template-Core-code-not-our-app-baaa5c6f887f40dd89bf36f0efe42e3f)

HP/the Prehensile Tales team will take a look 😊

# Miro Architecture Board (Somewhat old)

[The Mirror Architecture](https://miro.com/app/board/uXjVOfCN75Y=/?invite_link_id=175784448421)

# Testing

Until we run tests as part of our CI/CD, Please run all tests before pushing a non-draft PR:
1. Debug > Run Multiple Instances > 1 instance
2. Run the custom scenes:
  a. integration_tests.tscn
  b. unit_tests.tscn
3. Then change your PR a non-draft

https://user-images.githubusercontent.com/11084784/211808386-8617bef4-5e85-4e2a-9600-0e06ccab2c87.mp4



## Unit Testing

Unit testing is supported by the “Godot Unit Testing” GDScript addon (https://github.com/bitwes/Gut). This addon is currently integrated with the Mirror Godot project. Official GUT documentation: [https://github.com/bitwes/Gut/wiki](https://github.com/bitwes/Gut/wiki)

Pretty good explanation video of GUT:

[https://www.youtube.com/watch?v=5DrhMiuLRl0](https://www.youtube.com/watch?v=5DrhMiuLRl0)

### Running Unit Tests

To run tests, select GUT in the bottom debugger window, and click “Run All”.

![Untitled 6](https://user-images.githubusercontent.com/11920077/206996215-4496f5ac-f454-4ad5-8d5c-19518482a1f2.png)

### Creating a New Unit Test

To create a new test, browse to project directory /test/unit/. Create a new script inside of the /test/unit/ directory that extends class UnitTest. The script name must be prefixed with “test_” for GUT to detect it. When creating a test method, prepend the name with “test_”. Use the GUT methods that begin with “assert_” to make your assertions ([documentation on assertions here](https://github.com/bitwes/Gut/wiki/Asserts-and-Methods)).

```python
extends UnitTest

func test_string():
	assert_true("Hello World" is String)
```
![Untitled 7](https://user-images.githubusercontent.com/11920077/206996235-0b266ee8-4d04-46cd-aa72-34055b3e649a.png)

---

## Integration Testing

Integration tests help us make sure our app and RESTful services are communicating as intended at all times. It also allows developers to integrate web services into the application in a controlled and repeatable environment.

### Running Integration Tests

---

To run The Mirror integration tests:

1. Press the “Play Custom Scene” button in Godot Editor.

![Untitled 8](https://user-images.githubusercontent.com/11920077/206996253-8c23b31f-a163-49b3-bef1-41423b3195ee.png)


1. Search for scene “IntegrationTests.tscn”. Run this scene.

![Untitled 9](https://user-images.githubusercontent.com/11920077/206996266-75f698df-b454-43c6-9c97-f0e03f3e29a5.png)

1. Observe the output of the network service integration tests in the Godot console
    1. If it says `All client tests completed.` then all test ran successfully
    2. If it Fails at some test, it will stop any other integration tests (since they are dependent in order)

![Untitled 10](https://user-images.githubusercontent.com/11920077/206996287-4c06d5e6-9532-4113-bc0a-cd21733cbbde.png)

[Deep linking](https://www.notion.so/Deep-linking-98918f53719049f79727b53162fa6e81)

# CICD

Builds are made using the scripts in the following URL

[https://github.com/the-mirror-megaverse/mirror-godot-app/blob/dev/.github/workflows/main.yml](https://github.com/the-mirror-megaverse/mirror-godot-app/blob/dev/.github/workflows/main.yml)

**The purpose of this script is to:**

- Build the game and copy the pre-built engine from our godot-soft-fork.
- Run unit tests
- Export the game
- Create test builds for pull requests
- Upload our `dev` branch to our google cloud bucket - for auto updating and for server scaling. (WIP)

For our secrets on github actions: We have two keys: `UPLOAD_KEY` and `UPLOAD_USERNAME` if this list changes we will update the documentation.

![Screenshot 2022-09-26 at 16.45.21.png](Readme%20Godot%20App%20abf0107b48244d70bcd33d01f6d74170/Screenshot_2022-09-26_at_16.45.21.png)

These are used to send builds from Github Actions to Google Cloud’s storage buckets, when modifying the build scripts be aware that you may need to ensure dev/ uploads work too after modification.


**When using these keys you don’t ever want to print their contents, when checking PRs ensure nothing prints them to console. As when it gets merged to dev/ it will actually be built and uploaded, so the key could be exposed.**

**PRS do not have access to the secrets - this is by design.**
