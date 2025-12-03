CXX      := g++
CXXFLAGS := -O3 -std=c++11 \
            -I../../include \
            -I.

SRCS := tinyfiledialogs.c

OBJS := $(SRCS:.c=.o)

LIB := libtinyfiledialogs.a

all: $(LIB)

$(LIB): $(OBJS)
	ar rcs $@ $^

%.o: %.c
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(LIB)

.PHONY: all clean
