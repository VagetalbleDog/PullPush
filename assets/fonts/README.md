# Bundled Fonts

- Manrope by Mikhail Sharanda and Mirko Velimirovic, SIL Open Font License 1.1.
- Noto Sans SC by the Noto Project, SIL Open Font License 1.1.

Upstream: https://github.com/google/fonts/tree/main/ofl/manrope and
https://github.com/google/fonts/tree/main/ofl/notosanssc.

The matching OFL license files are included in this directory. Fonts are bundled
locally; the app does not fetch them at runtime. Static weight instances are used
for consistent rendering across native Flutter and web renderers. The regular
Chinese face retains the full upstream character set. The semibold face is
subset to the app's UI text. Run `scripts/prepare_fonts.py` with the upstream
variable TTF files to regenerate faces when UI copy changes.
