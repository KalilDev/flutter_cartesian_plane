#include <stdio.h>
#include <stdlib.h>

typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;

uint8_t alpha_val(uint32_t color) {
    return (uint8_t)((0xff000000 & color) >> 24);
}

uint8_t red_val(uint32_t color) {
    return (uint8_t)((0x00ff0000 & color) >> 16);
}

uint8_t green_val(uint32_t color) {
    return (uint8_t)((0x0000ff00 & color) >> 8);
}

uint8_t blue_val(uint32_t color) {
    return (uint8_t)((0x000000ff & color) >> 0);
}

uint8_t* process_image(uint16_t width, uint16_t height, uint32_t *colors, uint8_t def_count, uint16_t *values, uint32_t value_count, uint8_t line_size) {
    size_t byte_count = 4 * width * height;
    uint8_t* bytes = (uint8_t*)calloc(byte_count, sizeof(uint8_t));

    size_t size_of_row = 4 * width;
    size_t y_start_at_i[def_count];
    for (int i = 0; i < def_count; i++) {
        y_start_at_i[i] = i*width;
    }

    // There are two loops because data.values is an 2d array
    for (size_t x = 0; x < width; x++) {
        for (uint8_t i = 0; i < def_count; i++) {
            uint16_t y = values[x + y_start_at_i[i]];
            uint32_t color = colors[i];
            size_t initial_byte_i = (size_t)y*size_of_row + x*4;
            for (uint8_t py = 0; py < line_size; py++) {
                uint8_t lsb = py & 0x1;
                char sign_bit = -1 * lsb + (~lsb & 0x1);
                char py_offset = sign_bit * ((py + lsb) >> 0x1);
                size_t byte_i = (size_t)(initial_byte_i + py_offset * (long int)size_of_row);
                //printf("%lu\n", byte_i);
                if (byte_i >= byte_count) continue;
                bytes[byte_i] = red_val(color);
                bytes[byte_i + 1] = green_val(color);
                bytes[byte_i + 2] = blue_val(color);
                bytes[byte_i + 3] = alpha_val(color);
            }
        }
    }
    return bytes;
}

int main() {
    unsigned int imgSize = 1000;
    uint32_t colors[2] = { 0xFFFFFFFF, 0xFF00CCFF};
    uint16_t values[imgSize  * 2];
    for (int i = 0; i < imgSize * 2; i++) {
        if (i >= imgSize) {
            values[i] = 200;
        } else {
            values[i] = 500;
        }
    }

    uint8_t* img = process_image(imgSize, imgSize, &(colors[0]), 2, &(values[0]), imgSize * 2, 3);
    const int MaxColorComponentValue=255;
    char *comment="# ";/* comment should start with # */
    FILE * fp;
    char *filename="new1.ppm";
    fp= fopen(filename,"wb"); /* b -  binary mode */
    fprintf(fp,"P6\n %s\n %d\n %d\n %d\n",comment,imgSize,imgSize,MaxColorComponentValue);
    static unsigned char color[3];
    for (int y = 0; y < imgSize; y++) {
        for (int x = 0; x < imgSize; x++) {
            int idx = (y*imgSize + x)*4;
            color[0] = img[idx + 1];
            color[1] = img[idx + 2];
            color[2] = img[idx + 3];
            fwrite(color,1,3,fp);
        }
    }
    fclose(fp);
    free(img);
    return 0;
}

