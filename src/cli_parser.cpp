#include "include/cli_parser.h"

#include <optional>
#include <string>
#include <algorithm>

CliParser::CliParser (int &argc, char **argv) {
  for (int i=1; i < argc; ++i)
    this->tokens.push_back(std::string(argv[i]));
}

std::optional<std::string> CliParser::getCmdOption(const std::string &option) const {
  std::vector<std::string>::const_iterator itr;
  itr =  std::find(this->tokens.begin(), this->tokens.end(), option);
  if (itr != this->tokens.end() && ++itr != this->tokens.end()){
    return *itr;
  }
  return std::nullopt;
}

bool CliParser::cmdOptionExists(const std::string &option) const {
  return std::find(this->tokens.begin(), this->tokens.end(), option)
    != this->tokens.end();
}
