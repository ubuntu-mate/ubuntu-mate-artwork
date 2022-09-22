#!/usr/bin/env bash

sudo apt-get -y install meson ninja-build sassc libglib2.0-dev-bin devscripts
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

#wget "https://patch-diff.githubusercontent.com/raw/ubuntu/yaru/pull/3590.diff" -O 3590.diff
#patch -p1 < 3590.diff

# Enable MATE themes
sed  -i "s|mate', type: 'boolean', value: false|mate', type: 'boolean', value: true|" meson_options.txt
sed  -i "s|mate-dark', type: 'boolean', value: false|mate-dark', type: 'boolean', value: true|" meson_options.txt

sed  -i "s|panel', type: 'boolean', value: false|panel', type: 'boolean', value: true|" meson_options.txt
sed  -i "s|panel-dark', type: 'boolean', value: false|panel-dark', type: 'boolean', value: true|" meson_options.txt

# Create MATE accent colour; to create a correctly name spaced Yaru-MATE-dark
sed -i "/],/i \ \ \ \ \ \ \ \ 'MATE'," meson_options.txt
cat meson_options.txt

patch -p1 < "${YARU_DEV}/ubuntu-mate-artwork-dirty/yaru-mate.patch"
cat common/accent-colors.scss.in
mkdir -p "${YARU_DEV}/yaru-dirty/gtk/src/MATE/gtk-2.0"
mkdir -p "${YARU_DEV}/yaru-dirty/gtk/src/MATE-dark/gtk-2.0"
rsync -a --delete "${YARU_DEV}/yaru-dirty/gtk/src/mate/gtk-2.0/" "${YARU_DEV}/yaru-dirty/gtk/src/MATE/gtk-2.0/"
rsync -a --delete "${YARU_DEV}/yaru-dirty/gtk/src/mate-dark/gtk-2.0/" "${YARU_DEV}/yaru-dirty/gtk/src/MATE-dark/gtk-2.0/"
# END - Create MATE accent colour

rm -rf "${YARU_NEW}"
mkdir -p "${YARU_NEW}"

