#!/bin/bash
#
# Direct VyOS installation from ISO without intermediate boot
# Runs from rescue system, extracts ISO contents, and installs VyOS to disk
#

set -e

# Configuration variables
IMAGE_NAME="${IMAGE_NAME:-VyOS-1.5}"
DISK="${DISK:-/dev/sda}"
PASSWORD="${PASSWORD:-vyos}"
CONSOLE_TYPE="${CONSOLE_TYPE:-tty}"
DIR_INSTALLATION="/mnt/installation"
DIR_DST_ROOT="${DIR_INSTALLATION}/disk_dst"
ISO_MOUNT="/mnt/vyos-iso"

echo "VyOS Direct Installation"
echo "========================"
echo "Target disk: $DISK"
echo "Image name: $IMAGE_NAME"
echo "Console: $CONSOLE_TYPE"
echo ""

# Verify ISO exists
if [ ! -f /tmp/boot.iso ]; then
    echo "ERROR: /tmp/boot.iso not found!"
    exit 1
fi

# Mount the ISO
echo "Mounting ISO..."
mkdir -p "$ISO_MOUNT"
mount -o loop /tmp/boot.iso "$ISO_MOUNT"

# Verify required files exist in ISO
if [ ! -f "$ISO_MOUNT/live/filesystem.squashfs" ]; then
    echo "ERROR: filesystem.squashfs not found in ISO"
    umount "$ISO_MOUNT"
    exit 1
fi

if [ ! -f "$ISO_MOUNT/live/vmlinuz" ] || [ ! -f "$ISO_MOUNT/live/initrd.img" ]; then
    echo "ERROR: Kernel files not found in ISO"
    umount "$ISO_MOUNT"
    exit 1
fi

echo "ISO mounted successfully"

# Clean up any previous installation attempts
umount -R "$DIR_INSTALLATION" 2>/dev/null || true
rm -rf "$DIR_INSTALLATION"

# Create partition table
echo "Creating partition table on $DISK..."
wipefs -af "$DISK" 2>/dev/null || true
sgdisk --zap-all "$DISK"

# Create partitions:
# 1: BIOS boot partition (2048-4095 sectors)
# 2: EFI system partition (4096 + 256MB)
# 3: Root partition (rest of disk)
sgdisk -a1 \
  -n1:2048:4095 -t1:EF02 \
  -n2:4096:+256M -t2:EF00 \
  -n3:0:0 -t3:8300 \
  "$DISK"

# Update kernel partition table
sync
blockdev --rereadpt "$DISK" 2>/dev/null || partx -a "$DISK" 2>/dev/null || true
sleep 2

# Determine partition names
# Note: Some environments (like Hetzner/QEMU) use non-sequential numbering (1, 14, 15)
if [ -b "${DISK}p1" ]; then
  # NVMe/MMC style
  PART_BIOS="${DISK}p1"
  PART_EFI="${DISK}p2"
  PART_ROOT="${DISK}p3"
elif [ -b "${DISK}14" ]; then
  # Hetzner/QEMU style
  PART_BIOS="${DISK}1"
  PART_EFI="${DISK}14"
  PART_ROOT="${DISK}15"
else
  # Standard style
  PART_BIOS="${DISK}1"
  PART_EFI="${DISK}2"
  PART_ROOT="${DISK}3"
fi

echo "Using partitions: BIOS=$PART_BIOS, EFI=$PART_EFI, Root=$PART_ROOT"

echo "Creating filesystems..."
mkfs.fat -F 32 -n EFI "$PART_EFI"
mkfs.ext4 -F -L persistence "$PART_ROOT"

# Create mount points
echo "Mounting partitions..."
mkdir -p "$DIR_DST_ROOT"
mount "$PART_ROOT" "$DIR_DST_ROOT"
mkdir -p "$DIR_DST_ROOT/boot/efi"
mount "$PART_EFI" "$DIR_DST_ROOT/boot/efi"

# Create directory structure
echo "Creating directory structure..."
mkdir -p "$DIR_DST_ROOT/boot/$IMAGE_NAME/rw/opt/vyatta/etc/config"
chmod 2775 "$DIR_DST_ROOT/boot/$IMAGE_NAME/rw/opt/vyatta/etc/config"

