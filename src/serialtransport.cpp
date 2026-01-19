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

  cfsetospeed(&tty, this->config.speed);
  cfsetispeed(&tty, this->config.speed);

  tty.c_cflag
    = (tty.c_cflag & ~CSIZE) | CS8; // 8-bit characters
  tty.c_iflag &= ~IGNBRK; // disable break processing
  tty.c_lflag = 0; // no signaling chars, no echo, no
                   // canonical processing
  tty.c_oflag = 0; // no remapping, no delays
  tty.c_cc[VMIN] = 0; // read doesn't block
  tty.c_cc[VTIME] = 5; // 0.5 seconds read timeout

  tty.c_iflag &= ~(IXON | IXOFF
      | IXANY); // shut off xon/xoff ctrl

  tty.c_cflag
    |= (CLOCAL | CREAD); // ignore modem controls,
                         // enable reading
  tty.c_cflag &= ~(PARENB | PARODD); // shut off parity
  tty.c_cflag &= ~CSTOPB;
  tty.c_cflag &= ~CRTSCTS;

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
  return std::nullopt;
}

std::expected<std::string, int> SerialTransport::read(const uint32_t count) {
  return "serial";
}

bool SerialTransport::is_open() const {
  return fcntl(fd, F_GETFD) != -1 || errno != EBADF;
}
