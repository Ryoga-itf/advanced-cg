CXX      := g++
CXXFLAGS := -O3 -std=c++20 \
						-Iinclude \
						-I../common/include \
						-I../common/imgui \
						-I../common/tinyfiledialogs

LDLIBS   := -lglfw -lGLEW -lGL -lIL -lILU -lILUT -fopenmp

SRCDIR   := src
OBJDIR   := build
TARGET   := advanced03

COMMON_DIR       := ../common
IMGUI_LIB_DIR    := $(COMMON_DIR)/imgui
TFD_LIB_DIR      := $(COMMON_DIR)/tinyfiledialogs
IMGUI_LIB        := $(IMGUI_LIB_DIR)/libimgui.a
TFD_LIB          := $(TFD_LIB_DIR)/libtinyfiledialogs.a

VPATH := $(SRCDIR)

SRCS := \
	CheckGLError \
	EnvironmentMap \
	GLSLProgramObject \
	GLSLShaderObject \
	GeometricObject \
	Material \
	PathTracer \
	Scene \
	Sphere \
	Texture \
	Triangle \
	TriangleMesh \
	arcball_camera \
	main

OBJS := $(addprefix $(OBJDIR)/,$(addsuffix .o,$(SRCS)))

TYPST    := typst

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
	./$(TARGET)

report:
	$(TYPST) compile report/report.typ --root ..

clean:
	rm -rf $(OBJDIR) $(TARGET)

.PHONY: all run report clean
