#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <syslog.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>

int main(int argc, char *argv[]) {
	char *file, *str;

	int fd, len, err;

		if (argc != 3) {
			printf("Usage: ./writer writefile writestr\n");
			syslog(LOG_ERR, "%s", "Invalid arguments\n");
			exit(1);
		}

	file = argv[1];
	str = argv[2];


	fd = open(file, O_RDWR | O_CREAT, 0644); //perms
		if (fd < 0)  {
			syslog(LOG_ERR, "failed to open %s: error %s\n", file, strerror(errno));
			exit(1);
		}

	syslog(LOG_DEBUG, "Writing %s to %s", str, file);

	len = strlen(str); //length of string to write to file
	err = write(fd, str, len);
		if (err < 0 || err != len) {
			syslog(LOG_ERR, "Writing %s to %s failed with return value %d", str, file, err);
				if (err < 0) syslog(LOG_ERR, "%s", strerror(errno)); //if errno set, log the error
									     //
			exit(1);
		};

	close(fd);
}
