# High‑Level Architecture 

## Module (Tools)

Contains:

    - SSH execution
    - Normalisation
    - Logging
    - Error categories
    - UI output (Show-Step, Show-Result)
    - Maintenance commands
    - Update commands

## Runner 

Does:

    - Preflight checks
    - Calls module functions
    - Nothing else


## .psd1 manifest vs .psm1 file

The .psd1 manifest declares what should be exported,
but the .psm1 file controls what actually is exported.

PowerShell uses:

the manifest to filter exports
the module file to define exports
If the module file doesn’t export a function, the manifest cannot magically expose it.
So both must match.


add passwordless sudo only for the commands your script needs

ssh into the pi
run
sudo visudo
thewizard ALL=(ALL) NOPASSWD: /usr/bin/apt, /usr/bin/apt-get, /usr/bin/pihole, /usr/bin/rm
