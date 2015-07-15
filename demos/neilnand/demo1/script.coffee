# Properties
WIDTH = 640
HEIGHT = 480
USE_CAMERA = true

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
  constructor: (@canvasDom, @canvasGLDom, @videoDom) ->
    @context = @canvasDom.getContext "2d"
    @raster = new NyARRgbRaster_Canvas2D @canvasDom
    @param = new FLARParam WIDTH, HEIGHT
    @detector = new FLARMultiIdMarkerDetector @param, 120
    @detector.setContinueMode true
    @resultMat = new NyARTransMatResult()

    @display = new Magi.Scene @canvasGLDom

    @param.copyCameraMatrix @display.camera.perspectiveMatrix, 100, 10000
    @display.camera.useProjectionMatrix = true

    @videoTex = new Magi.FlipFilterQuad()
    @videoTex.material.textures.Texture0 = new Magi.Texture()
    @videoTex.material.textures.Texture0.image = @canvasDom
    @videoTex.material.textures.Texture0.generateMipmaps = false
    @display.scene.appendChild @videoTex

    @markers = {}
    @overlays = {}
    
  update: =>

    try
      @processVisuals()
      @processDetection()
      @renderOverlay()

    window.requestAnimFrame =>
      @update()
  processVisuals: ->

    # Update Canvas that is fed into AR
    @context.drawImage @videoDom, 0, 0, WIDTH, HEIGHT
    @canvasDom.changed = true

    # Update Material that is AR super-imposed on GL
    @videoTex.material.textures.Texture0.changed = true
    @videoTex.material.textures.Texture0.upload()

  processDetection: ->

    # Detect and update transformations of markers
    markerCount = @detector.detectMarkerLite(@raster, 170)

    @detected = !!markerCount

    return if not @detected

    idx = 0
    while idx < markerCount

      id = @detector.getIdMarkerData idx

      currId = -1
      if id.packetLength <= 4
        currId = 0
        i = 0
        while i < id.packetLength
          currId = (currId << 8) | id.getPacketData(i)
          i++

      @detector.getTransformMatrix idx, @resultMat
      @markers[currId] = {} if not @markers[currId]
      @markers[currId].transform = Object.asCopy @resultMat

      idx++

  renderOverlay: ->

    if not @detected

      # Remove Overlays if Marker not detected
      if @overlaysVisible
        for id, overlay of @overlays
          overlay.display = false
        @overlaysVisible = false
      return

    # Display and update overlays

    @overlaysVisible = true

    for id, marker of @markers
      @createOverlay id if not @overlays[id]

      @overlays[id].display = true

      arMat = marker.transform

      glMat = @overlays[id].transform
      glMat[0] = arMat.m00
      glMat[1] = -arMat.m10
      glMat[2] = arMat.m20
      glMat[3] = 0
      glMat[4] = arMat.m01
      glMat[5] = -arMat.m11
      glMat[6] = arMat.m21
      glMat[7] = 0
      glMat[8] = -arMat.m02
      glMat[9] = arMat.m12
      glMat[10] = -arMat.m22
      glMat[11] = 0
      glMat[12] = arMat.m03
      glMat[13] = -arMat.m13
      glMat[14] = arMat.m23
      glMat[15] = 1
      
        
  createOverlay: (id) ->
    pivot = new Magi.Node()
    pivot.transform = mat4.identity()
    pivot.setScale 100

    overlay = new Magi.Cube()
    overlay.setZ -0.125
    overlay.scaling[2] = 0.25
    pivot.appendChild overlay

    txt = new Magi.Text id.toString()
    txt.setColor "black"
    txt.setFontSize 48
    txt.setAlign txt.centerAlign, txt.bottomAlign
    txt.setZ -0.6
    txt.setY -0.34
    txt.setScale 1/80
    overlay.appendChild txt

    pivot.overlay = overlay
    pivot.txt = txt

    @display.scene.appendChild pivot
    @overlays[id] = pivot


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

jsar = new JSAR canvas[0], canvasGL[0], video[0]

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
    jsar.update()

  , (evt) ->
    new Error "Could not get Camera Stream", evt

else
  console.log "Camera Not Available"

  # Use Looping Video
  video.attr "src", "video_test.mp4"
  video[0].loop = true
  jsar.update()