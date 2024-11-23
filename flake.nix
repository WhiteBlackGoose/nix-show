{
  description = "Flake for nix-show, command to show a package information";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
  outputs = { nixpkgs, ... }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
    in {
      devShells = nixpkgs.lib.genAttrs systems (system:
        let 
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              cargo
              rustfmt
              rust-analyzer
              rustc
            ];
          };
        }
      );

      packages = nixpkgs.lib.genAttrs systems (system:
        let 
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = with pkgs; (pkgs.writeScriptBin "nix-show" ''
            #!${bash}/bin/bash
            meta=$(nix eval $1.meta --json)
            name=$(nix eval $1.name)
            get_key() {
              local val=$(echo "$meta" | ${jq}/bin/jq | grep "$1")
              echo $val
            }
            print_ansi() {
              printf "\033[$1m$2\033[0m\n"
            }
            print_green() {
              printf "\033[32m$1\033[0m\n"
            }
            print_red() {
              printf "\033[31m$1\033[0m\n"
            }
            print_bool() {
              true=$(get_key "\"$1\": true")
              if [ -n "$true" ]; then
                print_red "$3"
              fi
              false=$(get_key "\"$1\": false")
              if [ -n "$false" ]; then
                print_green "$2"
              fi
            }
            print_key() {
              local val=$(get_key "$2")
              if [ -n "$val" ]; then
                local val=''${val#*: \"}
                local val=''${val%\",*}
                echo "$1$val"
              fi
            }

            name=''${name#\"}
            name=''${name%\"}
            print_ansi "35;4;1" "$name\n"

            print_key "" "description"
            printf "\n"

            print_key "Homepage: " "homepage"
            printf "\n"

            print_bool "unfree" "✅ Free/Libre" "❌ Proprietary"
            print_bool "unsupported" "✅ Supported" "❌ Unsupported"
            print_bool "insecure" "✅ Secure" "❌ Insecure"
            printf "\n"
            
            print_key "Main program: " "mainProgram"
          '').overrideAttrs(_: {
            meta = {
              homepage = "https://github.com/WhiteBlackGoose/nix-show";
              license = pkgs.lib.licenses.mit;
              platforms = pkgs.lib.platforms.all;
              description = "Shows main meta attributes of a package";
            };
          });
        }
      );
    };
}
