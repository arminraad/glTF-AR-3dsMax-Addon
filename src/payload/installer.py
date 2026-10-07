from __future__ import annotations

import importlib
import re
import shutil
import sys
from pathlib import Path

from PySide6 import QtCore, QtGui, QtWidgets
import qtmax
from pymxs import runtime as rt


APP_NAME = "AR glTF Material Forge"
PACKAGE_VERSION = "1.3.1"
PAYLOAD_DIR = Path(__file__).resolve().parent


def _max_dir(symbol: str) -> Path:
    value = rt.execute(f"getDir #{symbol}")
    return Path(str(value))


USER_SCRIPTS = _max_dir("userScripts")
USER_MACROS = _max_dir("userMacros")
USER_STARTUP = _max_dir("userStartupScripts")
USER_ICONS = _max_dir("userIcons")

INSTALL_ROOT = USER_SCRIPTS / "AR_glTF_Material_Forge"
MACRO_DST = USER_MACROS / "AR_glTF_Material_Forge.mcr"
STARTUP_DST = USER_STARTUP / "AR_glTF_Material_Forge_startup.ms"
ICON_DST = USER_ICONS / "AR_glTF_Material_Forge.svg"

PANEL_OBJECT_NAME = "AR_gLTF_Material_Forge_Panel"
OLD_DOCK_OBJECT_NAME = "AR_gLTF_Material_Forge_Dock"
TOOLBAR_OBJECT_NAME = "AR_gLTF_Material_Forge_Toolbar"

_installer_ref = None


def _main_window() -> QtWidgets.QMainWindow:
    return qtmax.GetQMaxMainWindow()


def _icon() -> QtGui.QIcon:
    path = PAYLOAD_DIR / "icons" / "app.svg"
    return QtGui.QIcon(str(path)) if path.exists() else QtGui.QIcon()


def _is_installed() -> bool:
    return any(
        [
            (INSTALL_ROOT / "ar_gltf_material_forge.py").exists(),
            MACRO_DST.exists(),
            STARTUP_DST.exists(),
        ]
    )


def _installed_version() -> str | None:
    version_file = INSTALL_ROOT / "version.txt"
    if version_file.exists():
        try:
            value = version_file.read_text(encoding="utf-8").strip()
            if value:
                return value
        except Exception:
            pass

    app_file = INSTALL_ROOT / "ar_gltf_material_forge.py"
    if app_file.exists():
        try:
            text = app_file.read_text(encoding="utf-8", errors="ignore")
            match = re.search(r'^VERSION\s*=\s*["\']([^"\']+)["\']', text, re.MULTILINE)
            if match:
                return match.group(1)
        except Exception:
            pass

    return None


def _close_old_panel() -> None:
    main = _main_window()
    if main is None:
        return

    for cls, object_name in (
        (QtWidgets.QDialog, PANEL_OBJECT_NAME),
        (QtWidgets.QDockWidget, OLD_DOCK_OBJECT_NAME),
    ):
        widget = main.findChild(cls, object_name)
        if widget is not None:
            try:
                widget.close()
                widget.deleteLater()
            except Exception:
                pass

    QtWidgets.QApplication.processEvents()


def _copy_file(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)


