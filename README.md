# Stickerboard

tl;dr: This is [uSticker](https://github.com/apsun/uSticker) for iOS.

Unlike uSticker, Stickerboard is written from the ground up as a standalone
keyboard extension. This means that all of the awful Gboard bugs that
plagued uSticker on Android have been replaced with... probably more bugs,
but at least now we can fix them ourselves ;-)

There are currently no plans to "port" Stickerboard back to Android. Please
do not ask for this.

As with uSticker, this is strictly a personal project; bug reports are
welcome, but please do not submit feature requests. I make this app public
(and free - this Mac Mini and Apple Developer Program membership fee is
pretty expensive, you know!) in the hopes that you share my usecase and find
it useful.

## Usage

0. Please ensure that Stickerboard is enabled and has full access. You can
check this in the Settings app under Stickerboard > Keyboards. Note that we
do not upload any data; there is not a single line of network related code
in the app. We only need full access to copy the stickers to your clipboard.

1. Copy your sticker files to the Stickerboard documents directory. You can
do this in numerous ways:
  - Use the Files app on your device to copy files directly to the app
  - Connect your device to a computer and use iTunes File Sharing
  - Share an image, and use the "Save to Files" option to select Stickerboard

2. Open the Stickerboard app and hit the import button.

3. ???

4. Profit!

## Why does it copy my stickers to the clipboard?

This is an iOS restriction. Third party keyboards are only able to send text;
the only way to "send" images is by copying them to the clipboard so that you
can easily access them. After Stickerboard copies the image to your clipboard,
simply paste it wherever images are supported.

## License

MIT
