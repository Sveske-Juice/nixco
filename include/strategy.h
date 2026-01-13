#ifndef STRATEGY_H
#define STRATEGY_H

#include "include/transport.h"
#include <expected>
#include <optional>
#include <string>

class Strategy {
private:
  std::string strip_ansi(const std::string &s) const;
  bool looks_like_prompt(const std::string &buffer) const;
public:
  std::expected<std::string, int> wait_for_prompt(Transport &transport) const;
  virtual std::optional<std::string> apply(Transport &transport, const std::string &config) const;
};

#endif
