# WorkWife — approved Apple app icon bundle

The charcoal calendar, white ringing bell, and orange focus corners are the approved final design. The 1024-pixel master is an exact copy of the accepted PNG; no new image generation was used for this bundle.

## Included

- `Master/WorkWife-AppIcon-1024.png`: approved 1024 × 1024 RGB master, embedded sRGB profile, no alpha channel and no pre-rounded corners. Use for iOS/iPadOS and App Store artwork.
- `Assets.xcassets/AppIcon.appiconset`: Xcode asset catalog with 18 iPhone/iPad/App Store slots and all 10 standard macOS slots, with `Contents.json` supplied.
- `macOS/WorkWife.icns`: compiled Mac icon for Finder, the Dock, and macOS app bundles.
- `macOS/WorkWife.iconset`: the ten named Mac source images, from 16 × 16 to 1024 × 1024 pixels, including Retina variants.
- `Preview.png`: large comparison and actual-size Mac previews.
- `Validation.txt`: export and Xcode compiler validation results.
- `Manifest.json`: file sizes, dimensions, and SHA-256 checksums.

## Add to an Xcode project

1. Unzip the bundle.
2. Open the project's existing `Assets.xcassets` and replace its `AppIcon` set with the included `AppIcon.appiconset`. Keep a backup if the existing set is needed. Alternatively, add the supplied whole asset catalog if the project has none. Avoid two sets named `AppIcon` in the same target.
3. In the app target, select `AppIcon` as its App Icon. The corresponding build setting is `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`.
4. Build the app and check it in the Dock or on the Home Screen.

For a Mac app using an explicit `.icns` resource instead of an asset catalog, include `macOS/WorkWife.icns` in the app's resources and set `CFBundleIconFile` to `WorkWife`.

## Export notes

The iPhone/iPad assets retain the approved artwork and full square canvas. macOS exports place the same artwork inside an inset rounded square with transparent outside padding suitable for a classic Mac icon; the icon's internal design is unchanged. The unmasked opaque master remains available separately.

This is a standard raster asset-catalog and ICNS bundle, not a layered Icon Composer `.icon` file. It includes the approved default appearance; custom dark/tinted variants and tvOS, visionOS, and watchOS targets are not included. No app project was supplied, so this bundle is prepared for import rather than installed in an app.

## Apple references

- [Configure an app icon using an asset catalog](https://developer.apple.com/documentation/xcode/configuring-your-app-icon)
- [App icon asset format](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_ref-Asset_Catalog_Format/AppIconType.html)
- [Mac iconset naming and sizes](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_ref-Asset_Catalog_Format/IconSetType.html)
