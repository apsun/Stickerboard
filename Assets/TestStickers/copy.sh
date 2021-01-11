#!/bin/bash
script_dir="$(dirname "$0")"
app_id=com.crossbowffs.stickerboard
num_packs=3

get_booted_simulators() {
    xcrun simctl list devices | grep '(Booted)' | sed 's/.* (\(.*\)) (Booted)/\1/'
}

get_simulator_container_dir() {
    xcrun simctl get_app_container "$1" "${app_id}" data
}

get_sticker_files() {
    for file in "${script_dir}"/*; do
        if [ "$(basename "${file}")" != "$(basename "$0")" ]; then
            echo "${file}"
        fi
    done
}

get_booted_simulators | while read sim; do
    base_dir="$(get_simulator_container_dir "${sim}")/Documents"
    for n in $(seq "${num_packs}"); do
        dir="${base_dir}/pack-${n}"
        mkdir -p "${dir}"
        get_sticker_files | while read file; do
            cp "${file}" "${dir}/"
        done
    done
done
