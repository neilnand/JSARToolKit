# Properties
WIDTH = 640
HEIGHT = 320
USE_CAMERA = false

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


class JSAR
  constructor: (
    canvasDom
    canvasGLDom
  ) ->
    @raster = new NyARRgbRaster_Canvas2D canvasDom
    @param = new FLARParam WIDTH, HEIGHT
    @detector = new FLARMultiIdMarkerDetector @param, 120
    @detector.setContinueMode true
    @resultMat = new NyARTransMatResult()

    display = new Magi.Scene canvasGLDom

    @param.copyCameraMatrix display.camera.perspectiveMatrix, 10, 10000
    display.camera.useProjectionMatrix = true;

    @videoTex = new Magi.FlipFilterQuad()
    @videoTex.material.textures.Texture0 = new Magi.Texture()
    @videoTex.material.textures.Texture0.image = canvasDom
    @videoTex.material.textures.Texture0.generateMipmaps = false
    display.scene.appendChild @videoTex

    @markers = {}


class JSAREngine
  constructor: (@canvasDom, @videoDom, @jsar) ->
    @context = @canvasDom.getContext "2d"
  update: =>

    try
      @processVisuals()
      @processDetection()
      @render()

    window.requestAnimFrame =>
      @update()
  processVisuals: ->

    @context.drawImage @videoDom, 0, 0, WIDTH, HEIGHT
    @canvasDom.changed = true

    @jsar.videoTex.material.textures.Texture0.changed = true
    @jsar.videoTex.material.textures.Texture0.upload()

  processDetection: ->
    markerCount = @jsar.detector.detectMarkerLite(@jsar.raster, 170)

    idx = 0
    while idx < markerCount

      id = @jsar.detector.getIdMarkerData idx

      currId = -1
      if id.packetLength <= 4
        currId = 0
        i = 0
        while i < id.packetLength
          currId = (currId << 8) | id.getPacketData(i)
          i++

      @jsar.detector.getTransformMatrix idx, @jsar.resultMat
      @jsar.markers[currId] = {} if not @jsar.markers[currId]
      @jsar.markers[currId].transform = Object.asCopy @jsar.resultMat

      console.log @jsar.markers[currId]

      idx++

  render: ->
    for marker in @jsar.markers
      console.log marker


# Setup Elements
video = $ "video"
video[0].width = WIDTH
video[0].height = HEIGHT
video[0].controls = false
video[0].onloadedmetadata = (evt) ->
  console.log "video.onloadedmetadata", evt

canvas = $ "canvas.output"
canvas[0].width = WIDTH
canvas[0].height = HEIGHT

canvasGL = $ "canvas.gl"
canvasGL[0].width = WIDTH
canvasGL[0].height = HEIGHT

jsar = new JSAR canvas[0], canvasGL[0]
jsarEngine = new JSAREngine canvas[0], video[0], jsar

if navigator.getUserMedia and USE_CAMERA
  console.log "Camera Available"

  # Get Camera Feed
  navigator.getUserMedia {
      video:
        mandatory:
          minWidth: WIDTH
          minHeight: HEIGHT
    }, (stream) ->

    # Set Camera Feeds
    video.attr "src", window.URL.createObjectURL stream
    jsarEngine.update()

  , (evt) ->
    new Error "Could not get Camera Stream", evt

else
  console.log "Camera Not Available"

  video.attr "src", "video_test.mp4"
  video[0].loop = true
  jsarEngine.update()