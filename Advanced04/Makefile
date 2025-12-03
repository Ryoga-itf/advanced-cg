CXX      := g++
CXXFLAGS := -O3 -std=c++20 -Iinclude -I../common
LDLIBS   := -lglfw -lGLEW -lGL -lIL -lILU -lILUT

SRCDIR   := src
OBJDIR   := build
TARGET   := advanced04

TYPST    := typst

SRCNAMES := \
	BlinnPhongRenderer \
	CatmullClarkSubdivision \
	CheckGLError \
	EnvironmentMap \
	GLSLProgramObject \
	GLSLShaderObject \
	HalfEdgeDataStructure \
	LoopSubdivision \
	PolygonMesh \
	ReflectionLineRenderer \
	arcball_camera \
	imgui \
	imgui_demo \
	imgui_draw \
	imgui_impl_glfw \
	imgui_impl_opengl2 \
	imgui_tables \
	imgui_widgets \
	main \
	tinyfiledialogs

SRCS := $(addprefix $(SRCDIR)/,$(addsuffix .cpp,$(SRCNAMES)))
OBJS := $(SRCS:$(SRCDIR)/%.cpp=$(OBJDIR)/%.o)

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) -o $@ $^ $(LDLIBS)

$(OBJDIR)/%.o: $(SRCDIR)/%.cpp | $(OBJDIR)
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
