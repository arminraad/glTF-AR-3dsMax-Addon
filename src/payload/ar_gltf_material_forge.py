from __future__ import annotations

import traceback
from pathlib import Path

from PySide6 import QtCore, QtGui, QtWidgets
import qtmax
from pymxs import runtime as rt


APP_NAME = "AR glTF Material Forge"
VERSION = "1.2.0"
ROOT = Path(__file__).resolve().parent
SCRIPTS_DIR = ROOT / "scripts"
ICONS_DIR = ROOT / "icons"
PANEL_OBJECT_NAME = "AR_gLTF_Material_Forge_Panel"
OLD_DOCK_OBJECT_NAME = "AR_gLTF_Material_Forge_Dock"
TOOLBAR_OBJECT_NAME = "AR_gLTF_Material_Forge_Toolbar"
ACTION_OBJECT_NAME = "AR_gLTF_Material_Forge_Action"

# Fixed logical size. Qt/3ds Max applies the active Windows DPI scale.
PANEL_WIDTH = 920
PANEL_HEIGHT = 900

_panel_ref = None
_toolbar_ref = None


def _icon(name: str) -> QtGui.QIcon:
    path = ICONS_DIR / name
    return QtGui.QIcon(str(path)) if path.exists() else QtGui.QIcon()


def _main_window() -> QtWidgets.QMainWindow:
    return qtmax.GetQMaxMainWindow()


def _run_maxscript(path: Path) -> None:
    if not path.exists():
        raise FileNotFoundError(str(path))
    try:
        rt.fileIn(str(path), quiet=True)
    except Exception:
        p = str(path).replace('"', '\\"')
        rt.execute(f'fileIn @"{p}" quiet:true')


class ForgeTitleBar(QtWidgets.QFrame):
    def __init__(self, window: QtWidgets.QWidget, parent=None):
        super().__init__(parent)
        self._window = window
        self._drag_offset = None
        self.setObjectName("ForgeTitleBar")
        self.setFixedHeight(54)

        row = QtWidgets.QHBoxLayout(self)
        row.setContentsMargins(18, 0, 10, 0)
        row.setSpacing(10)

        app_icon = QtWidgets.QLabel(self)
        app_icon.setPixmap(_icon("app.svg").pixmap(24, 24))
        app_icon.setFixedSize(28, 28)
        app_icon.setAlignment(QtCore.Qt.AlignmentFlag.AlignCenter)
        app_icon.setAttribute(QtCore.Qt.WidgetAttribute.WA_TransparentForMouseEvents, True)
        row.addWidget(app_icon)

        title = QtWidgets.QLabel(APP_NAME, self)
        title.setObjectName("ForgeWindowTitle")
        title.setAttribute(QtCore.Qt.WidgetAttribute.WA_TransparentForMouseEvents, True)
        row.addWidget(title)
        row.addStretch(1)

        close_btn = QtWidgets.QToolButton(self)
        close_btn.setObjectName("ForgeCloseButton")
        close_btn.setIcon(_icon("close.svg"))
        close_btn.setIconSize(QtCore.QSize(25, 25))
        close_btn.setFixedSize(44, 40)
        close_btn.setCursor(QtCore.Qt.CursorShape.PointingHandCursor)
        close_btn.setToolTip("Close")
        close_btn.clicked.connect(window.close)
        row.addWidget(close_btn)

    def mousePressEvent(self, event):
        if event.button() == QtCore.Qt.MouseButton.LeftButton:
            self._drag_offset = event.globalPosition().toPoint() - self._window.frameGeometry().topLeft()
            event.accept()
            return
        super().mousePressEvent(event)

    def mouseMoveEvent(self, event):
        if self._drag_offset is not None and (event.buttons() & QtCore.Qt.MouseButton.LeftButton):
            self._window.move(event.globalPosition().toPoint() - self._drag_offset)
            event.accept()
            return
        super().mouseMoveEvent(event)

    def mouseReleaseEvent(self, event):
        self._drag_offset = None
        super().mouseReleaseEvent(event)


