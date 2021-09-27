import pikepdf
import fnmatch
import os

#Edit "0" with your own password, must be the same for all PDF files
pdf_password = "0"

#Filter PDF files only
files_in_path = fnmatch.filter(os.listdir("."), "*.pdf")

#For each .pdf files, open then save it without password
for files in files_in_path:
    pdf = pikepdf.open(".\\" + files, password=pdf_password, allow_overwriting_input=True)
    pdf.save(".\\" + files)
    print(files + " as been uncrypted")
os.system("pause")
