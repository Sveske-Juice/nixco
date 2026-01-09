#include <libssh/libssh.h>
#include <iostream>

#define HOST "192.168.2.129"
#define USER "admin"

int main(int argc, char **argv) {
  ssh_session session = ssh_new();
  if (!session) {
    fprintf(stderr, "Failed to create SSH Session object");
    exit(-1);
  }

  ssh_options_set(session, SSH_OPTIONS_HOST, HOST);
  ssh_options_set(session, SSH_OPTIONS_USER, USER);

  int verbosity = SSH_LOG_NOLOG;
  ssh_options_set(session, SSH_OPTIONS_LOG_VERBOSITY, &verbosity);

  if (ssh_connect(session) != SSH_OK) {
    std::string err = ssh_get_error(session);
    ssh_free(session);
    throw std::runtime_error("ssh_connect failed: " + err);
  }

  // Authenticate using ssh-agent / ~/.ssh
  if (ssh_userauth_publickey_auto(session, nullptr, nullptr)
    != SSH_AUTH_SUCCESS) {
    std::string err = ssh_get_error(session);
    ssh_disconnect(session);
    ssh_free(session);
    throw std::runtime_error("auth failed: " + err);
  }


  ssh_free(session);
  return 0;
}
