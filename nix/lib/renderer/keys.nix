{inputs, self, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.lib.renderKeyChain = name: chain:
    ''
      key chain ${name}
    ''
    + lib.optionalString (chain.description != null) "description ${chain.description}\n"
    + lib.optionalString (chain.keys != {})
    (
      lib.concatMapAttrsStringSep "\n" (keyId: key:
        ''
          key ${keyId}
          cryptographic-algorithm ${key.cryptographicAlgorithm}
          key-string ${key.keyString}
        ''
      ) chain.keys
    )
    ;
  flake.lib.renderKeys = device:
    lib.optionalString (device.keyChains != null) (
      lib.concatMapAttrsStringSep "\n" 
      (name: chain: self.lib.renderKeyChain name chain)
      device.keyChains
    );
}
