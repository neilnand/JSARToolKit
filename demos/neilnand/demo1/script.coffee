# Properties
WIDTH = 640
HEIGHT = 320

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
    @render()
    window.requestAnimFrame =>
      @update()
  render: ->

    @context.drawImage @videoDom, 0, 0, WIDTH, HEIGHT
    @canvasDom.changed = true

    @jsar.videoTex.material.textures.Texture0.changed = true
    @jsar.videoTex.material.textures.Texture0.upload()

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

      if not @jsar.markers[currId]
        @jsar.markers[currId] = {}

      @jsar.detector.getTransformMatrix idx, @jsar.resultMat

      console.log @jsar.markers[currId], Object.asCopy @jsar.resultMat

      @jsar.markers[currId].transform = Object.asCopy @jsar.resultMat

      idx++


# Init
if navigator.getUserMedia
  
  console.log "Camera Available"

  # Setup Elements
  video = $ "video"
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