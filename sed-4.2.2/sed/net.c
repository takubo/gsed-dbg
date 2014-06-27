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
int gsed_debug_send_message(char *);
int gsed_debug_recv_commands(char *);
int proc_debug_command(char *);

#define MSGLEN 64

int
main(int argc, char **argv)
{
  char buf[MSGLEN + 1];

  gsed_debug_open_connection();

//  getchar();
  gsed_debug_recv_commands(buf);
//  proc_debug_command(buf);

  gsed_debug_send_message("gsed:ok.");

  gsed_debug_close_connection("quit.");

  return 0;
}

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

  fprintf(stderr, "gsed: conneiotn established.\n");

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

  fprintf(stderr, "gsed: conneiotn closed.\n");
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








#if 0

int
proc_debug_command(char *buf)
{
  switch (buf[0])
    {
      case 'b':
      {
	int n;
	int i;

	n = atoi(input + 2);
	for (i = 0; i < BREAK_NUM; i++)
	  if (break_line[i] == 0)
	    break_line[i] = n;
      }
	break;
      default:
	break;
    }



  return 0;
}

int
gsed_debug_recv_commands(char *buf)
{
  size_t len;
  size_t total_len = 0;
  char tmp_buf[1024] = {0};
  char buf[1024] = {0};

  for ( ; ; )
    {
      len = recv(sock, tmp_buf, 1024, 0);

      strncpy(buf, tmp_buf, len);
      total_len += len;

      if (tmp_buf[len - 1] == '\n')
	{
	  buf[total_len] = '\0';
	  break;
	}

    }

  puts(buf);
  // proc_debug_command(buf);

  return 0;
}

#endif
