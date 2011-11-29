#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <linux/if_tun.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/select.h>
#include <stdint.h>
#include <arpa/inet.h>

#include <linux/ip.h>
#include <linux/tcp.h>
#include <linux/udp.h>


/* 
Replace ip adresses in packets on L2 level.

Setup:

tunctl -t tap1
tunctl -t tap2
brctl addif br1 tap1
brctl addif br1 eth0

ifconfig tap1 promisc up
ifconfig tap2 promisc up

ifconfig tap2 10.0.1.18 netmask 255.255.255.0

Send packets to 10.0.0.0/24 on tap2, they will appear as 192.168.14.0/24 on eth0.
Note that these values are harcoded in main.

*/


static int
tun_alloc_old(char *dev) {
    char tunname[IFNAMSIZ];

    sprintf(tunname, "/dev/%s", dev);
    return open(tunname, O_RDWR);
}


static int
tun_alloc(char *dev) {
    struct ifreq    ifr;
    int     fd;
    int     err;

    if ((fd = open("/dev/net/tun", O_RDWR)) < 0)
        return tun_alloc_old(dev);

    memset(&ifr, 0, sizeof(ifr));

    /* Flags: IFF_TUN   - TUN device (no Ethernet headers)
     *        IFF_TAP   - TAP device
     *
     *        IFF_NO_PI - Do not provide packet information
     */
    ifr.ifr_flags = IFF_TAP;
    if (*dev)
        strncpy(ifr.ifr_name, dev, IFNAMSIZ);

    if ((err = ioctl(fd, TUNSETIFF, (void*)&ifr)) < 0) {
        close(fd);
        perror("TUNSETIFF");
        return err;
    }

    strcpy(dev, ifr.ifr_name);
    return fd;
}



static size_t
write2(int fildes, const void *buf, size_t nbyte) {
    int     ret;
    size_t  n;

    n = nbyte;
    while (n > 0) {
        ret = write(fildes, buf, nbyte);
        if (ret < 0)
            return ret;

        n -= ret;
        buf += ret;
    }

    return nbyte;
}



static uint16_t
ipcheck(uint16_t *ptr, size_t len) {
    uint32_t    sum;
    uint16_t    answer;

    sum = 0;

    while (len > 1) {
        sum += *ptr++;
        len -= 2;
    }

    sum = (sum >> 16) + (sum & 0xFFFF);
    sum += (sum >> 16);
    answer = ~sum;
    
    return answer;
}


static uint16_t
check2(struct iovec *iov, int iovcnt) {
    long    sum;
    uint16_t    answer;
    struct iovec   *iovp;

    sum = 0;

    for (iovp = iov; iovp < iov + iovcnt; iovp++) {
        uint16_t *ptr;
        size_t len;

        ptr = iovp->iov_base;
        len = iovp->iov_len;

        while (len > 1) {
            sum += *ptr++;
            len -= 2;
        }

        if (len == 1) {
            u_char t[2];
            t[0] = (u_char)*ptr;
            t[1] = 0;

            sum += (uint16_t)*t;
        }

    }

    sum = (sum >> 16) + (sum & 0xFFFF);
    sum += (sum >> 16);
    answer = ~sum;
    
    return answer;
}


static void
tcpcheck(struct iphdr *iph, struct tcphdr *tcph, size_t len) {
    struct iovec iov[5];

    iov[0].iov_base = &iph->saddr;
    iov[0].iov_len = 4;
    iov[1].iov_base = &iph->daddr;
    iov[1].iov_len = 4;

    u_char  t[2];
    t[0] = 0;
    t[1] = iph->protocol;
    iov[2].iov_base = t;
    iov[2].iov_len = 2;

    uint16_t l;
    l = htons(tcph->doff * 4 + len);
    iov[3].iov_base = &l;
    iov[3].iov_len = 2;

    iov[4].iov_base = tcph;
    iov[4].iov_len = tcph->doff * 4 + len;

    tcph->check = 0;
    tcph->check = check2(iov, sizeof(iov) / sizeof(struct iovec));
}

