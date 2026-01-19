#ifndef TRANSPORT_H
#define TRANSPORT_H

#include "config.h"
#include "include/cli_parser.h"
#include <cstdint>
#include <expected>
#include <libssh/libssh.h>
#include <memory>
#include <optional>
#include <string>

class Transport {
public:
  virtual ~Transport() = default;
  [[nodiscard]] virtual std::optional<std::string> connect() = 0;
  [[nodiscard]] virtual std::optional<std::string> init() = 0;
  [[nodiscard]] virtual std::optional<std::string> write(const std::string& msg) = 0;
  [[nodiscard]] virtual std::expected<std::string, int> read(const uint32_t count) = 0;
  virtual bool is_open() const = 0;
  static std::expected<std::unique_ptr<Transport>, std::string> create_from_cliargs(const CliParser &cliparser);
};

class SshTransport : public Transport {
private:
  const SshConfig config;
  ssh_session session;
  ssh_channel channel;

  std::expected<ssh_key, std::string> loadIdentity(const std::string& path);

public:
  explicit SshTransport(SshConfig _config);
  ~SshTransport();

  std::optional<std::string> init() override;
  std::optional<std::string> connect() override;
  std::optional<std::string> write(const std::string& cmd) override;
  std::expected<std::string, int> read(const uint32_t count) override;
  bool is_open() const override;
};

class SerialTransport : public Transport {
private:
  const SerialConfig config;
  int fd;

public:
  explicit SerialTransport(SerialConfig _config);
  ~SerialTransport();

  std::optional<std::string> init() override;
  std::optional<std::string> connect() override;
  std::optional<std::string> write(const std::string& cmd) override;
  std::expected<std::string, int> read(const uint32_t count) override;
  bool is_open() const override;
};

#endif
