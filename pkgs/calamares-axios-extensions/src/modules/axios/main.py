#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
#
# axiOS Calamares job module
#
# Generates an axiOS flake structure and runs nixos-install.
# Replaces the upstream NixOS "nixos" job module.

import os
import re
import shutil
import subprocess
import libcalamares

# ─── Template constants ───────────────────────────────────────────
# Using @@var@@ markers to avoid conflict with Nix's { } braces.

cfg_flake = """\
{
  description = "NixOS configuration for @@hostname@@";

  inputs = {
    # Use axios as the base framework
    axios.url = "github:kcalvelli/axios";

    # Follow axios's nixpkgs to ensure compatibility
    nixpkgs.follows = "axios/nixpkgs";
  };

  outputs = { self, axios, nixpkgs, ... }:
    let
      # Helper to build a host configuration
      # Each host declares its users by name; axiOS resolves users/<name>.nix automatically
      mkHost = hostname: axios.lib.mkSystem (
        (import ./hosts/${hostname}.nix { lib = nixpkgs.lib; }).hostConfig // {
          configDir = self.outPath;
        }
      );
    in
    {
      nixosConfigurations = {
        @@hostname@@ = mkHost "@@hostname@@";
      };
    };
}
"""

cfg_host = """\
# Host: @@hostname@@ (@@formfactor@@)
{ lib, ... }:
{
  hostConfig = {
    # Basic identification
    hostname = "@@hostname@@";
    system = "x86_64-linux";
    formFactor = "@@formfactor@@";

    # Users on this host (references users/<name>.nix)
    users = [ "@@username@@" ];

    # Hardware configuration
    hardware = {
      cpu = @@cpu@@;
      gpu = @@gpu@@;
      hasSSD = @@hasssd@@;
      isLaptop = @@islaptop@@;
    };

    # NixOS modules to enable
    modules = {
      system = true;
      desktop = true;
      development = true;
      graphics = true;
      networking = true;
      users = true;
      virt = @@enable_virt@@;
      gaming = @@enable_gaming@@;
      pim = @@enable_pim@@;
      secrets = @@enable_secrets@@;
    };

    # Virtualization (if virt module enabled)
    virt = {
      libvirt.enable = @@enable_libvirt@@;
      containers.enable = @@enable_containers@@;
    };

    # Home-manager profile default
    homeProfile = "@@homeprofile@@";

    # Hardware configuration path
    hardwareConfigPath = ./@@hostname@@/hardware.nix;

    # Extra NixOS configuration
    extraConfig = {
      # System timezone (required)
      axios.system.timeZone = "@@timezone@@";
@@extra_config@@
    };
  };
}
"""

cfg_user = """\
{ ... }:
{
  axios.users.users.@@username@@ = {
    fullName = "@@fullname@@";
    isAdmin = true;
    homeProfile = "@@homeprofile@@";
  };
}
"""


def catenate(d, key, *args):
    """Set d[key] to the concatenation of args, but only if no arg is None."""
    for a in args:
        if a is None:
            return
    d[key] = "".join(str(a) for a in args)


def nix_bool(val):
    """Convert a Python truthy value to a Nix boolean string."""
    return "true" if val else "false"


def nix_string_or_null(val):
    """Convert a string to a Nix string literal, or null if None/empty."""
    if val:
        return '"{}"'.format(val)
    return "null"


def generate_proxy_strings():
    """Build env command prefix for proxy variables."""
    assignments = []
    for var in ("http_proxy", "https_proxy", "HTTP_PROXY", "HTTPS_PROXY",
                "ftp_proxy", "FTP_PROXY", "no_proxy", "NO_PROXY"):
        val = os.environ.get(var)
        if val:
            assignments.append("{}={}".format(var, val))
    if assignments:
        return ["env"] + assignments
    return []


