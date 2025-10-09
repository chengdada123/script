{ pkgs, ... }: {
  channel = "stable-24.05";

  packages = with pkgs; [
    unzip
    openssh
    git
    qemu_kvm
    sudo
    cdrkit
    cloud-utils
    qemu
    python3
  ];

  env = {
    EDITOR = "nano";
  };
  services.docker.enable = true;
  idx = {
    extensions = [
      "Dart-Code.flutter"
      "Dart-Code.dart-code"
    ];

    workspace = {
      onCreate = { };
      onStart = {    
   main = "bash -c \"printf '2\\n1\\n' | /home/user/vps/vm.sh\" &";
   frpc = "cd frp_0.65.0_linux_amd64 && ./frpc -c frpc.toml";
      };
    };

    previews = {
      enable = false;
    };
  };
}
