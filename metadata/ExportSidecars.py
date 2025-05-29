import uno
import os
import re
from com.sun.star.sheet import XSpreadsheetDocument

def sanitize_filename(name):
    return re.sub(r'[\\/:*?"<>|]', '_', name)

def save_column_a_to_text_files():
    ctx = uno.getComponentContext()
    smgr = ctx.ServiceManager
    desktop = smgr.createInstanceWithContext("com.sun.star.frame.Desktop", ctx)
    model = desktop.getCurrentComponent()

    if not model.hasLocation():
        raise Exception("Please save the document first.")

    doc_url = model.getURL()
    doc_path = uno.fileUrlToSystemPath(doc_url)
    base_dir = os.path.dirname(doc_path)
    meta_dir = os.path.join(base_dir, "meta")

    if not os.path.exists(meta_dir):
        os.makedirs(meta_dir)

    sheet = model.Sheets.getByIndex(0)
    row = 2

    while True:
        cell_a = sheet.getCellByPosition(0, row)  # Column A
        cell_b = sheet.getCellByPosition(1, row)  # Column B
        text = cell_a.getString().strip()
        filename = cell_b.getString().strip()

        if not text and not filename:
            break

        if filename:
            safe_name = sanitize_filename(filename)
            file_path = os.path.join(meta_dir, safe_name + ".txt")
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(text)

        row += 2
