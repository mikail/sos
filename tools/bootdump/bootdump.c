#include <stdio.h>

#pragma pack(1)
struct bootsector {
	unsigned char	jmpcode[3];
	unsigned char 	os_name[8];
	// BIOS parameter block
	unsigned short 	bytes_per_sector;
	unsigned char 	sectors_per_cluster;
	unsigned short	reserved_sectors;
	unsigned char	fat_copies;
	unsigned short	max_root_entries;
	unsigned short	small_num_of_sectors;
	unsigned char	media_descriptor;
	unsigned short	sectors_per_fat;
	unsigned short	sectors_per_track;
	unsigned short	num_of_heads;
	unsigned int	hidden_sectors;//
	unsigned int	large_num_of_sectors;//
	// ext bpm
	unsigned char	drive_number;
	unsigned char	reserved;
	unsigned char	ex_boot_signature;
	unsigned int 	volume_serial_number;
	unsigned char	volume_label[11];
	unsigned char	file_system_type[8];

	unsigned char	code[448];
	unsigned char	signature[2];
};


int main(int argc, char **argv) {
	int i;
	FILE *fp;
	struct bootsector buf;

	fp = fopen(argv[1], "rb");
	fread(&buf, 1, 512, fp);
	printf("OS name:\t\t"); for(i=0;i<8;i++) putc(buf.os_name[i], stdout); printf("\n");
	printf("bytes per sector:\t%d\n", buf.bytes_per_sector);
	printf("Sectors per cluster\t%d\n", buf.sectors_per_cluster);
	printf("Reserved sectors:\t%d\n", buf.reserved_sectors);
	printf("FAT copies number:\t%d\n", buf.fat_copies);
	printf("Max files number:\t%d\n", buf.max_root_entries);
	printf("Small num of sectors:\t%d\n", buf.small_num_of_sectors);
	printf("Media descriptor:\t0x%X\n", buf.media_descriptor);
	printf("Sectors per FAT:\t%d\n", buf.sectors_per_fat);
	printf("Sectors per track:\t%d\n", buf.sectors_per_track);
	printf("Number of heads:\t%d\n", buf.num_of_heads);
	printf("Hidden sectors number:\t%d\n", buf.hidden_sectors);
	printf("Large num of sectors:\t%d\n", buf.large_num_of_sectors);
	printf("Drive number:\t\t%d\n", buf.drive_number);
	printf("Reserved:\t\t0x%X\n", buf.reserved);
	printf("Ext boot signature:\t0x%X\n", buf.ex_boot_signature);
	printf("Volume serial number:\t0x%X\n", buf.volume_serial_number);	
	printf("Volume label:\t\t"); for(i=0;i<11;i++) putc(buf.volume_label[i],stdout); printf("\n");
	printf("File system type:\t"); for(i=0;i<8;i++) putc(buf.file_system_type[i],stdout); printf("\n");
	printf("Signature:\t\t0x%X%Xh\n", buf.signature[0], buf.signature[1]);


	
	return 0;
}
