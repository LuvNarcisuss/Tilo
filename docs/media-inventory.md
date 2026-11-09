# Tilo Media Inventory

Acquired and visually inspected on November 3, 2026. These are actual Pexels photographs and cooking clips, not generated images. The authoritative per-file record is [manifest.json](../Assets/SourceMedia/manifest.json).

## Runtime mapping

| Basename | Subject | Photographer / videographer |
| --- | --- | --- |
| cooking-01 | Pasta added to a skillet | cottonbro studio |
| cooking-02 | Pancake batter poured onto a griddle | Vlada Karpovich |
| cooking-03 | Diced vegetables cooking in a skillet | Kampus Production |
| cooking-04 | Seasoning grilled steak | Kuiyibo Campos |
| cooking-05 | Kneading dough | Pavel Danilyuk |
| cooking-06 | Tossing a leafy salad | Mikhail Nilov |
| recipe-01 | Tomato basil spaghetti | cottonbro studio |
| recipe-02 | Berry pancakes | alleksana |
| recipe-03 | Cheeseburger and fries | MARIANNE RIXHON |
| recipe-04 | Margherita pizza | Sobee Berly |
| recipe-05 | Grilled salmon | Giovanna Kamimura |
| recipe-06 | Steak with sauce | Nadin Sh |
| recipe-07 | Vegetable soup | Polina Tankilevitch |
| recipe-08 | Mixed garden salad | Madison Inouye |
| recipe-09 | Roast chicken and potatoes | Mahmoud Salem |
| recipe-10 | Tomato basil bruschetta | Lucie Liz |
| recipe-11 | Tomato and mozzarella toast | Nadezhda Moryak |
| recipe-12 | Chicken and potato tray bake | ArtHouse Studio |
| chef-01 | Chef in a restaurant kitchen | Ünal Aslan |
| chef-02 | Woman in a home kitchen | Mizuno K |
| chef-03 | Chef in a commercial kitchen | Hazel Montero |
| chef-04 | Cook in a neighborhood kitchen | Kinz-studio Photographe |
| chef-05 | Chef in a dark uniform | Tochukwu Ekeh |

The six MP4s have matching JPEG covers extracted from each clip's midpoint. All 23 primary media files have different SHA-256 values. There are 29 runtime files including covers, approximately 12 MB in total; this is resource size, not an IPA size.

## Processing and review

The 29 prepared files are served from the dedicated Tilo Storage bucket. A November 9, 2026 audit downloaded all 29 public objects and matched their SHA-256 digests and sizes to the upload manifest. The database references for all recipe covers, replay covers, replays and editorial avatars matched those objects. [Upload manifest](BackendAPI/media-upload-manifest.json)

Videos preserve the original playback speed and proportional framing. Width is capped at 720 pixels, duration is capped at approximately 20 seconds, and output is H.264 with AAC where an audio stream exists. The final frame boundary can produce a 20.02-second container. No speed changes or stretched framing are applied. Photos use the Pexels proportional 1200-pixel-width JPEG rendition.

Every clip was inspected at its beginning, midpoint and ending. The 18 checkpoints and both contact sheets are local inspection evidence under the ignored `Assets/SourceMedia/inspection` directory. The source manifest preserves the timestamps and observations for each clip. Each MP4 shows actual food preparation. All photo subjects match their recorded food or kitchen context. No overlaid captions or watermarks were observed. The initial foreground blur in `cooking-03` clears to visible vegetables at the next checkpoints. Portrait clothing includes incidental source details.

This is representative-frame inspection, not continuous viewing of every video frame, food-safety certification, or an iOS runtime test. No app build, typecheck, simulator launch or runtime test was performed for this media work.

## Reproduction

For maintenance, run `python3 scripts/fetch_media.py` from the repository root in a network-enabled environment with `curl`, `ffmpeg` and `ffprobe` installed. The script stages originals in `Assets/SourceMedia/originals` and prepares MP4s and covers in `Assets/PublishedMedia`. Both directories are ignored and intended for temporary use. Previously reviewed records are retained only when the prepared file hash matches. Replaced or newly processed files require a fresh visual review.
