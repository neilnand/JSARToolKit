# Shim
navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia

# Classes
class Error
  constructor: (msg, e) ->
    console.log msg, e

class Camera


# Init
WIDTH = 640
HEIGHT = 480

if navigator.getUserMedia
  console.log "Camera Available"

  video = document.querySelector "video"
  video.onloadedmetadata = (evt) ->
    console.log "video.onloadedmetadata", evt

  # Get Camera Feed
  navigator.getUserMedia {
      video:
        mandatory:
          minWidth: WIDTH
          minHeight: HEIGHT
    }, (stream) ->
    video.src = window.URL.createObjectURL stream
  , (evt) ->
    new Error "Could not get Camera Stream", evt

else
  console.log "Camera Not Available"