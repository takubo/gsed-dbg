#include "sed.h"
#include "debug.h"
#include <stdio.h>
#include <stdlib.h>

#define RES_HEADER "@"
#define SED_HEADER "[sed-dbg] : "

/* return value of proc_debug_command() */
enum {
  MORE_CMD,
  PROC_RUN,
  PROC_CONT,
  PROC_QUIT,
  PRINT_ALL,
  PRINT_PTRN,
  PRINT_HOLD,
  PRINT_FLAG,
  INVALID_CMD,
};

static int proc_debug_command(char *, char *);
static int gsed_debug_print(int,
    struct line *ps,	// Pattern Space
    struct line *hs,	// Hold Space
    bool replaced	// flag for `t' command
);

/* Sed operates a line at a time. */
struct line {
  char *text;		/* Pointer to line allocated by malloc. */
  char *active;		/* Pointer to non-consumed part of text. */
  size_t length;	/* Length of text (or active, if used). */
  size_t alloc;		/* Allocated space for active. */
  bool chomped;		/* Was a trailing newline dropped? */
  mbstate_t mbstate;
};

//	/* Have we done any replacements lately?  This is used by the `t' command. */
//	extern bool replaced = false;
//	/* The current output file (stdout if -i is not being used. */
//	extern struct output output_file;
//	/* The `current' input line. */
//	extern struct line line;
//	/* An input line used to accumulate the result of the s and e commands. */
//	extern struct line s_accum;
//	/* An input line that's been stored by later use by the program */
//	extern struct line hold;

bool debug_flag;
bool stepping = false;

countT break_line[BREAK_NUM] = {0};

int
stop_check(countT line)
{
  int i;

  /* ブレークポイントによる提出は、ステップ実行による停止より優先する */
  for (i = 0; i < BREAK_NUM; i++)
    if (line == break_line[i])
      {
	fprintf(stderr, SED_HEADER "Stop at break Point : line = %d\n", line);
	return debug_stat_break;
      }

  if (stepping)
    return debug_stat_step;

  return debug_stat_invalid;
}

int
debug_cmd(int state, char *msg, struct sed_cmd *cmd,
    struct line *ps,	// Pattern Space
    struct line *hs,	// Hold Space
    bool replaced	// flag for `t' command
    )
{
  char input[1024] = {0};
  char res_msg[1024] = RES_HEADER;
  int ret;

  if (state == debug_stat_start) {
  } else {
    if (state == debug_stat_break) {
      char msg[1024];

      sprintf(msg, RES_HEADER "stop by break Point : line = %d\n", cmd->line);
      gsed_debug_send_message(msg);
    } else if (state == debug_stat_step) {
      char msg[1024];

      sprintf(msg, RES_HEADER "stop by stepping executtion : line = %d\n", cmd->line);
      gsed_debug_send_message(msg);
    }
    // fprintf(stderr, SED_HEADER "Line : %d\n", cmd->line);
    // fprintf(stderr, SED_HEADER "Ptrn : %s\n", ps->active);
    // fprintf(stderr, SED_HEADER "Hold : %s\n", hs->active);
    // fprintf(stderr, SED_HEADER "Flag : %s\n", replaced ? "T" : "F");
  }

  do {
loop:
    gsed_debug_recv_commands(input);
    ret = proc_debug_command(input, res_msg + strlen(RES_HEADER));

    switch (ret) {
      case PRINT_ALL: case PRINT_PTRN: case PRINT_HOLD: case PRINT_FLAG:
	gsed_debug_print(ret, ps, hs, replaced);
	goto loop;
      default:
	gsed_debug_send_message(res_msg);
	break;
    }
  } while (ret == MORE_CMD);

  if (ret == PROC_QUIT)
    exit(0);
}


static int
proc_debug_command(char *cmd, char *res_msg)
{
  int ret = MORE_CMD;

  switch (cmd[0])
    {
/* break */
      case 'b':
	{
	  int n;
	  int i;

	  n = atoi(cmd + 2);
	  for (i = 0; i < BREAK_NUM; i++)
	    if (break_line[i] == 0)
	      {
		break_line[i] = n;
		sprintf(res_msg, "break set line = %d id = %d", n, i);
		break;
	      }
	}
	break;

/* continue */
      case 'c':
	/* TODO */
/* run */
      case 'r':
	stepping = false;
	strcpy(res_msg, "run");
	ret = PROC_CONT;
	break;

/* delete */
      case 'd':
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
		sprintf(res_msg, "break delete line = %d id = %d\n", n, i);
		break;
	      }
#endif
	}
	break;

