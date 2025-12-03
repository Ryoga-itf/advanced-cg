CXX      := g++
CXXFLAGS := -O3 -std=c++20 -Iinclude -I../common -I../common/imgui
LDLIBS   := -lglfw -lGLEW -lGL -lIL -lILU -lILUT

SRCDIR   := src
OBJDIR   := build
TARGET   := advanced01

TYPST    := typst

VPATH := $(SRCDIR):../common/imgui

CORE_SOURCES := \
	AbstractScene \
	CheckGLError \
	GLSLProgramObject \
	GLSLShaderObject \
	Image2OGLTexture \
	Scene01Checker2D \
	Scene02ImageSmoothing \
	Scene03WaveAnimation \
	Scene04PseudoNormal \
	Scene05EnvironmentMapping \
	Scene06 \
	TriMesh \
	arcball_camera \
	main \
	tinyfiledialogs

IMGUI_SOURCES := \
	imgui \
	imgui_draw \
	imgui_impl_glfw \
	imgui_impl_opengl3 \
	imgui_tables \
	imgui_widgets

SRCS := $(CORE_SOURCES) $(IMGUI_SOURCES)
OBJS := $(addprefix $(OBJDIR)/,$(addsuffix .o,$(SRCS)))

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) -o $@ $^ $(LDLIBS)

$(OBJDIR)/%.o: %.cpp | $(OBJDIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(OBJDIR):
	mkdir -p $@

run: $(TARGET)
	./$(TARGET)

report:
	$(TYPST) compile report/report.typ --root ..

clean:
	rm -rf $(OBJDIR) $(TARGET)

.PHONY: all run report clean