class ToolCard(QtWidgets.QFrame):
    clicked = QtCore.Signal()

    def __init__(self, title: str, subtitle: str, icon_name: str, parent=None):
        super().__init__(parent)
        self.setObjectName("ForgeCard")
        self.setCursor(QtCore.Qt.CursorShape.PointingHandCursor)
        self.setFixedHeight(108)
        self.setAttribute(QtCore.Qt.WidgetAttribute.WA_Hover, True)

        row = QtWidgets.QHBoxLayout(self)
        row.setContentsMargins(18, 15, 18, 15)
        row.setSpacing(16)

        icon_box = QtWidgets.QLabel(self)
        icon_box.setObjectName("ForgeCardIcon")
        icon_box.setAlignment(QtCore.Qt.AlignmentFlag.AlignCenter)
        icon_box.setPixmap(_icon(icon_name).pixmap(44, 44))
        icon_box.setFixedSize(58, 58)
        row.addWidget(icon_box, 0, QtCore.Qt.AlignmentFlag.AlignVCenter)

        text_col = QtWidgets.QVBoxLayout()
        text_col.setSpacing(6)
        text_col.setContentsMargins(0, 0, 0, 0)

        title_label = QtWidgets.QLabel(title, self)
        title_label.setObjectName("ForgeCardTitle")
        title_label.setWordWrap(True)
        title_label.setAttribute(QtCore.Qt.WidgetAttribute.WA_TransparentForMouseEvents, True)

        subtitle_label = QtWidgets.QLabel(subtitle, self)
        subtitle_label.setObjectName("ForgeCardSubtitle")
        subtitle_label.setWordWrap(True)
        subtitle_label.setAttribute(QtCore.Qt.WidgetAttribute.WA_TransparentForMouseEvents, True)

        text_col.addWidget(title_label)
        text_col.addWidget(subtitle_label)
        text_col.addStretch(1)
        row.addLayout(text_col, 1)

        arrow = QtWidgets.QLabel("›", self)
        arrow.setObjectName("ForgeCardArrow")
        arrow.setAlignment(QtCore.Qt.AlignmentFlag.AlignCenter)
        arrow.setFixedWidth(24)
        arrow.setAttribute(QtCore.Qt.WidgetAttribute.WA_TransparentForMouseEvents, True)
        row.addWidget(arrow, 0, QtCore.Qt.AlignmentFlag.AlignVCenter)

    def mouseReleaseEvent(self, event):
        if event.button() == QtCore.Qt.MouseButton.LeftButton and self.rect().contains(event.position().toPoint()):
            self.clicked.emit()
        super().mouseReleaseEvent(event)


class SectionLabel(QtWidgets.QLabel):
    def __init__(self, text: str, parent=None):
        super().__init__(text, parent)
        self.setObjectName("ForgeSectionLabel")


