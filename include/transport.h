#ifndef TRANSPORT_H
#define TRANSPORT_H

#include "config.h"
#include <cstdint>
#include <expected>
#include <functional>
#include <libssh/libssh.h>
#include <optional>
#include <string>

class Transport {
public:
  virtual ~Transport() = default;
  [[nodiscard]] virtual std::optional<std::string> connect() = 0;
  [[nodiscard]] virtual std::optional<std::string> init() = 0;
  [[nodiscard]] virtual std::optional<std::string> write(const std::string& msg) = 0;
  [[nodiscard]] virtual std::expected<std::string, int> read(const uint32_t count) = 0;
};


class SshTransport : public Transport {
private:
  const SshConfig config;
  ssh_session session;
  ssh_channel channel;

public:
  explicit SshTransport(SshConfig _config);
  ~SshTransport();

  std::optional<std::string> init() override;
  std::optional<std::string> connect() override;
  std::optional<std::string> write(const std::string& cmd) override;
  std::expected<std::string, int> read(const uint32_t count) override;
};

#endif
