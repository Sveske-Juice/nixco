#ifndef CLI_PARSER_H
#define CLI_PARSER_H

#include <optional>
#include <string>
#include <vector>

// Modified from stackoverflow:
// https://stackoverflow.com/questions/865668/parsing-command-line-arguments-in-c
class CliParser{
  public:
    CliParser (int &argc, char **argv);
    std::optional<std::string> getCmdOption(const std::string &option) const;
    bool cmdOptionExists(const std::string &option) const;
  private:
    std::vector <std::string> tokens;
};

#endif
