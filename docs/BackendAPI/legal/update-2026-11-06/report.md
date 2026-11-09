# Tilo legal publication update

Date: November 6, 2026. Project: `hdapofqufmxlghmcrftg`, organization `wuwstedwrsfrxkbxjuqa`.

The owner requested the Tilo app name in both public agreements, synchronized documents and versions, and unchanged links. The update is deployed.

## Content and links

Both English documents now use Tilo in their titles, body, footer and PDF metadata. Their effective date is November 6, 2026. Other terms and the explicitly unconfirmed planned contact `support@toli.com` are unchanged.

| Agreement | Original public URL, preserved exactly | SHA-256 |
| --- | --- | --- |
| Terms of Use | https://hdapofqufmxlghmcrftg.supabase.co/storage/v1/object/public/legal/2026-11-03/terms.pdf | `fcc24f042faf9ec1bfcec87aa48a3f847ce83aa39fadffc852d6d30c84c1f5fa` |
| Privacy Policy | https://hdapofqufmxlghmcrftg.supabase.co/storage/v1/object/public/legal/2026-11-03/privacy.pdf | `e0cf2f940758b146c24270931c4d3f729cd0c7e6653046e8c59ec5b27099e5b2` |

The `2026-11-03` path component remains a stable public address; it does not identify the current document effective date. The original source files, PDFs and manifest are archived under `../history/2026-11-03-24e387172fe8/`. Current cloud snapshots use the explicit `2026-11-06-99d6afcc3037` filename suffix, recorded in `../manifest.json`.

## Version and deployment

Current consent version: `2026-11-06-99d6afcc3037`. The suffix is the first 12 SHA-256 hex characters of the Terms Markdown bytes, two LF bytes, then the Privacy Markdown bytes. This value is synchronized in the current manifest, deployment plan, Swift configuration and deployed private RPC implementation.

The Supabase connector returned `Unknown tool`, so the authenticated dashboard was used in the verified 139 organization. Existing Storage objects were replaced through their Replace file actions. The guarded SQL deployment script `supabase/legal-name-update.sql` replaced only the previous version literal in the existing function. Normalizing the new literal back to its predecessor recovered the exact pre-update function MD5. All four historical consent rows retained the same count and content digest. No consent was fabricated, rewritten or accepted for an existing member. Auth settings, RLS, grants, business rows and Edge Functions were not changed.

New consent submissions require the current version. Previously built apps still submitting `2026-11-03-24e387172fe8` need an updated build. The Swift PDF viewer now bypasses its local URL cache and requests revalidation, retaining the exact public URLs.

## Verification and limits

- Both PDFs were parsed, rendered and visually inspected: one page each, correct Tilo name/date, complete readable layout.
- Anonymous GET requests at both original URLs returned `application/pdf` with bytes matching the inspected local PDFs. Current cloud version snapshots matched too.
- Server readback returned `current_version_present=true`, `old_version_removed=true` and `only_version_changed=true`. Historical consent digest remained `c0748ea52116a4538787b3412ce75318` for four rows.
- Static inspection passed 322 checks with zero failures. The public-artifact script also verified one unchanged cooking replay.
- No native compilation, typechecking, app/Simulator launch, native agreement UI test, live Auth/RPC consent submission or StoreKit test was performed for this update. Earlier native reports are historical.

Evidence includes the public downloads, server verification, and current manifest. The dashboard screenshot and static verification output are local artifacts. [Public downloads](public-verification.json) · [Server verification](server-verification.json) · [Current manifest](../manifest.json)
