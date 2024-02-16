# Gizmo communication and dependencies

The gizmo interacts with the current camera directly by grabbing it
from the Viewport. It uses the camera to determine how big it should
be, and update the highlighting on its parts.

The base camera node, raycast camera, has an `raycast_camera_input` method
that performs a raycast for the Gizmo pieces (ex: an arrow or plane) when
a click is received using the `interact_raycast_layer` method.
This looks for a `click_raycast_event` method on the gizmo pieces,
which then signals up to a main part (ex: translation gizmo) and calls
its `process_input_signal` method, starting the transformation.

Each gizmo part has an `_input` method that listens for input whenever
its `current_gizmo_piece` member is set, and process input for that piece.
For example, if an arrow piece was clicked on, it will calculate the closest
point on that line to the mouse and save it in `position_dragged_to`.
This variable is then snapped and passed to the selection helper `target`.

CreatorUI handles communication between the toolbars and the gizmo.
Whenever a toolbar has its Gizmo options updated, it calls a method
on CreatorUI, which then updates all other toolbars and the Gizmo.
This is used when changing the gizmo type, changing the snap settings,
and changing if relative is enabled.
