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

    @display = new Magi.Scene canvasGLDom

    @param.copyCameraMatrix @display.camera.perspectiveMatrix, 10, 10000
    @display.camera.useProjectionMatrix = true

    @videoTex = new Magi.FlipFilterQuad()
    @videoTex.material.textures.Texture0 = new Magi.Texture()
    @videoTex.material.textures.Texture0.image = canvasDom
    @videoTex.material.textures.Texture0.generateMipmaps = false
    @display.scene.appendChild @videoTex

    @markers = {}
    @cubes = {}


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

    @detected = !!markerCount

    return if not @detected

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

      idx++

  render: ->
    if not @detected
      if @cubesVisible
        for id, cube of @jsar.cubes
          cube.display = false
        @cubesVisible = false
      return

    @cubesVisible = true

    for id, marker of @jsar.markers
      @createCube id if not @jsar.cubes[id]

      @jsar.cubes[id].display = true

      mat = marker.transform

      cm = @jsar.cubes[id].transform
      cm[0] = mat.m00
      cm[1] = -mat.m10
      cm[2] = mat.m20
      cm[3] = 0
      cm[4] = mat.m01
      cm[5] = -mat.m11
      cm[6] = mat.m21
      cm[7] = 0
      cm[8] = -mat.m02
      cm[9] = mat.m12
      cm[10] = -mat.m22
      cm[11] = 0
      cm[12] = mat.m03
      cm[13] = -mat.m13
      cm[14] = mat.m23
      cm[15] = 1
      
        
  createCube: (id) ->
    pivot = new Magi.Node()
    pivot.transform = mat4.identity()
    pivot.setScale 80

    cube = new Magi.Cube()
    cube.setZ -0.125
    cube.scaling[2] = 0.25
    pivot.appendChild cube

    txt = new Magi.Text id.toString()
    txt.setColor "black"
    txt.setFontSize 48
    txt.setAlign txt.centerAlign, txt.bottomAlign
    txt.setZ -0.6
    txt.setY -0.34
    txt.setScale 1/80
    cube.appendChild txt

    pivot.cube = cube
    pivot.txt = txt

    @jsar.display.scene.appendChild pivot
    @jsar.cubes[id] = pivot







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

  # Use Looping Video
  video.attr "src", "video_test.mp4"
  video[0].loop = true
  jsarEngine.update()