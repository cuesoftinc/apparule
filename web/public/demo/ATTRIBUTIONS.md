# Demo photo attributions

CC-licensed outfit photography used by the seeded mock server and the
marketing home demo (design.md §8.3 sourcing decision — Openverse/Wikimedia
Commons pool; same pool as the Figma Assets page). Each image below keeps its
full attribution: original title, author, license, source URL, and the seed
entities that render it. Files live in `web/public/demo/`.

All images are derivatives of the Commons originals: resized to ≤900 px on
the longest side and JPEG-recompressed for web weight (≤~200 KB);
`outfit-w00.jpg` is additionally rotated to its upright orientation.

Each `outfit-*.jpg` also ships pre-generated responsive WebP variants
(`<base>.w128/.w384/.w640/.w960.webp`, from
`web/scripts/generate-demo-image-variants.mjs`) that next/image serves via
the custom loader — the deploy target disables runtime image optimization.
Every variant is derived from its `.jpg` above and carries the same
attribution and license.

## outfit-w00.jpg

- "AFRICA FASHION WEEK (2023) - IMG 1962.jpg" by Bárbara Jadeh, CC BY-SA 4.0, via Wikimedia Commons
- Source: https://commons.wikimedia.org/wiki/File:AFRICA_FASHION_WEEK_(2023)_-_IMG_1962.jpg
- Used by: seed `post-bridal-gown` (maisonbisi); marketing explore-grid tile; dev gallery + component fixtures

## outfit-w01.jpg

- "Afri Art Fashion Show Model.jpg" by Thehopemonger, CC BY-SA 4.0, via Wikimedia Commons
- Source: https://commons.wikimedia.org/wiki/File:Afri_Art_Fashion_Show_Model.jpg
- Used by: seed `post-ankara-gown` (amara.designs) + order #APR-1042 thumb/thread inspiration shot + notifications; marketing hero feed post, amara story avatar, hero order thumbs, explore-grid tile

## outfit-w05.jpg

- "Recorte moderno no maio da Água de Coco @ São Paulo Fashion Week em Junho de 2011.jpg" by O Boticário SPFW, CC BY 2.0, via Wikimedia Commons
- Source: https://commons.wikimedia.org/wiki/File:Recorte_moderno_no_maio_da_Água_de_Coco_@_São_Paulo_Fashion_Week_em_Junho_de_2011.jpg
- Used by: seed `post-runway-orange` (maisonbisi) + notification thumb; marketing hero phone mock, SMPL section, zuri story avatar, explore-grid tile

## outfit-w06.jpg

- "University students perform a dance during an event to showcase traditional Somali culture week at Bosaso University.jpg" by Faaris Adam, CC BY-SA 4.0, via Wikimedia Commons
- Source: https://commons.wikimedia.org/wiki/File:University_students_perform_a_dance_during_an_event_to_showcase_traditional_Somali_culture_week_at_Bosaso_University.jpg
- Used by: seed `post-dance-troupe` (tunde.o); marketing kikithreads carousel

## outfit-w10.jpg

- "A Nigerian fashion designer making clothes.jpg" by ClintAmerica, CC BY-SA 4.0, via Wikimedia Commons
- Source: https://commons.wikimedia.org/wiki/File:A_Nigerian_fashion_designer_making_clothes.jpg
- Used by: seed `post-fabric-drop` second media (amara.designs) + order #APR-1042 progress-shot thread message; marketing kikithreads carousel, explore-grid tile; dev walkthrough exemplar

## outfit-w13.jpg

- "Obasanjo traditional wear.IMG 4251.JPG" by IRENE GAOUDA, CC BY-SA 4.0, via Wikimedia Commons
- Source: https://commons.wikimedia.org/wiki/File:Obasanjo_traditional_wear.IMG_4251.JPG
- Used by: seed `post-asooke-set` (maisonbisi) + order #APR-1058 thumb + notifications; marketing bisi story avatar, kikithreads carousel, order thumb; explore-grid tile

## outfit-w14.jpg

- "AFRICAN FABRIC ON DISPLAY.jpg" by Nyuso Za Nairobi, CC BY-SA 4.0, via Wikimedia Commons
- Source: https://commons.wikimedia.org/wiki/File:AFRICAN_FABRIC_ON_DISPLAY.jpg
- Used by: seed `post-fabric-drop` lead media (amara.designs) + moderation report rep-2 thumb; marketing kikithreads carousel + thread-bubble demo; explore-grid tile

## outfit-w15.jpg

- "African print brothers.jpg" by Zediajaab, CC BY-SA 4.0, via Wikimedia Commons
- Source: https://commons.wikimedia.org/wiki/File:African_print_brothers.jpg
- Used by: tunde.o avatar (his own published post) + seed `post-print-brothers` + order #APR-1044; marketing tunde.a story avatar; explore-grid tile

## outfit-w16.jpg

- "African print couple love.jpg" by Zediajaab, CC BY-SA 4.0, via Wikimedia Commons
- Source: https://commons.wikimedia.org/wiki/File:African_print_couple_love.jpg
- Used by: seed `post-print-couple` (amara.designs) + quote notification thumb; marketing kiki story avatar, kikithreads avatar/carousel, delivered-order thumb

## outfit-w17.jpg

- "Man Wearing Agbada.jpg" by Reflect photo, CC BY-SA 4.0, via Wikimedia Commons
- Source: https://commons.wikimedia.org/wiki/File:Man_Wearing_Agbada.jpg
- Used by: seed `post-agbada` (tunde.o) + request notification thumb; marketing agbada order thumb, explore-grid tile

## outfit-w18.jpg

- "A Tailor Sewing Clothes in Her Shop.jpg" by Meritkosy, CC BY-SA 4.0, via Wikimedia Commons
- Source: https://commons.wikimedia.org/wiki/File:A_Tailor_Sewing_Clothes_in_Her_Shop.jpg
- Used by: eniola.stitches avatar (her own published post) + seed `post-atelier-abuja`

## outfit-w19.jpg

- "Afri Art Fashion Show Model 2024.jpg" by Thehopemonger, CC BY-SA 4.0, via Wikimedia Commons
- Source: https://commons.wikimedia.org/wiki/File:Afri_Art_Fashion_Show_Model_2024.jpg
- Used by: seed `post-evening-gown` (maisonbisi); marketing eveningwear order thumb + maisonbisi avatar; dev gallery GridTile exemplar
