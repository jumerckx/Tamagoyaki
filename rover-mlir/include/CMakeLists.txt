##===- CMakeLists.txt - ---------------------------------------*- cmake -*-===//
##
## Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
## See https://llvm.org/LICENSE.txt for license information.
## SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
##
##===----------------------------------------------------------------------===//

add_subdirectory(Comb)
set(COMB_GENERATED_HEADERS ${COMB_GENERATED_HEADERS} PARENT_SCOPE)
add_subdirectory(Datapath)
set(DATAPATH_GENERATED_HEADERS ${DATAPATH_GENERATED_HEADERS} PARENT_SCOPE)
add_subdirectory(HW)
set(HW_GENERATED_HEADERS ${HW_GENERATED_HEADERS} PARENT_SCOPE)
add_subdirectory(Rover)
set(ROVER_GENERATED_HEADERS ${ROVER_GENERATED_HEADERS} PARENT_SCOPE)