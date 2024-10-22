import { useEffect, useState } from 'react'

export function useAllowDisallowKeyboardPropogationForCanvas(canvasRef) {
  const [canvasFocused, setCanvasFocused] = useState(false)
  // Handle mouse clicks to determine if canvas is focused
  useEffect(() => {
    const handleClick = (event) => {
      if (canvasRef.current && canvasRef.current.contains(event.target)) {
        setCanvasFocused(true) // Clicked inside the canvas
      } else {
        setCanvasFocused(false) // Clicked outside the canvas
      }
    }

    // Add click event listener
    document.addEventListener('mousedown', handleClick)

    return () => {
      document.removeEventListener('mousedown', handleClick)
    }
  }, [])

  // Prevent keyboard events if canvas is not focused
  useEffect(() => {
    const handleKeyDown = (event) => {
      if (!canvasFocused) {
        // Prevent default keyboard events if canvas isn't focused
        console.log(
          'useAllowDisallowKeyboardPropogationForCanvas: Canvas not focused; stopping propogation'
        )
        event.stopPropagation()
      }
    }

    document.addEventListener('keydown', handleKeyDown)

    return () => {
      document.removeEventListener('keydown', handleKeyDown)
    }
  }, [canvasFocused])
}
