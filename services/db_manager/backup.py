#!/usr/bin/env python3

"""Small runner to invoke the DB backup function."""

from .db_manager import backup_db

def main() -> None:
    """Run the DB backup function.

    The import is performed locally to avoid top-level import-order/style
    complaints from linters while keeping the module runnable as a script.
    """

    backup_db()


if __name__ == "__main__":
    main()
