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

    echo "Registering plugins and configs"
    rm -rf "${cfg.stateDir}/csgo/addons"
    for plugin in ${plugins}/*; do
      echo "Registering $plugin"
      cp -rLv --no-preserve=mode,ownership $plugin/share/* "${cfg.stateDir}/csgo"
    done
    ${linkConfigs}
    ln -fsv ${adminsFile} "${cfg.stateDir}/csgo/addons/sourcemod/configs/admins_simple.ini"
    echo "Done registering plugins and configs"

    # Fix permissions
    chown -R ${cfg.user}:${cfg.group} ${cfg.stateDir}
    chmod -R +w ${cfg.stateDir}
  '';

  plugins = pkgs.linkFarmFromDrvs "csgods-plugins" cfg.plugins;

  linkConfigs = lib.concatMapStringsSep "\n" ({ name, content }: ''ln -fsv "${pkgs.writeText name content}" "${cfg.stateDir}/csgo/cfg/${name}"'') cfg.configs;

  adminsFile = pkgs.writeText "admins_simple.ini" (lib.concatMapStringsSep "\n" (admin: ''"${admin}" "z"'') cfg.pluginOptions.admins);

  pluginOptions = with types; {
    admins = mkOption {
      type = listOf str;
      default = [];
    };
  };

  launchOptions = with types; {
    tickrate = mkOption {
      type = int;
      default = 128;
      description = "Server tickrate";
    };
    maxPlayers = mkOption {
      type = int;
      default = 14;
      description = "Slots on the server";
    };
    ip = mkOption {
      type = str;
      default = "0.0.0.0";
      description = "IP address the server binds to";
    };
    port = mkOption {
      type = int;
      default = 27015;
      description = "Server port";
    };
    map = mkOption {
      type = str;
      default = "de_dust2";
      description = "Starting map";
    };
    gameLoginToken = mkOption {
      type = nullOr str;
      description = ''
        Game Login Token, which is required for non-LAN servers.
        Can be generated on https://steamcommunity.com/dev/managegameservers.
        Note that you need different ones for each server.
      '';
      default = null;
    };
  };
in
{
  options.services.csgods = with types; {
    enable = mkEnableOption "CS:GO dedicated server";

    user = mkOption {
      type = str;
      default = "csgods";
      description = "User account under which csgods runs.";
    };

    group = mkOption {
      type = str;
      default = "csgods";
      description = "Group under which csgods runs.";
    };

    stateDir = mkOption {
      type = str;
      default = "/var/lib/csgods";
      description = "Directory for CS:GO dedicated server files.";
    };

    pluginOptions = mkOption {
      type = submodule { options = pluginOptions; };
      default = {};
      description = "Options for sourcemod and sourcemod plugins";
    };

    launchOptions = mkOption {
      type = submodule { options = launchOptions; };
      default = {};
      description = "Launch options to be provided for the server";
    };

    plugins = mkOption {
      type = listOf package;
      default = [ ];
      description = "CS:GO server plugins to be installed on the server";
    };

    configs = mkOption {
      type = listOf attrs;
      default = [ ];
      description = "Config files available to be executed by the server with `exec`";
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
      after = [ "network-online.target" ];
      wantedBy = [ "network-online.target" ];
      environment = {
        LD_LIBRARY_PATH = "${cfg.stateDir}:${cfg.stateDir}/bin";
      };
      serviceConfig = {
        ExecStartPre = "${csgods-update}";
        ExecStart = ''${cfg.stateDir}/srcds_run \
          -game csgo -usercon \
          +game_type 0 +game_mode 1 \
          -autoupdate -steam_dir ${cfg.stateDir} -steamcmd_script ${csgods-update} \
          -tickrate ${toString cfg.launchOptions.tickrate} \
          -maxplayers ${toString cfg.launchOptions.maxPlayers} \
          -ip ${cfg.launchOptions.ip} \
          -port ${toString cfg.launchOptions.port} \
          +map ${cfg.launchOptions.map} \
          ${optionalString (cfg.launchOptions.gameLoginToken != null) "+sv_setsteamaccount ${cfg.launchOptions.gameLoginToken}"}
        '';
        TimeoutStartSec = 0;
        RestartSec = "120s";
        Restart = "always";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = "-${cfg.stateDir}";
      };
    };
  };
}
