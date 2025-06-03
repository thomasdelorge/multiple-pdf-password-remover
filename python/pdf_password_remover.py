import os
import sys
from pathlib import Path
import pikepdf
import logging
import coloredlogs
from typing import Optional


class PDFPasswordRemover:
    """Remove passwords from PDF files in a directory."""

    def __init__(self, password: str, target_path: Optional[str] = None):
        """
        Initialize the PDF password remover.

        Args:
            password: Password to try for locked PDFs
            target_path: Directory or file path to process (defaults to current directory)
        """
        self.password = password
        self.target_path = Path(target_path) if target_path else Path.cwd()
        self.processed_count = 0
        self._setup_logging()

    def _setup_logging(self) -> None:
        """Configure logging with file and console output."""
        script_name = Path(__file__).stem
        log_format = "[%(asctime)s] [%(levelname)s] %(message)s"

        # File logging
        logging.basicConfig(
            level=logging.DEBUG,
            filename=f"{script_name}.log",
            filemode="a",
            format=log_format,
        )

        # Console logging with colors
        self.logger = logging.getLogger(__name__)
        stream_handler = logging.StreamHandler()
        self.logger.addHandler(stream_handler)
        coloredlogs.install(level=logging.DEBUG, logger=self.logger, fmt=log_format)

    def _process_pdf(self, file_path: Path) -> bool:
        """
        Process a single PDF file to remove password protection.

        Args:
            file_path: Path to the PDF file

        Returns:
            True if processing was successful, False otherwise
        """
        self.processed_count += 1
        self.logger.info(
            f"🚀  {self.processed_count}) Processing: '{file_path.name}' ..."
        )

        try:
            # Try to open PDF without password
            with pikepdf.open(file_path) as pdf:
                self.logger.info(f"⏭️  '{file_path.name}' is not password protected")
                return True

        except pikepdf.exceptions.PasswordError:
            # PDF is password protected, try to unlock
            return self._remove_password(file_path)
        except Exception as e:
            self.logger.error(f"🚨  Error opening '{file_path.name}': {e}")
            return False

    def _remove_password(self, file_path: Path) -> bool:
        """
        Remove password protection from a PDF file.

        Args:
            file_path: Path to the password-protected PDF

        Returns:
            True if password was successfully removed, False otherwise
        """
        try:
            with pikepdf.open(
                file_path, password=self.password, allow_overwriting_input=True
            ) as pdf:
                pdf.save(file_path)
                self.logger.info(f"✅  Successfully removed password from '{file_path.name}'")
                return True

        except pikepdf.exceptions.PasswordError:
            self.logger.error(f"🚨 Incorrect password for '{file_path.name}'")
            return False
        except Exception as e:
            self.logger.error(
                f"🚨 Failed to remove password from '{file_path.name}': {e}"
            )
            return False

    def process_files(self) -> None:
        """Process all PDF files in the target directory or single file."""

        # 📄 File
        if self.target_path.is_file():
            # Process single file
            if self.target_path.suffix.lower() == ".pdf":
                self._process_pdf(self.target_path)
            else:
                self.logger.error("🚨  Target file is not a PDF")

        # 📂 Directory
        elif self.target_path.is_dir():
            # Process directory
            pdf_files = list(self.target_path.rglob("*.pdf"))
            if not pdf_files:
                self.logger.warning("🚨  No PDF files found in directory")
                return

            for pdf_file in pdf_files:
                self._process_pdf(pdf_file)

        # 😵 KO
        else:
            self.logger.error(f"🚨  Target path does not exist: '{self.target_path}'")


def get_target_path() -> str:
    """
    Get target path from command line argument or interactive input.

    Returns:
        Target path as string
    """
    # Check if path provided as command line argument
    if len(sys.argv) > 1:
        target_path = sys.argv[1]
        print(f"Using path from argument: {target_path}")
        return target_path

    # Interactive input
    while True:
        target_path = input(
            "👉  Enter path to PDF file or directory (or press Enter for current directory): "
        ).strip()

        if not target_path:
            target_path = os.getcwd()
            return target_path

        if Path(target_path).exists():
            return target_path
        else:
            print(f"🚨  Path '{target_path}' does not exist. Please try again.")


def main():
    """Main function to run the PDF password remover."""
    # Configuration
    PDF_PASSWORD = "CHANGEME"  # Change this password

    # Get target path from argument or user input
    target_path = get_target_path()

    # Create and run password remover
    remover = PDFPasswordRemover(PDF_PASSWORD, target_path)
    remover.process_files()

    input("Press 'Enter' to close ...")


if __name__ == "__main__":
    main()
