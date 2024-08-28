#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <sys/stat.h>
#include <string.h>

#define FILENAME "BOOT    BIN"

char buffer[512 * 2880];
struct __attribute__((__packed__)) BPB {
	char skip1[11];
	unsigned short bytesPerSector;
	unsigned char sectorsPerCluster;
	unsigned short reservedSectors;
	unsigned char fats;
	unsigned short rootDirEntries;
	char skip2[3];
	unsigned short sectorsPerFAT;
} *bpb;

unsigned char *fatTable;

struct __attribute__((__packed__)) DirEntry {
	char filename[11];
	char skip3[15];
	unsigned short cluster;
	unsigned int size;
} *dirEntry;

int main() {
	int fd = open("disk.img", O_RDONLY);

	if (read(fd, buffer, 512 * 2880) != 512 * 2880) {
		close(fd);
		return 2;
	}

	bpb = (struct BPB *) buffer;
	unsigned long firstFatSector = bpb->reservedSectors;
	unsigned long firstRootDirSector = firstFatSector + ((unsigned long) bpb->fats * (unsigned long) bpb->sectorsPerFAT);
	unsigned long firstDataSector = firstRootDirSector + ((unsigned long) bpb->rootDirEntries * sizeof(struct DirEntry) / 512);
	printf("First FAT sector: \t\t%ld\n", firstFatSector);
	printf("First root dir sector: \t\t%ld\n", firstRootDirSector);
	printf("First data sector: \t\t%ld\n", firstDataSector);

	fatTable = (unsigned char *) (buffer + (firstFatSector * (unsigned long) 512));
	dirEntry = (struct DirEntry *) (buffer + (firstRootDirSector * (unsigned long) 512));

	printf("FAT: \t\t%p\n", fatTable);
	printf("Root dir: \t%p\n", dirEntry);
	printf("Data segment: \t%p\n", buffer + (firstDataSector * 512));

	unsigned short cluster = 0;
	unsigned int counter = 0;
	printf("Searching for file %s...\n", FILENAME);
	while (counter != bpb->rootDirEntries) {
		printf("Checking entry %d, file: %s\n", counter, dirEntry[counter].filename);

		if (!strncmp(dirEntry[counter].filename, FILENAME, 11)) {
			cluster = dirEntry[counter].cluster;
			break;
		}

		counter++;
	}

	printf("File content begins on cluster: %hu\n", cluster);
	while (cluster != 0 && cluster <= 0xff0) {
		char *fat_cluster_data = buffer + (firstDataSector * 512) + ((((unsigned long) cluster - 2) * (unsigned long) bpb->sectorsPerCluster) * 512);
		printf("Cluster %d, data:\n", cluster);
		fflush(stdout);
		write(STDOUT_FILENO, fat_cluster_data, (unsigned long) bpb->sectorsPerCluster * 512);
		putchar('\n');

		unsigned int fatOffset = cluster + (cluster / 2);
		unsigned short newCluster = *((unsigned short *) &fatTable[fatOffset]);
		newCluster = (cluster & 1) ? newCluster >> 4 : newCluster & 0xfff;
		cluster = newCluster;
	}

	if (cluster < 0xff8) {
		printf("Got %hu cluster\n", cluster);
		close(fd);
		return 1;
	}
	
	printf("%hu means end of the file\n", cluster);

	close(fd);
}