def fix_btrfs_subvolumes(hw_config_path):
    """
    Fix btrfs subvolume options in hardware-configuration.nix.
    nixos-generate-config sometimes gets subvol= paths wrong.
    """
    if not os.path.exists(hw_config_path):
        return

    with open(hw_config_path, "r") as f:
        content = f.read()

    # Map mount points to expected subvolume names
    subvol_map = {
        "/home": "home",
        "/nix": "nix",
    }

    for mount, subvol in subvol_map.items():
        # Fix subvol= option for known mount points
        pattern = r'(fileSystems\."{}"\s*=\s*\{{[^}}]*options\s*=\s*\[)([^\]]*)(])'.format(
            re.escape(mount)
        )
        match = re.search(pattern, content, re.DOTALL)
        if match:
            options = match.group(2)
            # Replace any existing subvol= with the correct one
            new_options = re.sub(
                r'"subvol=([^"]*)"',
                '"subvol={}"'.format(subvol),
                options
            )
            content = content[:match.start(2)] + new_options + content[match.end(2):]

    # For root mount point, remove subvol= entirely (use top-level)
    pattern = r'(fileSystems\."/"\s*=\s*\{[^}]*options\s*=\s*\[)([^\]]*)(])'
    match = re.search(pattern, content, re.DOTALL)
    if match:
        options = match.group(2)
        new_options = re.sub(r'\s*"subvol=[^"]*"\s*', " ", options)
        content = content[:match.start(2)] + new_options + content[match.end(2):]

    with open(hw_config_path, "w") as f:
        f.write(content)


def strip_unfree_hw_packages(hw_config_path):
    """
    Remove unfree packages from boot.extraModulePackages in
    hardware-configuration.nix when unfree is disabled.
    """
    if not os.path.exists(hw_config_path):
        return

    with open(hw_config_path, "r") as f:
        content = f.read()

    # Find boot.extraModulePackages line
    pattern = r'boot\.extraModulePackages\s*=\s*\[([^\]]*)\]'
    match = re.search(pattern, content)
    if not match:
        return

    packages_str = match.group(1).strip()
    if not packages_str:
        return

    # Check each package for unfree status via nix-instantiate
    packages = [p.strip() for p in packages_str.split() if p.strip()]
    free_packages = []

    for pkg in packages:
        try:
            result = subprocess.run(
                ["nix-instantiate", "--eval", "-E",
                 "with import <nixpkgs> {{}}; ({}).meta.unfree or false".format(pkg)],
                capture_output=True, text=True, timeout=30
            )
            is_unfree = result.stdout.strip() == "true"
            if not is_unfree:
                free_packages.append(pkg)
        except (subprocess.TimeoutExpired, Exception):
            # If we can't determine, keep the package
            free_packages.append(pkg)

    new_packages_str = " ".join(free_packages)
    content = content[:match.start(1)] + " " + new_packages_str + " " + content[match.end(1):]

    with open(hw_config_path, "w") as f:
        f.write(content)


