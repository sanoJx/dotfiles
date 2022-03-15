#!/bin/bash

randomString() {
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-6} | head -n 1
}

deploycommand=(ln -s)

while getopts "hc:a:" name; do 
  case $name in
    c) deploycommand=(cp) ;;
    h) echo "Usage: 
             ./deploy.sh            Deploy all dotfiles using symbolic links
             ./deploy.sh -c         Deploy all dotfiles by copying them
             ./deploy.sh -a ANSWER  Deploy all files, using ANSWER as the answer in case of conflicts" ;;
    a)  defaultAnswer=$OPTARG ;;
  esac
done

deploy_file() {
  ans="y"
  fullPath="$1/$2"

  mkdir -p $1

  if ([ -f "$fullPath" ] || [ -L "$fullPath" ]) ; then
    if [ -z "$defaultAnswer" ]; then 
      ans="b"
      printf "File already exists at ($fullPath)\nOverwrite it? [y/n/B] "
      read ans < /dev/tty
    else
      ans=$defaultAnswer
    fi
  fi


  [[ "$ans" =~ ^[^yYbB].*$ ]] && return
  
  [[ "$ans" =~ ^[^yY]$ ]] || [ -z "$ans" ] && mv $fullPath "$1/$2.old-`randomString`"

  (${deploycommand[@]} "$filesDir/$2" $fullPath)
}

filesDir=`realpath $(dirname $0)`

while IFS= read -r line; do
  IFS=" " read p filename <<< $line
  filepath="${p/#\~/$HOME}"
  deploy_file $filepath $filename
done < $filesDir/dotfiles.txt