# Copy kernel files from ISO
echo "Copying kernel files from ISO..."
cp "$ISO_MOUNT/live/vmlinuz" "$DIR_DST_ROOT/boot/$IMAGE_NAME/"
cp "$ISO_MOUNT/live/initrd.img" "$DIR_DST_ROOT/boot/$IMAGE_NAME/"

# Copy squashfs from ISO
echo "Copying system image from ISO..."
cp "$ISO_MOUNT/live/filesystem.squashfs" "$DIR_DST_ROOT/boot/$IMAGE_NAME/${IMAGE_NAME}.squashfs"

# Create default configuration
echo "Creating default configuration..."
ENCRYPTED_PASSWORD=$(python3 -c "import crypt; print(crypt.crypt('$PASSWORD', crypt.METHOD_SHA512))")

cat >"$DIR_DST_ROOT/boot/$IMAGE_NAME/rw/opt/vyatta/etc/config/config.boot" <<EOF
system {
    host-name vyos
    login {
        user vyos {
            authentication {
                encrypted-password "$ENCRYPTED_PASSWORD"
            }
        }
    }
}
EOF

touch "$DIR_DST_ROOT/boot/$IMAGE_NAME/rw/opt/vyatta/etc/config/.vyatta_config"

# Create persistence.conf
echo "/ union" >"$DIR_DST_ROOT/persistence.conf"

# Set up GRUB configuration
echo "Installing GRUB configuration..."
mkdir -p "$DIR_DST_ROOT/boot/grub/grub.cfg.d/vyos-versions"

# Create main grub.cfg
cat >"$DIR_DST_ROOT/boot/grub/grub.cfg" <<'GRUBEOF'
load_env
insmod regexp

