#!/bin/sh

ambiant="'Ambiant-MATE'"
ambiant_dark="'Ambiant-MATE-Dark'"
radiant="'Radiant-MATE'"

yaru_mate_light="'Yaru-MATE-light'"
yaru_mate_dark="'Yaru-MATE-dark'"

metacity_light="'Yaru'"
metacity_dark="'Yaru-dark'"

color_scheme_light="'default'"
color_scheme_dark="'prefer-dark'"

plank_light="'Yaru-light'"
plank_dark="'Yaru-dark'"

cursor_theme="'Yaru'"

if [ "$(gsettings get org.mate.interface gtk-theme)" = "$ambiant" ] || [ "$(gsettings get org.mate.interface gtk-theme)" = "$ambiant_dark" ]; then
    gsettings set org.mate.Marco.general theme "$yaru_mate_dark"
    gsettings set org.mate.interface gtk-theme "$yaru_mate_dark"
    gsettings set org.mate.interface icon-theme "$yaru_mate_dark"
    gsettings set org.mate.peripherals-mouse cursor-theme "$cursor_theme"
    gsettings set org.mate.pluma "$yaru_mate_dark"

    gsettings set org.gnome.desktop.interface gtk-theme "$yaru_mate_dark"
    gsettings set org.gnome.desktop.interface icon-theme "$yaru_mate_dark"
    gsettings set org.gnome.desktop.interface color-scheme "$color_scheme_dark"
    gsettings set org.gnome.desktop.interface cursor-theme "$cursor_theme"

    gsettings set net.launchpad.plank.dock.settings theme "$plank_dark"
fi

if [ "$(gsettings get org.mate.interface gtk-theme)" = "$radiant" ]; then
    gsettings set org.mate.Marco.general theme "$yaru_mate_light"
    gsettings set org.mate.interface gtk-theme "$yaru_mate_light"
    gsettings set org.mate.interface icon-theme "$yaru_mate_light"
    gsettings set org.mate.peripherals-mouse cursor-theme "$cursor_theme"
    gsettings set org.mate.pluma "$yaru_mate_light"

    gsettings set org.gnome.desktop.interface gtk-theme "$yaru_mate_light"
    gsettings set org.gnome.desktop.interface icon-theme "$yaru_mate_light"
    gsettings set org.gnome.desktop.interface color-scheme "$color_scheme_light"
    gsettings set org.gnome.desktop.interface cursor-theme "$cursor_theme"

    gsettings set net.launchpad.plank.dock.settings theme "$plank_light"
fi

