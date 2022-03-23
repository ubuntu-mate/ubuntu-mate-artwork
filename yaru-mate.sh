#!/usr/bin/env bash

# sudo apt-get -y install meson ninja-build sassc libglib2.0-dev-bin devscripts
YARU_DEV="${HOME}/Builds/Yaru-Dev"
YARU_NEW="${HOME}/Builds/Yaru-New"
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

rm -rf "${YARU_NEW}"
mkdir -p "${YARU_NEW}"
meson build --prefix="${YARU_NEW}"
ninja -C build
ninja -C build install > /dev/null

#icons
for THEME in light dark; do
    rsync -aHAWXx "${YARU_NEW}/share/icons/Yaru-mate/" "${YARU_NEW}/share/icons/Yaru-MATE-${THEME}/"
    for RES in 16 22 24; do
        rsync -aHAWXx "${YARU_NEW}/share/icons/Yaru/${RES}x${RES}/panel/" "${YARU_NEW}/share/icons/Yaru-MATE-${THEME}/${RES}x${RES}/panel/"
        if [ ${RES} -ne 16 ]; then
            rsync -aHAWXx "${YARU_NEW}/share/icons/Yaru/${RES}x${RES}/animations/" "${YARU_NEW}/share/icons/Yaru-MATE-${THEME}/${RES}x${RES}/animations/"
        fi
    done
    sed -i "s|Yaru-mate|Yaru-MATE-${THEME}|g" "${YARU_NEW}/share/icons/Yaru-MATE-${THEME}/index.theme"
    echo "Icons: ${THEME}"

    # Make panel icons dark on the light theme
    if [ "${THEME}" == "light" ]; then
        echo " - Patching panel icons"
        sed -i 's|"#fff"|"#333"|g' ${YARU_NEW}/share/icons/Yaru-MATE-${THEME}/*/panel/*.svg
        sed -i 's|"#ffffff"|"#3D3D3D"|g' ${YARU_NEW}/share/icons/Yaru-MATE-${THEME}/*/panel/*.svg
        sed -i 's|"#F9F9F9"|"#3D3D3D"|g' ${YARU_NEW}/share/icons/Yaru-MATE-${THEME}/*/panel/*.svg
        sed -i 's|fill:#fff;|fill:#333;|g' ${YARU_NEW}/share/icons/Yaru-MATE-${THEME}/*/panel/*.svg
        sed -i 's|fill:#ffffff;|fill:#3D3D3D;|g' ${YARU_NEW}/share/icons/Yaru-MATE-${THEME}/*/panel/*.svg
        sed -i 's|"#fff"|"#333"|g' ${YARU_NEW}/share/icons/Yaru-MATE-${THEME}/*/animations/*.svg
    fi
    rsync -aHAWXx \
        "${YARU_NEW}/share/icons/Yaru-MATE-${THEME}/" "${YARU_DEV}/ubuntu-mate-artwork-dirty/usr/share/icons/Yaru-MATE-${THEME}/"

    update-icon-caches "${YARU_DEV}/ubuntu-mate-artwork-dirty/usr/share/icons/Yaru-MATE-${THEME}/"
done

#themes
rsync -aHAWXx --delete --exclude=metacity-1 "${YARU_NEW}/share/themes/Yaru-mate/" "${YARU_NEW}/share/themes/Yaru-MATE-light/"
rsync -aHAWXx --delete --exclude=metacity-1 "${YARU_NEW}/share/themes/Yaru-mate-dark/" "${YARU_NEW}/share/themes/Yaru-MATE-dark/"

for THEME in light dark; do
    case ${THEME} in
      light) METACITY_THEME="Yaru";;
      dark) METACITY_THEME="Yaru-dark";;
    esac

    echo "[X-GNOME-Metatheme]
Name=Yaru-MATE-${THEME}
Type=X-GNOME-Metatheme
Comment=Ubuntu MATE Yaru-${THEME} theme
Encoding=UTF-8
GtkTheme=Yaru-MATE-${THEME}
MetacityTheme=${METACITY_THEME}
IconTheme=Yaru-MATE-${THEME}
CursorTheme=Yaru
CursorSize=24
ButtonLayout=:minimize,maximize,close" > "${YARU_NEW}/share/themes/Yaru-MATE-${THEME}/index.theme"
    echo "Theme: ${THEME}"
    rsync -aHAWXx --delete --exclude="gtk-2.0/assets" "${YARU_NEW}/share/themes/Yaru-MATE-${THEME}/" "${YARU_DEV}/ubuntu-mate-artwork-dirty/usr/share/themes/Yaru-MATE-${THEME}/"
done

cd "${YARU_DEV}/ubuntu-mate-artwork-dirty"
dch -v 22.04.9~jammy$(date +%y\.%j\.%H%M) --distribution jammy "Sync Yaru-MATE themes/icons with upstream Yaru."
echo
head -n9 debian/changelog
echo
echo "${YARU_DEV}/ubuntu-mate-artwork-dirty"
for THEME in Yaru-MATE-light Yaru-MATE-dark; do
  sudo rsync -aHAWXx --delete ${YARU_DEV}/ubuntu-mate-artwork-dirty/usr/share/themes/${THEME}/ /usr/share/themes/${THEME}/
  sudo rsync -aHAWXx ${YARU_DEV}/ubuntu-mate-artwork-dirty/usr/share/icons/${THEME}/ /usr/share/icons/${THEME}/
done
#for THEME in Yaru Yaru-bark Yaru-blue Yaru-magenta Yaru-mate Yaru-olive Yaru-prussiangreen Yaru-purple Yaru-red Yaru-sage Yaru-viridian; do
#  sudo rsync -aHAWXx --delete ${YARU_NEW}/share/themes/${THEME}/ /usr/share/themes/${THEME}/
#  sudo rsync -aHAWXx --delete ${YARU_NEW}/share/themes/${THEME}-dark/ /usr/share/themes/${THEME}-dark/
#  sudo rsync -aHAWXx --delete ${YARU_NEW}/share/icons/${THEME}/ /usr/share/icons/${THEME}/
#done
