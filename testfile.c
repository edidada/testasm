/* Exclusive create of test.txt, write one 'a', then close.
 * Based on docs/doc.txt: fopen("test.txt", "wx") fails when the file
 * already exists, so it never truncates or overwrites an existing file. */
#include <stdio.h>

int main(void)
{
    FILE *fp = fopen("test.txt", "wx");

    if (fp == NULL) {
        perror("create failed");
        return 1;
    }

    if (fputc('a', fp) == EOF) {
        perror("write failed");
        fclose(fp);
        return 1;
    }

    if (fclose(fp) == EOF) {
        perror("close failed");
        return 1;
    }

    return 0;
}
