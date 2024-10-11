# Change history for the Godot OpenXR loaders asset

## 3.0.1
- Fixed hand tracking issue

## 3.0.0
- Merge GDExtension into a single implementation
- Upgrade Android, Gradle, Godot and Kotlin dependencies
- Add XR_FB_face_tracking support
- Update to OpenXR 1.0.34 headers
- Add XR_FB_render_model extension wrapper and OpenXRFBRenderModel node
- Add XR_FB_passthrough extension wrapper
- Add XR_FB_hand_tracking_mesh extension wrapper and OpenXRFbHandTrackingMesh node
- Add XR_FB_hand_tracking_aim support
- Update Meta OpenXR mobile SDK to version 62
- Add a developer-facing API for interacting with scene anchors
- Add support for developer-created spatial anchors via XR_FB_spatial_entity
- Add XR_FB_hand_tracking_capsules extension wrapper
- Add OpenXRFbPassthroughGeometry node
- Add OpenXRMetaPassthroughColorLut
- Add feature flags to Khronos loader for HTC
- Add XR_HTC_passthrough extension wrapper
- Add manifest entries to Pico and switch Pico to using the Khronos Loader
- Add Meta Passthrough tutorial doc

## 2.0.3
- Migrate the export scripts from gdscript to C++ via gdextension
- Manually request eye tracking permission if it's included in the app manifest
- Change how singletons are accessed
- Fix the plugin version for the export plugins
- Add OpenXR extension wrappers for fb_scene, fb_spatial_entity, fb_spatial_entity_query, fb_spatial_entity_container

## 2.0.0
- Update to the new Godot 4.2 Android plugin packaging format
- Update the plugin to Godot v2 Android plugin
- Update to the Godot 4.2 Android library
- Add warning when multiple loaders are selected
- Add configs for the OpenXR Eye gaze interaction extension
- Add the ability to customize supported Meta devices
- Add support for Quest 3 devices
- Update the directory structure for the v2 plugin
- Update Meta OpenXR mobile SDK to version 57
- Update the java version to 17
- Rename the plugin to 'Godot OpenXR Vendors'
- Add godot-cpp dependency
- Add OpenXR 1.0.30 headers
- Add support for the Meta scene capture API (Donated by [Migeran](https://migeran.com))

## 1.1.0
- Update Meta OpenXR loader to version 54
- Update PICO OpenXR loader to version 2.2.0
- Bump dependencies versions to match the latest Godot 4.x stable version (v4.0.3)

## 1.0.0
- First version
- Added support for Meta Quest loader
- Added support for Pico loader
- Added support for Khronos loader (Magic Leap 2, HTC, etc.)
- Added support for Lynx loader
- Add logic to automatically publish the Godot OpenXR loaders libraries to mavencentral on release
