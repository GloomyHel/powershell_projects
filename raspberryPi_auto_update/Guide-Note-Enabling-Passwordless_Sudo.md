⭐ Guide Note — Enabling Passwordless Sudo for Raspberry Pi Maintenance Automation
Why this change was needed
Our PowerShell automation connects to the Raspberry Pi using SSH key‑based authentication, which removes the need to type the SSH password.

However, SSH keys only replace the login password.

They do not replace the sudo password.

Several commands in the maintenance script require elevated privileges:

sudo rm -rf /var/log/*

sudo apt upgrade -y

sudo pihole -up

When these run through a non‑interactive SSH session (like our script), sudo cannot prompt for a password. This causes failures such as:

Code
sudo: a terminal is required to read the password
To fix this, we safely enabled passwordless sudo for only the commands our automation needs.

This keeps the system secure while allowing the script to run unattended.

⭐ What we changed
We added a rule to the Pi’s sudoers configuration that allows your user (thewizard) to run specific commands without entering a password.

This is the safest approach because it:

does not grant full passwordless sudo

limits access to only the commands used by the automation

avoids weakening system security

⭐ How we applied the fix
1. SSH into the Raspberry Pi
bash
ssh thewizard@blockmagic
(or whatever your actual username/hostname is)

2. Open the sudoers file safely
Always use visudo — it validates syntax and prevents breaking sudo.

bash
sudo visudo
3. Add this line just above the @includedir line
Replace thewizard with your actual username if different.

text
thewizard ALL=(ALL) NOPASSWD: /usr/bin/apt, /usr/bin/apt-get, /usr/bin/pihole, /usr/bin/rm
Correct placement example
text
# Allow members of group sudo to execute any command
%sudo   ALL=(ALL:ALL) ALL

thewizard ALL=(ALL) NOPASSWD: /usr/bin/apt, /usr/bin/apt-get, /usr/bin/pihole, /usr/bin/rm

# See sudoers(5) for more information on "@include" directives:
@includedir /etc/sudoers.d
4. Save and exit nano
Inside visudo (nano):

CTRL + O → save

ENTER → confirm

CTRL + X → exit

Visudo will validate the file before applying changes.

⭐ Result
After this change:

log wiping works

apt upgrades work

Pi‑hole updates work

no more “terminal required” errors

the automation runs fully unattended

Your maintenance script now behaves exactly as intended.