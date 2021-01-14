# Find, load common utilities
# Defines IS_MACOS, fetch_unpack
MULTIBUILD_DIR=$(dirname "${BASH_SOURCE[0]}")
source $MULTIBUILD_DIR/common_utils.sh

# Only source configure_build once
if [ -n "$CONFIGURE_BUILD_SOURCED" ]; then
    return
fi
CONFIGURE_BUILD_SOURCED=1

BUILD_PREFIX="${BUILD_PREFIX:-/usr/local}"
MB_ML_VER=${MB_ML_VER:-1}

# IS_MACOS is defined in common_utils.sh
if [ -n "$IS_MACOS" ]; then
    # Default compilation flags for OSX
    source $MULTIBUILD_DIR/osx_utils.sh
    PLAT=${PLAT:-$(macpython_arch_for_version $MB_PYTHON_VERSION)}
    if [[ $PLAT == intel ]]; then
        ARCH_FLAGS=${ARCH_FLAGS:-"-arch i386 -arch x86_64"}
    elif [[ $PLAT == x86_64 ]]; then
        ARCH_FLAGS=${ARCH_FLAGS:-"-arch x86_64"}
    elif [[ $PLAT == arm64 ]]; then
        ARCH_FLAGS=${ARCH_FLAGS:-"-arch arm64"}
    elif [[ $PLAT == universal2 ]]; then
        # Do nothing as we are going with fusing wheels
        ARCH_FLAGS=${ARCH_FLAGS:-}
    else
        echo "invalid platform = '$PLAT', supported values are 'intel' or 'x86_64' or 'arm64' or 'universal2'"
        exit 1
    fi
    # Only set CFLAGS, FFLAGS if they are not already defined.  Build functions
    # can override the arch flags by setting CFLAGS, FFLAGS
    export CFLAGS="${CFLAGS:-$ARCH_FLAGS}"
    export CXXFLAGS="${CXXFLAGS:-$ARCH_FLAGS}"
    export FFLAGS="${FFLAGS:-$ARCH_FLAGS}"

    # Disable homebrew auto-update
    export HOMEBREW_NO_AUTO_UPDATE=1
else
    # default compilation flags for linux
    PLAT="${PLAT:-x86_64}"
    # Strip all binaries after compilation.
    STRIP_FLAGS=${STRIP_FLAGS:-"-Wl,-strip-all"}

    export CFLAGS="${CFLAGS:-$STRIP_FLAGS}"
    export CXXFLAGS="${CXXFLAGS:-$STRIP_FLAGS}"
    export FFLAGS="${FFLAGS:-$STRIP_FLAGS}"
    if [[ $MB_ML_VER == "1" ]]; then
        if [ "${MB_PYTHON_VERSION:0:4}" == "pypy" ]; then
            yum install -y libtool wget
        else
            yum install -y libtool
        fi
    elif [ "${MB_PYTHON_VERSION:0:4}" == "pypy" ]; then
        yum install -y wget
    fi
fi

export CPPFLAGS_BACKUP="$CPPFLAGS"
export LIBRARY_PATH_BACKUP="$LIBRARY_PATH"
export PKG_CONFIG_PATH_BACKUP="$PKG_CONFIG_PATH"
export PATH_BACKUP="$PATH"

function update_env_for_build_prefix {
  # Promote BUILD_PREFIX on search path to any newly built libs
  export CPPFLAGS="-I$BUILD_PREFIX/include $CPPFLAGS_BACKUP"
  export LIBRARY_PATH="$BUILD_PREFIX/lib:$LIBRARY_PATH_BACKUP"
  export PKG_CONFIG_PATH="$BUILD_PREFIX/lib/pkgconfig/:$PKG_CONFIG_PATH_BACKUP"
  # Add binary path for configure utils etc
  export PATH="$BUILD_PREFIX/bin:$PATH_BACKUP"
}

update_env_for_build_prefix
