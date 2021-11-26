# Multiple pdf password remover

## Description
A really simple script to remove (not crack !) password from multiple pdf files.
Simply put the .py script in the same directory than pdf files you want to remove password, then launch script.
**It will search all pdf files into subdirectories** and try to remove password protection.

I'm using pikepdf instead of PyPDF2 because it's support Adobe 6+ encryption

## Config
1) Install pikepdf `pip install pikepdf`
2) Install coloredlogs `pip install coloredlogs` (if you don't want to add this dependency, just #comment lines 4, 21, 22, 23 into the script)
3) Edit line 7 to put your owner password (must be the same for all your pdf files)

## Warning
This script will overwrite pdf files : please make sure you had copy of encrypted pdf ! (you can edit line 13 with something like `pdf.save(".\\" + "uncrypted_" + files)` if you don't want to overwrite existing files)

## Exemple
Tree :
`C:.
│   pdf_crypted_1.pdf
│   pdf_password_remover_subdirectories.py
│   pdf_uncrypted_1.pdf
│
└───folder
        pdf_crypted_2.pdf
        pdf_uncrypted_2.pdf`

Log file :
`[2021-11-26 22:24:15,895] [INFO] 1) File processing : pdf_crypted_1.pdf (C:\Users\Thomas\Desktop\pdf_test\action\pdf_crypted_1.pdf)
[2021-11-26 22:24:15,904] [INFO] Successfully remove password on pdf_crypted_1.pdf
[2021-11-26 22:24:15,904] [INFO] 2) File processing : pdf_uncrypted_1.pdf (C:\Users\Thomas\Desktop\pdf_test\action\pdf_uncrypted_1.pdf)
[2021-11-26 22:24:15,907] [INFO] pdf_uncrypted_1.pdf isn't lock with a password
[2021-11-26 22:24:15,907] [INFO] 3) File processing : pdf_crypted_2.pdf (C:\Users\Thomas\Desktop\pdf_test\action\folder\pdf_crypted_2.pdf)
[2021-11-26 22:24:15,912] [ERROR] Bad password for pdf_crypted_2.pdf
[2021-11-26 22:24:15,912] [INFO] 4) File processing : pdf_uncrypted_2.pdf (C:\Users\Thomas\Desktop\pdf_test\action\folder\pdf_uncrypted_2.pdf)
[2021-11-26 22:24:15,926] [INFO] pdf_uncrypted_2.pdf isn't lock with a password`

## Screenshots