class MaterialForgePanel(QtWidgets.QDialog):
    def __init__(self, parent=None):
        super().__init__(parent or _main_window())
        self.setObjectName(PANEL_OBJECT_NAME)
        self.setWindowTitle(APP_NAME)
        self.setWindowIcon(_icon("app.svg"))
        self.setWindowFlags(QtCore.Qt.WindowType.Tool | QtCore.Qt.WindowType.FramelessWindowHint)
        self.setModal(False)
        self.setSizeGripEnabled(False)
        self.setFixedSize(PANEL_WIDTH, PANEL_HEIGHT)
        self._build_ui()

    def _build_ui(self):
        root = QtWidgets.QVBoxLayout(self)
        root.setContentsMargins(1, 1, 1, 1)
        root.setSpacing(0)

        shell = QtWidgets.QFrame(self)
        shell.setObjectName("ForgeShell")
        shell_layout = QtWidgets.QVBoxLayout(shell)
        shell_layout.setContentsMargins(0, 0, 0, 0)
        shell_layout.setSpacing(0)
        root.addWidget(shell)

        shell_layout.addWidget(ForgeTitleBar(self, shell))

        header = QtWidgets.QFrame(shell)
        header.setObjectName("ForgeHeader")
        h = QtWidgets.QHBoxLayout(header)
        h.setContentsMargins(26, 18, 26, 18)
        h.setSpacing(18)

        logo_wrap = QtWidgets.QFrame(header)
        logo_wrap.setObjectName("ForgeLogoWrap")
        logo_wrap.setFixedSize(62, 62)
        logo_layout = QtWidgets.QVBoxLayout(logo_wrap)
        logo_layout.setContentsMargins(8, 8, 8, 8)
        logo = QtWidgets.QLabel(logo_wrap)
        logo.setAlignment(QtCore.Qt.AlignmentFlag.AlignCenter)
        logo.setPixmap(_icon("app.svg").pixmap(44, 44))
        logo_layout.addWidget(logo)
        h.addWidget(logo_wrap)

        title_col = QtWidgets.QVBoxLayout()
        title_col.setSpacing(5)
        title = QtWidgets.QLabel(APP_NAME, header)
        title.setObjectName("ForgeTitle")
        subtitle = QtWidgets.QLabel("Material preparation for architectural AR / glTF delivery", header)
        subtitle.setObjectName("ForgeSubtitle")
        title_col.addWidget(title)
        title_col.addWidget(subtitle)
        h.addLayout(title_col, 1)

        version = QtWidgets.QLabel(f"v{VERSION}", header)
        version.setObjectName("ForgeVersion")
        h.addWidget(version, 0, QtCore.Qt.AlignmentFlag.AlignTop)
        shell_layout.addWidget(header)

        scroll = QtWidgets.QScrollArea(shell)
        scroll.setObjectName("ForgeScroll")
        scroll.setWidgetResizable(True)
        scroll.setFrameShape(QtWidgets.QFrame.Shape.NoFrame)
        scroll.setHorizontalScrollBarPolicy(QtCore.Qt.ScrollBarPolicy.ScrollBarAlwaysOff)
        scroll.setVerticalScrollBarPolicy(QtCore.Qt.ScrollBarPolicy.ScrollBarAsNeeded)

        body = QtWidgets.QWidget(scroll)
        body.setObjectName("ForgeBody")
        layout = QtWidgets.QVBoxLayout(body)
        layout.setContentsMargins(26, 20, 26, 20)
        layout.setSpacing(15)

        intro = QtWidgets.QLabel(
            "Run each operation independently. Conversion tools preserve Multi/Sub assignments and Material IDs.",
            body,
        )
        intro.setObjectName("ForgeIntro")
        intro.setWordWrap(True)
        intro.setMinimumHeight(66)
        layout.addWidget(intro)

        self._add_section(layout, "V-RAY WRAPPER CONVERSION", [
            (
                "Remove V-Ray 2Sided Wrapper",
                "Use the Front glTF material directly",
                "wrap.svg",
                "Remove_VRay2Sided_Keep_glTF.ms",
            ),
            (
                "Remove V-Ray Blend Wrapper",
                "Use the Base glTF material directly",
                "blend.svg",
                "Replace_VRayBlendMtl_With_Base_glTF.ms",
            ),
        ])

        self._add_section(layout, "BASE COLOR SIMPLIFICATION", [
            (
                "Keep Base Color Branch Only",
                "Disconnect all other glTF texture-map branches",
                "basecolor.svg",
                "Clean_glTF_Keep_Only_BaseColor.ms",
            ),
            (
                "Flatten Base Color to Bitmap",
                "Bypass Mix, Color Correction and intermediate maps",
                "flatten.svg",
                "glTF_Flatten_BaseColor_To_Bitmap_v2.ms",
            ),
        ])

        self._add_section(layout, "SCENE CLEANUP", [
            (
                "Clean Orphan Slate Nodes",
                "Keep only graphs rooted in glTF or Multi/Sub materials",
                "clean.svg",
                "Clean_Slate_Orphans_Protected_Roots_v2_1.ms",
            ),
            (
                "Purge Unused Materials",
                "Remove materials with no real scene usage",
                "purge.svg",
                "Purge_Unused_Scene_Materials.ms",
            ),
        ])

        self._add_section(layout, "FINALIZATION", [
            (
                "Disable Extra glTF Extensions",
                "Turn off Sheen, Specular, Transmission, Volume and IOR",
                "off.svg",
                "Disable_glTF_Advanced_Extensions.ms",
            ),
            (
                "Show Textures in Viewport",
                "Enable connected material textures on models",
                "eye.svg",
                "Show_All_Scene_Textures_In_Viewport.ms",
            ),
        ])

        layout.addStretch(1)
        scroll.setWidget(body)
        shell_layout.addWidget(scroll, 1)

        footer = QtWidgets.QFrame(shell)
        footer.setObjectName("ForgeFooter")
        fl = QtWidgets.QHBoxLayout(footer)
        fl.setContentsMargins(24, 13, 24, 13)
        fl.setSpacing(14)

        self.status_label = QtWidgets.QLabel("Ready", footer)
        self.status_label.setObjectName("ForgeStatus")
        fl.addWidget(self.status_label, 1)

        hint = QtWidgets.QLabel("Save a scene copy before cleanup", footer)
        hint.setObjectName("ForgeHint")
        fl.addWidget(hint)
        shell_layout.addWidget(footer)

        self._apply_style()

    def _add_section(self, layout, title: str, tools):
        layout.addWidget(SectionLabel(title, self))

        grid = QtWidgets.QGridLayout()
        grid.setContentsMargins(0, 0, 0, 0)
        grid.setHorizontalSpacing(14)
        grid.setVerticalSpacing(12)
        grid.setColumnStretch(0, 1)
        grid.setColumnStretch(1, 1)

        for index, (button_title, subtitle, icon_name, script_name) in enumerate(tools):
            card = ToolCard(button_title, subtitle, icon_name, self)
            card.clicked.connect(lambda f=script_name, t=button_title: self.run_tool(f, t))
            grid.addWidget(card, index // 2, index % 2)

        layout.addLayout(grid)

    def run_tool(self, filename: str, title: str):
        script_path = SCRIPTS_DIR / filename
        self.status_label.setText(f"Running: {title}")
        QtWidgets.QApplication.setOverrideCursor(QtCore.Qt.CursorShape.WaitCursor)
        QtWidgets.QApplication.processEvents()
        try:
            _run_maxscript(script_path)
            self.status_label.setText(f"Complete: {title}")
        except Exception as exc:
            self.status_label.setText(f"Failed: {title}")
            details = traceback.format_exc()
            QtWidgets.QMessageBox.critical(self, APP_NAME, f"{title} failed.\n\n{exc}\n\n{details}")
        finally:
            QtWidgets.QApplication.restoreOverrideCursor()
            try:
                rt.redrawViews()
            except Exception:
                pass

    def _apply_style(self):
        self.setStyleSheet(
            """
            QDialog {
                background: #070d17;
                color: #e8eef7;
                font-family: "Segoe UI";
                font-size: 15px;
            }
            QFrame#ForgeShell {
                background: #09111f;
                border: 1px solid #31435a;
                border-radius: 13px;
            }
            QFrame#ForgeTitleBar {
                background: #151a22;
                border: none;
                border-bottom: 1px solid #2c3543;
                border-top-left-radius: 12px;
                border-top-right-radius: 12px;
            }
            QLabel#ForgeWindowTitle {
                color: #cbd5e1;
                font-size: 16px;
                font-weight: 500;
                background: transparent;
            }
            QToolButton#ForgeCloseButton {
                background: #222a35;
                border: 1px solid #344153;
                border-radius: 10px;
                padding: 7px;
            }
            QToolButton#ForgeCloseButton:hover {
                background: #dc3f4f;
                border: 1px solid #f06a76;
            }
            QToolButton#ForgeCloseButton:pressed {
                background: #b92f3d;
                border: 1px solid #d9505d;
            }
            QWidget#ForgeBody {
                background: #09111f;
            }
            QFrame#ForgeHeader {
                background: #101a2b;
                border: none;
                border-bottom: 1px solid #26364c;
            }
            QFrame#ForgeLogoWrap {
                background: #0a1527;
                border: 1px solid #2b4057;
                border-radius: 14px;
            }
            QLabel#ForgeTitle {
                font-size: 24px;
                font-weight: 700;
                color: #f8fbff;
            }
            QLabel#ForgeSubtitle {
                font-size: 14px;
                color: #a9b9cc;
            }
            QLabel#ForgeVersion {
                background: #12313d;
                color: #73ecfa;
                border: 1px solid #238195;
                border-radius: 11px;
                padding: 6px 12px;
                font-size: 13px;
                font-weight: 700;
            }
            QLabel#ForgeIntro {
                color: #d0d9e5;
                background: #0f1a2c;
                border: 1px solid #2d4058;
                border-radius: 12px;
                padding: 14px 17px;
                font-size: 15px;
            }
            QLabel#ForgeSectionLabel {
                color: #67e8f9;
                font-size: 13px;
                font-weight: 800;
                letter-spacing: 1px;
                padding-top: 5px;
                padding-bottom: 2px;
            }
            QFrame#ForgeCard {
                background: #111d2f;
                border: 1px solid #2d4058;
                border-radius: 13px;
            }
            QFrame#ForgeCard:hover {
                background: #162840;
                border: 1px solid #3eddf2;
            }
            QLabel#ForgeCardIcon {
                background: #0b1728;
                border: 1px solid #294056;
                border-radius: 12px;
            }
            QLabel#ForgeCardTitle {
                color: #f7faff;
                font-size: 17px;
                font-weight: 700;
                background: transparent;
            }
            QLabel#ForgeCardSubtitle {
                color: #adbdcf;
                font-size: 14px;
                background: transparent;
            }
            QLabel#ForgeCardArrow {
                color: #55e5f5;
                font-size: 32px;
                font-weight: 400;
                background: transparent;
            }
            QFrame#ForgeFooter {
                background: #101a2b;
                border: none;
                border-top: 1px solid #26364c;
                border-bottom-left-radius: 12px;
                border-bottom-right-radius: 12px;
            }
            QLabel#ForgeStatus {
                color: #a7f3d0;
                font-size: 14px;
                font-weight: 700;
            }
            QLabel#ForgeHint {
                color: #899bb0;
                font-size: 12px;
            }
            QScrollArea#ForgeScroll {
                border: none;
                background: #09111f;
            }
            QScrollBar:vertical {
                background: #09111f;
                width: 11px;
                margin: 2px;
            }
            QScrollBar::handle:vertical {
                background: #40546d;
                min-height: 36px;
                border-radius: 5px;
            }
            QScrollBar::handle:vertical:hover {
                background: #5a718e;
            }
            QScrollBar::add-line:vertical,
            QScrollBar::sub-line:vertical {
                height: 0px;
            }
            """
        )


def _center_on_max(panel: QtWidgets.QWidget) -> None:
    main = _main_window()
    if main is None:
        return
    frame = main.frameGeometry()
    geo = panel.frameGeometry()
    geo.moveCenter(frame.center())
    panel.move(geo.topLeft())


def show_panel():
    global _panel_ref
    main = _main_window()

    old_dock = main.findChild(QtWidgets.QDockWidget, OLD_DOCK_OBJECT_NAME)
    if old_dock is not None:
        try:
            old_dock.close()
            old_dock.deleteLater()
        except Exception:
            pass

    existing = main.findChild(QtWidgets.QDialog, PANEL_OBJECT_NAME)
    if existing is not None:
        # If an older in-memory version is open, close it so the new fixed-size
        # version is recreated immediately after updating the MZP.
        try:
            existing.close()
            existing.deleteLater()
            QtWidgets.QApplication.processEvents()
        except Exception:
            pass

    panel = MaterialForgePanel(main)
    panel.show()
    _center_on_max(panel)
    panel.raise_()
    panel.activateWindow()
    _panel_ref = panel
    return panel


def ensure_toolbar():
    global _toolbar_ref
    main = _main_window()

    existing = main.findChild(QtWidgets.QToolBar, TOOLBAR_OBJECT_NAME)
    if existing is not None:
        _toolbar_ref = existing
        existing.setIconSize(QtCore.QSize(32, 32))
        existing.show()
        return existing

    toolbar = QtWidgets.QToolBar(APP_NAME, main)
    toolbar.setObjectName(TOOLBAR_OBJECT_NAME)
    toolbar.setMovable(True)
    toolbar.setFloatable(True)
    toolbar.setIconSize(QtCore.QSize(32, 32))

    action = QtGui.QAction(_icon("app.svg"), APP_NAME, toolbar)
    action.setObjectName(ACTION_OBJECT_NAME)
    action.setToolTip("Open AR glTF Material Forge")
    action.setStatusTip("Open the AR glTF material preparation panel")
    action.triggered.connect(show_panel)
    toolbar.addAction(action)

    main.addToolBar(QtCore.Qt.ToolBarArea.TopToolBarArea, toolbar)
    toolbar.show()
    _toolbar_ref = toolbar
    return toolbar


def startup():
    ensure_toolbar()


def launch():
    ensure_toolbar()
    show_panel()


if __name__ == "__main__":
    launch()
