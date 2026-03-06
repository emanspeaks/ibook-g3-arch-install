# ibook-g3-arch-install

Script for installing ArchPower on a 2003 Snow iBook G3 (M9018) [900MHz, 256MB, 40GB HDD]

## Prerequisites

Download an [ArchPower](https://github.com/kth5/archpower) ISO and burn to a Live CD.
I used the 2026.02.01 release for [powerpc](https://archlinuxpower.org/iso/stable/archpower-2026.02.01-powerpc.iso).
Insert the CD into the Mac, and hold down C while the computer boots.
This should boot into grub on the CD.
Choose the installer from the menu and wait while Linux boots.
This will take a long time.

Once you get to a command prompt, enter:
`curl -sL https://raw.githubusercontent.com/emanspeaks/ibook-g3-arch-install/main/install.sh | bash`
