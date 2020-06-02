nasm -fwin32 helloworld.asm
# This creates an OBJ file which needs to be linked.
link /entry:main helloworld.obj /subsystem:console /nodefaultlib kernel32.lib
