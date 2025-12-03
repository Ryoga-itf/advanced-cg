CXX      := g++
CXXFLAGS := -O3 -std=c++11 \
            -I../../include \
            -I.
SRCS := \
    imgui.cpp \
    imgui_demo.cpp \
    imgui_draw.cpp \
    imgui_impl_glfw.cpp \
    imgui_impl_opengl3.cpp \
    imgui_tables.cpp \
    imgui_widgets.cpp

OBJS := $(SRCS:.cpp=.o)

LIB := libimgui.a

all: $(LIB)

$(LIB): $(OBJS)
	ar rcs $@ $^

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(LIB)

.PHONY: all clean
