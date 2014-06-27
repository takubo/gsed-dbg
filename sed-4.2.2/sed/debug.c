#include "sed.h"
#include "debug.h"
#include <stdio.h>
#include <stdlib.h>

// return value of proc_debug_command()
enum {
  MORE_CMD,
  PROC_RUN,
  PROC_CONT,
  PROC_QUIT,
  INVALID_CMD,
};

static int proc_debug_command(char *, char *);

/* Sed operates a line at a time. */
struct line {
  char *text;		/* Pointer to line allocated by malloc. */
  char *active;		/* Pointer to non-consumed part of text. */
  size_t length;	/* Length of text (or active, if used). */
  size_t alloc;		/* Allocated space for active. */
  bool chomped;		/* Was a trailing newline dropped? */
  mbstate_t mbstate;
};

// /* Have we done any replacements lately?  This is used by the `t' command. */
// extern bool replaced = false;
// /* The current output file (stdout if -i is not being used. */
// extern struct output output_file;
// /* The `current' input line. */
// extern struct line line;
// /* An input line used to accumulate the result of the s and e commands. */
// extern struct line s_accum;
// /* An input line that's been stored by later use by the program */
// extern struct line hold;


bool debug_flag;
bool step_by_step = false;


countT break_line[BREAK_NUM] = {0};


int
stop_check(countT line)
{
  int i;

  if (step_by_step)
    return debug_stat_step;

  for (i = 0; i < BREAK_NUM; i++)
      if (line == break_line[i])
	{
	  fprintf(stderr, "[Stop at break Point] : line = %d\n", line);
	  return debug_stat_break;
	}

  return debug_stat_invalid;
}

#define RES_HDDR "gsed : "

int
debug_cmd(int state, char *msg, struct sed_cmd *cmd,
    struct line *ps,	// Pattern Space
    struct line *hs,	// Hold Space
    bool replaced	// flag for `t' command
    )
{
  char input[1024] = {0};
  char res[1024] = RES_HDDR;
  int ret;

  // if (state != debug_stat_start) return 0;
  // fprintf(stderr, "> \n");
  // gets(input);

  if (state == debug_stat_start) {
  } else {
    if (state == debug_stat_break) {
      msg = "STOP_AT_BREAK";
    } else if (state == debug_stat_step) {
      msg = "STOP_BY_STEP";
    }
    fprintf(stderr, "[Line]%d\n", cmd->line);
    // fprintf(stderr, "[Ptrn]%s\n", ps->text);
    fprintf(stderr, "[Ptrn]%s\n", ps->active);
    // fprintf(stderr, "[Hold]%s\n", hs->text);
    fprintf(stderr, "[Hold]%s\n", hs->active);
    fprintf(stderr, "[Flag]%s\n", replaced ? "t" : "f");
  }

  do {
    gsed_debug_recv_commands(input);
    ret = proc_debug_command(input, res + strlen(RES_HDDR));
    gsed_debug_send_message(res);
  } while (ret == MORE_CMD);
}


static int
proc_debug_command(char *cmd, char *res)
{
  int ret = MORE_CMD;

  switch (cmd[0])
    {
      case 'b':		// break
	{
	  int n;
	  int i;

	  n = atoi(cmd + 2);
	  for (i = 0; i < BREAK_NUM; i++)
	    if (break_line[i] == 0)
	      {
		break_line[i] = n;
		// fprintf(stderr, "[break set] : line = %d  id = %d\n", n, i);
		sprintf(res, "[break set] : line = %d  id = %d", n, i);
		break;
	      }
	}
	break;

      case 'c':		// continue
	// TODO
      case 'r':		// run
	step_by_step = false;
	strcpy(res, "run");
	ret = PROC_CONT;
	break;

      case 'd':		// delete
	{
	  int n;

	  n = atoi(cmd + 2);
#if 0
	  break_line[n] = 0;
#else
	  int i;

	  for (i = 0; i < BREAK_NUM; i++)
	    if (break_line[i] == n)
	      {
		break_line[i] = 0;
		sprintf(res, "[break delete] : line = %d  id = %d\n", n, i);
		break;
	      }
#endif
	}
	break;

      case 'n':		// next
      case 's':		// step
	step_by_step = true;
	strcpy(res, "step");
	ret = PROC_CONT;
	break;

      case 'q':		// quit
	{
	  // gsed_debug_end("quit.\n");
	  strcpy(res, "quit");
	  ret = PROC_QUIT;
	  exit(0);
	  break;
	}

      default:
	strcpy(res, "INVALID_CMD!!!");
	ret = INVALID_CMD;
	break;
    }

  return ret;
}

