extends Node3D


const _ROTATE_180_XZ_BASIS := Basis(Vector3.LEFT, Vector3.UP, Vector3.FORWARD)


func fit_onto_seat_points(seat_dict: Dictionary) -> void:
	GLTFDocumentExtensionOMISeat.convert_seat(seat_dict)
	basis = Basis.looking_at(seat_dict.get("upper_leg_dir"), seat_dict.get("upper_leg_norm"))
	basis *= _ROTATE_180_XZ_BASIS
	global_transform.basis = global_transform.basis.orthonormalized()
	var seat_knee: Vector3 = seat_dict.get("knee")
	# For simplicity, the values in this Vector3 are hard-coded for the astronaut ghost.
	position = seat_knee - basis * Vector3(0.0, 0.45, 0.38)
