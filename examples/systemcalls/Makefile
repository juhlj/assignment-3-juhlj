CC = gcc
CFLAGS = -g
TARGET = sys_assignment
SOURCE = $(wildcard *.c)
INCLUDES = $(wildcard *.h)
default:
	$(CC) -o $(TARGET) $(SOURCE) $(CFLAGS) $(INCLUDES)
clean:
	rm -f $(TARGET) $(wildcard *.o)