// net {
int
gsed_debug_open_connection()
{
  int sock0;
  struct sockaddr_in addr;
  struct sockaddr_in client;
  int len;

  /* ソケットの作成 */
  if ((sock0 = socket(AF_INET, SOCK_STREAM, 0)) < 0)
    puts("eeeror");

  /* ソケットの設定 */
  bzero(&addr, sizeof(addr));

  addr.sin_family = AF_INET;
  addr.sin_port = htons(1234);
  addr.sin_addr.s_addr = INADDR_ANY;

  bind(sock0, (struct sockaddr *)&addr, sizeof(addr));

  /* TCPクライアントからの接続要求を待てる状態にする */
  listen(sock0, 1);

  fprintf(stderr, "gsed: debug connect waiting...\n");

  /* TCPクライアントからの接続要求を受け付ける */
  len = sizeof(client);
  sock = accept(sock0, (struct sockaddr *)&client, &len);

  fprintf(stderr, "gsed: connection established.\n");

  /* listen するsocketの終了 */
  close(sock0);

#if 0
  /* 文字送信 */
  char *start_msg = "gsed: debug mode start.\n";
  write(sock, start_msg, strlen(start_msg));
#endif

// ?? {
#if defined( SOL_TCP ) && defined( TCP_NODELAY )
  int one = 1;
  setsockopt(sock, SOL_TCP, TCP_NODELAY, &one, sizeof(one));
#endif

  sock_file = fdopen(sock, "w+");
// } ??

  return 0;
}

int
gsed_debug_close_connection(char *msg)
{
  gsed_debug_send_message(msg);

  /* TCPセッションの終了 */
  shutdown(sock, SHUT_RDWR);
  close(sock);

  fprintf(stderr, "gsed: connection closed.\n");
  return 0;
}

int
gsed_debug_recv_commands(char *buf)
{
  size_t len;
  size_t total_len = 0;

  for ( ; ; )
    {
      len = recv(sock, buf, MSGLEN - total_len, 0);

      total_len += len;

      if (total_len == MSGLEN)
	{
	  buf[MSGLEN] = '\0';
	  break;
	}

    }

  fprintf(stderr,"gsed: recv{%s}\n", buf);

  return 0;
}

int
gsed_debug_send_message(char *msg)
{
  size_t msg_len;
  size_t sent;
  size_t total_sent;

  // '\0'がメッセージの終端子なので、'\0'も送るため+1している。
  msg_len = strlen(msg) + 1;
  // msg_len = strlen(msg);
  total_sent = 0;

  while (total_sent < msg_len)
    {
      sent = send(sock, msg + total_sent, msg_len - total_sent, 0);
      // fprintf(stderr, "######## %d  / %d\n", sent, msg_len);
      if (sent == 0)
	{
	  fprintf(stderr, "gsed: socket connection broken.\n");
	  return -1;
	}
	total_sent += sent;
    }

  fflush(sock_file);
  return 0;
}
// } net


#if 0
int
debug_cmd(int state, char *msg, struct sed_cmd *cmd,
    struct line *ps,	// Pattern Space
    struct line *hs,	// Hold Space
    bool replaced	// flag for `t' command
    )
{
  char input[1024] = {0};

  // if (state != debug_stat_start) return 0;
  // fprintf(stderr, "> \n");
  // gets(input);

  if (state == debug_stat_start) {
    // TODO
    input[0] = 'b';
    input[1] = ' ';
    input[2] = '2';
  } else {
    if (state == debug_stat_break) {
      msg = "STOP_AT_BREAK";
    } else if (state == debug_stat_step) {
      msg = "STOP_BY_STEP";
    }
    fprintf(stderr, "[line]%d\n", cmd->line);
    // fprintf(stderr, "[Ptrn]%s\n", ps->text);
    fprintf(stderr, "[Ptrn]%s\n", ps->active);
    // fprintf(stderr, "[Hold]%s\n", hs->text);
    fprintf(stderr, "[Hold]%s\n", hs->active);
    fprintf(stderr, "[flag]%s\n", replaced ? "t" : "f");
  }

  switch (input[0])
    {
      case 'b':		// break
	{
	  int n;
	  int i;

	  n = atoi(input + 2);
	  for (i = 0; i < BREAK_NUM; i++)
	    if (break_line[i] == 0)
	      break_line[i] = n;
	}
	break;

      case 'c':		// continue
	// TODO
      case 'r':		// run
	step_by_step = false;
	break;

      case 'd':		// delete
	{
	  int n;

	  n = atoi(input + 2);
#if 0
	  break_line[n] = 0;
#else
	  int i;

	  for (i = 0; i < BREAK_NUM; i++)
	    if (break_line[i] == n)
	      break_line[i] = 0;
#endif
	}
	break;

      case 'n':		// next
      case 's':		// step
	step_by_step = true;
	break;

      case 'q':		// quit
	{
	  // gsed_debug_end("quit.\n");
	  exit(0);
	  break;
	}

      default:
	break;
    }

  return 0;
}
#endif
