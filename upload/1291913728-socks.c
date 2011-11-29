#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/wait.h>
#include <signal.h>
#include <netdb.h>
#include <fcntl.h>

#ifndef MSG_WAITALL
#define MSG_WAITALL 0x100
#endif

#define MAXDATASIZE 96000 /* max number of bytes we can get at once  */
#define BACKLOG 10     /* how many pending connections queue will hold */
void sigchld_handler(int s) {
	while (waitpid(-1, NULL, WNOHANG) > 0)
		;
}

/* only works for IPv4 */
static int addr_print(char *addr) {
	u_int8_t split[4];
	u_int32_t ip;
	u_int32_t *x = (u_int32_t *) addr;

	ip = ntohl(*x);
	split[0] = (ip & 0xff000000) >> 24;
	split[1] = (ip & 0x00ff0000) >> 16;
	split[2] = (ip & 0x0000ff00) >> 8;
	split[3] = (ip & 0x000000ff);
	printf("%d.%d.%d.%d\n", split[0], split[1], split[2], split[3]);
	return 0;
}

int sendall(int s, char *buf, int *len) {
	int total = 0; /* how many bytes we've sent */
	int bytesleft = *len; /* how many we have left to send */
	int n = 0;

	while (total < *len) {
		n = send(s, buf+total, bytesleft, 0);
		if (n == -1) {
			break;
		}
		total += n;
		bytesleft -= n;
	}

	*len = total; /* return number actually sent here */

	return n==-1 ? -1 : 0; /* return -1 on failure, 0 on success */
}

int senderror(int sock, int error) {
	char buf[3];
	buf[0] = 5; /* protocol version: X'05' */
	buf[1] = error; /* Reply field X'00' - X'FF' */
	buf[2] = 0; /* RESERVED */

	int len = 3;
	return sendall(sock, buf, &len);
}

