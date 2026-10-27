// Cover-flow wallpaper picker, modelled on 43PR's hyprquickpaper.
// Hover or A/D/arrows to move, click/Enter/Space to apply, Esc/W or click outside to close.
import QtQuick
import QtQuick.Window
import QtQuick.Effects
import Qt.labs.folderlistmodel

Window {
    id: main
    readonly property real ui: height / 1080
    readonly property real refWidth: 1920
    readonly property real refHeight: 500
    readonly property int tilesOnScreen: 10
    property int speed: 5000
    property int animDuration: 1000
    property real zoomScale: 0.8
    property real edgeScale: 0.3
    property real edgeSpacing: 80

    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "transparent"
    visible: false  // shown fullscreen by wallpaper-picker once it has picked the screen

    FolderListModel {
        id: folderModel
        folder: backend.folderUrl
        showDirs: false
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.gif", "*.bmp", "*.avif", "*.jxl",
                      "*.PNG", "*.JPG", "*.JPEG", "*.WEBP", "*.GIF"]
        sortField: FolderListModel.Name
    }

    // Dim the desktop slightly and close on any click outside the strip.
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.35
        MouseArea { anchors.fill: parent; onClicked: Qt.quit() }
    }

    Column {
        anchors.centerIn: parent
        spacing: 10 * main.ui
        visible: folderModel.status === FolderListModel.Ready && folderModel.count === 0
        Text {
            text: "No wallpapers found"
            color: "#ffffff"; font.pixelSize: 22 * main.ui; font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Text {
            text: "Add images to " + backend.folderPath
            color: "#cccccc"; font.pixelSize: 14 * main.ui
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    ListView {
        id: list
        width: parent.width
        height: tileHeight
        anchors.centerIn: parent
        focus: true
        model: folderModel
        orientation: ListView.Horizontal
        clip: true
        cacheBuffer: 400 * main.ui
        boundsBehavior: Flickable.StopAtBounds

        property int selectedIndex: 0
        property bool ready: false
        property real lastMouseX: -1
        property real lastMouseY: -1

        readonly property real tileHeight: main.refHeight * main.ui
        readonly property real tileWidth: (main.refWidth / main.tilesOnScreen - 10) * main.ui
        readonly property real viewportCenterX: width / 2
        readonly property real falloffRadius: (main.refWidth / 2) * main.ui
        readonly property real sideMargin: Math.max(0, viewportCenterX - tileWidth / 2)

        leftMargin: sideMargin
        rightMargin: sideMargin

        function clampIndex(i) { return Math.max(0, Math.min(i, count - 1)) }
        function centerX(i) {
            const it = itemAtIndex(i)
            if (it) return it.x + tileWidth / 2 - width / 2
            return i * tileWidth - sideMargin
        }
        function startAtCurrent() {
            if (ready || count <= 0) return
            let start = 0
            for (let i = 0; i < count; i++)
                if (folderModel.get(i, "filePath") === backend.currentWallpaper) { start = i; break }
            selectedIndex = start
            contentX = centerX(start)
            ready = true
        }
        function moveSelection(delta, mult) {
            anim.velocity = main.speed * mult
            selectedIndex = clampIndex(selectedIndex + delta)
            contentX = centerX(selectedIndex)
        }
        function activateCurrent() {
            backend.apply(folderModel.get(selectedIndex, "filePath"))
            Qt.quit()
        }

        onCountChanged: Qt.callLater(startAtCurrent)

        Behavior on contentX {
            enabled: list.ready
            SmoothedAnimation { id: anim; property real velocity: main.speed; duration: main.animDuration }
        }

        delegate: Item {
            id: tile
            width: list.tileWidth
            height: list.tileHeight

            readonly property bool active: index === list.selectedIndex
            readonly property bool isGif: fileName.toLowerCase().endsWith(".gif")
            readonly property real centerOnScreen: x - list.contentX + width / 2
            readonly property real fraction: Math.min(1, Math.abs(centerOnScreen - list.viewportCenterX) / list.falloffRadius)
            readonly property real edgeOffset: {
                const amount = main.edgeSpacing * main.ui * Math.pow(fraction, 4)
                return centerOnScreen < list.viewportCenterX ? amount : -amount
            }
            readonly property real scaleFactor: {
                const t = 1 - fraction * fraction * (3 - 2 * fraction)
                return main.edgeScale + (main.zoomScale - main.edgeScale) * t
            }

            Item {
                id: content
                anchors.verticalCenter: parent.verticalCenter
                width: tile.width * tile.scaleFactor
                height: tile.height * Math.min(1, tile.scaleFactor)
                x: (tile.width - width) / 2 + tile.edgeOffset

                Image {
                    id: img
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                    source: "file://" + filePath
                    sourceSize.width: list.tileWidth * main.zoomScale * 1.5
                    sourceSize.height: list.tileHeight
                    opacity: 0.95
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: "#000000"
                        shadowOpacity: 0.5
                        shadowBlur: 0.6
                        shadowHorizontalOffset: 6 * main.ui
                        shadowVerticalOffset: 6 * main.ui
                    }
                }

                AnimatedImage {
                    anchors.fill: parent
                    source: tile.isGif && tile.active ? "file://" + filePath : ""
                    visible: status === AnimatedImage.Ready
                    playing: visible
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                Rectangle {
                    anchors.fill: parent
                    visible: tile.active
                    color: "transparent"
                    border.width: Math.max(1, Math.round(2 * main.ui))
                    border.color: "#ffffff"
                    opacity: 0.8
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: list.ready
                onPositionChanged: function(mouse) {
                    const p = mapToItem(null, mouse.x, mouse.y)
                    if (p.x === list.lastMouseX && p.y === list.lastMouseY) return
                    list.lastMouseX = p.x
                    list.lastMouseY = p.y
                    list.selectedIndex = index
                }
                onClicked: list.activateCurrent()
                onWheel: function(wheel) { list.flick(-wheel.angleDelta.y * 8, 0); wheel.accepted = true }
            }
        }

        Keys.onPressed: function(event) {
            const fast = event.isAutoRepeat ? 2 : 1
            switch (event.key) {
            case Qt.Key_Left: case Qt.Key_A: moveSelection(-1, fast); break
            case Qt.Key_Right: case Qt.Key_D: moveSelection(1, fast); break
            case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space:
                if (count > 0) activateCurrent(); break
            case Qt.Key_W: case Qt.Key_Escape: Qt.quit(); break
            default: return
            }
            event.accepted = true
        }
    }
}
