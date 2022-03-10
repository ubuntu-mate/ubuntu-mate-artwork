#!/usr/bin/env bash

# sudo apt-get -y install meson ninja-build sassc libglib2.0-dev-bin devscripts
YARU_DEV="${HOME}/Development/Yaru"
YARU_NEW="${HOME}/Yaru-New"
mkdir -p "${YARU_DEV}"
mkdir -p "${YARU_NEW}"

function git_sync() {
    local GIT_URL="${1}"
    local GIT_NAME=""

    GIT_NAME=$(echo "${GIT_URL}" | sed 's|https://github.com/||' | sed 's|git@github.com:||' | cut -d'.' -f1 | cut -d'/' -f2)

    if [ ! -d "${GIT_NAME}/.git" ]; then
        git clone "${GIT_URL}"
    else
        cd "${YARU_DEV}/${GIT_NAME}"
        if [ -d build ]; then
            rm -rfv build
        fi
        git pull -r
        cd "${YARU_DEV}"
    fi
}

mkdir -p "${YARU_DEV}"
cd "${YARU_DEV}"

git_sync "https://github.com/ubuntu/yaru.git"
git_sync "https://github.com/ubuntu-mate/ubuntu-mate-artwork.git"

# Copy the pristine git to a dirty copy.
rsync -aHAWXx --delete "${YARU_DEV}/yaru/" "${YARU_DEV}/yaru-dirty/"
rsync -aHAWXx --delete "${YARU_DEV}/ubuntu-mate-artwork/" "${YARU_DEV}/ubuntu-mate-artwork-dirty/"

cd "${YARU_DEV}/yaru-dirty/"
if [ -d build ]; then
    rm -rfv build
fi

# Revert making panel dark in both light and dark themes.
#  - https://github.com/ubuntu/yaru/pull/3378
#  - https://github.com/ubuntu/yaru/issues/3307
#git revert --no-edit --no-commit 85312a3338b21d760ca79b00d87c1e3597262708
wget -q "https://patch-diff.githubusercontent.com/raw/ubuntu/yaru/pull/3430.diff" -O 3430.diff
patch -p1 < 3430.diff
rm 3430.diff

# Enable MATE themes
sed  -i "s|mate', type: 'boolean', value: false|mate', type: 'boolean', value: true|" meson_options.txt
sed  -i "s|mate-dark', type: 'boolean', value: false|mate-dark', type: 'boolean', value: true|" meson_options.txt
grep mate meson_options.txt

rm -rf "${YARU_NEW}"
mkdir -p "${YARU_NEW}"
meson build --prefix="${YARU_NEW}"
ninja -C build
ninja -C build install > /dev/null

#gtksourceview
for VER in 2.0 3.0 4; do
    cp "${YARU_NEW}/share/gtksourceview-${VER}/styles/Yaru-mate.xml" "${YARU_NEW}/share/gtksourceview-${VER}/styles/Yaru-MATE-light.xml"
    cp "${YARU_NEW}/share/gtksourceview-${VER}/styles/Yaru-mate-dark.xml" "${YARU_NEW}/share/gtksourceview-${VER}/styles/Yaru-MATE-dark.xml"
    sed -i 's|Yaru-mate|Yaru-MATE-light|g' "${YARU_NEW}/share/gtksourceview-${VER}/styles/Yaru-MATE-light.xml"
    sed -i 's|Yaru-mate-dark|Yaru-MATE-dark|g' "${YARU_NEW}/share/gtksourceview-${VER}/styles/Yaru-MATE-dark.xml"
    echo
    echo "GtkSourceView: ${VER}"
    cp -v "${YARU_NEW}"/share/gtksourceview-"${VER}"/styles/Yaru-MATE-light.xml "${YARU_DEV}"/ubuntu-mate-artwork-dirty/usr/share/gtksourceview-"${VER}"/styles/
    cp -v "${YARU_NEW}"/share/gtksourceview-"${VER}"/styles/Yaru-MATE-dark.xml "${YARU_DEV}"/ubuntu-mate-artwork-dirty/usr/share/gtksourceview-"${VER}"/styles/
done

#icons
for THEME in light dark; do
    case ${THEME} in
        light) INHERIT="Radiant-MATE";;
        dark)  INHERIT="Ambiant-MATE";;
    esac
    rsync -aHAWXx --delete "${YARU_NEW}/share/icons/Yaru/" "${YARU_NEW}/share/icons/Yaru-MATE-${THEME}/"
    rsync -aHAWXx "${YARU_NEW}/share/icons/Yaru-mate/" "${YARU_NEW}/share/icons/Yaru-MATE-${THEME}/"
    sed -i "s|Yaru-mate|Yaru-MATE-${THEME}|g" "${YARU_NEW}/share/icons/Yaru-MATE-${THEME}/index.theme"
    sed -i "s|Yaru,Humanity,hicolor|${INHERIT}|g" "${YARU_NEW}/share/icons/Yaru-MATE-${THEME}/index.theme"
    sed -i "s|Yaru|Yaru-MATE-${THEME}|g" "${YARU_NEW}/share/icons/Yaru-MATE-${THEME}/cursor.theme"

    echo
    echo "Icons: ${THEME}"
    head -n4 "${YARU_NEW}/share/icons/Yaru-MATE-${THEME}/index.theme"
    echo
    echo "Cursor: ${THEME}"
    head -n3 "${YARU_NEW}/share/icons/Yaru-MATE-${THEME}/cursor.theme"
    echo
    rsync -aHAWXx \
        --exclude="16x16/panel" \
        --exclude="22x22/panel" \
        --exclude="24x24/panel" \
        --exclude="emblem-symbolic-link.png" \
        --exclude="document-export.png" \
        "${YARU_NEW}/share/icons/Yaru-MATE-${THEME}/" "${YARU_DEV}/ubuntu-mate-artwork-dirty/usr/share/icons/Yaru-MATE-${THEME}/"
    rsync -aHAWXx --delete "${YARU_NEW}/share/icons/Yaru-MATE-${THEME}/cursors/" "${YARU_DEV}/ubuntu-mate-artwork-dirty/usr/share/icons/Yaru-MATE-${THEME}/cursors/"
    update-icon-caches "${YARU_DEV}/ubuntu-mate-artwork-dirty/usr/share/icons/Yaru-MATE-${THEME}/"
