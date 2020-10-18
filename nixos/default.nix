{ config, lib, pkgs, utils, ... }:

with lib;

let
  cfg = config.services.csgods;
  csgods-update = pkgs.writeShellScript "update.sh" ''
    mkdir -p ${cfg.stateDir}
    echo "Checking for updates"
    ${pkgs.steamcmd}/bin/steamcmd <<EOF
      login anonymous
      force_install_dir ${cfg.stateDir}
      app_update 740
      exit
    EOF
    ${pkgs.patchelf}/bin/patchelf \
       --set-interpreter "$(cat ${pkgs.stdenv_32bit.cc}/nix-support/dynamic-linker-m32)" \
       --set-rpath "${cfg.stateDir}/bin" \
       ${cfg.stateDir}/srcds_linux
    echo "Done updating"

    # Cleanup /tmp/dumps, otherwise it prevents steam from starting
    rm -rf /tmp/dumps

    echo "Registering plugins"
    ln -fs "${plugins}/share/addons" "${cfg.stateDir}/csgo"
    for f in ${plugins}/share/cfg/*; do
      ln -fs "$f" "${cfg.stateDir}/csgo/cfg"
    done
    echo "Done registering plugins"
  '';
  plugins = pkgs.buildEnv {
    name = "csgods-plugins";
    paths = cfg.plugins;
  };

  launchOptions = {
    tickrate = mkOption {
      type = types.int;
      default = 128;
      description = "Server tickrate";
    };
    maxPlayers = mkOption {
      type = types.int;
      default = 14;
      description = "Slots on the server";
    };
    ip = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "IP address the server binds to";
    };
    port = mkOption {
      type = types.int;
      default = 27015;
      description = "Server port";
    };
    map = mkOption {
      type = types.str;
      default = "de_dust2";
      description = "Starting map";
    };
    gameLoginToken = mkOption {
      type = types.str;
      description = ''
        Game Login Token, which is required for non-LAN servers.
        Can be generated on https://steamcommunity.com/dev/managegameservers.
        Note that you need different ones for each server.
      '';
    };
  };
in
{
  options.services.csgods = {
    enable = mkEnableOption "CS:GO dedicated server";

    user = mkOption {
      type = types.str;
      default = "csgods";
      description = "User account under which csgods runs.";
    };

    group = mkOption {
      type = types.str;
      default = "csgods";
      description = "Group under which csgods runs.";
    };

    stateDir = mkOption {
      type = types.str;
      default = "/var/lib/csgods";
      description = "Directory for CS:GO dedicated server files.";
    };

    launchOptions = mkOption {
      type = with types; submodule { options = launchOptions; };
      default = {};
      description = "Launch options to be provided for the server";
    };

    plugins = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "CS:GO server plugins to be installed on the server";
    };
  };

  config = mkIf cfg.enable {
    users.users = optionalAttrs (cfg.user == "csgods") {
      csgods = {
        home = cfg.stateDir;
        createHome = true;
        isSystemUser = true;
        group = cfg.group;
      };
    };

    users.groups = optionalAttrs (cfg.group == "csgods") {
      csgods = { };
    };

    systemd.services.csgods = {
      description = "CS:GO dedicated server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        LD_LIBRARY_PATH = "${cfg.stateDir}:${cfg.stateDir}/bin";
      };
  # default = "-autoupdate -game csgo -usercon -tickrate 128 -port 27015 +game_type 0 +game_mode 0 +mapgroup mg_active +map de_dust2";
      preStart = ''
      '';
      serviceConfig = {
        ExecStartPre = "${csgods-update}";
        ExecStart = ''${cfg.stateDir}/srcds_run \
          -game csgo -usercon \
          +game_type 0 +game_mode 0 \
          -autoupdate -steam_dir ${cfg.stateDir} -steamcmd_script ${csgods-update} \
          -tickrate ${toString cfg.launchOptions.tickrate} \
          -maxplayers ${toString cfg.launchOptions.maxPlayers} \
          -ip ${cfg.launchOptions.ip} \
          -port ${toString cfg.launchOptions.port} \
          +map ${cfg.launchOptions.map} \
          +sv_setsteamaccount ${cfg.launchOptions.gameLoginToken}
        '';
        TimeoutStartSec = 0;
        RestartSec = "120s";
        Restart = "always";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = "${cfg.stateDir}";
      };
    };
  };
}
