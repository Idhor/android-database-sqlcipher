(cd external/openssl;

    if [ ! ${ANDROID_NDK_ROOT} ]; then
        echo "ANDROID_NDK_ROOT environment variable not set, set and rerun"
        exit 1
    fi

    HOST_INFO=`uname -a`
    case ${HOST_INFO} in
        Darwin*)
            TOOLCHAIN_SYSTEM=darwin-x86_64
            ;;
        Linux*)
            if [[ "${HOST_INFO}" == *i686* ]]
            then
                TOOLCHAIN_SYSTEM=linux-x86
            else
                TOOLCHAIN_SYSTEM=linux-x86_64
            fi
            ;;
        *)
            echo "Toolchain unknown for host system"
            exit 1
            ;;
    esac

    rm ../android-libs/armeabi/libcrypto.a \
    	../android-libs/armeabi-v7a/libcrypto.a
        ../android-libs/x86/libcrypto.a

    git clean -dfx && git checkout -f
	sed -i "" 's/MAKEDEPPROG=makedepend/MAKEDEPPROG=$(CC) -M/g' Makefile.org

    ANDROID_PLATFORM_VERSION=android-19
    ANDROID_TOOLCHAIN_DIR=/tmp/sqlcipher-android-toolchain
    OPENSSL_EXCLUSION_LIST="\
    no-ssl \
	no-tls \
	no-ssl2 \
	no-ssl3 \
	no-tls1 \
	no-tlsext \
	no-sock \
	no-engine \
	no-hw \
	no-bf \
	no-camellia \
	no-cast \
	no-cms \
	no-des \
	no-dh \
	no-dsa \
	no-dso \
	no-ec \
	no-ecdh \
	no-ecdsa \
	no-engine \
	no-err \
	no-idea \
	no-jpake \
	no-krb5 \
	no-md2 \
	no-md4 \
	no-mdc2 \
	no-perlasm \
	no-rc2 \
	no-rc4 \
	no-rc5 \
	no-ripemd \
	no-rsa \
	no-seed \
	no-srp \
	no-store \
	no-whirlpool \
	"
	
	export PATH=${ANDROID_TOOLCHAIN_DIR}/bin:$PATH
	
	rm -rf ${ANDROID_TOOLCHAIN_DIR}
    ${ANDROID_NDK_ROOT}/build/tools/make-standalone-toolchain.sh \
        --platform=${ANDROID_PLATFORM_VERSION} \
        --install-dir=${ANDROID_TOOLCHAIN_DIR} \
        --system=${TOOLCHAIN_SYSTEM} \
		--arch=arm
    
	export RANLIB=arm-linux-androideabi-ranlib
    export AR=arm-linux-androideabi-ar
    export CC=arm-linux-androideabi-gcc
    
    # arm
	make dclean
    ./Configure android ${OPENSSL_EXCLUSION_LIST}
	make depend
    make build_crypto
    mv -f libcrypto.a ../android-libs/armeabi/
    
    # armv7-a
	make dclean
    ./Configure android-armv7 ${OPENSSL_EXCLUSION_LIST}
	make depend
    make build_crypto
    mv -f libcrypto.a ../android-libs/armeabi-v7a/
    
    # x86    
    rm -rf ${ANDROID_TOOLCHAIN_DIR}
    ${ANDROID_NDK_ROOT}/build/tools/make-standalone-toolchain.sh \
        --platform=${ANDROID_PLATFORM_VERSION} \
        --install-dir=${ANDROID_TOOLCHAIN_DIR} \
        --system=${TOOLCHAIN_SYSTEM} \
        --arch=x86
    
	export RANLIB=i686-linux-android-ranlib
    export AR=i686-linux-android-ar
    export CC=i686-linux-android-gcc
    
	make dclean
    ./Configure android-x86 ${OPENSSL_EXCLUSION_LIST}
	make depend
    make build_crypto
    mv -f libcrypto.a ../android-libs/x86/
    
    rm -rf ${ANDROID_TOOLCHAIN_DIR}
)
