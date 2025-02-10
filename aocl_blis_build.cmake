# Copyright (C) 2025, Advanced Micro Devices, Inc. All rights reserved.

# Set CMake policy
cmake_policy(SET CMP0010 NEW)

# Define variables for BLIS path, repository, and build log file
set(BLIS_PATH "" CACHE STRING "Local path of the AOCL-BLAS source code")
set(BLIS_GIT_REPOSITORY "https://github.com/amd/blis.git" CACHE STRING "AOCL-BLAS git repository path")
set(BLIS_GIT_TAG "master" CACHE STRING "Tag or Branch name of AOCL-BLAS")
set(BLIS_DIR ${CMAKE_BINARY_DIR}/blis)
set(BLIS_BUILD_LOG_FILE_PATH "${CMAKE_BINARY_DIR}/aocl_blis_build.log")

# Initialize build log file
file(WRITE "${BLIS_BUILD_LOG_FILE_PATH}" "=========================AOCL-BLAS Build Logs=========================.\n")

# Remove existing BLIS directory if it exists
if(EXISTS ${BLIS_DIR})
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E remove_directory ${BLIS_DIR}
    )
endif()

# Use local BLIS source code if provided, otherwise clone from git repository
if(BLIS_PATH)
    message(STATUS "Using AOCL-BLIS source code from ${BLIS_PATH}.")
    file(APPEND "${BLIS_BUILD_LOG_FILE_PATH}" "Using AOCL-BLIS source code from ${BLIS_PATH}.\n")
    string(REPLACE "\\" "/" BLIS_DIR "${BLIS_PATH}/blis")
else()
    execute_process(
        COMMAND git clone ${BLIS_GIT_REPOSITORY} -b ${BLIS_GIT_TAG} blis 
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        RESULT_VARIABLE result
        OUTPUT_VARIABLE output
        ERROR_VARIABLE error
    )
    if(result EQUAL 0)
        file(APPEND "${BLIS_BUILD_LOG_FILE_PATH}" "${output}.\n")
    else()
        file(APPEND "${BLIS_BUILD_LOG_FILE_PATH}" "${error}.\n")
    endif()
endif()

# Log the BLIS path
message(STATUS "BLIS_PATH: ${BLIS_DIR}.")
file(APPEND "${BLIS_BUILD_LOG_FILE_PATH}" "BLIS_PATH: ${BLIS_DIR}.\n")

# Log the start of the configuration and build process
message(STATUS "\"The configuration and build process for the AOCL-BLAS library has started, and logs are being redirected to ${BLIS_BUILD_LOG_FILE_PATH}\"")

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
file(APPEND "${BLIS_BUILD_LOG_FILE_PATH}" "CONFIGURATION COMMAND: cmake -G \"${CMAKE_GENERATOR}\" -S ${BLIS_DIR} -B ${CMAKE_BINARY_DIR}/blis/build_dir -DCMAKE_CONFIGURATION_TYPES=${CMAKE_CONFIGURATION_TYPES} -DBLIS_CONFIG_FAMILY=${BLIS_CONFIG_FAMILY} -DENABLE_CBLAS=${ENABLE_CBLAS} -DENABLE_ADDON=${ENABLE_ADDON} -DENABLE_THREADING=${ENABLE_THREADING} -DOpenMP_libomp_LIBRARY=${OpenMP_libomp_LIBRARY} -DBLAS_INT_SIZE=${BLAS_INT_SIZE} -DCOMPLEX_RETURN=${COMPLEX_RETURN} -DBUILD_SHARED_LIBS=${BUILD_SHARED_LIBS} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DENABLE_TRSM_PREINVERSION=${ENABLE_TRSM_PREINVERSION} -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/blis/install_package ${CompilerToolSet}.\n")

# Execute the configuration command
execute_process(
    COMMAND cmake -G ${CMAKE_GENERATOR} -S ${BLIS_DIR} -B ${CMAKE_BINARY_DIR}/blis/build_dir -DCMAKE_CONFIGURATION_TYPES=${CMAKE_CONFIGURATION_TYPES} -DBLIS_CONFIG_FAMILY=${BLIS_CONFIG_FAMILY} -DENABLE_CBLAS=${ENABLE_CBLAS} -DENABLE_THREADING=${ENABLE_THREADING} -DOpenMP_libomp_LIBRARY=${OpenMP_libomp_LIBRARY} -DBLAS_INT_SIZE=${BLAS_INT_SIZE} -DCOMPLEX_RETURN=${COMPLEX_RETURN} -DBUILD_SHARED_LIBS=${BUILD_SHARED_LIBS} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DENABLE_TRSM_PREINVERSION=${ENABLE_TRSM_PREINVERSION} -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/blis/install_package ${CompilerToolSet}
    WORKING_DIRECTORY ${BLIS_DIR}
    RESULT_VARIABLE result
    OUTPUT_VARIABLE output
    ERROR_VARIABLE error
)
if(result EQUAL 0)
    file(APPEND "${BLIS_BUILD_LOG_FILE_PATH}" "${output}.\n")
    message(STATUS "AOCL-BLAS library configuration completed successfully.")
else()
    file(APPEND "${BLIS_BUILD_LOG_FILE_PATH}" "${error}.\n")
    message(FATAL_ERROR "Error occured while AOCL-BLAS library configuration!!!.\n${error}\n")
endif()

# Execute the build command
execute_process(
    COMMAND cmake --build ${CMAKE_BINARY_DIR}/blis/build_dir --config ${CMAKE_BUILD_TYPE} --target install -j
    WORKING_DIRECTORY ${BLIS_DIR}
    RESULT_VARIABLE result
    OUTPUT_VARIABLE output
    ERROR_VARIABLE error
)

# Check the result of the build process
if(result EQUAL 0)
    file(APPEND "${BLIS_BUILD_LOG_FILE_PATH}" "${output}.\n")
    message(STATUS "AOCL-BLAS library built successfully.")
else()
    file(APPEND "${BLIS_BUILD_LOG_FILE_PATH}" "${error}.\n")
    message(FATAL_ERROR "Error occured while AOCL-BLAS library building!!!.\n${error}\n")
endif()

# Remove unnecessary directories based on the generator
if(substring_position EQUAL -1)
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_BINARY_DIR}/blis/build_dir/CMakeFiles/ShowIncludes
    )
else()
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_BINARY_DIR}/blis/build_dir/CMakeFiles
    )
endif()

# Collect object files and append to the list
string(REPLACE "\\" "/" blis_build_path "${CMAKE_BINARY_DIR}/blis/build_dir")
file(GLOB_RECURSE blis_obj_files LIST_DIRECTORIES false ${blis_build_path}/*\.${suff})
list(APPEND OBJECT_FILES ${blis_obj_files})

# Install the BLIS headers
install(DIRECTORY ${CMAKE_BINARY_DIR}/blis/install_package/include/ DESTINATION include)
