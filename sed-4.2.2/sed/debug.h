// net {
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

static int sock;
static FILE *sock_file;

int gsed_debug_open_connection();
int gsed_debug_close_connection();
int gsed_debug_recv_commands(char *);
int gsed_debug_send_message(char *);

#define MSGLEN 64
// } net

extern bool debug_flag;
extern bool step_by_step;


#define BREAK_NUM 64
extern countT break_line[];


enum {
  debug_stat_invalid = 0,
  debug_stat_start = 1,
  debug_stat_break,
  debug_stat_step,
  debug_stat_prog_end,
};


int stop_check(countT line);

#if 0
int debug_cmd(int state, char *msg, struct sed_cmd *cmd);
#else
struct line;
int
debug_cmd(int state, char *msg, struct sed_cmd *cmd,
    struct line *ps,	// Pattern Space
    struct line *hs,	// Hold Space
    bool replaced	// flag for `t' command
);
#endif
