# apple-fonts fallback

The AUR `apple-fonts` 7.0.6-1 recipe still contains the old SF Pro and SF Compact
checksums. The official Apple DMGs changed on 2026-11-04. SF Mono and New York
checksums did not change. Verified against the official downloads on 2026-11-20.

This local 7.0.6-2 recipe keeps integrity verification enabled, handles DMGs with
nested package paths, extracts Payload with libarchive, and preserves all four
licenses separately. Font binaries are downloaded from Apple at build time and
are not redistributed in this repository.

The installer first tries the normal package source. If `apple-fonts` remains
uninstalled, it builds this recipe under `~/.cache/dotfiles/build/apple-fonts/`
with `makepkg -si --needed --cleanbuild`. Build output is retained with the other
package logs. Two-thread extraction/compression limits resource usage.

Validation on 2026-11-20: a real package build completed without installation;
147 font files and four licenses were present; fontconfig identified
`SF-Pro-Display-Bold.otf` as `SF Pro Display: Bold`.

Sources:
- [AUR source](https://aur.archlinux.org/apple-fonts.git)
- [Official Apple fonts](https://developer.apple.com/fonts/)
- [SF Pro](https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg)
- [SF Compact](https://devimages-cdn.apple.com/design/resources/download/SF-Compact.dmg)
- [SF Mono](https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg)
- [New York](https://devimages-cdn.apple.com/design/resources/download/NY.dmg)
