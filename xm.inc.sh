# These are just the bash near-equivalents for reference

# TODO grab from settings.json or td --dump-settings
configDir=/var/lib/transmission/.config/transmission-daemon
downloadDir=/mnt/downloads

alias xm=transmission-remote

xmo() {
  local op=$1
  shift
  local ids=($@)
  local IFS=,
  transmission-remote -t"${ids[*]}" $op
}

_xm_get_complete() {
  transmission-remote -l | grep 100% | awk '{print $1}' | grep -v \*
}

_xm_get_complete_with_errors() {
  transmission-remote -l | grep 100% | awk '{print $1}' | cut -d\* -f1
}

xmclean() {
  local ids=($(_xm_get_complete))
  # TODO move only the actually about-to-be-removed torrents
  sudo rsync -rP ${configDir}/torrents/ ${downloadDir}/_torrents || return
  xmo -r ${ids[@]}
  # TODO move completed files into ${downloadDir}/_complete or start using incomplete dir again

  # another way to remove:
  #export -f xmo
  #_xm_get_complete | xargs bash -c "xmo -l"
}

unset IFS
