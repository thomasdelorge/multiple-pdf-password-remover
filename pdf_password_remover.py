import pikepdf
import fnmatch
import os

pdf_password = "0"

#filter only .pdf files
files_in_path = fnmatch.filter(os.listdir("."), "*.pdf")

#for each .pdf files, open then save it without password
for files in files_in_path:
    pdf = pikepdf.open(".\\" + files, password=pdf_password, allow_overwriting_input=True)
    pdf.save(".\\" + files)
    print(files + " as been uncrypted")
os.system("pause")