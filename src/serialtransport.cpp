#include "include/config.h"
#include "include/transport.h"
#include <cstdint>
#include <cstring>
#include <errno.h>
#include <expected>
#include <fmt/format.h>
#include <optional>
#include <fcntl.h>
#include <spdlog/spdlog.h>
#include <string>
#include <unistd.h>
#include <termios.h>

// aint no one using windows bruh
#ifdef _WIN32
SerialTransport::SerialTransport(SerSerialConfig _config) : config(_config) {
  spdlog::error("Windows serial not implemented");
}
#endif

SerialTransport::SerialTransport(SerialConfig _config) : config(_config) {}
std::optional<std::string> SerialTransport::init() {
  return std::nullopt;
}
std::optional<std::string> SerialTransport::connect() {
  this->fd = open(this->config.portname.c_str(), O_RDWR | O_NOCTTY | O_SYNC);
  if (fd < 0) {
    return fmt::format("Error opening serial port {:s}: {:s}", this->config.portname, strerror(errno));
  }

  // From geeks for geeks
  struct termios tty;
  if (tcgetattr(fd, &tty) != 0) {
    return fmt::format("Error from tcgetattr: {:s}", strerror(errno));
  }

  cfmakeraw(&tty);
  cfsetospeed(&tty, this->config.speed);
  cfsetispeed(&tty, this->config.speed);

  tty.c_cflag |= (CLOCAL | CREAD);

  if (tcsetattr(fd, TCSANOW, &tty) != 0) {
    return fmt::format("Error from tcsetattr: {:s}", strerror(errno));
  }

  return std::nullopt;
}
SerialTransport::~SerialTransport() {
  if (!is_open())
    return;

  int rc = close(this->fd);
  if (rc) {
    spdlog::error("Failed to close delete serial transport: {:s}", strerror(errno));
  }
}

std::optional<std::string> SerialTransport::write(const std::string& cmd) {
  int written = ::write(this->fd, static_cast<const void *>(cmd.data()), cmd.size());
  if (written < 0)
    return fmt::format("Error writing to transport: {:s}", strerror(errno));

  return std::nullopt;
}

std::expected<std::string, int> SerialTransport::read(const uint32_t count) {
  std::string out;
  out.resize(count, '\0');
  int read = ::read(this->fd, static_cast<void *>(out.data()), static_cast<size_t>(count));

  if (read == 0)
    return "";
  
  if (read < 0) {
    return std::unexpected<int>(errno);
  }

  out.resize(read);
  return out;
}

bool SerialTransport::is_open() {
  // We must wake the device to know, otherwise we dont know
  // this->write("\n");

  return fcntl(fd, F_GETFD) != -1 || errno != EBADF;
}
