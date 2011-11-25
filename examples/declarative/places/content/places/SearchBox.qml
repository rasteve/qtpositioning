/****************************************************************************
**
** Copyright (C) 2011 Nokia Corporation and/or its subsidiary(-ies).
** All rights reserved.
** Contact: Nokia Corporation (qt-info@nokia.com)
**
** This file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** You may use this file under the terms of the BSD license as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of Nokia Corporation and its Subsidiary(-ies) nor
**     the names of its contributors may be used to endorse or promote
**     products derived from this software without specific prior written
**     permission.
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 2.0
import QtLocation 5.0
import "../components"

Rectangle {
    id: searchRectangle

    property bool suggestionsEnabled: true

    height: searchBox.height + 20
    Behavior on height {
        NumberAnimation { duration: 250 }
    }

    clip: true

    TextWithLabel {
        id: searchBox
        opacity: 0.9
        label: "Search"
        text: "sushi"

        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.right: row.left
        anchors.rightMargin: 10
        anchors.verticalCenter: row.verticalCenter

        BusyIndicator {
            height: parent.height * 0.8
            width: height
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 3

            running: placeSearchModel.status === PlaceSearchModel.Executing
            visible: running
        }

        onTextChanged: {
            if (suggestionsEnabled) {
                if (text.length >= 3) {
                    suggestionModel.searchTerm = text;
                    suggestionModel.execute();
                } else {
                    searchRectangle.state = "";
                }
            }
        }
    }

    Row {
        id: row

        anchors.right: parent.right
        anchors.rightMargin: 10
        spacing: 10

        IconButton {
            id: searchButton

            source: "../resources/search.png"
            hoveredSource: "../resources/search_hovered.png"
            pressedSource: "../resources/search_pressed.png"

            onClicked: {
                placeSearchModel.searchForText(searchBox.text);
                searchRectangle.state = "";
            }
        }

        IconButton {
            id: categoryButton

            source: "../resources/categories.png"
            hoveredSource: "../resources/categories_hovered.png"
            pressedSource: "../resources/categories_pressed.png"

            onClicked: {
                if (searchRectangle.state !== "CategoriesShown")
                    searchRectangle.state = "CategoriesShown";
                else if (suggestionView.count > 0)
                    searchRectangle.state = "SuggestionsShown";
                else
                    searchRectangle.state = "";
            }
        }
    }

    ListView {
        id: categoryView

        anchors.top: row.bottom
        anchors.topMargin: 10
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 10
        height: 450
        visible: false

        clip: true
        snapMode: ListView.SnapToItem

        header: IconButton {
            source: "../resources/left.png"
            hoveredSource: "../resources/left_hovered.png"
            pressedSource: "../resources/left_pressed.png"

            onClicked: categoryListModel.rootIndex = categoryListModel.parentModelIndex()
            visible: !busy.visible
        }

        model: VisualDataModel {
            id: categoryListModel
            model: categoryModel
            delegate: CategoryDelegate {
                onClicked: {
                    placeSearchModel.searchForCategory(category);
                    searchRectangle.state = "";
                }
                onArrowClicked: categoryListModel.rootIndex = categoryListModel.modelIndex(index)
            }
        }
    }

    BusyIndicator {
        id: busy

        visible: false
        running: visible

        anchors.centerIn: parent
    }

    Text {
        id: noCategories

        anchors.centerIn: parent
        text: qsTr("No categories")
        visible: false
    }

    CategoryModel {
        id: categoryModel
        plugin: placesPlugin
        hierarchical: true
    }

    ListView {
        id: suggestionView

        anchors.top: row.bottom
        anchors.topMargin: 10
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 10
        height: 450
        visible: false

        clip: true
        snapMode: ListView.SnapToItem

        model: suggestionModel
        delegate: Text {
            text: suggestion

            width: parent.width

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    suggestionsEnabled = false;
                    searchBox.text = suggestion;
                    suggestionsEnabled = true;
                    placeSearchModel.searchForText(suggestion);
                    searchRectangle.state = "";
                }
            }
        }
    }

    PlaceSearchSuggestionModel {
        id: suggestionModel
        plugin: placesPlugin
        searchArea: plugin.name === "nokia_places_jsondb" ? null : placeSearchModel.searchArea

        onStatusChanged: {
            if (status == PlaceSearchSuggestionModel.Ready)
                searchRectangle.state = "SuggestionsShown";
        }
    }

    states: [
        State {
            name: "CategoriesShown"
            PropertyChanges {
                target: searchRectangle
                height: childrenRect.height + 20
            }
            PropertyChanges {
                target: busy
                visible: categoryModel.status === CategoryModel.Updating
            }
            PropertyChanges {
                target: noCategories
                visible: categoryView.count == 0 && !busy.visible
            }
            PropertyChanges {
                target: categoryView
                visible: true
            }
        },
        State {
            name: "SuggestionsShown"
            PropertyChanges {
                target: searchRectangle
                height: childrenRect.height + 20
            }
            PropertyChanges {
                target: suggestionView
                visible: true
            }
        }
    ]
}