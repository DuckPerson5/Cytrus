download_citra() {
    git clone https://github.com/citra-emu/citra citra-src
}

setup_core_dirs() {
    mkdir -p Citra/audio_core
    mkdir Citra/common
    mkdir Citra/core
    mkdir Citra/input_common
    mkdir Citra/network
    mkdir Citra/video_core
    mkdir Citra/web_service

    mkdir -p Citra/include/audio_core
    mkdir Citra/include/common
    mkdir Citra/include/core
    mkdir Citra/include/input_common
    mkdir Citra/include/network
    mkdir Citra/include/video_core
    mkdir Citra/include/web_service
}

move_headers_to_include_dir() {
    cp -r citra-src/src/audio_core Citra/include
    cp -r citra-src/src/common Citra/include
    cp -r citra-src/src/core Citra/include
    cp -r citra-src/src/input_common Citra/include
    cp -r citra-src/src/network Citra/include
    cp -r citra-src/src/video_core Citra/include
    cp -r citra-src/src/web_service Citra/include
}

cleanse_include_dirs() {
    find Citra/include -not -name "*.h" -not -name "*.hpp" -not -name "*.inc" -type f -delete
}

move_source_files_to_citra_dir() {
    cp -r citra-src/src/audio_core Citra
    cp -r citra-src/src/common Citra
    cp -r citra-src/src/core Citra
    cp -r citra-src/src/input_common Citra
    cp -r citra-src/src/network Citra
    cp -r citra-src/src/video_core Citra
    cp -r citra-src/src/web_service Citra
}

cleanse_source_dirs() {
    find Citra -not -name "*.c" -not -name "*.cpp" -type f -delete
}

# fixes an issue with the vfpinstr source file and possibly more at some point as they are included but this script removes them above
move_files_to_fix_issues() {
    cp citra-src/src/core/arm/skyeye_common/vfp/vfpinstr.cpp Citra/include/core/arm/skyeye_common/vfp/vfpinstr.cpp
    
    mkdir host_shaders
    cd host_shaders
    cmake ../citra-src/src/video_core/host_shaders
    make host_shaders
    cd ..
    cp -r host_shaders/include/video_core/host_shaders/* Citra/include/video_core/host_shaders
    
    mkdir Citra/include/video_core/renderer_software
    mkdir Citra/video_core/renderer_software
    cp citra-src/src/video_core/renderer_software/sw_blitter.h Citra/include/video_core/renderer_software
    cp citra-src/src/video_core/renderer_software/sw_blitter.cpp Citra/video_core/renderer_software
    cp citra-src/src/common/scm_rev.cpp.in Citra/common/scm_rev.cpp
}

remove_files_not_for_ios() {
    rm -rf Citra/audio_core/cubeb* Citra/common/android* Citra/common/apple* Citra/common/linux Citra/common/x64 Citra/input_common/gcadapter Citra/video_core/renderer_opengl Citra/video_core/renderer_software
    
    rm -rf Citra/include/audio_core/cubeb* Citra/include/common/android* Citra/include/common/apple* Citra/include/common/linux Citra/include/common/x64 Citra/include/input_common/gcadapter Citra/include/video_core/renderer_opengl Citra/include/video_core/renderer_software
}



setup_core_dirs
download_citra
move_source_files_to_citra_dir
cleanse_source_dirs
move_headers_to_include_dir
cleanse_include_dirs
remove_files_not_for_ios
move_files_to_fix_issues

rm -rf citra-src host_shaders
