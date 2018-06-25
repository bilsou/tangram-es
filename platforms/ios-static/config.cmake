add_definitions(-DTANGRAM_IOS)

set(TANGRAM_FRAMEWORK_VERSION "0.9.4-dev")

### Configure iOS toolchain.
set(IOS TRUE)
set(CMAKE_OSX_SYSROOT "iphoneos")
set(CMAKE_XCODE_EFFECTIVE_PLATFORMS "-iphoneos;-iphonesimulator")
set(CMAKE_XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "9.3")
execute_process(COMMAND xcrun --sdk iphoneos --show-sdk-version OUTPUT_VARIABLE IOS_SDK_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)

# Tell SQLiteCpp to not build its own copy of SQLite, we will use the system library instead.
if (IOS_SDK_VERSION VERSION_LESS 11.0)
  set(SQLITE_USE_LEGACY_STRUCT ON CACHE BOOL "")
endif()
set(SQLITECPP_INTERNAL_SQLITE OFF CACHE BOOL "")

set(TANGRAM_FRAMEWORK_HEADERS
  platforms/ios/framework/src/TangramMap.h
  platforms/ios/framework/src/TGGeoPolyline.h
  platforms/ios/framework/src/TGGeoPolygon.h
  platforms/ios/framework/src/TGGeoPoint.h
  platforms/ios/framework/src/TGMarker.h
  platforms/ios/framework/src/TGSceneUpdate.h
  platforms/ios/framework/src/TGMapData.h
  platforms/ios/framework/src/TGTypes.h
  platforms/ios/framework/src/TGHttpHandler.h
  platforms/ios/framework/src/TGLabelPickResult.h
  platforms/ios/framework/src/TGMarkerPickResult.h
  platforms/ios/framework/src/TGMapViewController.h
)

add_library(TangramMap STATIC
  ${TANGRAM_FRAMEWORK_HEADERS}
  platforms/common/platform_gl.cpp
  platforms/common/appleAllowedFonts.h
  platforms/common/appleAllowedFonts.mm
  platforms/ios/framework/src/iosPlatform.h
  platforms/ios/framework/src/iosPlatform.mm
  platforms/ios/framework/src/TGHelpers.h
  platforms/ios/framework/src/TGHelpers.mm
  platforms/ios/framework/src/TGGeoPolyline.mm
  platforms/ios/framework/src/TGGeoPolygon.mm
  platforms/ios/framework/src/TGHttpHandler.mm
  platforms/ios/framework/src/TGMapData+Internal.h
  platforms/ios/framework/src/TGMapData.mm
  platforms/ios/framework/src/TGSceneUpdate.mm
  platforms/ios/framework/src/TGLabelPickResult+Internal.h
  platforms/ios/framework/src/TGLabelPickResult.mm
  platforms/ios/framework/src/TGMarkerPickResult+Internal.h
  platforms/ios/framework/src/TGMarkerPickResult.mm
  platforms/ios/framework/src/TGMarker+Internal.h
  platforms/ios/framework/src/TGMarker.mm
  platforms/ios/framework/src/TGTypes.mm
  platforms/ios/framework/src/TGMapViewController+Internal.h
  platforms/ios/framework/src/TGMapViewController.mm
)

target_link_libraries(TangramMap PRIVATE
  tangram-core
  sqlite3
  # Frameworks: use quotes so "-framework X" is treated as a single linker flag.
  "-framework CoreFoundation"
  "-framework CoreGraphics"
  "-framework CoreText"
  "-framework GLKit"
  "-framework OpenGLES"
  "-framework UIKit"
)

target_include_directories(TangramMap PRIVATE
  platforms/common
)

set_target_properties(TangramMap PROPERTIES
  PUBLIC_HEADER "${TANGRAM_FRAMEWORK_HEADERS}"
  XCODE_ATTRIBUTE_CURRENT_PROJECT_VERSION "${TANGRAM_FRAMEWORK_VERSION}"
  XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC "YES"
  XCODE_ATTRIBUTE_CLANG_CXX_LANGUAGE_STANDARD "c++14"
  XCODE_ATTRIBUTE_CLANG_CXX_LIBRARY "libc++"
)

set(TANGRAM_STATIC_DEPENDENCIES
  $<TARGET_FILE:TangramMap>
  $<TARGET_FILE:tangram-core>
  $<TARGET_FILE:duktape>
  $<TARGET_FILE:css-color-parser-cpp>
  $<TARGET_FILE:yaml-cpp>
  $<TARGET_FILE:alfons>
  $<TARGET_FILE:linebreak>
  $<TARGET_FILE:harfbuzz>
  $<TARGET_FILE:freetype>
  $<TARGET_FILE:icucommon>
  $<TARGET_FILE:SQLiteCpp>
  $<TARGET_FILE:double-conversion>
  $<TARGET_FILE:miniz>
)

# Combine TangramMap with dependency libraries to make a single archive.
# In a post-build step run libtool to combine them into a single archive.
set(TANGRAM_STATIC_OUTPUT "${PROJECT_BINARY_DIR}/\${CONFIGURATION}\${EFFECTIVE_PLATFORM_NAME}/libtangram-static.a")
add_custom_command(OUTPUT ${TANGRAM_STATIC_OUTPUT}
  COMMAND
  libtool -static -o 
  ${TANGRAM_STATIC_OUTPUT}
  ${TANGRAM_STATIC_DEPENDENCIES}
  DEPENDS
  ${TANGRAM_STATIC_DEPENDENCIES}
  COMMAND
  ${CMAKE_COMMAND} -E make_directory
  "${PROJECT_BINARY_DIR}/Include/TangramMap/"
  COMMAND
  ${CMAKE_COMMAND} -E copy_if_different
  ${TANGRAM_FRAMEWORK_HEADERS}
  "${PROJECT_BINARY_DIR}/Include/TangramMap/"
)

add_custom_target(tangram-static DEPENDS ${TANGRAM_STATIC_OUTPUT})
