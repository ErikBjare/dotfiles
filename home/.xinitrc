if (hostname=='erb-main-kubuntu'); then
    xrandr --output HDMI-0 --auto --primary
    xrandr --output DisplayPort-0 --left-of HDMI-0
    xrandr --output DVI-1 --right-of HDMI-0
fi

feh --bg-fill "~/Media/Wallpapers/Nothing is real.jpg"
redshift -t 7000:3500 &
dropbox start &

exec xmonad