int main(int argc, char* argv[]) {
	
	char *host = NULL;
	int myport = 1119;    /* the port users will be connecting to */

	if (argc == 2) {
		myport = atoi(argv[1]);
	}
	else if (argc == 3) {
		host = argv[1];
		myport = atoi(argv[2]);
	}

	int ipnum = -1; /* number of ip adresses */
	struct hostent *host_ent = NULL;
	if (host != NULL) {
		if ((host_ent=gethostbyname(host)) == NULL) { /* get the host info */
			herror("gethostbyname");
			exit(1);
		}

		ipnum = 0;
		while (host_ent->h_addr_list[ipnum])
			ipnum++;
	}


#if 1
    /* run as daemon */
    int i = fork();
    if (i < 0) exit(1); /* fork error */
    if (i > 0) exit(0); /* parent exits */
    /* child (daemon) continues */

    setsid(); /* obtain a new process group */

    for (i = getdtablesize(); i >= 0; --i) close(i); /* close all descriptors */
    i = open("/dev/null", O_RDWR); /* open stdin */
    dup(i); /* stdout */
    dup(i); /* stderr */

    /* file creation Mask */
    umask(027);

    /* running directory */
    chdir("/");
#endif

	
	printf("ipnum= %d\n", ipnum);
	srand((unsigned int) clock());

	int sockfd, new_fd; /* listen on sock_fd, new connection on new_fd */
	struct sockaddr_in my_addr; /* my address information */
	struct sockaddr_in their_addr; /* connector's address information */
	socklen_t sin_size;
	struct sigaction sa;
	int yes=1;

	if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
		perror("socket");
		exit(1);
	}

	if (setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(int)) == -1) {
		perror("setsockopt");
		exit(1);
	}

	my_addr.sin_family = AF_INET; /* host byte order */
	my_addr.sin_port = htons(myport); /* short, network byte order */
	my_addr.sin_addr.s_addr = INADDR_ANY; /* automatically fill with my IP */
	memset(my_addr.sin_zero, '\0', sizeof my_addr.sin_zero);

	if (bind(sockfd, (struct sockaddr *)&my_addr, sizeof my_addr) == -1) {
		perror("bind");
		exit(1);
	}

	if (listen(sockfd, BACKLOG) == -1) {
		perror("listen");
		exit(1);
	}

	sa.sa_handler = sigchld_handler; /* reap all dead processes */
	sigemptyset(&sa.sa_mask);
	sa.sa_flags = SA_RESTART;
	if (sigaction(SIGCHLD, &sa, NULL) == -1) {
		perror("sigaction");
		exit(1);
	}

	while (1) { /* main accept() loop */
		sin_size = sizeof their_addr;
		if ((new_fd = accept(sockfd, (struct sockaddr *)&their_addr, &sin_size))
				== -1) {
			perror("accept");
			continue;
		}
		printf("got connection from %s\n", inet_ntoa(their_addr.sin_addr));
		
		int nextip = (unsigned int) (rand() / ((double) RAND_MAX + 1) * ipnum);
		if (!fork()) { /* this is the child process */
		/*			close(sockfd); // child doesn't need the listener */

			char buf[MAXDATASIZE];

			/* The version identifier/method selection message */
			int numbytes;
			if ((numbytes=recv(new_fd, buf, MAXDATASIZE, 0)) == -1) {
				perror("recv");
				exit(1);
			}

			if (buf[0] != 5) {
				senderror(new_fd, 1); /* general SOCKS server failure */
				fprintf(stderr, "SOCKS version %d not supported\n", buf[0]);
				close(new_fd);
				exit(1);
			}

			int nmethods = buf[1];
/*			if (nmethods > 1) { */
/*				// Read other methods */
/*				if ((numbytes=recv(sockfd, buf + 3, nmethods - 1, MSG_WAITALL)) */
/*						== -1) { */
/*					perror("recv"); */
/*					exit(1); */
/*				} */
/*			} */

			/* Find X'00' NO AUTHENTICATION REQUIRED */
			int noauthfound = 0;
            int i;
			for (i = 0; i < nmethods; i++) {
				if (buf[i + 2] == 0) {
					noauthfound = 1;
					break;
				}
			}

			if (!noauthfound) {
				/* If the selected METHOD is X'FF', none of the methods listed by the */
				/* client are acceptable, and the client MUST close the connection. */
				buf[1] = 0xFF;
				send(new_fd, buf, 2, 0);
				fprintf(stderr, "NO AUTHENTICATION REQUIRED not supported by the client\n");
				close(new_fd);
				exit(1);
			}

			/* Send the METHOD selection message */
			buf[1] = 0; /* X'00' NO AUTHENTICATION REQUIRED */
			if (send(new_fd, buf, 2, 0) == -1) {
				perror("send");
				close(new_fd);
				exit(1);
			}

			/* Read the SOCKS request */
			if ((numbytes=recv(new_fd, buf, 4, MSG_WAITALL)) == -1) {
				perror("recv");
				close(new_fd);
				exit(1);
			}

			if (buf[0] != 5) {
				senderror(new_fd, 1); /* general SOCKS server failure */
				fprintf(stderr, "SOCKS version %d not supported\n", buf[0]);
				close(new_fd);
				exit(1);
			}

			if (buf[1] != 1) {
				senderror(new_fd, 7); /* Command not supported */
				fprintf(stderr, "Command %d not supported\n", (unsigned int) buf[1]);
				close(new_fd);
				exit(1);
			}

			if (buf[3] != 1 && buf[3] != 3) {
				senderror(new_fd, 8); /* Address type not supported */
				fprintf(stderr, "Address type %d not supported\n", buf[3]);
				close(new_fd);
				exit(1);
			}

			struct hostent *he;
			struct sockaddr_in their_addr; /* connector's address information */

			if (buf[3] == 1) {
				/* IP V4 address: X'01' */

				/* Read IP:port */
				if ((numbytes=recv(new_fd, buf, 6, MSG_WAITALL)) == -1) {
					perror("recv");
					senderror(new_fd, 1); /* general SOCKS server failure */
					close(new_fd);
					exit(1);
				}

				memcpy(&their_addr.sin_addr, buf, 4);
				memcpy(&their_addr.sin_port, buf + 4, 2); /* short, network byte order */
				
				printf("connecting to %s %d...\n", inet_ntoa(their_addr.sin_addr), ntohs(their_addr.sin_port));

			} else if (buf[3] == 3) {
				/* DOMAINNAME: X'03' */

				if ((numbytes=recv(new_fd, buf, 1, MSG_WAITALL)) == -1) {
					perror("recv");
					senderror(new_fd, 1); /* general SOCKS server failure */
					close(new_fd);
					exit(1);
				}
				int domainlen = buf[0];
				if ((numbytes=recv(new_fd, buf, domainlen + 2, MSG_WAITALL))
						== -1) {
					perror("recv");
					senderror(new_fd, 1); /* general SOCKS server failure */
					close(new_fd);
					exit(1);
				}

				memcpy(&their_addr.sin_port, buf + domainlen, 2); /* short, network byte order */

				buf[domainlen] = '\0';
				printf("connecting to %s %d...\n", buf, ntohs(their_addr.sin_port));

				if ((he=gethostbyname(buf)) == NULL) { /* get the host info  */
					herror("gethostbyname");
					senderror(new_fd, 4); /* Host unreachable */
					fprintf(stderr, "Host %s unreachable\n", buf);
					close(new_fd);
					exit(1);
				}
				their_addr.sin_addr = *((struct in_addr *)he->h_addr);
			}

			their_addr.sin_family = AF_INET; /* host byte order  */
			memset(their_addr.sin_zero, '\0', sizeof their_addr.sin_zero);

			/*>>>>>>>>> */
			if ((sockfd = socket(PF_INET, SOCK_STREAM, 0)) == -1) {
				perror("socket");
				senderror(new_fd, 1); /* general SOCKS server failure */
				close(new_fd);
				exit(1);
			}
			
			
			if (setsockopt(sockfd, SOL_SOCKET, SO_KEEPALIVE, &yes, sizeof(int)) == -1) {
				perror("setsockopt");
				senderror(new_fd, 1); /* general SOCKS server failure */
				close(new_fd);
				exit(1);
			}
			
			
			/* Bind to the random ip */
			if (ipnum > 0 && (ntohs(their_addr.sin_port) == 80 || ntohs(their_addr.sin_port) == 8080)) {
				my_addr.sin_family = AF_INET; /* host byte order */
				my_addr.sin_port = 0; /* short, network byte order */
				printf("bind to ");
				addr_print(host_ent->h_addr_list[nextip]);
				my_addr.sin_addr.s_addr
						= *((u_int32_t*) host_ent->h_addr_list[nextip]); /* automatically fill with my IP */
				memset(my_addr.sin_zero, '\0', sizeof my_addr.sin_zero);

				if (bind(sockfd, (struct sockaddr *)&my_addr, sizeof my_addr) == -1) {
					perror("bind");
					exit(1);
				}
			}


			if (connect(sockfd, (struct sockaddr *)&their_addr,
					sizeof their_addr) == -1) {
				perror("connect");
				if (errno == ECONNREFUSED)
					senderror(new_fd, 5); /* Connection refused */
				else if (errno == ETIMEDOUT)
					senderror(new_fd, 6); /* TTL expired */
				else if (errno == ENETUNREACH)
					senderror(new_fd, 3); /* Network unreachable */
				else
					senderror(new_fd, 1); /* general SOCKS server failure */
				close(new_fd);
				exit(1);
			}

			printf("connected to %s %d\n", inet_ntoa(their_addr.sin_addr), ntohs(their_addr.sin_port));

			/* Send socks response */
			buf[0] = 5;
			buf[1] = 0; /* succeeded */
			buf[2] = 0;
			buf[3] = 1; /* IP V4 address */

			struct sockaddr_in this_addr; /* own address information */
			socklen_t namelen = sizeof(struct sockaddr_in);
			if (getsockname(sockfd, (struct sockaddr*) &this_addr, &namelen) == -1) {
				perror("getsockname");
				senderror(new_fd, 1); /* general SOCKS server failure */
				close(new_fd);
				exit(1);
			}

			memcpy(buf + 4, &this_addr.sin_addr, 4);
			memcpy(buf + 8, &this_addr.sin_port, 2);

			if ((numbytes=send(new_fd, buf, 10, 0)) == -1) {
				perror("send");
				senderror(new_fd, 1); /* general SOCKS server failure */
				close(new_fd);
				exit(1);
			}

			int fdmax = sockfd;

			/* main loop */
			for (;;) {

				fd_set read_fds;
				FD_ZERO(&read_fds);
				FD_SET(new_fd, &read_fds);
				FD_SET(sockfd, &read_fds);

				if (select(fdmax+1, &read_fds, NULL, NULL, NULL) == -1) {
					perror("select");
					exit(1);
				}

                int i;
				for (i = new_fd; i <= fdmax; i++) {
					if (FD_ISSET(i, &read_fds)) { /* we got one!! */

						/* handle data from a client */
						if ((numbytes = recv(i, buf, sizeof buf, 0)) <= 0) {
							/* got error or connection closed by client */
							if (numbytes == 0) {
								/* connection closed */
								printf("socket %d hung up\n", i);
							} else {
								perror("recv");
							}
							close(sockfd);
							close(new_fd);
							exit(0); /* bye! */
                        } else {
                            
                            /* DEBUG */
                            /*if (i == new_fd) {
                                fprintf(stderr, "%d>>>>>>> ", getpid());
                                for (int j = 0; j < numbytes; j++) {
                                    fputc(buf[j], stderr);
                                }
                                fprintf(stderr, "\n");
                            }
                            else {
                                fprintf(stderr, "%d<<<<<<< ", getpid());
                                for (int j = 0; j < numbytes; j++) {
                                    fputc(buf[j], stderr);
                                }
                                fprintf(stderr, "\n");
                            }*/

                            /* we got some data from a client */
                            if (sendall((i == new_fd) ? sockfd : new_fd, buf,
                                        &numbytes) == -1) {


                                perror("sendall");
                                close(sockfd);
                                close(new_fd);
                                exit(1); /* bye! */
                            }
                        }

					}
				}
			}

			/*<<<<<<<<< */

		}
		close(new_fd); /* parent doesn't need this */
	}

	return 0;
}
