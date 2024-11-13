#!/bin/bash

modes="fgd md"
games="momentum p2ce templategame"

build_dir="build"
build_md_dir="build_md"
bin_dir="bin/win64" # Hammer is windows only

# Setup hammer folder copy exclusions (*_momentum, *_p2ce, etc)
copy_exclusions=(--exclude="scripts")
for i in $games
  do
  copy_exclusions+=(--exclude="*_$i")
done

mode=$1
# Make sure mode isn't empty by asking the user
if [ $# -eq 0 ]; then
  echo Modes: "${modes[*]}" && echo Enter mode. Use ALL to build everything. && read -p "" mode
fi

game=$2
# Make sure game isn't empty by asking the user for what game to build
if [ $# -eq 0 ]; then
  echo Games: "${games[*]}" && echo Enter game to build. Use ALL to build every game. && read -p "" game
fi

build_fgd_cleanup() {
  echo "Removing previous FGD build in $build_dir"
  rm -rf "$build_dir"
}
build_md_cleanup() {
  echo "Removing previous markdown build in $build_md_dir"
  rm -rf "$build_md_dir"
}

build() {
  if [[ "${mode^^}" = "FGD" ]] || [[ "${mode^^}" = "ALL" ]]; then
    build_fgd_$1
  fi
  if [[ "${mode^^}" = "MD" ]] || [[ "${mode^^}" = "ALL" ]]; then
    build_game_markdown $1
  fi
  return 0
}

build_fgd_p2ce() {
  copy_hammer_files p2ce
  build_game_fgd p2ce srctools --extra patch_postcompiler.fgd
}

build_fgd_momentum() {
  copy_hammer_files momentum
  build_game_fgd momentum
}

build_fgd_templategame() {
  copy_hammer_files templategame
  build_game_fgd templategame
}

build_game_markdown() {
  echo "Generating markdown from FGD for $1..."
  mkdir -p "$build_md_dir/$1"
  python3 unify_fgd.py expmd $1 -o "$build_md_dir/$1"

  if [ $? -ne 0 ]; then
    echo "Building markdown for $1 has failed. Exitting." && exit 1
  fi
  return 0
}

copy_hammer_files() {
  echo "Copying Hammer files..."
  mkdir -p "$build_dir"
  rsync -a "${copy_exclusions[@]}" "hammer" "$build_dir"
  rsync -a hammer/cfg_$1/* $build_dir/hammer/cfg

  if [ $? -ne 0 ]; then
    echo "Failed copying Hammer files. Exitting." && exit 1
  fi
  return 0
}

build_game_fgd() {
  echo "Building FGD for $1..."
  mkdir -p "$build_dir/$1"
  python3 unify_fgd.py $3 $4 exp $1 $2 -o "$build_dir/$1/$1.fgd"

  if [ $? -ne 0 ]; then
    echo "Building FGD for $1 has failed. Exitting." && exit 1
  fi
  return 0
}

if [[ "${mode^^}" = "FGD" ]] || [[ "${mode^^}" = "ALL" ]]; then
  build_fgd_cleanup
fi
if [[ "${mode^^}" = "MD" ]] || [[ "${mode^^}" = "ALL" ]]; then
  build_md_cleanup
fi

if [ "${game^^}" = "ALL" ]; then
  # Modify build directory to not have directories clash
  main_build_dir=$build_dir
  for i in $games
    do
    unset build_dir
    build_dir=$main_build_dir/$i
    build $i
  done
else
  for i in $games
    do
    if [ "$i" = "$game" ]; then
      build $game
      exit
    fi
  done
  echo "Unknown game. Exitting." && exit 1
fi
