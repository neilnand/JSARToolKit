# Shim
navigator.getUserMedia =
navigator.getUserMedia ||
navigator.webkitGetUserMedia ||
navigator.mozGetUserMedia ||
navigator.msGetUserMedia

window.requestAnimFrame = (->
  window.requestAnimationFrame ||
  window.webkitRequestAnimationFrame ||
  window.mozRequestAnimationFrame ||
  (callback) ->
    window.setTimeout(callback, 1000 / 60)
)()

# Classes
class Error
  constructor: (msg, e) ->
    console.log "ERROR:", msg, e

class CanvasStream
  constructor: (@canvasDom, @videoDom) ->
    @context = @canvasDom.getContext "2d"
  update: =>
    @render()
    window.requestAnimFrame =>
      @update()
  render: ->
    @context.drawImage @videoDom, 0, 0


# Init
WIDTH = 640
HEIGHT = 480

if navigator.getUserMedia
  
  console.log "Camera Available"

  # Setup Elements
  video = document.querySelector "video"
  video.onloadedmetadata = (evt) ->
    console.log "video.onloadedmetadata", evt

  canvas = document.querySelector "canvas"
  canvas.width = WIDTH
  canvas.height = HEIGHT
  canvasStream = new CanvasStream canvas, video

  # Get Camera Feed
  navigator.getUserMedia {
      video:
        mandatory:
          minWidth: WIDTH
          minHeight: HEIGHT
    }, (stream) ->

    # Set Camera Feeds
    video.src = window.URL.createObjectURL stream
    canvasStream.update()

  , (evt) ->
    new Error "Could not get Camera Stream", evt

else
  console.log "Camera Not Available"