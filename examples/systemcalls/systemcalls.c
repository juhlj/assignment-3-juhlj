#include "systemcalls.h"

/**
 * @param cmd the command to execute with system()
 * @return true if the command in @param cmd was executed
 *   successfully using the system() call, false if an error occurred,
 *   either in invocation of the system() call, or if a non-zero return
 *   value was returned by the command issued in @param cmd.
*/
bool do_system(const char *cmd)
{

	return system(cmd) ? false : true ;


}

/**
* @param count -The numbers of variables passed to the function. The variables are command to execute.
*   followed by arguments to pass to the command
*   Since exec() does not perform path expansion, the command to execute needs
*   to be an absolute path.
* @param ... - A list of 1 or more arguments after the @param count argument.
*   The first is always the full path to the command to execute with execv()
*   The remaining arguments are a list of arguments to pass to the command in execv()
* @return true if the command @param ... with arguments @param arguments were executed successfully
*   using the execv() call, false if an error occurred, either in invocation of the
*   fork, waitpid, or execv() command, or if a non-zero return value was returned
*   by the command issued in @param arguments with the specified arguments.
*/

bool do_exec(int count, ...)
{

	    pid_t pid;
	    va_list args;
	    va_start(args, count);
	    char * command[count+1];
	    int i, ret, status;
	    for(i=0; i<count; i++)
	    {
		command[i] = va_arg(args, char *);
	    }
	    command[count] = NULL;
	    // this line is to avoid a compile warning before your implementation is complete
	    // and may be removed


	/*
	 * TODO:
	 *   Execute a system command by calling fork, execv(),
	 *   and wait instead of system (see LSP page 161).
	 *   Use the command[0] as the full path to the command to execute
	 *   (first argument to execv), and use the remaining arguments
	 *   as second argument to the execv() command.
	 *
	 *
	*/
	    pid = fork();
		    if (pid < 0) { //fatal
			printf("fork failed %s\n", strerror(errno));
			exit(1);
		    }	    
		if (!pid) {

			ret = execv(command[0], command);
				if (ret < 0) {
					printf("execv failed with %s %s\n", command[0], strerror(errno));
					exit(1); //exit child process
				}

		} 
		if (waitpid(pid, &status, 0) < 0) {
				printf("wait returned %s\n", strerror(errno));
		}
		va_end(args);

		//fprintf(stdout, "WIFEXITED:%d WEXITSTATUS %d")
		return WEXITSTATUS(status) ? false : true;
}

/**
* @param outputfile - The full path to the file to write with command output.
*   This file will be closed at completion of the function call.
* All other parameters, see do_exec above
*/
bool do_exec_redirect(const char *outputfile, int count, ...)
{
	va_list args;
	va_start(args, count);
	char * command[count+1];
	int i, fd, ret, dups[2];
	pid_t pid;
		for(i=0; i<count; i++)
		{
		command[i] = va_arg(args, char *);
		}
	fd = open(outputfile, O_CREAT | O_WRONLY | O_APPEND, 0644); //read for others, write for owner
		if (fd < 0) {
			printf("open: %s\n", strerror(errno));
		}
	command[count] = NULL;
	// this line is to avoid a compile warning before your implementation is complete
	// and may be removed
	for (i = 0;i < 2;i++) {
		dups[i] = dup2(fd, i + 1);
			if (dups[i] < 0) {
				printf("dup2 %s\n", strerror(errno));
			}
	}

	pid = fork();
		if (pid < 0) {
			printf("fork %s\n", strerror(errno));
		}
		if (pid == 0) {
			ret = execv(command[0], command);
				if (ret < 0) {
					printf("execv %s\n", strerror(errno));
				}
		}

	/*
	* TODO
	*   Call execv, but first using https://stackoverflow.com/a/13784315/1446624 as a refernce,
	*   redirect standard out to a file specified by outputfile.
	*   The rest of the behaviour is same as do_exec()
	*
	*/
	
	va_end(args);
	close(fd);
	return true;
}