def run():
    """Main Calamares job entry point."""
    gs = libcalamares.globalstorage
    root_mount_point = gs.value("rootMountPoint")

    if not root_mount_point:
        return ("Failed to find mount point",
                "globalstorage does not contain a rootMountPoint")

    # ─── Read globalstorage ─────────────────────────────────────
    variables = {}

    catenate(variables, "hostname", gs.value("hostname"))
    catenate(variables, "username", gs.value("username"))
    catenate(variables, "fullname", gs.value("fullname"))
    catenate(variables, "timezone",
             gs.value("locationRegion"), "/", gs.value("locationZone"))

    allow_unfree = gs.value("nixos_allow_unfree")
    auto_login_user = gs.value("autoLoginUser")

    # Keyboard
    kb_layout = gs.value("keyboardLayout") or "us"
    kb_variant = gs.value("keyboardVariant") or ""

    # Firmware type
    firmware_type = gs.value("firmwareType") or "efi"

    # ─── axiOS-specific config from QML page / auto-detection ─────

    # Form factor: default to desktop
    form_factor = gs.value("axios_formFactor") or "desktop"
    variables["formfactor"] = form_factor
    variables["islaptop"] = nix_bool(form_factor == "laptop")

    # Hardware: use detected values or null for MVP
    cpu_vendor = gs.value("axios_cpuVendor")
    gpu_vendor = gs.value("axios_gpuVendor")
    variables["cpu"] = nix_string_or_null(cpu_vendor)
    variables["gpu"] = nix_string_or_null(gpu_vendor)
    variables["hasssd"] = nix_bool(gs.value("axios_hasSSD") or False)

    # Profile
    home_profile = gs.value("axios_homeProfile") or "standard"
    variables["homeprofile"] = home_profile

    # Feature toggles
    # Normie profile forces all optional modules off
    if home_profile == "normie":
        enable_gaming = False
        enable_pim = False
        enable_secrets = False
        enable_libvirt = False
        enable_containers = False
    else:
        enable_gaming = gs.value("axios_enableGaming") or False
        enable_pim = gs.value("axios_enablePim") or False
        enable_secrets = gs.value("axios_enableSecrets") or False
        enable_libvirt = gs.value("axios_enableLibvirt") or False
        enable_containers = gs.value("axios_enableContainers") or False
    enable_virt = enable_libvirt or enable_containers

    variables["enable_gaming"] = nix_bool(enable_gaming)
    variables["enable_pim"] = nix_bool(enable_pim)
    variables["enable_secrets"] = nix_bool(enable_secrets)
    variables["enable_virt"] = nix_bool(enable_virt)
    variables["enable_libvirt"] = nix_bool(enable_libvirt)
    variables["enable_containers"] = nix_bool(enable_containers)

    # ─── Build extra config lines ───────────────────────────────
    extra_lines = []

    # Keyboard layout in extraConfig
    if kb_layout:
        extra_lines.append(
            '      services.xserver.xkb.layout = "{}";'.format(kb_layout))
        if kb_variant:
            extra_lines.append(
                '      services.xserver.xkb.variant = "{}";'.format(kb_variant))

    # Unfree
    if allow_unfree:
        extra_lines.append(
            "      nixpkgs.config.allowUnfree = true;")

    # PIM role
    if enable_pim:
        pim_role = gs.value("axios_pimRole") or "server"
        extra_lines.append("")
        extra_lines.append(
            '      services.pim.role = "{}";'.format(pim_role))
        if pim_role == "server":
            extra_lines.append(
                '      services.pim.user = "{}";'.format(
                    variables.get("username", "")))

    # Immich
    enable_immich = gs.value("axios_enableImmich") or False
    if enable_immich:
        immich_role = gs.value("axios_immichRole") or "client"
        extra_lines.append("")
        extra_lines.append("      axios.immich.enable = true;")
        extra_lines.append(
            '      axios.immich.role = "{}";'.format(immich_role))

    # Local LLM
    enable_local_llm = gs.value("axios_enableLocalLlm") or False
    if enable_local_llm:
        llm_role = gs.value("axios_localLlmRole") or "server"
        extra_lines.append("")
        extra_lines.append("      services.ai.local.enable = true;")
        extra_lines.append(
            '      services.ai.local.role = "{}";'.format(llm_role))

    # Tailnet domain — notesqml doesn't support keyboard input, so we
    # write a placeholder that the user must update post-install.
    pim_role = gs.value("axios_pimRole") or "server"
    immich_role = gs.value("axios_immichRole") or "server"
    llm_role = gs.value("axios_localLlmRole") or "server"
    needs_tailnet = (
        (enable_pim and pim_role == "client")
        or (enable_immich and immich_role == "client")
        or (enable_local_llm and llm_role == "client")
    )
    if needs_tailnet:
        extra_lines.append("")
        extra_lines.append(
            '      # TODO: Update with your actual Tailnet domain')
        extra_lines.append(
            '      networking.tailscale.domain = "CHANGE-ME.ts.net";')
        # Set tailnetDomain for any service that requires it in client mode
        if enable_pim and pim_role == "client":
            extra_lines.append(
                '      services.pim.tailnetDomain = "CHANGE-ME.ts.net";')
        if enable_immich and immich_role == "client":
            extra_lines.append(
                '      axios.immich.tailnetDomain = "CHANGE-ME.ts.net";')
        if enable_local_llm and llm_role == "client":
            extra_lines.append(
                '      services.ai.local.tailnetDomain = "CHANGE-ME.ts.net";')

    # Secure boot
    enable_secureboot = gs.value("axios_enableSecureBoot") or False
    if enable_secureboot:
        extra_lines.append("")
        extra_lines.append(
            "      boot.lanzaboote.enableSecureBoot = true;")

    variables["extra_config"] = "\n".join(extra_lines)

    # ─── Validate required variables ────────────────────────────
    if "hostname" not in variables:
        return ("Missing hostname",
                "No hostname was set in the installer")
    if "username" not in variables:
        return ("Missing username",
                "No username was set in the installer")
    if "timezone" not in variables:
        return ("Missing timezone",
                "No timezone was set in the installer")

    libcalamares.job.setprogress(0.1)

    # ─── Generate config files ──────────────────────────────────
    hostname = variables["hostname"]
    nixos_dir = os.path.join(root_mount_point, "etc/nixos")
    hosts_dir = os.path.join(nixos_dir, "hosts")
    host_hw_dir = os.path.join(hosts_dir, hostname)
    users_dir = os.path.join(nixos_dir, "users")

    os.makedirs(host_hw_dir, exist_ok=True)
    os.makedirs(users_dir, exist_ok=True)

    # Apply variable substitution to templates
    def substitute(template):
        result = template
        for key, value in variables.items():
            pattern = "@@{}@@".format(key)
            result = result.replace(pattern, str(value))
        return result

    # Write flake.nix
    with open(os.path.join(nixos_dir, "flake.nix"), "w") as f:
        f.write(substitute(cfg_flake))

    # Write host config
    with open(os.path.join(hosts_dir, "{}.nix".format(hostname)), "w") as f:
        f.write(substitute(cfg_host))

    # Write user config
    with open(os.path.join(users_dir, "{}.nix".format(variables["username"])), "w") as f:
        f.write(substitute(cfg_user))

    libcalamares.job.setprogress(0.18)

    # ─── Generate hardware-configuration.nix ────────────────────
    try:
        subprocess.run(
            ["nixos-generate-config", "--root", root_mount_point],
            check=True, capture_output=True, text=True
        )
    except subprocess.CalledProcessError as e:
        return ("Failed to generate hardware config",
                "nixos-generate-config failed: {}".format(e.stderr))

    # Move hardware-configuration.nix to hosts/<hostname>/hardware.nix
    hw_source = os.path.join(root_mount_point, "etc/nixos/hardware-configuration.nix")
    hw_dest = os.path.join(host_hw_dir, "hardware.nix")
    if os.path.exists(hw_source):
        shutil.move(hw_source, hw_dest)

    # Remove the generated configuration.nix (we don't need it)
    gen_config = os.path.join(root_mount_point, "etc/nixos/configuration.nix")
    if os.path.exists(gen_config):
        os.remove(gen_config)

    # Fix btrfs subvolumes if needed
    fix_btrfs_subvolumes(hw_dest)

    # Strip unfree kernel packages if unfree is disabled
    if not allow_unfree:
        strip_unfree_hw_packages(hw_dest)

    libcalamares.job.setprogress(0.25)

    # ─── Lock the flake (requires network) ─────────────────────
    # nixos-install --flake will resolve inputs, but we lock first
    # to get a clear error if network is unavailable.
    libcalamares.utils.debug("Locking flake inputs (this requires network)...")
    try:
        subprocess.run(
            ["nix", "flake", "lock",
             "--extra-experimental-features", "nix-command flakes"],
            cwd=nixos_dir,
            check=True, capture_output=True, text=True,
            timeout=300
        )
    except subprocess.TimeoutExpired:
        return ("Flake lock timed out",
                "nix flake lock timed out after 5 minutes. "
                "Check your network connection.")
    except subprocess.CalledProcessError as e:
        return ("Failed to lock flake",
                "nix flake lock failed (is the network available?):\n{}".format(
                    e.stderr))

    libcalamares.job.setprogress(0.3)

    # ─── Run nixos-install ──────────────────────────────────────
    flake_ref = "{}#{}".format(
        os.path.join(root_mount_point, "etc/nixos"),
        hostname
    )

    cmd = []
    cmd.extend(generate_proxy_strings())
    cmd.extend([
        "nixos-install",
        "--no-root-passwd",
        "--root", root_mount_point,
        "--flake", flake_ref,
        "--option", "build-dir", "/nix/var/nix/builds",
    ])

    try:
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True
        )

        # Stream output for progress, keep last lines for error reporting
        last_lines = []
        for line in proc.stdout:
            stripped = line.rstrip()
            libcalamares.utils.debug("[nixos-install] " + stripped)
            last_lines.append(stripped)
            if len(last_lines) > 50:
                last_lines.pop(0)

        proc.wait()

        if proc.returncode != 0:
            tail = "\n".join(last_lines[-30:])
            return ("nixos-install failed",
                    "nixos-install exited with code {}\n\n{}".format(
                        proc.returncode, tail))

    except Exception as e:
        return ("nixos-install failed",
                "Error running nixos-install: {}".format(str(e)))

    libcalamares.job.setprogress(1.0)
    return None