#gtk-2.0
#Hover:    SAT-10    or VAL+5
#Activ:    HUE+10
#Insen:    SAT=20    or VAL+5 SAT=10
#Insen Dk: VAL=30
GTK2=0
if [ ${GTK2} -eq 1 ]; then
    for THEME in bark blue magenta mate olive prussiangreen purple red sage viridian; do
    case ${THEME} in
        bark)
            accent="#787859"
            hover="#858562"
            active="#737859"
            insensitive="#858577"
            insensitive_dark="#4D4D39"
            ;;
        blue)
            accent="#0073E5"
            hover="#177EE5"
            active="#004CE5"
            insensitive="#B8CFE6"
            insensitive_dark="#00264D"
            ;;
        magenta)
            accent="#B34CB3"
            hover="#B35DB3"
            active="#B34CA2"
            insensitive="#B38FB3"
            insensitive_dark="#4D204D"
            ;;
        mate)
            accent="#87A556"
            hover="#8DA566"
            active="#7AA556"
            insensitive="#98A584"
            insensitive_dark="#3F4D28"
            ;;
        olive)
            accent="#4B8501"
            hover="#51850F"
            active="#368501"
            insensitive="#79856A"
            insensitive_dark="#2B4D01"
            ;;
        prussiangreen)
            accent="#308280"
            hover="#3D8280"
            active="#307682"
            insensitive="#688281"
            insensitive_dark="#1C4D4B"
            ;;
        purple)
            accent="#7764D8"
            hover="#8979D8"
            active="#8B64D8"
            insensitive="#B4ADD8"
            insensitive_dark="#2A234D"
            ;;
        red)
            accent="#DA3450"
            hover="#DA4A62"
            active="#DA3434"
            insensitive="#DAAEB6"
            insensitive_dark="#4D121C"
            ;;
        sage)
            accent="#657B69"
            hover="#6F8773"
            active="#657B6D"
            insensitive="#7A877C"
            insensitive_dark="#3F4D41"
            ;;
        viridian)
            accent="#03875B"
            hover="#10875F"
            active="#038771"
            insensitive="#6C877E"
            insensitive_dark="#024D34"
            ;;
    esac
    cd "${YARU_DEV}/yaru-dirty/"
    mkdir -p gtk/src/${THEME}/gtk-2.0/
    mkdir -p gtk/src/${THEME}-dark/gtk-2.0/
    rsync -a --delete gtk/src/default/gtk-2.0/ gtk/src/${THEME}/gtk-2.0/
    rsync -a --delete gtk/src/dark/gtk-2.0/ gtk/src/${THEME}-dark/gtk-2.0/

    # DEFAULT
    sed -i "s|#E95420|${accent}|g" gtk/src/${THEME}/gtk-2.0/gtkrc
    sed -i "s|#19B6EE|${accent}|g" gtk/src/${THEME}/gtk-2.0/gtkrc     #link
    sed -i "s|#0b7196|${active}|g" gtk/src/${THEME}/gtk-2.0/gtkrc     #visited link

    # Accent
    sed -i "s|#f85731|${accent}|g" gtk/src/${THEME}/gtk-2.0/assets.svg
    sed -i "s|#f85731|${accent}|g" gtk/src/${THEME}/gtk-2.0/assets-external.svg
    # Hover
    sed -i "s|#f96640|${hover}|g" gtk/src/${THEME}/gtk-2.0/assets-external.svg
    # Active
    sed -i "s|#e55730|${active}|g" gtk/src/${THEME}/gtk-2.0/assets.svg
    sed -i "s|#c34113|${active}|g" gtk/src/${THEME}/gtk-2.0/assets.svg
    sed -i "s|#c74729|${active}|g" gtk/src/${THEME}/gtk-2.0/assets-external.svg
    # Insensitive
    sed -i "s|#fea691|${insensitive}|g" gtk/src/${THEME}/gtk-2.0/assets.svg
    sed -i "s|#f1a78d|${insensitive}|g" gtk/src/${THEME}/gtk-2.0/assets.svg
    sed -i "s|#f6b6a0|${insensitive}|g" gtk/src/${THEME}/gtk-2.0/assets.svg
    sed -i "s|#f1a78d|${insensitive}|g" gtk/src/${THEME}/gtk-2.0/assets-external.svg

    cd gtk/src/${THEME}/gtk-2.0
    ./render-all-assets.sh
    ./render-assets-external.sh

    cd "${YARU_DEV}/yaru-dirty/"
    # DARK
    sed -i "s|#E95420|${accent}|g" gtk/src/${THEME}-dark/gtk-2.0/gtkrc
    sed -i "s|#2194bd|${accent}|g" gtk/src/${THEME}-dark/gtk-2.0/gtkrc     #link
    sed -i "s|#c97c5b|${active}|g" gtk/src/${THEME}-dark/gtk-2.0/gtkrc     #visited link

    # Accent
    sed -i "s|#f85731|${accent}|g" gtk/src/${THEME}-dark/gtk-2.0/assets.svg
    sed -i "s|#f85731|${accent}|g" gtk/src/${THEME}-dark/gtk-2.0/assets-external.svg
    # Hover
    sed -i "s|#f96640|${hover}|g" gtk/src/${THEME}-dark/gtk-2.0/assets-external.svg
    # Active
    sed -i "s|#e55730|${active}|g" gtk/src/${THEME}-dark/gtk-2.0/assets.svg
    sed -i "s|#c34113|${active}|g" gtk/src/${THEME}-dark/gtk-2.0/assets.svg
    sed -i "s|#c74729|${active}|g" gtk/src/${THEME}-dark/gtk-2.0/assets-external.svg
    # Insensitive
    sed -i "s|#bf6a57|${insensitive}|g" gtk/src/${THEME}-dark/gtk-2.0/assets.svg
    sed -i "s|#bf6a5f|${insensitive}|g" gtk/src/${THEME}-dark/gtk-2.0/assets.svg
    sed -i "s|#b56d54|${insensitive}|g" gtk/src/${THEME}-dark/gtk-2.0/assets.svg
    sed -i "s|#92442e|${insensitive_dark}|g" gtk/src/${THEME}-dark/gtk-2.0/assets-external.svg
    cd gtk/src/${THEME}-dark/gtk-2.0
    ./render-all-assets.sh
    ./render-assets-external.sh
    done
fi

cd "${YARU_DEV}/yaru-dirty/"
meson build --prefix="${YARU_NEW}"
ninja -C build
ninja -C build install > /dev/null

