export default function downloadFile(data: Blob, filename: string) {
  const url = window.URL.createObjectURL(data) // Create a Blob URL
  const link = document.createElement('a') // Create an anchor element
  link.href = url // Set the Blob URL as the href attribute
  link.setAttribute('download', filename) // Set the filename for download

  document.body.appendChild(link) // Append the anchor to the DOM
  link.click() // Simulate a click event

  document.body.removeChild(link) // Clean up the anchor
  window.URL.revokeObjectURL(url) // Release the Blob URL
}