def _install_payload() -> None:
    _close_old_panel()

    # Replace the add-on payload as a complete unit. This removes stale files
    # from older versions while leaving the temporary MZP extraction untouched.
    if INSTALL_ROOT.exists():
        shutil.rmtree(INSTALL_ROOT)

    INSTALL_ROOT.mkdir(parents=True, exist_ok=True)

    for filename in (
        "ar_gltf_material_forge.py",
        "startup.py",
        "open_panel.py",
        "version.txt",
    ):
        _copy_file(PAYLOAD_DIR / filename, INSTALL_ROOT / filename)

    shutil.copytree(PAYLOAD_DIR / "scripts", INSTALL_ROOT / "scripts", dirs_exist_ok=True)
    shutil.copytree(PAYLOAD_DIR / "icons", INSTALL_ROOT / "icons", dirs_exist_ok=True)

    _copy_file(PAYLOAD_DIR / "AR_glTF_Material_Forge.mcr", MACRO_DST)
    _copy_file(PAYLOAD_DIR / "AR_glTF_Material_Forge_startup.ms", STARTUP_DST)
    _copy_file(PAYLOAD_DIR / "icons" / "app.svg", ICON_DST)

    try:
        rt.fileIn(str(MACRO_DST), quiet=True)
    except Exception:
        escaped = str(MACRO_DST).replace('"', '\\"')
        rt.execute(f'fileIn @"{escaped}" quiet:true')

    # Force a fresh module reload, then rebind the existing toolbar QAction to
    # the new module. This fixes the old-toolbar-launches-old-panel problem.
    install_root_str = str(INSTALL_ROOT)
    if install_root_str not in sys.path:
        sys.path.insert(0, install_root_str)

    import ar_gltf_material_forge

    importlib.invalidate_caches()
    importlib.reload(ar_gltf_material_forge)
    ar_gltf_material_forge.launch()


