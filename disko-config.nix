# disko-config.nix
{ disks ? [ "/dev/sda" ], ... }: {
  disko.devices.disk.main = {
    device = builtins.elemAt disks 0;
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "@root" = { mountpoint = "/"; mountOptions = [ "compress=zstd" "noatime" ]; };
              "@home" = { mountpoint = "/home"; mountOptions = [ "compress=zstd" "noatime" ]; };
              "@nix" = { mountpoint = "/nix"; mountOptions = [ "compress=zstd" "noatime" ]; };
              "@log" = { mountpoint = "/var/log"; mountOptions = [ "compress=zstd" "noatime" ]; };
	    };
          };
        };
      };
    };
  };
}