done

#themes
rsync -aHAWXx --delete "${YARU_NEW}/share/themes/Yaru-mate/" "${YARU_NEW}/share/themes/Yaru-MATE-light/"
rsync -aHAWXx --delete "${YARU_NEW}/share/themes/Yaru-mate-dark/" "${YARU_NEW}/share/themes/Yaru-MATE-dark/"

for THEME in light dark; do
    echo "[Desktop Entry]
Type=X-GNOME-Metatheme
Name=Yaru-MATE-${THEME}
Comment=Ubuntu Yaru-MATE-${THEME} theme
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme=Yaru-MATE-${THEME}
MetacityTheme=Yaru-MATE-${THEME}
IconTheme=Yaru-MATE-${THEME}
CursorTheme=Yaru-MATE-${THEME}
CursorSize=24
ButtonLayout=:minimize,maximize,close" > "${YARU_NEW}/share/themes/Yaru-MATE-${THEME}/index.theme"
    echo
    echo "Theme: ${THEME}"
    cat "${YARU_NEW}/share/themes/Yaru-MATE-${THEME}/index.theme"
    rsync -aHAWXx --delete --exclude="gtk-2.0/assets" "${YARU_NEW}/share/themes/Yaru-MATE-${THEME}/" "${YARU_DEV}/ubuntu-mate-artwork-dirty/usr/share/themes/Yaru-MATE-${THEME}/"
done

# patch metacity

# Light
for SVG in close_unfocused.svg maximize_unfocused.svg menu_unfocused.svg minimize_unfocused.svg unmaximize_unfocused.svg; do
  echo "${SVG}"
  sed -i 's/#e6e6e6/#e7e7e7/g' "${YARU_DEV}/ubuntu-mate-artwork-dirty/usr/share/themes/Yaru-MATE-light/metacity-1/${SVG}"
done

for SVG in close_unfocused_prelight.svg maximize_unfocused_prelight.svg menu_unfocused_prelight.svg minimize_unfocused_prelight.svg unmaximize_unfocused_prelight.svg; do
  echo "${SVG}"
  sed -i 's/#c5c5c5/#dedede/g' "${YARU_DEV}/ubuntu-mate-artwork-dirty/usr/share/themes/Yaru-MATE-light/metacity-1/${SVG}"
done

for SVG in close_focused_prelight.svg maximize_focused_prelight.svg menu_focused_prelight.svg minimize_focused_prelight.svg unmaximize_focused_prelight.svg; do
  echo "${SVG}"
  sed -i 's/#c6c6c6/#d1d1d1/g' "${YARU_DEV}/ubuntu-mate-artwork-dirty/usr/share/themes/Yaru-MATE-light/metacity-1/${SVG}"
done

for SVG in close_focused_normal.svg maximize_focused_normal.svg menu_focused_normal.svg minimize_focused_normal.svg unmaximize_focused_normal.svg; do
  echo "${SVG}"
  sed -i 's/#d1d1d1/#dadada/g' "${YARU_DEV}/ubuntu-mate-artwork-dirty/usr/share/themes/Yaru-MATE-light/metacity-1/${SVG}"
done

# Dark
for SVG in close_unfocused.svg maximize_unfocused.svg menu_unfocused.svg minimize_unfocused.svg unmaximize_unfocused.svg; do
  echo "${SVG}"
  sed -i 's/#575757/#414141/g' "${YARU_DEV}/ubuntu-mate-artwork-dirty/usr/share/themes/Yaru-MATE-dark/metacity-1/${SVG}"
done

for SVG in close_focused_prelight.svg maximize_focused_prelight.svg menu_focused_prelight.svg minimize_focused_prelight.svg unmaximize_focused_prelight.svg; do
  echo "${SVG}"
  sed -i 's/#4a4a4a/#424242/g' "${YARU_DEV}/ubuntu-mate-artwork-dirty/usr/share/themes/Yaru-MATE-dark/metacity-1/${SVG}"
done

for SVG in close_focused_normal.svg maximize_focused_normal.svg menu_focused_normal.svg minimize_focused_normal.svg unmaximize_focused_normal.svg; do
  echo "${SVG}"
  sed -i 's/#373737/#383838/g' "${YARU_DEV}/ubuntu-mate-artwork-dirty/usr/share/themes/Yaru-MATE-dark/metacity-1/${SVG}"
done


cd "${YARU_DEV}/ubuntu-mate-artwork-dirty"
dch -v 22.04.2~jammy$(date +%y%j%H%M\.%S) --distribution jammy "Sync Yaru-MATE themes/icons with upstream Yaru."
dch --append "Fix Monitor Properties (LP: #1934752)"
echo
head -n9 debian/changelog
echo
echo "${YARU_DEV}/ubuntu-mate-artwork-dirty"
echo "sudo rsync -aHAWXx --delete ${YARU_DEV}/ubuntu-mate-artwork-dirty/usr/share/themes/Yaru-MATE-light/ /usr/share/themes/Yaru-MATE-light/"
echo "sudo rsync -aHAWXx --delete ${YARU_DEV}/ubuntu-mate-artwork-dirty/usr/share/themes/Yaru-MATE-dark/ /usr/share/themes/Yaru-MATE-dark/"