/* next */
      case 'n':
/* step */
      case 's':
	stepping = true;
	strcpy(res_msg, "step");
	ret = PROC_CONT;
	break;

/* print */
      case 'p':
	if (strncmp("PTRN", cmd + 2, 4))
	  ret = PRINT_PTRN;
	else if (strncmp("HOLD", cmd + 2, 4))
	  ret = PRINT_HOLD;
	else if (strncmp("FLAG", cmd + 2, 4))
	  ret = PRINT_FLAG;
	else
	  ret = PRINT_ALL;
	break;

/* quit */
      case 'q':
	{
	  strcpy(res_msg, "quit");
	  ret = PROC_QUIT;
	  break;
	}

/* invalid command */
      default:
	strcpy(res_msg, "INVALID_CMD!!!");
	ret = INVALID_CMD;
	break;
    }

  return ret;
}

static int
gsed_debug_print(int mode,
    struct line *ps,	// Pattern Space
    struct line *hs,	// Hold Space
    bool replaced	// flag for `t' command
    )
{
  char msg[4096];

  if (mode == PRINT_PTRN || mode == PRINT_ALL)
    {
      sprintf(msg, RES_HEADER "value PTRN : %s", ps->active);
      gsed_debug_send_message(msg);
    }
  if (mode == PRINT_HOLD || mode == PRINT_ALL)
    {
      sprintf(msg, RES_HEADER "value HOLD : %s", hs->active);
      gsed_debug_send_message(msg);
    }
  if (mode == PRINT_FLAG || mode == PRINT_ALL)
    {
      sprintf(msg, RES_HEADER "value FLAG : %s", replaced ? "T" : "F");
      gsed_debug_send_message(msg);
    }

  return 0;
}

// net {{{
int
gsed_debug_open_connection()
{
  int sock0;
  struct sockaddr_in addr;
  struct sockaddr_in client;
  int len;

  /* ソケットの作成 */
  if ((sock0 = socket(AF_INET, SOCK_STREAM, 0)) < 0)
    fprintf(stderr, SED_HEADER "making socket failed.\n");

  /* ソケットの設定 */
  bzero(&addr, sizeof(addr));

  addr.sin_family = AF_INET;
  addr.sin_port = htons(33333);
  addr.sin_addr.s_addr = INADDR_ANY;

  bind(sock0, (struct sockaddr *)&addr, sizeof(addr));

  /* TCPクライアントからの接続要求を待てる状態にする */
  listen(sock0, 1);

  fprintf(stderr, SED_HEADER "debug connect waiting...\n");

  /* TCPクライアントからの接続要求を受け付ける */
  len = sizeof(client);
  sock = accept(sock0, (struct sockaddr *)&client, &len);

  fprintf(stderr, SED_HEADER "connection established.\n");

  /* listen するsocketの終了 */
  close(sock0);

#if 0
  /* コネクション確立メッセージ送信 */
  char *start_msg = "gsed: debug start.";

  gsed_debug_send_message(start_msg);
#endif

// ?? {{{
#if defined( SOL_TCP ) && defined( TCP_NODELAY )
  int one = 1;

  setsockopt(sock, SOL_TCP, TCP_NODELAY, &one, sizeof(one));
#endif
// ?? }}}

  sock_file = fdopen(sock, "w+");

  return 0;
}

int
gsed_debug_close_connection(char *msg)
{
  gsed_debug_send_message(msg);

  /* TCPセッションの終了 */
  shutdown(sock, SHUT_RDWR);
  close(sock);

  fprintf(stderr, SED_HEADER "connection closed.\n");
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

  fprintf(stderr,SED_HEADER "recv : {%s}\n", buf);

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
      if (sent == 0)
	{
	  fprintf(stderr, SED_HEADER "socket connection broken.\n");
	  return -1;
	}
      total_sent += sent;
    }

  fflush(sock_file);

  fprintf(stderr,SED_HEADER "send : {%s}\n", msg);

  return 0;
}
// net }}}