static void
udpcheck(struct iphdr *iph, struct udphdr *udph) {
    struct iovec iov[5];

    iov[0].iov_base = &iph->saddr;
    iov[0].iov_len = 4;
    iov[1].iov_base = &iph->daddr;
    iov[1].iov_len = 4;

    u_char  t[2];
    t[0] = 0;
    t[1] = iph->protocol;
    iov[2].iov_base = t;
    iov[2].iov_len = 2;

    uint16_t l;
    l = udph->len;
    iov[3].iov_base = &l;
    iov[3].iov_len = 2;

    iov[4].iov_base = udph;
    iov[4].iov_len = ntohs(udph->len);

    udph->check = 0;
    udph->check = check2(iov, sizeof(iov) / sizeof(struct iovec));
}




static int
substitute(u_char* buf, ssize_t n, u_char* net1, u_char* net2) {

    if (buf[12] == 8 && buf[13] == 6) {
        u_char     *arp;

        arp = buf + 14;

        /* replace ip */
        if (!memcmp(arp + 14, net1, 3)) {
            memcpy(arp + 14, net2, 3);
        }

        if (!memcmp(arp + 24, net1, 3)) {
            memcpy(arp + 24, net2, 3);
        }
    }
    else if (buf[12] == 8 && buf[13] == 0) {
        struct iphdr   *iph;
        size_t      len;


        iph = (struct iphdr*)(buf + 14);
        len = iph->ihl * 4;

        /* clear crc */
        iph->check = 0;


        /* replcace ip */
        if (!memcmp(&iph->saddr, net1, 3)) {
            memcpy(&iph->saddr, net2, 3);
        }

        if (!memcmp(&iph->daddr, net1, 3)) {
            memcpy(&iph->daddr, net2, 3);
        }

        /* put new crc */
        iph->check = ipcheck((uint16_t*)iph, len);


        if (iph->protocol == 6) {
            struct tcphdr  *tcph;

            tcph = (struct tcphdr*)((u_char*)iph + len);
            tcpcheck(iph, tcph, n - ((u_char*)tcph - buf) - tcph->doff * 4);
        }
        else if (iph->protocol == 17) {
            struct udphdr  *udph;

            udph = (struct udphdr*)((u_char*)iph + len);
            udpcheck(iph, udph);
        }
    }

    return 0;
}




int
main(int argc, char **argv) {
    int     tap1;
    int     tap2;
    int     maxfd;
    char    tunname[IFNAMSIZ];
    u_char  buf[15000];
    ssize_t n;

    u_char net1[] = {192, 168, 14};
    u_char net2[] = {10, 0, 1};




    strcpy(tunname, "tap1");
    if ((tap1 = tun_alloc(tunname)) < 0) {
        goto error;
    }

    strcpy(tunname, "tap2");
    if ((tap2 = tun_alloc(tunname)) < 0) {
        goto error;
    }


    maxfd = (tap1 > tap2)? tap1 : tap2;

    while (1) {
        int     ret;
        fd_set  rd_set;
        
        FD_ZERO(&rd_set);
        FD_SET(tap1, &rd_set);
        FD_SET(tap2, &rd_set);
    
        ret = select(maxfd + 1, &rd_set, NULL, NULL, NULL);
        
        if (ret < 0 && errno == EINTR) {
            continue;
        }

        if (ret < 0) {
            perror("select()");
            goto error;
        }

        if (FD_ISSET(tap1, &rd_set)) {
            n = read(tap1, buf, sizeof(buf));
            if (n < 0)
                goto error;



            if (substitute(buf, n, net1, net2))
                goto error;




            if (write2(tap2, buf, n) < 0)
                goto error;
        }


        if (FD_ISSET(tap2, &rd_set)) {

            n = read(tap2, buf, sizeof(buf));
            if (n < 0)
                goto error;




            if (substitute(buf, n, net2, net1))
                goto error;





            if (write2(tap1, buf, n) < 0)
                goto error;
        }
    }
    

    close(tap1);
    close(tap2);


    return 0;



error:

    return 1;
}
