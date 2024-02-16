# HTTPSSEClient

This is an implementation of the server-sent events/event-source protocol (https://www.w3.org/TR/eventsource/) in GDScript for the Godot game engine.

To use this, simply download this project and place it into the `res://addons/HTTPSSEClient/` folder in your project; then you can just turn it on.

I've included demo.tscn and demo.gd to show the usage of this plugin, and here's a summary:

1) Download and place into the proper folder as the above suggests
2) Switch the new plugin, found in Project Settings -> Plugins, to active
3) Instantiate a new HTTPSSEClient node in your scene tree somewhere
4) Click on the script icon for the newly-created node
5) Enter in any connection information necessary to connect to your SSE-supported server; for demonstration purposes, I use Firebase, and in the config dictionary, I just add the entire config I get back from adding a new Android app to any Firebase project (it'll give you back the google-services.json file, copy/paste it into config and change the url in the script to firebase_url and you're set for this)
6) If you're using Firebase, you need a sub_url value that is something like "/your_demo_list.json?auth=" and then the value of either your Firebase ID token, or your database secret. It's not clear how long database secrets will remain functional as they're already deprecated, but it is supported for the time being due to backward compatibility issues.

When using my GDFirebase plugin, all of the above is handled for you automatically, so you will only need to use the information provided by that plugin.
