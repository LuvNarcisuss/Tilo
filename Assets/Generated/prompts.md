# Tilo generated shell artwork

Created November 3, 2026 with the built-in image_gen tool. No CLI or alternate model was used.

## Icon atlas

Transparent square atlas with 36 isolated hand-painted gouache icons in six columns and six rows. Tomato red, deep olive, buttery cream, charcoal outlines; contemporary Italian cookbook style, clear at 28 points. Rows: cooking pot/open book/grocery tote/chat bubbles/chef profile/search; back/close/plus/more/heart/bookmark; send/gift/diamond/share/settings/bell; camera/microphone/video/speaker/play/pause; shield/flag/person/group/trash/pencil; check/clock/calendar/list/info/cutlery. No text or system symbols. The atlas is packaged by alpha bounds; no icon is redrawn by code.

## Background

Tall warm ivory handmade paper with very pale olive gingham wash and delicate kitchen doodles at outer borders: tomato, basil, whisk, olive branch, fork and lemon. Central 80 percent near-plain ivory for readable native text. Soft red top arc, olive leaves in a bottom corner. European cookbook aesthetic; no UI, words or mockup.

## App mark

Opaque tomato-red square with gouache paper texture. A large cream hand-painted cooking pot with olive handles, friendly steam strokes and a tiny basil leaf. Minimal original silhouette, no letters, border, tile mockup or external shadow.

## Outputs

- tilo-icon-atlas.png: original alpha artwork.
- tilo-background.png: original background.
- tilo-app-mark.png: original opaque logo.
- asset-manifest.json: source SHA-256 and icon extraction bounds.

The 36 app icons, backdrop and app icon are copied into the project's asset catalog. Kalam Bold and Comic Neue Regular are bundled unchanged under their SIL Open Font Licenses. System-owned Apple sheets and controls can retain system presentation; app-owned text uses those bundled fonts.

## Inactive recipe heart — November 5, 2026

Built-in image_gen edit, referenced existing icon-heart.png. Prompt: Preserve the heart silhouette and centered composition and handmade gouache edge style. Replace the solid red interior with true transparent space. Use a thick deep olive-green hand-painted outline, clear at 28 points. One hollow heart, no fill, button container, text or shadow; transparent outer background and inner hole.

Generated source: tilo-heart-outline.png. Runtime: icon-heartOutline.imageset/icon-heartOutline.png, proportionally resized to 256 pixels with generated transparency preserved. This adds one raster to the original 36-icon set. No original icon was overwritten.

## Active saved bookmark — November 5, 2026

Built-in image_gen edit referenced icon-bookmark.png. Prompt: Preserve the upright ribbon silhouette, bottom V-notch, gouache texture, olive outline and centered composition. Fill the ribbon interior with tomato red (#BD2E1F), clearly distinct from the pale outlined inactive reference at 26 points. No heart, check mark, text, circle, button, shadow or additional objects. Transparent outer background.

Source: tilo-bookmark-filled.png. Runtime: icon-bookmarkFilled.imageset/icon-bookmarkFilled.png. Proportional 256px resize retains generated alpha. The original inactive bookmark remains unchanged.

## Owner-selected yellow and hollow bookmark pair — November 5, 2026

This supersedes the red active bookmark above. Two built-in image_gen edits produced the final pair. Active prompt: change only the ribbon interior to saturated golden yellow (#F3C443); preserve upright silhouette, V-notch, olive gouache outline, texture and transparent outer background; no extra text, marks, objects or shadow. Inactive prompt: preserve the original bookmark outline and remove the full cream interior; both ribbon interior and outside must be transparent, leaving only a thick olive hand-painted outline.

Sources: tilo-bookmark-filled-yellow.png and tilo-bookmark-outline.png. Runtime: icon-bookmarkFilled and icon-bookmarkOutline image sets. Both are cropped to visible alpha bounds (threshold 32 excludes near-transparent generation noise without replacing the generated alpha), proportionally fitted into 150 by 174 pixels, then centered in transparent 256-pixel canvases. Generated colors and alpha are retained. Superseded red source stays outside the target.
