#
# Copyright 2015 gRPC authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

HOST_SYSTEM = $(shell uname | cut -f 1 -d_)
SYSTEM ?= $(HOST_SYSTEM)
CXX = g++
INCLUDE_FLAGS= -I include/ -I protos/
CPPFLAGS += `pkg-config --cflags protobuf grpc ` ${INCLUDE_FLAGS}
CXXFLAGS += -std=c++11 -g
ifeq ($(SYSTEM),Darwin)
LDFLAGS += -L/usr/local/lib `pkg-config --libs protobuf grpc++`\
           -pthread\
           -lgrpc++_reflection\
           -ldl
else
LDFLAGS += -L/usr/local/lib `pkg-config --libs protobuf grpc++`\
           -pthread\
           -Wl,--no-as-needed -lgrpc++_reflection -Wl,--as-needed\
           -ldl
endif
PROTOC = protoc
GRPC_CPP_PLUGIN = grpc_cpp_plugin
GRPC_CPP_PLUGIN_PATH ?= `which $(GRPC_CPP_PLUGIN)`

BINARIES= pfsClient metadataManager fileServer testClient1 testClient2 testClient3 test2

PROTOS_PATH = protos

vpath %.proto $(PROTOS_PATH)

all: system-check ${BINARIES}

PROTOS_FILES = $(wildcard ${PROTOS_PATH}/*.proto)
PROTOS_CPP_HEADERS = $(PROTOS_FILES:%.proto=%.pb.h)
PROTOS_CPP_FILES = $(PROTOS_FILES:%.proto=%.pb.cc)
PROTOS_OBJS = $(PROTOS_FILES:%.proto=%.pb.o)
GRPC_PROTOS_CPP_HEADERS =  $(PROTOS_FILES:%.proto=%.grpc.pb.h)
GRPC_PROTOS_CPP_FILES =  $(PROTOS_FILES:%.proto=%.grpc.pb.cc)
GRPC_PROTOS_OBJS = $(PROTOS_FILES:%.proto=%.grpc.pb.o)
COMMON_FILES = $(wildcard common/*.cpp)
COMMON_OBJS = $(COMMON_FILES:%.cpp=%.o)
PFSCLIENT_FILES = $(wildcard client/*.cpp)
PFSCLIENT_OBJS = $(PFSCLIENT_FILES:%.cpp=%.o)
METADATA_MANAGER_FILES = $(wildcard metadata_manager/*.cpp)
METADATA_MANAGER_OBJS = $(METADATA_MANAGER_FILES:%.cpp=%.o)
FILE_SERVER_FILES = $(wildcard file_server/*.cpp)
FILE_SERVER_OBJS = $(FILE_SERVER_FILES:%.cpp=%.o)

pfsClient: ${PROTOS_OBJS} ${GRPC_PROTOS_OBJS} ${COMMON_OBJS} ${PFSCLIENT_OBJS} pfs-client.o
	$(CXX) $^ $(LDFLAGS) ${INCLUDE_FLAGS} -o $@ 
	
testClient1: ${PROTOS_OBJS} ${GRPC_PROTOS_OBJS} ${COMMON_OBJS} ${PFSCLIENT_OBJS} test1-c1.o
	$(CXX) $^ $(LDFLAGS) ${INCLUDE_FLAGS} -o $@ 
	
testClient2: ${PROTOS_OBJS} ${GRPC_PROTOS_OBJS} ${COMMON_OBJS} ${PFSCLIENT_OBJS} test1-c2.o
	$(CXX) $^ $(LDFLAGS) ${INCLUDE_FLAGS} -o $@ 
	
testClient3: ${PROTOS_OBJS} ${GRPC_PROTOS_OBJS} ${COMMON_OBJS} ${PFSCLIENT_OBJS} test1-c3.o
	$(CXX) $^ $(LDFLAGS) ${INCLUDE_FLAGS} -o $@ 
	
test2: ${PROTOS_OBJS} ${GRPC_PROTOS_OBJS} ${COMMON_OBJS} ${PFSCLIENT_OBJS} test2-c1.o
	$(CXX) $^ $(LDFLAGS) ${INCLUDE_FLAGS} -o $@ 
	
metadataManager : ${PROTOS_OBJS} ${GRPC_PROTOS_OBJS} ${COMMON_OBJS} ${METADATA_MANAGER_OBJS} pfs_MM.o
	$(CXX) $^ $(LDFLAGS) ${INCLUDE_FLAGS} -o $@
	
fileServer :  ${PROTOS_OBJS} ${GRPC_PROTOS_OBJS} ${COMMON_OBJS} ${FILE_SERVER_OBJS} pfs_file_server.o
	$(CXX) $^ $(LDFLAGS) ${INCLUDE_FLAGS} -o $@

#greeter_server: helloworld.pb.o helloworld.grpc.pb.o greeter_server.o
#	$(CXX) $^ $(LDFLAGS) -o $@

.PRECIOUS: %.grpc.pb.cc
%.grpc.pb.cc: %.proto
	$(PROTOC) -I $(PROTOS_PATH) --grpc_out=${PROTOS_PATH} --plugin=protoc-gen-grpc=$(GRPC_CPP_PLUGIN_PATH) $<

.PRECIOUS: %.pb.cc
%.pb.cc: %.proto
	$(PROTOC) -I $(PROTOS_PATH) --cpp_out=${PROTOS_PATH} $<

clean:
	rm -f ${COMMON_OBJS} ${PROTOS_CPP_FILES} ${PROTOS_CPP_HEADERS} ${PROTOS_OBJS} \
	 ${GRPC_PROTOS_CPP_FILES} ${GRPC_PROTOS_CPP_HEADERS} ${GRPC_PROTOS_OBJS} \
	 *.o */*.o *.pb.cc *.pb.h ${BINARIES}


# The following is to test your system and ensure a smoother experience.
# They are by no means necessary to actually compile a grpc-enabled software.

PROTOC_CMD = which $(PROTOC)
PROTOC_CHECK_CMD = $(PROTOC) --version | grep -q libprotoc.3
PLUGIN_CHECK_CMD = which $(GRPC_CPP_PLUGIN)
HAS_PROTOC = $(shell $(PROTOC_CMD) > /dev/null && echo true || echo false)
ifeq ($(HAS_PROTOC),true)
HAS_VALID_PROTOC = $(shell $(PROTOC_CHECK_CMD) 2> /dev/null && echo true || echo false)
endif
HAS_PLUGIN = $(shell $(PLUGIN_CHECK_CMD) > /dev/null && echo true || echo false)

SYSTEM_OK = false
ifeq ($(HAS_VALID_PROTOC),true)
ifeq ($(HAS_PLUGIN),true)
SYSTEM_OK = true
endif
endif

system-check:
ifneq ($(HAS_VALID_PROTOC),true)
	@echo " DEPENDENCY ERROR"
	@echo
	@echo "You don't have protoc 3.0.0 installed in your path."
	@echo "Please install Google protocol buffers 3.0.0 and its compiler."
	@echo "You can find it here:"
	@echo
	@echo "   https://github.com/google/protobuf/releases/tag/v3.0.0"
	@echo
	@echo "Here is what I get when trying to evaluate your version of protoc:"
	@echo
	-$(PROTOC) --version
	@echo
	@echo
endif
ifneq ($(HAS_PLUGIN),true)
	@echo " DEPENDENCY ERROR"
	@echo
	@echo "You don't have the grpc c++ protobuf plugin installed in your path."
	@echo "Please install grpc. You can find it here:"
	@echo
	@echo "   https://github.com/grpc/grpc"
	@echo
	@echo "Here is what I get when trying to detect if you have the plugin:"
	@echo
	-which $(GRPC_CPP_PLUGIN)
	@echo
	@echo
endif
ifneq ($(SYSTEM_OK),true)
	@false
endif
