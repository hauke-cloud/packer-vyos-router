#!/bin/bash
set -e

echo "Setting up ISO boot..."

# Create working directory
sudo mkdir -p /live

# Copy the ISO to boot partition
echo "Copying ISO to boot partition..."
sudo cp /tmp/boot.iso /live/boot.iso

# Get boot partition UUID
BOOTUUID=$(sudo blkid | grep /dev/sda1: | sed -n 's/.* UUID="\([^"]*\)".*/\1/p')

if [ -z "$BOOTUUID" ]; then
    echo "Error: Could not determine boot UUID"
    exit 1
fi

echo "Boot UUID: $BOOTUUID"

# Create GRUB entry for ISO boot
sudo tee /etc/grub.d/09_isoboot > /dev/null <<'GRUBEOF'
#!/bin/sh
exec tail -n +3 $0
menuentry "ISO Boot" --class os --class gnu-linux --class gnu --class os --group group_main {
         set isofile="/live/boot.iso"
         insmod part_gpt
         insmod ext2
         insmod loopback
         insmod iso9660
         loopback loop (hd0,gpt1)$isofile
GRUBEOF

echo "         search --no-floppy --fs-uuid --set=root $BOOTUUID" | sudo tee -a /etc/grub.d/09_isoboot > /dev/null

# Boot VyOS with basic parameters
sudo tee -a /etc/grub.d/09_isoboot > /dev/null <<'GRUBEOF'
         linux (loop)/live/vmlinuz fromiso=/dev/sda1/$isofile boot=live toram username=vyos hostname=vyos
         initrd (loop)/live/initrd.img
}
GRUBEOF

sudo chmod +x /etc/grub.d/09_isoboot

echo "Updating GRUB configuration..."
sudo update-grub

echo "Listing GRUB menu entries..."
awk -F\' '/menuentry / {print $2}' /boot/grub/grub.cfg | nl -v 0

# The 09_ prefix should make it appear early in the menu
# Find the menu entry index for our ISO boot
ISO_ENTRY=$(awk -F\' '/menuentry / {print $2}' /boot/grub/grub.cfg | grep -n "ISO Boot" | cut -d: -f1)
if [ -n "$ISO_ENTRY" ]; then
    # GRUB menu entries are 0-indexed
    ISO_INDEX=$((ISO_ENTRY - 1))
    echo "Found ISO Boot at index: $ISO_INDEX"
    
    # Set GRUB_DEFAULT to boot the ISO entry
    sudo sed -i "s/^GRUB_DEFAULT=.*/GRUB_DEFAULT=$ISO_INDEX/" /etc/default/grub
    echo "Set GRUB_DEFAULT to $ISO_INDEX"
else
    echo "WARNING: Could not find ISO Boot entry, setting by name"
    sudo sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT="ISO Boot"/' /etc/default/grub
fi

# Update GRUB with the new default
sudo update-grub

echo "Current GRUB default:"
grep "^GRUB_DEFAULT" /etc/default/grub

echo "Rebooting into VyOS ISO..."
sudo reboot