class InstallerDialog(QtWidgets.QDialog):
    def __init__(self, parent=None):
        super().__init__(parent or _main_window())
        self.setWindowTitle(f"{APP_NAME} Installer")
        self.setWindowIcon(_icon())
        self.setModal(True)
        self.setFixedSize(560, 360)
        self.setWindowFlag(QtCore.Qt.WindowType.WindowContextHelpButtonHint, False)
        self._build_ui()
        self._refresh_state()

    def _build_ui(self) -> None:
        root = QtWidgets.QVBoxLayout(self)
        root.setContentsMargins(26, 24, 26, 24)
        root.setSpacing(18)

        header = QtWidgets.QHBoxLayout()
        header.setSpacing(16)

        logo = QtWidgets.QLabel(self)
        logo.setPixmap(_icon().pixmap(56, 56))
        logo.setFixedSize(62, 62)
        logo.setAlignment(QtCore.Qt.AlignmentFlag.AlignCenter)
        header.addWidget(logo)

        title_col = QtWidgets.QVBoxLayout()
        title_col.setSpacing(4)
        title = QtWidgets.QLabel(APP_NAME, self)
        title.setObjectName("InstallerTitle")
        subtitle = QtWidgets.QLabel("Installer / Updater for Autodesk 3ds Max", self)
        subtitle.setObjectName("InstallerSubtitle")
        title_col.addWidget(title)
        title_col.addWidget(subtitle)
        header.addLayout(title_col, 1)
        root.addLayout(header)

        info = QtWidgets.QFrame(self)
        info.setObjectName("InfoCard")
        info_layout = QtWidgets.QVBoxLayout(info)
        info_layout.setContentsMargins(18, 16, 18, 16)
        info_layout.setSpacing(8)

        self.package_label = QtWidgets.QLabel(f"Package version: v{PACKAGE_VERSION}", info)
        self.package_label.setObjectName("InfoStrong")
        self.installed_label = QtWidgets.QLabel(info)
        self.installed_label.setObjectName("InfoNormal")
        self.state_label = QtWidgets.QLabel(info)
        self.state_label.setObjectName("StateLabel")
        self.state_label.setWordWrap(True)

        info_layout.addWidget(self.package_label)
        info_layout.addWidget(self.installed_label)
        info_layout.addWidget(self.state_label)
        root.addWidget(info)

        root.addStretch(1)

        buttons = QtWidgets.QHBoxLayout()
        buttons.setSpacing(12)
        buttons.addStretch(1)

        self.close_button = QtWidgets.QPushButton("Cancel", self)
        self.close_button.setObjectName("SecondaryButton")
        self.close_button.setFixedSize(120, 44)
        self.close_button.clicked.connect(self.reject)
        buttons.addWidget(self.close_button)

        self.action_button = QtWidgets.QPushButton(self)
        self.action_button.setObjectName("PrimaryButton")
        self.action_button.setFixedSize(150, 44)
        self.action_button.clicked.connect(self._perform_install)
        buttons.addWidget(self.action_button)

        root.addLayout(buttons)

        self.setStyleSheet(
            """
            QDialog {
                background: #0a1220;
                color: #e8eef7;
                font-family: "Segoe UI";
                font-size: 14px;
            }
            QLabel#InstallerTitle {
                color: #f8fbff;
                font-size: 24px;
                font-weight: 700;
            }
            QLabel#InstallerSubtitle {
                color: #9fb0c4;
                font-size: 14px;
            }
            QFrame#InfoCard {
                background: #111d2f;
                border: 1px solid #2d4058;
                border-radius: 12px;
            }
            QLabel#InfoStrong {
                color: #67e8f9;
                font-size: 15px;
                font-weight: 700;
            }
            QLabel#InfoNormal {
                color: #d7e0ea;
                font-size: 14px;
            }
            QLabel#StateLabel {
                color: #a7f3d0;
                font-size: 14px;
                padding-top: 4px;
            }
            QPushButton {
                border-radius: 9px;
                font-size: 14px;
                font-weight: 700;
            }
            QPushButton#PrimaryButton {
                background: #0891b2;
                color: white;
                border: 1px solid #22d3ee;
            }
            QPushButton#PrimaryButton:hover {
                background: #06a9cb;
            }
            QPushButton#PrimaryButton:pressed {
                background: #087e99;
            }
            QPushButton#SecondaryButton {
                background: #172235;
                color: #d9e3ef;
                border: 1px solid #34465d;
            }
            QPushButton#SecondaryButton:hover {
                background: #202f46;
            }
            """
        )

    def _refresh_state(self) -> None:
        installed = _is_installed()
        version = _installed_version()

        if installed:
            self.action_button.setText("Update")
            self.installed_label.setText(
                f"Installed version: v{version}" if version else "Installed version: detected (version unknown)"
            )
            if version == PACKAGE_VERSION:
                self.state_label.setText(
                    "This version is already installed. Update will refresh all files and toolbar bindings."
                )
            else:
                self.state_label.setText(
                    "An existing installation was detected. Update will replace it with this package."
                )
        else:
            self.action_button.setText("Install")
            self.installed_label.setText("Installed version: not installed")
            self.state_label.setText(
                "The add-on is ready to install for the current 3ds Max user profile."
            )

    def _perform_install(self) -> None:
        was_installed = _is_installed()
        action_word = "Update" if was_installed else "Install"

        self.action_button.setEnabled(False)
        self.close_button.setEnabled(False)
        self.state_label.setText(f"{action_word} in progress…")
        QtWidgets.QApplication.setOverrideCursor(QtCore.Qt.CursorShape.WaitCursor)
        QtWidgets.QApplication.processEvents()

        try:
            _install_payload()
        except Exception as exc:
            self.state_label.setText(f"{action_word} failed.")
            QtWidgets.QMessageBox.critical(
                self,
                f"{APP_NAME} — {action_word} Error",
                f"{action_word} failed.\n\n{exc}",
            )
            self.action_button.setEnabled(True)
            self.close_button.setEnabled(True)
            return
        finally:
            QtWidgets.QApplication.restoreOverrideCursor()

        self.installed_label.setText(f"Installed version: v{PACKAGE_VERSION}")
        self.state_label.setText(
            "Update completed successfully. The toolbar button is now bound to the current version."
            if was_installed
            else "Installation completed successfully. The toolbar button is ready to use."
        )
        self.action_button.setText("Close")
        try:
            self.action_button.clicked.disconnect()
        except Exception:
            pass
        self.action_button.clicked.connect(self.accept)
        self.action_button.setEnabled(True)
        self.close_button.hide()


def show_installer() -> InstallerDialog:
    global _installer_ref

    main = _main_window()
    existing = (
        main.findChild(QtWidgets.QDialog, "AR_gLTF_Material_Forge_Installer")
        if main
        else None
    )
    if existing is not None:
        try:
            existing.close()
            existing.deleteLater()
            QtWidgets.QApplication.processEvents()
        except Exception:
            pass

    dialog = InstallerDialog(main)
    dialog.setObjectName("AR_gLTF_Material_Forge_Installer")
    _installer_ref = dialog
    dialog.exec()
    return dialog


if __name__ == "__main__":
    show_installer()