for cfgfile in ${prefix}/grub.cfg.d/*-autoload.cfg
do
    source ${cfgfile}
done
GRUBEOF

# Create GRUB header file
cat >"$DIR_DST_ROOT/boot/grub/grub.cfg.d/00-vyos-header.cfg" <<'GRUBEOF'
set VYOS_CFG_VER=1
GRUBEOF

# Create GRUB modules file
cat >"$DIR_DST_ROOT/boot/grub/grub.cfg.d/10-vyos-modules-autoload.cfg" <<'GRUBEOF'
# modules are loaded automatically
GRUBEOF

# Create GRUB variables file
cat >"$DIR_DST_ROOT/boot/grub/grub.cfg.d/20-vyos-defaults-autoload.cfg" <<GRUBEOF
set timeout=5
set console_type=$CONSOLE_TYPE
set console_num=0
set console_speed=115200
set bootmode=normal
set default=0
GRUBEOF

# Create common configuration
cat >"$DIR_DST_ROOT/boot/grub/grub.cfg.d/25-vyos-common-autoload.cfg" <<'GRUBEOF'
# load EFI video modules
if [ "${grub_platform}" == "efi" ]; then
    insmod efi_gop
    insmod efi_uga
fi

# create and activate serial console
function setup_serial {
    if [ "${console_type}" == "ttyS" ]; then
        if [ "${console_num}" == "0" ]; then
          serial --unit=0 --speed=${console_speed}
        else
          serial --unit=${console_num} --speed=115200
        fi
    else
        serial --unit=0 --speed=${console_speed}
    fi
    terminal_output --append serial console
    terminal_input --append serial console
}

setup_serial
GRUBEOF

# Create menu configuration
cat >"$DIR_DST_ROOT/boot/grub/grub.cfg.d/40-vyos-menu-autoload.cfg" <<'GRUBEOF'
for cfgfile in ${config_directory}/vyos-versions/*.cfg
do
    source "${cfgfile}"
done
source ${config_directory}/50-vyos-options.cfg
GRUBEOF

# Create boot options menu
cat >"$DIR_DST_ROOT/boot/grub/grub.cfg.d/50-vyos-options.cfg" <<'GRUBEOF'
submenu "Boot options" {
    submenu "Select boot mode" {
        menuentry "Normal" {
            set bootmode="normal"
            export bootmode
            configfile ${prefix}/grub.cfg.d/*vyos-menu*.cfg
        }
        menuentry "Password reset" {
            set bootmode="pw_reset"
            export bootmode
            configfile ${prefix}/grub.cfg.d/*vyos-menu*.cfg
        }
        menuentry "System recovery" {
            set bootmode="recovery"
            export bootmode
            configfile ${prefix}/grub.cfg.d/*vyos-menu*.cfg
        }
    }
    submenu "Select console type" {
        menuentry "tty (graphical)" {
            set console_type="tty"
            export console_type
            configfile ${prefix}/grub.cfg.d/*vyos-menu*.cfg
        }
        menuentry "ttyS (serial)" {
            set console_type="ttyS"
            export console_type
            setup_serial
            configfile ${prefix}/grub.cfg.d/*vyos-menu*.cfg
        }
    }
    menuentry "Current: boot mode: ${bootmode}, console: ${console_type}${console_num}" {
        echo
    }
}
GRUBEOF

# Generate UUID for the image
IMAGE_UUID=$(python3 -c "import uuid; print('uuid5-' + str(uuid.uuid5(uuid.NAMESPACE_URL, '$IMAGE_NAME')))")

# Create GRUB menu entry for the image
cat >"$DIR_DST_ROOT/boot/grub/grub.cfg.d/vyos-versions/${IMAGE_NAME}.cfg" <<GRUBEOF
menuentry "$IMAGE_NAME" --id $IMAGE_UUID {
    set boot_opts="boot=live rootdelay=5 noautologin net.ifnames=0 biosdevname=0 vyos-union=/boot/$IMAGE_NAME"
    if [ "\${console_type}" == "ttyS" ]; then
        set console_opts="console=\${console_type}\${console_num},\${console_speed}"
    else
        set console_opts="console=\${console_type}\${console_num}"
    fi
    if [ "\${bootmode}" == "pw_reset" ]; then
        set boot_opts="\${boot_opts} \${console_opts} init=/usr/libexec/vyos/system/standalone_root_pw_reset"
    elif [ "\${bootmode}" == "recovery" ]; then
        set boot_opts="\${boot_opts} \${console_opts} init=/usr/bin/busybox init"
    else
        set boot_opts="\${boot_opts} \${console_opts}"
    fi
    linux "/boot/$IMAGE_NAME/vmlinuz" \${boot_opts}
    initrd "/boot/$IMAGE_NAME/initrd.img"
}
GRUBEOF

# Install GRUB bootloader
echo "Installing GRUB bootloader..."

# Install required GRUB packages if not present
if ! dpkg -l | grep -q grub-efi-amd64-bin; then
  echo "Installing GRUB packages..."
  apt-get update -qq
  apt-get install -y -qq grub-efi-amd64-bin grub-pc-bin 2>/dev/null || true
fi

if [ "$(uname -m)" = "x86_64" ]; then
  # BIOS mode (optional, skip if modules not available)
  if [ -d /usr/lib/grub/i386-pc ]; then
    echo "Installing BIOS bootloader..."
    grub-install --no-floppy --target=i386-pc \
      --boot-directory="$DIR_DST_ROOT/boot" "$DISK" --force
  else
    echo "Skipping BIOS bootloader (modules not available)"
  fi
  
  # UEFI mode (required for Hetzner Cloud)
  echo "Installing UEFI bootloader..."
  grub-install --no-floppy --recheck --target=x86_64-efi \
    --force-extra-removable \
    --boot-directory="$DIR_DST_ROOT/boot" \
    --efi-directory="$DIR_DST_ROOT/boot/efi" \
    --bootloader-id="VyOS" \
    --no-uefi-secure-boot
elif [ "$(uname -m)" = "aarch64" ]; then
  grub-install --no-floppy --recheck --target=arm64-efi \
    --force-extra-removable \
    --boot-directory="$DIR_DST_ROOT/boot" \
    --efi-directory="$DIR_DST_ROOT/boot/efi" \
    --bootloader-id="VyOS" \
    --no-uefi-secure-boot
fi

# Sync and unmount
echo "Finalizing installation..."
sync
umount "$DIR_DST_ROOT/boot/efi"
umount "$DIR_DST_ROOT"

# Cleanup
rm -rf "$DIR_INSTALLATION"
umount "$ISO_MOUNT"
rmdir "$ISO_MOUNT"
rm -f /tmp/boot.iso

echo ""
echo "Installation complete!"
echo "Image '$IMAGE_NAME' has been installed to $DISK"
echo ""
echo "Default login: vyos / $PASSWORD"
echo ""
echo "The system is ready for snapshot creation."
