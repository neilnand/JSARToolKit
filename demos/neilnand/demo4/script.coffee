# Properties
WIDTH = 640
HEIGHT = 480
USE_STATIC_VIDEO = false

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
  constructor: (@elements) ->
    @ctxIn = @elements.canvasIn[0].getContext "2d"
    @ctxOut = @elements.canvasOut[0].getContext "2d"
    @raster = new NyARRgbRaster_Canvas2D @elements.canvasIn[0]
    @param = new FLARParam WIDTH, HEIGHT

    @resultMat = new NyARTransMatResult()
    @display = new Magi.Scene @elements.canvasGL[0]

    @param.copyCameraMatrix @display.camera.perspectiveMatrix, 100, 10000
    @display.camera.useProjectionMatrix = true

    @videoTex = new Magi.FlipFilterQuad()
    @videoTex.material.textures.Texture0 = new Magi.Texture()
    @videoTex.material.textures.Texture0.image = @elements.canvasOut[0]
    @videoTex.material.textures.Texture0.generateMipmaps = false
    @display.scene.appendChild @videoTex

  init: ->

    $.get "custom.pat", (data) =>

      # Load Pattern
      @mpattern = new FLARCode 64, 64
      @mpattern.loadARPatt data

      @detector = new FLARSingleMarkerDetector @param, @mpattern, 100
      @detector.setContinueMode true

      img = $("<img/>").attr("src", "bizCard.png").load (evt) =>

        if img[0].complete
          @marker = {}
          @overlay = @createOverlay img
        else
          new Error "Could not load Overlay Image", evt

      # Load Marker Overlay
      @update()

  update: =>

    try
      @processVisuals()
      @processDetection()
      @renderOverlay()

    window.requestAnimFrame =>
      @update()
  processVisuals: ->

    # Update Canvas that is fed into AR
    @ctxOut.drawImage @elements.video[0], 0, 0, WIDTH, HEIGHT
    utils.invertContext @ctxOut, @ctxIn, 0, 0, WIDTH, HEIGHT
    @elements.canvasIn[0].changed = true

    # Update Material that is AR super-imposed on GL
    @videoTex.material.textures.Texture0.changed = true
    @videoTex.material.textures.Texture0.upload()

  processDetection: ->

    # Detect and update transformations of markers
    @detected = @detector.detectMarkerLite(@raster, 170) and @detector.getConfidence() > .4

    return if not @detected

    @detector.getTransformMatrix @resultMat
    @marker.transform = Object.asCopy @resultMat

  renderOverlay: ->

    if not @detected
      # Remove Overlays if Marker not detected
      if @overlay.display
        @overlay.display = false
      return

    # Display and update overlays
    @overlay.display = true

    arMat = @marker.transform
    glMat = @overlay.transform

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

  createOverlay: (img) ->
    pivot = new Magi.Node()
    pivot.transform = mat4.identity()
    pivot.setScale 100

    overlay = new Magi.Image img[0]
    overlay.setZ .07
    overlay.setScale 1/110
    pivot.appendChild overlay

    pivot.overlay = overlay

    @display.scene.appendChild pivot
    pivot

class Utils
  invertContext: (ctxIn, ctxOut, x, y, w, h) ->
    imgData = ctxIn.getImageData x, y, w, h
    data = imgData.data

    i = 0
    while i < data.length
      data[i] = 255 - data[i]
      data[i + 1] = 255 - data[i + 1]
      data[i + 2] = 255 - data[i + 2]
      i += 4

    ctxOut.putImageData imgData, x, y


# Setup Elements
elements =
  video: $ "video"
  canvasIn: $ "canvas.input"
  canvasOut: $ "canvas.output"
  canvasGL: $ "canvas.gl"

for id, el of elements
  el[0].width = WIDTH
  el[0].height = HEIGHT

utils = new Utils()
jsar = new JSAR elements

if navigator.getUserMedia and not USE_STATIC_VIDEO
  console.log "Camera Available"

  # Get Camera Feed
  navigator.getUserMedia {
      video:
        mandatory:
          minWidth: WIDTH
          minHeight: HEIGHT
    }, (stream) ->

    # Set Camera Feeds
    elements.video.attr "src", window.URL.createObjectURL stream
    jsar.init()

  , (evt) ->
    new Error "Could not get Camera Stream", evt

else
  console.log "Camera Not Available"

  videoToggle = ->
    if elements.video[0].paused
      elements.video[0].play()
    else
      elements.video[0].pause()

  # Use Looping Video
  elements.video.attr "src", "video_test_biz_card.mp4"
  elements.video[0].loop = true
  for id, el of elements
    el.click videoToggle
  jsar.init()

