# Copyright (C) 2025, Advanced Micro Devices, Inc. All rights reserved.

# Set CMake policy
cmake_policy(SET CMP0010 NEW)

# Define variables for Crypto path, repository, and build log file
set(Crypto_PATH "" CACHE STRING "Local path of the AOCL-Crypto source code")
set(Crypto_GIT_REPOSITORY "https://github.com/amd/aocl-crypto.git" CACHE STRING "AOCL-Crypto git repository path")
set(Crypto_GIT_TAG "main" CACHE STRING "Tag or Branch name of AOCL-Crypto")
set(Crypto_DIR ${CMAKE_BINARY_DIR}/aocl-crypto)
set(Crypto_BUILD_LOG_FILE_PATH "${CMAKE_BINARY_DIR}/aocl_crypto_build.log")

# Initialize build log file
file(WRITE "${Crypto_BUILD_LOG_FILE_PATH}" "=========================AOCL-Crypto Build Logs=========================.\n")

# Remove existing Crypto directory if it exists
if(EXISTS ${Crypto_DIR})
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E remove_directory ${Crypto_DIR}
    )
endif()

# Use local Crypto source code if provided, otherwise clone from git repository
if(Crypto_PATH)
    message(STATUS "Using AOCL-Crypto source code from ${Crypto_PATH}.")
    file(APPEND "${Crypto_BUILD_LOG_FILE_PATH}" "Using Crypto-Utils source code from ${Crypto_PATH}.\n")
    string(REPLACE "\\" "/" Crypto_DIR "${Crypto_PATH}/aocl-crypto")
else()
    execute_process(
        COMMAND git clone ${Crypto_GIT_REPOSITORY} -b ${Crypto_GIT_TAG} aocl-crypto
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        RESULT_VARIABLE result
        OUTPUT_VARIABLE output
        ERROR_VARIABLE error
    )
    if(result EQUAL 0)
        file(APPEND "${Crypto_BUILD_LOG_FILE_PATH}" "${output}.\n")
    else()
        file(APPEND "${Crypto_BUILD_LOG_FILE_PATH}" "${error}.\n")
    endif()
endif()

# Log the Crypto path
message(STATUS "Crypto_PATH: ${Crypto_DIR}.")
file(APPEND "${Crypto_BUILD_LOG_FILE_PATH}" "Crypto_PATH: ${Crypto_DIR}.\n")

# Log the start of the configuration and build process
message(STATUS "\"The configuration and build process for the AOCL-Crypto library has started, and logs are being redirected to ${Crypto_BUILD_LOG_FILE_PATH}\"")

# Determine the compiler toolset based on the generator
string(FIND "${CMAKE_GENERATOR}" "Visual Studio" substring_position)
if(substring_position EQUAL -1)
    set(CompilerToolSet 
        -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER} -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
    )
else()
    set(CompilerToolSet "-T${CMAKE_GENERATOR_TOOLSET}")
endif()

# Log the configuration command
file(APPEND "${Crypto_BUILD_LOG_FILE_PATH}" "CONFIGURATION COMMAND: cmake -G \"${CMAKE_GENERATOR}\" -S ${Crypto_DIR} -B ${CMAKE_BINARY_DIR}/aocl-crypto/build_dir -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/aocl-crypto/install_package -DOPENSSL_INSTALL_DIR=${OPENSSL_INSTALL_DIR} -DENABLE_AOCL_UTILS=ON -DAOCL_UTILS_INSTALL_DIR=${CMAKE_BINARY_DIR}/aocl-utils/install_package -DDALCP_ENABLE_EXAMPLES=OFF ${CompilerToolSet}.\n")

# Execute the configuration command
execute_process(
    COMMAND cmake -G ${CMAKE_GENERATOR} -S ${Crypto_DIR} -B ${CMAKE_BINARY_DIR}/aocl-crypto/build_dir -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/aocl-crypto/install_package -DOPENSSL_INSTALL_DIR=${OPENSSL_INSTALL_DIR} -DENABLE_AOCL_UTILS=ON -DAOCL_UTILS_INSTALL_DIR=${CMAKE_BINARY_DIR}/aocl-utils/install_package -DDALCP_ENABLE_EXAMPLES=OFF ${CompilerToolSet}
    WORKING_DIRECTORY ${Crypto_DIR}
    RESULT_VARIABLE result
    OUTPUT_VARIABLE output
    ERROR_VARIABLE error
)
if(result EQUAL 0)
    file(APPEND "${Crypto_BUILD_LOG_FILE_PATH}" "${output}.\n")
    message(STATUS "AOCL-Crypto library configuration completed successfully.")
else()
    file(APPEND "${Crypto_BUILD_LOG_FILE_PATH}" "${error}.\n")
    message(FATAL_ERROR "Error occured while AOCL-Crypto library configuration!!!.\n${error}\n")
endif()

# Execute the build command
execute_process(
    COMMAND cmake --build ${CMAKE_BINARY_DIR}/aocl-crypto/build_dir --config ${CMAKE_BUILD_TYPE} --target install
    WORKING_DIRECTORY ${Crypto_DIR}
    RESULT_VARIABLE result
    OUTPUT_VARIABLE output
    ERROR_VARIABLE error
)

# Check the result of the build process
if(result EQUAL 0)
    file(APPEND "${Crypto_BUILD_LOG_FILE_PATH}" "${output}.\n")
    message(STATUS "AOCL-Crypto library built successfully.")
else()
    file(APPEND "${Crypto_BUILD_LOG_FILE_PATH}" "${error}.\n")
    message(FATAL_ERROR "Error occured while AOCL-Crypto library building!!!.\n${error}\n")
endif()

# Remove unnecessary directories based on the generator
if(substring_position EQUAL -1)
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_BINARY_DIR}/aocl-crypto/build_dir/CMakeFiles/ShowIncludes
    )
else()
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_BINARY_DIR}/aocl-crypto/build_dir/CMakeFiles/
    )
endif()

# Add dependent libraries based on the platform
if(WIN32)
    list(APPEND DEPENDENT_LIBS "${OPENSSL_INSTALL_DIR}/lib/libcrypto.lib")
else()
    list(APPEND DEPENDENT_LIBS "${OPENSSL_INSTALL_DIR}/lib64/libcrypto.so")
endif()

# Collect object files and append to the list
if(substring_position EQUAL -1)
    string(REPLACE "\\" "/" crypto_build_path "${CMAKE_BINARY_DIR}/aocl-crypto/build_dir/lib/CMakeFiles/alcp.dir")
    file(GLOB_RECURSE crypto_obj_files LIST_DIRECTORIES false ${crypto_build_path}/*\.${suff})
    list(APPEND OBJECT_FILES ${crypto_obj_files})
else()
    string(REPLACE "\\" "/" crypto_build_path "${CMAKE_BINARY_DIR}/aocl-crypto/build_dir/lib/alcp.dir")
    file(GLOB_RECURSE crypto_obj_files LIST_DIRECTORIES false ${crypto_build_path}/*\.${suff})
    list(APPEND OBJECT_FILES ${crypto_obj_files})
endif()
string(REPLACE "\\" "/" crypto_build_path "${CMAKE_BINARY_DIR}/aocl-crypto/build_dir/lib/arch")
file(GLOB_RECURSE crypto_obj_files LIST_DIRECTORIES false ${crypto_build_path}/*\.${suff})
list(APPEND OBJECT_FILES ${crypto_obj_files})

# Install the Crypto headers
install(DIRECTORY ${CMAKE_BINARY_DIR}/aocl-crypto/install_package/include/ DESTINATION include)
