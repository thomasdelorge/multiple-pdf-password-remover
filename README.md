# simple-pdf-password-remover

## Description
A really simple script to remove (not crack !) password from multiple pdf files.
Simply put the .py script in the same directory than pdf files you want to remove password, then launch script.

I'm using pikepdf instead of PyPDF2 because it's support Adobe 6+ encryption

## Config
Edit line 5 to put your owner password (must be the same for all your pdf files)

## Warning :
1) This script won't search into subdirectories
2) This script will overwrite pdf files : please make sure you had copy of encrypted pdf ! (you can edit line 13 with something like `pdf.save(".\\" + "uncrypted_" + files)` if you don't want to overwrite existing files)
