# JSARToolkit

##### Original Notes

--------------------------------------------------------------------------------

This is a JavaScript port of FLARToolKit, operating on canvas images and
video element contents. And hopefully one day on device elements with webcam
input.

The license is GPL 3 as was the original library. If you use it in your own scripts, you need to make the unminified unobfuscated source code of your script available and licensed under GPL 3.

All the hard work was done by the ARToolKit/NyARToolKit/FLARToolKit people,
a huge thank you to them. This port was quite mechanical, though it has some
major JS optimizations and a tracking robustness hack or two. And some
uninformed bogus hacks in FLARParam to sort-of make it work on 16:9 video.

See demos/AR_simple_webgl.html for an example of integrating JSARToolKit
output with a WebGL program.

I've only tested the ID markers and square detection paths, so you may
encounter problems working with custom markers. In which case, filing a bug
report on GitHub would be very much appreciated.


- Ilmari Heikkinen

--------------------------------------------------------------------------------
This work is based on the original ARToolKit developed by
  Hirokazu Kato
  Mark Billinghurst
  HITLab, University of Washington, Seattle
http://www.hitl.washington.edu/artoolkit/

And the NyARToolkitAS3 ARToolKit class library.
  Copyright (C)2010 Ryo Iizuka

The FLARToolKit is ActionScript 3.0 version ARToolkit class library.
   Copyright (C)2008 Saqoosha

JSARToolkit is a JavaScript port of NyARToolkitAS3 and FLARToolKit.
  Copyright (C)2011 Ilmari Heikkinen

--------------------------------------------------------------------------------

## Updates by @neilnand

- NPM & Express added to get runing faster
- Example: Multiple ID Marker Demo
- Example: Single ID Marker Demo
- Example: Single Custom Marker Demo
- Example: Inverted Biz Card Demo
- Pattern Generator Application: Custom Marker Pattern Generator Installer (AIR App)

### Real World Demo

1. Print or Open on mobile device: [neilnand-access-bizcard.gif](https://neilnand.com/assets/neilnand-access-bizcard.gif)
2. Visit [neilnand.com/london-career-campaign](https://neilnand.com/london-career-campaign) using Chrome or Firefox on Desktop
3. Scroll to **London Career Campaign**
4. Press **Click here to Activate Webcam**
5. Show [neilnand-access-bizcard.gif](https://neilnand.com/assets/neilnand-access-bizcard.gif) image to webcam

### Installation

##### Pre-requisites
Ensure you have the following repositories setup:

- NodeJS / NPM: [nodejs.org](http://nodejs.org/), download and install **NodeJS**
- Compass / SASS: <http://compass-style.org/install/>

##### Instructions

1. download this repository and install dependencies

        $ git clone git@github.com:neilnand/JSARToolKit.git
        $ cd JSARToolKit
        $ npm install
        $ bower install
        $ grunt bowerlink

2. start server

        $ grunt

3. live updates - watch for changes

        ## Run in another Terminal window
        $ grunt devwatch

4. open up web browser to:

        ## http://localhost:3000

##### Other

- Minify JSARToolKit.js

        $ grunt minify

