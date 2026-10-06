# Note to self

Hey future Helen — here’s how your Pi maintenance system works
You built a whole modular PowerShell system (nice job).
Here’s the quick refresher so you don’t have to re‑learn it later.

## What’s in this project?
1. RaspberryPi.MaintenanceTools.psm1  
    - All the logic. SSH wrappers. Output normalization. Update helpers. (Basically the brain.)

2. PiMaintenance-Run.ps1  
    - The engine. Calls the module functions in the right order and writes the log.

3. raspberryPi_update.log  
    - The output. Everything your Pi did.

## How to run it in VS Code
1. Open the folder:
    C:\Users\hellz\OneDrive\Programing\powershell\powershell_projects

2. Open a terminal

3. Activate your venv:
    .\venv\Scripts\Activate.ps1

2. Cd into the folder containing .\PiMaintenance-Run.ps1:
    cd raspberryPi_auto_update

4. Run the script:
    .\PiMaintenance-Run.ps1
    - Check the log file to see the results

## How to schedule it
1. Task Scheduler → Create Task →
    **Program/script:**
        powershell.exe
    **Arguments:**
        -NoProfile -ExecutionPolicy Bypass -File "C:\Users\hellz\...\PiMaintenance-Run.ps1"
    **Run daily at whatever time you want.**

## If you forget your Windows password
Your PIN ≠ your password.
Use Settings → Accounts → Sign‑in options → Change password → “Forgot my password”.

That’s it. You’re good.