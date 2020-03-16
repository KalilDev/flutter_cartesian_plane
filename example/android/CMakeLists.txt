cmake_minimum_required(VERSION 3.4.1)  # for example

add_library( processImage

             # Sets the library as a shared library.
             SHARED

             # Provides a relative path to your source file(s).
             ../../lib/computation/ffi/process_image.c )

