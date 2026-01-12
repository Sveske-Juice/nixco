#include <cstdint>
#include <expected>
#include <iostream>
#include <libssh/libssh.h>
#include <optional>
#include <string>

#include "include/config.h"
#include "include/transport.h"

SshTransport::SshTransport(SshConfig _config) : config(std::move(_config)) {}
SshTransport::~SshTransport() {
    std::cout << "Cleaning up SSH Transport" << std::endl;

    if (this->channel) {
      ssh_channel_send_eof(this->channel);
      ssh_channel_close(this->channel);
      ssh_channel_free(this->channel);
    }

    if (this->session) {
      ssh_disconnect(this->session);
      ssh_free(this->session);
    }
}

std::optional<std::string> SshTransport::init() {
    this->session = ssh_new();
    if (!this->session) {
      return "Failed to create SSH Session object";
    }

    ssh_options_set(session, SSH_OPTIONS_HOST, config.host.c_str());
    ssh_options_set(session, SSH_OPTIONS_USER, config.user.c_str());
    ssh_options_set(session, SSH_OPTIONS_LOG_VERBOSITY, &config.verbosity);
    // ssh_options_set (session, SSH_OPTIONS_KEY_EXCHANGE, "ssh-rsa,diffie-hellman-group-exchange-sha1");

    return std::nullopt;
}

std::optional<std::string> SshTransport::connect() {
  ssh_options_set(session, SSH_OPTIONS_HOSTKEYS, "ssh-rsa");
  ssh_options_set(session, SSH_OPTIONS_KEY_EXCHANGE,
      "diffie-hellman-group14-sha1,diffie-hellman-group1-sha1");
  if (ssh_connect(this->session) != SSH_OK) {
    return std::string("ssh_connect failed: ") + ssh_get_error(session);
  }

  // Authentication
  if (!this->config.password.empty()) {
    if (ssh_userauth_password(this->session, NULL, this->config.password.c_str()) == SSH_AUTH_ERROR) {
      return std::string("password auth failed: ") + ssh_get_error(this->session);
    }
  }
  else {
    // Try ssh key
    if (ssh_userauth_publickey_auto(session, nullptr, nullptr)
        != SSH_AUTH_SUCCESS) {
      return std::string("auth failed: ") + ssh_get_error(this->session);
    }
  }

  // Create SSH channel
  this->channel = ssh_channel_new(this->session);
  if (!this->channel) {
    return "Failed to create channel";
  }

  if (ssh_channel_open_session(this->channel) < 0) {
    return "Failed to open session";
  }

  if (ssh_channel_request_shell(this->channel) != SSH_OK) {
    return "Failed to request shell";
  }

  return std::nullopt;
}

std::optional<std::string> SshTransport::write(const std::string& cmd) {
  if (ssh_channel_write(this->channel, cmd.data(), cmd.size()) == SSH_ERROR)
    return std::string("Failed to write to SSH Channel: ") + ssh_get_error(this->session);

  return std::nullopt;
}


std::expected<std::string, int> SshTransport::read(const uint32_t count) {
  std::string out;
  out.reserve(count);

  int read = ssh_channel_read_nonblocking(this->channel, out.data(), count, 0);

  // Nothing to read, EOF
  if (read == 0) {
    return "";
  }

  // On error: give rc
  if (read < 0) {
    return std::unexpected<int>(read);
  }

  out.resize(read);
  return out;
}
