#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/i2c.h>
#include <linux/i2c-dev.h>
#include <errno.h>
#include <string.h>

int openI2C(char *bus, int address) {
	int handle = open(bus, O_RDWR);
	if(handle >= 0) 
		if(ioctl(handle, I2C_SLAVE, 0x70) < 0) return -2;
	return handle;
}

void writeBuf(int handle, u_char *buf, int count) {
	int written;
	if((written = write(handle, buf, count)) != count) {
		printf("%s\n", strerror(errno));
		printf("Failed to write %d bytes to 0x70 (%d)\n", count, written);

	}
}

int closeI2C(int bus) {
	close(bus);
}

#ifdef RUN_AS_MAIN
int main(int argc, char ** argv) {
	int bus;
	u_char frame[17] = {0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00 };
	printf("Opening I2C bus\n");
	bus = openI2C("/dev/i2c-1", 0x70); 
	
	printf("Sending sequence to 0x70\n");
	writeByte(bus, 0x21);
	writeByte(bus, 0x81);
	writeByte(bus, 0xEb);
	writeBuf(bus, frame, 17);

	printf("Done, closing I2C bus\n");
	close(bus);
}
#endif
