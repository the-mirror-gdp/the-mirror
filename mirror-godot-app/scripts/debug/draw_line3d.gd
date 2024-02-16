# From completely libre work of https://github.com/klaykree/godot-3_d_lines/blob/6518f911cda92de4a65f65c47ec716ee1c5cebff/draw_line3_d.gd
# With a license allowing everything without constraints ( The Unlicense license )
extends Node2D


class Line:
	var Start
	var End
	var LineColor
	var time

	func _init(New_Start, New_End, New_LineColor, New_time):
		self.Start = New_Start
		self.End = New_End
		self.LineColor = New_LineColor
		self.time = New_time


var Lines = []
var RemovedLine = false


func _process(delta):
	for i in range(len(Lines)):
		Lines[i].time -= delta

	if len(Lines) > 0 or RemovedLine:
		queue_redraw() # Calls _draw
		RemovedLine = false


func _draw():
	var viewport = PlayerData.get_local_player().camera_get_viewport()
	var Cam = viewport.get_camera()
	for i in range(len(Lines)):
		var ScreenPointStart = Cam.unproject_position(Lines[i].Start)
		var ScreenPointEnd = Cam.unproject_position(Lines[i].End)

		# Dont draw line if either start or end is considered behind the camera
		# this causes the line to not be drawn sometimes but avoids a bug where the
		# line is drawn incorrectly
		if Cam.is_position_behind(Lines[i].Start) or Cam.is_position_behind(Lines[i].End):
			continue

		draw_line(ScreenPointStart, ScreenPointEnd, Lines[i].LineColor)

	# Remove lines that have timed out
	var i = Lines.size() - 1
	while i >= 0:
		if Lines[i].time < 0.0:
			Lines.remove(i)
			RemovedLine = true
		i -= 1


func DrawLine(Start, End, LineColor, time = 0.0):
	Lines.append(Line.new(Start, End, LineColor, time))


func DrawRay(Start, Ray, LineColor, time = 0.0):
	Lines.append(Line.new(Start, Start + Ray, LineColor, time))


func DrawCube(Center, HalfExtents, LineColor, time = 0.0):
	# Start at the 'top left'
	var LinePointStart = Center
	LinePointStart.x -= HalfExtents
	LinePointStart.y += HalfExtents
	LinePointStart.z -= HalfExtents

	# Draw top square
	var LinePointEnd = LinePointStart + Vector3(0, 0, HalfExtents * 2.0)
	DrawLine(LinePointStart, LinePointEnd, LineColor, time)
	LinePointStart = LinePointEnd
	LinePointEnd = LinePointStart + Vector3(HalfExtents * 2.0, 0, 0)
	DrawLine(LinePointStart, LinePointEnd, LineColor, time)
	LinePointStart = LinePointEnd
	LinePointEnd = LinePointStart + Vector3(0, 0, -HalfExtents * 2.0)
	DrawLine(LinePointStart, LinePointEnd, LineColor, time)
	LinePointStart = LinePointEnd
	LinePointEnd = LinePointStart + Vector3(-HalfExtents * 2.0, 0, 0)
	DrawLine(LinePointStart, LinePointEnd, LineColor, time)

	# Draw bottom square
	LinePointStart = LinePointEnd + Vector3(0, -HalfExtents * 2.0, 0)
	LinePointEnd = LinePointStart + Vector3(0, 0, HalfExtents * 2.0)
	DrawLine(LinePointStart, LinePointEnd, LineColor, time)
	LinePointStart = LinePointEnd
	LinePointEnd = LinePointStart + Vector3(HalfExtents * 2.0, 0, 0)
	DrawLine(LinePointStart, LinePointEnd, LineColor, time)
	LinePointStart = LinePointEnd
	LinePointEnd = LinePointStart + Vector3(0, 0, -HalfExtents * 2.0)
	DrawLine(LinePointStart, LinePointEnd, LineColor, time)
	LinePointStart = LinePointEnd
	LinePointEnd = LinePointStart + Vector3(-HalfExtents * 2.0, 0, 0)
	DrawLine(LinePointStart, LinePointEnd, LineColor, time)

	# Draw vertical lines
	LinePointStart = LinePointEnd
	DrawRay(LinePointStart, Vector3(0, HalfExtents * 2.0, 0), LineColor, time)
	LinePointStart += Vector3(0, 0, HalfExtents * 2.0)
	DrawRay(LinePointStart, Vector3(0, HalfExtents * 2.0, 0), LineColor, time)
	LinePointStart += Vector3(HalfExtents * 2.0, 0, 0)
	DrawRay(LinePointStart, Vector3(0, HalfExtents * 2.0, 0), LineColor, time)
	LinePointStart += Vector3(0, 0, -HalfExtents * 2.0)
	DrawRay(LinePointStart, Vector3(0, HalfExtents * 2.0, 0), LineColor, time)