#icons
rsync -aHAWXx --delete "${YARU_NEW}/share/icons/Yaru-mate/" "${YARU_NEW}/share/icons/Yaru-MATE-light/"
rsync -aHAWXx --delete "${YARU_NEW}/share/icons/Yaru-dark/" "${YARU_NEW}/share/icons/Yaru-MATE-dark/"
sed -i "s|Name=Yaru-mate|Name=Yaru-MATE-light|" "${YARU_NEW}/share/icons/Yaru-MATE-light/index.theme"
sed -i "s|Name=Yaru-dark|Name=Yaru-MATE-dark|" "${YARU_NEW}/share/icons/Yaru-MATE-dark/index.theme"
sed -i "s|Inherits=Yaru,|Inherits=Yaru-MATE-light,|" "${YARU_NEW}/share/icons/Yaru-MATE-dark/index.theme"
for THEME in light dark; do
    sed -i "s|Example=folder|Example=user-desktop|" "${YARU_NEW}/share/icons/Yaru-MATE-${THEME}/index.theme"
    rsync -aHAWXx --delete "${YARU_NEW}/share/icons/Yaru-MATE-${THEME}/" "${YARU_DEV}/ubuntu-mate-artwork-dirty/usr/share/icons/Yaru-MATE-${THEME}/"
done

#themes
mv "${YARU_NEW}/share/themes/Yaru-MATE/" "${YARU_NEW}/share/themes/Yaru-MATE-light/"
sed -i "s|Yaru-MATE|Yaru-MATE-light|g" "${YARU_NEW}/share/themes/Yaru-MATE-light/index.theme"
rsync -aHAWXx --delete "${YARU_NEW}/share/themes/Yaru-MATE-light/" "${YARU_DEV}/ubuntu-mate-artwork-dirty/usr/share/themes/Yaru-MATE-light/"
rsync -aHAWXx --delete "${YARU_NEW}/share/themes/Yaru-MATE-dark/" "${YARU_DEV}/ubuntu-mate-artwork-dirty/usr/share/themes/Yaru-MATE-dark/"

cd "${YARU_DEV}/ubuntu-mate-artwork-dirty"
dch -v 22.10.2~kinetic$(date +%y\.%j\.%H%M) --distribution kinetic "Sync Yaru-MATE themes/icons with upstream Yaru."
#dch --append "debian/control: Drop D: ubuntu-mono (ubuntu-mate-icon-themes). No longer required."
echo
head -n9 debian/changelog
echo
echo "${YARU_DEV}/ubuntu-mate-artwork-dirty"

exit

#for THEME in Yaru Yaru-dark; do
#  sudo rsync -aHAWXx --delete ${YARU_NEW}/share/themes/${THEME}/ /usr/share/themes/${THEME}/
#  sudo rsync -aHAWXx --delete ${YARU_NEW}/share/icons/${THEME}/ /usr/share/icons/${THEME}/
#  sudo gtk-update-icon-cache -f /usr/share/icons/${THEME}
#done

#for THEME in Yaru-MATE-light Yaru-MATE-dark; do
#  sudo rsync -aHAWXx --delete ${YARU_NEW}/share/themes/${THEME}/ /usr/share/themes/${THEME}/
#  sudo rsync -aHAWXx --delete ${YARU_NEW}/share/icons/${THEME}/ /usr/share/icons/${THEME}/
#  sudo gtk-update-icon-cache -f /usr/share/icons/${THEME}
#done

#for THEME in Yaru-bark Yaru-blue Yaru-magenta Yaru-olive Yaru-prussiangreen Yaru-purple Yaru-red Yaru-sage Yaru-viridian; do
#  sudo rsync -aHAWXx --delete ${YARU_NEW}/share/themes/${THEME}/ /usr/share/themes/${THEME}/
#  sudo rsync -aHAWXx --delete ${YARU_NEW}/share/themes/${THEME}-dark/ /usr/share/themes/${THEME}-dark/
#  sudo rsync -aHAWXx --delete ${YARU_NEW}/share/icons/${THEME}/ /usr/share/icons/${THEME}/
#  sudo rsync -aHAWXx --delete ${YARU_NEW}/share/icons/${THEME}-dark/ /usr/share/icons/${THEME}-dark/
#  sudo gtk-update-icon-cache -f /usr/share/icons/${THEME}
#  sudo gtk-update-icon-cache -f /usr/share/icons/${THEME}-dark
#done

#for THEME in Yaru-mate; do
#  sudo rsync -aHAWXx --delete ${YARU_NEW}/share/themes/${THEME}/ /usr/share/themes/${THEME}/
#  sudo rsync -aHAWXx --delete ${YARU_NEW}/share/themes/${THEME}-dark/ /usr/share/themes/${THEME}-dark/
#  sudo rsync -aHAWXx --delete ${YARU_NEW}/share/icons/${THEME}/ /usr/share/icons/${THEME}/
#  sudo rsync -aHAWXx --delete ${YARU_NEW}/share/icons/${THEME}-dark/ /usr/share/icons/${THEME}-dark/
#  sudo gtk-update-icon-cache -f /usr/share/icons/${THEME}
#  sudo gtk-update-icon-cache -f /usr/share/icons/${THEME}-dark
#done
