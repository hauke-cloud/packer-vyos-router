#!/bin/bash
set -e

echo "Setting up ISO boot..."

# Verify ISO exists
if [ ! -f /tmp/boot.iso ]; then
    echo "ERROR: /tmp/boot.iso not found!"
    exit 1
fi

echo "ISO file size: $(du -h /tmp/boot.iso | cut -f1)"

# Create working directory on root partition
sudo mkdir -p /live

# Copy the ISO to boot partition
echo "Copying ISO to /live/boot.iso..."
sudo cp /tmp/boot.iso /live/boot.iso
ls -lh /live/boot.iso

# Get boot partition device and UUID
BOOTDEV=$(df /boot | tail -1 | awk '{print $1}')
BOOTUUID=$(sudo blkid $BOOTDEV | sed -n 's/.* UUID="\([^"]*\)".*/\1/p')

if [ -z "$BOOTUUID" ]; then
    echo "Error: Could not determine boot UUID"
    echo "Boot device: $BOOTDEV"
    sudo blkid
    exit 1
fi

echo "Boot device: $BOOTDEV"
echo "Boot UUID: $BOOTUUID"

# Determine the partition path for fromiso parameter
# For /dev/sda1 use /dev/sda1, for /dev/vda1 use /dev/vda1, etc.
FROMISO_PATH=$(echo $BOOTDEV | sed 's|/dev/||')/live/boot.iso

echo "ISO will be loaded from: $FROMISO_PATH"

# Create GRUB entry for ISO boot
echo "Creating GRUB menu entry..."

# Create the complete GRUB script with proper heredoc handling
cat > /tmp/grub_script <<GRUBSCRIPT
#!/bin/sh
cat << 'GRUBENTRY'
menuentry "VyOS ISO Boot" {
         set isofile="/live/boot.iso"
         insmod part_gpt
         insmod part_msdos
         insmod ext2
         insmod loopback
         insmod iso9660
         search --no-floppy --fs-uuid --set=root ${BOOTUUID}
         loopback loop \$isofile
         linux (loop)/live/vmlinuz fromiso=/dev/${FROMISO_PATH} boot=live toram username=vyos hostname=vyos
         initrd (loop)/live/initrd.img
}
GRUBENTRY
GRUBSCRIPT

sudo mv /tmp/grub_script /etc/grub.d/09_isoboot
sudo chmod +x /etc/grub.d/09_isoboot

echo "Verifying GRUB script was created:"
ls -la /etc/grub.d/09_isoboot
echo "Content of /etc/grub.d/09_isoboot:"
sudo cat /etc/grub.d/09_isoboot
echo ""

echo "Updating GRUB configuration..."
sudo update-grub 2>&1 | grep -E "(VyOS|ISO|Found|Generating)"

echo ""
echo "Listing GRUB menu entries..."
awk -F\' '/menuentry / {print NR-1 ": " $2}' /boot/grub/grub.cfg

echo ""
# Find the ISO Boot entry
ISO_ENTRY=$(awk -F\' '/menuentry / {print $2}' /boot/grub/grub.cfg | grep -n "VyOS ISO Boot" | cut -d: -f1)
if [ -n "$ISO_ENTRY" ]; then
    # GRUB menu entries are 0-indexed
    ISO_INDEX=$((ISO_ENTRY - 1))
    echo "Found VyOS ISO Boot at index: $ISO_INDEX"
    sudo sed -i "s/^GRUB_DEFAULT=.*/GRUB_DEFAULT=$ISO_INDEX/" /etc/default/grub
else
    echo "WARNING: Could not find VyOS ISO Boot by index, setting by name"
    sudo sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT="VyOS ISO Boot"/' /etc/default/grub
fi

# Update GRUB with the new default
echo "Updating GRUB with new default..."
sudo update-grub

echo "Current GRUB default:"
grep "^GRUB_DEFAULT" /etc/default/grub

echo "GRUB configuration ready. Rebooting into VyOS ISO..."
sleep 2
sudo reboot
