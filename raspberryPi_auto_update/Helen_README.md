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

# Side Note

## How to create a shortcut for it:

### 2 options:
1. A standard Windows shortcut
    **Steps:**
    1. Right‑click your desktop → New → Shortcut
    2. Paste this in location:
        powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\hellz\OneDrive\Programing\powershell\powershell_projects\raspberryPi_auto_update\PiMaintenance-Run.ps1"
    3. Name it: Run Raspberry Pi Maintenance
    4. Optional: Give it a cute icon
        1. Right‑click the shortcut → Properties
        2. Click Change Icon
        3. Choose something fun (or browse to a custom .ico file)
    Done. Double‑click the icon → your whole maintenance system runs.
    This works even if VS Code isn’t open, even if your venv isn’t activated, even if you’re half‑asleep.
    **Why this works without activating your venv**
    - Your script doesn’t use Python.
    - Your venv is irrelevant.
    - Everything is PowerShell + SSH.
    - So the shortcut can run the script directly.

2. A .bat launcher file (if you want a custom icon without messing with Windows’ icon picker)
    **Steps:**
    1. Create a file: RunPiMaintenance.bat
    2. Put this inside:
        powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\hellz\OneDrive\Programing\powershell\powershell_projects\raspberryPi_auto_update\PiMaintenance-Run.ps1"
    pause
    3. Then create a shortcut to the .bat file and assign any icon you want.
    **This is useful if you want:**
        a Raspberry Pi icon
        a terminal icon
        a wizard icon (because your Pi is named thewizard)

3. A PowerShell .ps1 launcher with a custom icon (advanced)
    **Steps:**
    1. You can create a tiny launcher script:
        Start-PiMaintenance.ps1
    2. Inside:
        & "C:\Users\hellz\OneDrive\Programing\powershell\powershell_projects\raspberryPi_auto_update\PiMaintenance-Run.ps1"
    3. Then create a shortcut to that file.

**Which option should YOU use?**
✔ Option 1
If you want the simplest, cleanest, most Windows‑native solution.

✔ Option 2
If you want a custom icon and a little “pause” so you can see the output.

✔ Option 3
If you want a launcher script for aesthetic reasons.

Recommendation: Option 1.
It’s perfect for your setup.