#include <cstdint>
#include <cstdio>
#include <cstring>
#include <ctime>
#include <expected>
#include <fmt/base.h>
#include <iostream>
#include <libssh/libssh.h>
#include <memory>
#include <optional>
#include <spdlog/spdlog.h>
#include <stdexcept>
#include <string>
#include <fmt/format.h>

#include "include/cli_parser.h"
#include "include/config.h"
#include "include/transport.h"

SshTransport::SshTransport(SshConfig _config) : config(std::move(_config)) {}
SshTransport::~SshTransport() {
  spdlog::info("Cleaning up SSH transport");

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
    
    return std::nullopt;
}

std::optional<std::string> SshTransport::connect() {
  ssh_options_set(session, SSH_OPTIONS_HOSTKEYS, "ssh-rsa,rsa-sha2-512");
  ssh_options_set(session, SSH_OPTIONS_KEY_EXCHANGE,
      "diffie-hellman-group14-sha1,diffie-hellman-group1-sha1,curve25519-sha256,ssh-ed25519");
  if (ssh_connect(this->session) != SSH_OK) {
    return fmt::format("ssh_connect failed: {:s}", ssh_get_error(this->session));
  }

  // Authentication
  // Use provided identity (with potential password protected key)
  if (!this->config.identityFile.empty()) {
    auto key = loadIdentity(this->config.identityFile);
    if (!key)
      return key.error(); // Propagate error

    int rc = ssh_userauth_publickey(this->session, nullptr, *key);
    ssh_key_free(*key);

    if (rc != SSH_AUTH_SUCCESS) {
      return fmt::format("Failed to auth with provided identity: ", ssh_get_error(this->session));
    }
  }
  // Try auto public key or password
  else {
    // Try keys on host
    int rc = ssh_userauth_publickey_auto(session, nullptr, nullptr);
    if (rc == SSH_AUTH_DENIED) {
      spdlog::info("Public key not accepted. Trying password auth");

      // Try password
      // TODO: hide user input
      std::cout << "password: ";
      std::string input;
      std::cin >> input;

      if (ssh_userauth_password(this->session, NULL, input.c_str()) == SSH_AUTH_ERROR) {
        return fmt::format("password auth failed: ", ssh_get_error(this->session));
      }
    }
    else if (rc != SSH_AUTH_SUCCESS) {
      return fmt::format("auth failed: {:s}", ssh_get_error(this->session));
    }
  }


  // Create SSH channel
  this->channel = ssh_channel_new(this->session);
  if (!this->channel) {
    return fmt::format("Failed to create channel: {:s}", ssh_get_error(this->session));
  }

  if (ssh_channel_open_session(this->channel) < 0) {
    return fmt::format("Failed to open session: ", ssh_get_error(this->session));
  }

  if (ssh_channel_request_pty(this->channel) != SSH_OK) {
    return fmt::format("Failed to request PTY: ", ssh_get_error(this->session));
  }

  if (ssh_channel_request_shell(this->channel) != SSH_OK) {
    return fmt::format("Failed to request shell: ", ssh_get_error(this->session));
  }

  return std::nullopt;
}

std::optional<std::string> SshTransport::write(const std::string& cmd) {
  if (ssh_channel_write(this->channel, cmd.data(), cmd.size()) == SSH_ERROR)
    return fmt::format("Failed to write to SSH Channel: ", ssh_get_error(this->session));

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

std::expected<ssh_key, std::string> SshTransport::loadIdentity(const std::string& path) {
  ssh_key key = nullptr;

  // Try without passphrase
  int rc = ssh_pki_import_privkey_file(
      path.c_str(),
      nullptr,    // no passphrase
      nullptr,
      nullptr,
      &key
      );

  if (rc == SSH_OK) {
    return key; // unencrypted key
  }

  if (rc == SSH_EOF) {
    return std::unexpected<std::string>("identity file not found");
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
    return std::unexpected<std::string>(ssh_get_error(this->session));
  }

  return key;
}

bool SshTransport::is_open() {
  return ssh_channel_is_open(this->channel) && !ssh_channel_is_eof(this->channel);
}

std::expected<std::unique_ptr<Transport>, std::string> Transport::create_from_cliargs(const CliParser &cliparser) {
  auto transportType =
    cliparser.getCmdOption("-t")
        .value_or(cliparser.getCmdOption("--transport").value_or(""));
  if (transportType.empty())
    return std::unexpected<std::string>("No transport supplied");

  if (transportType == "ssh") {
    SshConfig config;
    auto host = cliparser.getCmdOption("--host");
    if (!host) return std::unexpected<std::string>("Expected a host");

    auto username = cliparser.getCmdOption("-u").value_or(cliparser.getCmdOption("--user").value_or(""));
    if (username.empty()) return std::unexpected<std::string>("Expected user");

    auto port = cliparser.getCmdOption("-p").value_or(cliparser.getCmdOption("--port").value_or(""));
    if (!port.empty()) {
      config.port = std::stoi(port);
    }

    auto identityFile = cliparser.getCmdOption("-i").value_or(cliparser.getCmdOption("--identity").value_or(""));

    config.identityFile = identityFile;
    config.host = *host;
    config.user = username;

    return std::make_unique<SshTransport>(config);
  }
  else if (transportType == "serial") {
    SerialConfig config;
    auto portname = cliparser.getCmdOption("--port");
    if (!portname) return std::unexpected<std::string>("Expected a port for serial transport");

    config.portname = *portname;

    return std::make_unique<SerialTransport>(config);
  }

  return std::unexpected<std::string>(fmt::format("Unrecognized transport type: {:s}", transportType));
}
