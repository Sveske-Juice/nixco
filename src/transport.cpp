#include <cstdint>
#include <cstring>
#include <ctime>
#include <expected>
#include <iostream>
#include <libssh/libssh.h>
#include <libssh/callbacks.h>
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
    ssh_options_set(session, SSH_OPTIONS_TIMEOUT, &config.timeout);
    
    // Callbacks
    // ssh_callbacks_struct callbacks{};
    // callbacks.auth_function = passphrase_callback;
    // callbacks.userdata = nullptr;
    // ssh_set_callbacks(session, &callbacks);

    return std::nullopt;
}

std::optional<std::string> SshTransport::connect() {
  ssh_options_set(session, SSH_OPTIONS_HOSTKEYS, "ssh-rsa,rsa-sha2-512");
  ssh_options_set(session, SSH_OPTIONS_KEY_EXCHANGE,
      "diffie-hellman-group14-sha1,diffie-hellman-group1-sha1,curve25519-sha256,ssh-ed25519");
  if (ssh_connect(this->session) != SSH_OK) {
    return std::string("ssh_connect failed: ") + ssh_get_error(session);
  }

  // Authentication
  // Use provided identity (with potential password protected key)
  if (!this->config.identityFile.empty()) {
    ssh_key key = loadIdentity(this->config.identityFile);
    if (!key)
      return "Failed to load identity file";

    int rc = ssh_userauth_publickey(this->session, nullptr, key);
    ssh_key_free(key);

    if (rc != SSH_AUTH_SUCCESS) {
      return std::string("Failed to auth with provided identity: ") + ssh_get_error(this->session);
    }
  }
  // Try auto public key or password
  else {
    // Try keys on host
    int rc = ssh_userauth_publickey_auto(session, nullptr, nullptr);
    if (rc == SSH_AUTH_DENIED) {
      std::cout << "Public key not accepted. Trying password auth" << std::endl;

      // Try password
      std::cout << "password: ";
      std::string input;
      std::cin >> input;

      if (ssh_userauth_password(this->session, NULL, input.c_str()) == SSH_AUTH_ERROR) {
        return std::string("password auth failed: ") + ssh_get_error(this->session);
      }
    }
    else if (rc != SSH_AUTH_SUCCESS) {
      return std::string("auth failed: ") + ssh_get_error(this->session);
    }
  }


  // Create SSH channel
  this->channel = ssh_channel_new(this->session);
  if (!this->channel) {
    return std::string("Failed to create channel: ") + ssh_get_error(this->session);
  }

  if (ssh_channel_open_session(this->channel) < 0) {
    return std::string("Failed to open session: ") + ssh_get_error(this->session);
  }

  if (ssh_channel_request_pty(this->channel) != SSH_OK) {
    return std::string("Failed to request PTY: ") + ssh_get_error(this->session);
  }

  if (ssh_channel_request_shell(this->channel) != SSH_OK) {
    return std::string("Failed to request shell: ") + ssh_get_error(this->session);
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
  out.resize(count, '\0');

  int read = ssh_channel_read(this->channel, out.data(), count, 0);

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

ssh_key SshTransport::loadIdentity(const std::string& path) {
  ssh_key key = nullptr;

  // Try without passphrase
  int rc = ssh_pki_import_privkey_file(
      path.c_str(),
      nullptr,    // no passphrase
      nullptr,
      nullptr,
      &key
      );

  std::cout << rc << std::endl;
  if (rc == SSH_OK) {
    return key; // unencrypted key
  }

  if (rc == SSH_EOF) {
    std::cerr << "identityFile file not found" << std::endl;
    return nullptr;
  }

  // Try with passphrase
  std::string passphrase;
  std::cout << "Enter passphrase for " << path << ": ";
  std::cin >> passphrase;

  rc = ssh_pki_import_privkey_file(
      path.c_str(),
      passphrase.c_str(),
      nullptr,
      nullptr,
      &key
      );

  explicit_bzero(passphrase.data(), passphrase.size());

  if (rc != SSH_OK) {
    std::cerr << ssh_get_error(this->session) << std::endl;
    return nullptr;
  }

  return key;
}

bool SshTransport::is_open() const {
  return ssh_channel_is_open(this->channel) && !ssh_channel_is_eof(this->channel);
}
