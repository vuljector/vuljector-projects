#include <stdarg.h>
#include <stdlib.h>

struct daemon {
  int max_logs;
};

struct daemon *dnsmasq_daemon = 0;

void die(const char *fmt, ...)
{
  (void)fmt;
  abort();
}

void fix_fd(int fd)
{
  (void)fd;
}

void my_syslog(int level, const char *fmt, ...)
{
  (void)level;
  (void)fmt;
}
