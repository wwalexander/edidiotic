edidiotic
=========

edidiotic creates EDID overrides for external displays on macOS that set the
display type to RGB color and removes all extension blocks. This seems to fix an
issue where macOS uses YCbCr with chroma subsampling on external displays. This
also fixed a rather particular issue of mine involving a Thunderbolt to HDMI 2.0
dock.

I haven't added much in the way of error handling, usability, or versatility,
but if you find this at all useful please open up an issue as I love to work on
projects I know people are using.

edidiotic is based on [adaugherity's script](https://gist.github.com/adaugherity/7435890)
but gets display info directly via IOKit rather than by parsing the output of
the `ioreg` command. It also appears that adaugherity's script incorrectly sets
the color mode to "Monochrome / grayscale display" instead of "RGB color
display" as per the [EDID 1.3 standard](https://glenwing.github.io/docs/VESA-EEDID-A1.pdf),
which edidiotic fixes.