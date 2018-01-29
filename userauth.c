#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main () {
	FILE *f;
	f = fopen("user.txt", "r");
	char buff[100];

	if(f == NULL) return -1;

	char* user = getenv("username");
	char* pass = getenv("password");
	char* user2;
	char* pass2;

	while(fgets (buff, 100, f)) {
		user2 = strtok(buff, ":");
		pass2 = strtok(NULL, ":");
		if(pass2[strlen(pass2)-1] == '\n') pass2[strlen(pass2)-1] = '\0';
		if(!strcmp(user, user2))
			if(!strcmp(pass, pass2))
				return 0;
			else
				return 1;
		
	}
	return 2;
}
