CXX      := g++
CXXFLAGS := -O3 -std=c++20 \
						-Iinclude \
						-I../common/include \
						-I../common/include/rx \
						-I../common/imgui \

LDLIBS   := -lglfw -lGLEW -lGL -lIL -lILU -lILUT

SRCDIR   := src
OBJDIR   := build
TARGETDIR = ../bin
TARGET   := $(TARGETDIR)/advanced05

COMMON_DIR       := ../common
IMGUI_LIB_DIR    := $(COMMON_DIR)/imgui
IMGUI_LIB        := $(IMGUI_LIB_DIR)/libimgui.a

VPATH := $(SRCDIR)

SRCS := \
  deformation \
	scene \
	main

OBJS := $(addprefix $(OBJDIR)/,$(addsuffix .o,$(SRCS)))

all: $(TARGET)

$(TARGET): $(OBJS) $(IMGUI_LIB) $(TFD_LIB)
	$(CXX) -o $@ $(OBJS) $(IMGUI_LIB) $(TFD_LIB) $(LDLIBS)

$(OBJDIR)/%.o: %.cpp | $(OBJDIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(OBJDIR):
	mkdir -p $@

$(IMGUI_LIB):
	$(MAKE) -C $(IMGUI_LIB_DIR)

$(TFD_LIB):
	$(MAKE) -C $(TFD_LIB_DIR)

run: $(TARGET)
	cd $(TARGETDIR); ./$(TARGET); cd -

report:
	$(TYPST) compile report/report.typ --root ..

clean:
	rm -rf $(OBJDIR) $(TARGET)

.PHONY: all run report clean
