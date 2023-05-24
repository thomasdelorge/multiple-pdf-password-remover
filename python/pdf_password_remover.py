import os
import pikepdf
import logging
import coloredlogs

# CHANGE PASSWORD HERE
pdf_password = "changeme"

# Logs to scriptName.log
scriptName = os.path.basename(__file__)
logging.basicConfig(level=logging.DEBUG,
                    filename=scriptName + ".log",
                    filemode="a",
                    format='[%(asctime)s] [%(levelname)s] %(message)s')

# Logs into console
mylogs = logging.getLogger(__name__)
stream = logging.StreamHandler()
mylogs.addHandler(stream)
coloredlogs.install(level=logging.DEBUG,
                    logger=mylogs,
                    fmt='[%(asctime)s] [%(levelname)s] %(message)s')

rootdir = os.getcwd()
nb = 0
for subdir, dirs, files in os.walk(rootdir):
    for file in files:
        filepath = subdir + os.sep + file
        if filepath.endswith(".pdf"):
            nb += 1
            mylogs.info(str(nb) + ") File processing : " + file + " (" + filepath + ")")
            # Check if the PDF is password locked
            try:
                pdf = pikepdf.open(filepath)
                mylogs.info(file + " isn't locked with a password")
            except pikepdf.PasswordError:
                # If locked, try to unlock with password line 7
                try:
                    pdf = pikepdf.open(filepath, password=pdf_password, allow_overwriting_input=True)
                    pdf.save(filepath)
                    mylogs.info("Successfully remove password on " + file)
                except pikepdf.PasswordError:
                    mylogs.error("Bad password for " + file)
                except:  # default
                    mylogs.error("Failed to remove password on " + file)

input("Press Enter to continue...")
