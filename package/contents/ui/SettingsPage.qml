/*
 * SPDX-FileCopyrightText: 2026 Agundur <info@agundur.de>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import org.kde.kcmutils as KCM

// Plasma passes the complete configuration (including defaults) to each page.
KCM.SimpleKCM {
    property int cfg_hexSize
    property int cfg_columns
    property int cfg_spacing
    property string cfg_orientation
    property color cfg_placeholderColor
    property string cfg_backgroundImage
    property string cfg_backgroundFillMode
    property int cfg_backgroundDim
    property int cfg_bevelStrength
    property int cfg_gridPadding
    property color cfg_textColor
    property int cfg_textSize
    property string cfg_slots
    property int cfg_hexSizeDefault
    property int cfg_columnsDefault
    property int cfg_spacingDefault
    property string cfg_orientationDefault
    property color cfg_placeholderColorDefault
    property string cfg_backgroundImageDefault
    property string cfg_backgroundFillModeDefault
    property int cfg_backgroundDimDefault
    property int cfg_bevelStrengthDefault
    property int cfg_gridPaddingDefault
    property color cfg_textColorDefault
    property int cfg_textSizeDefault
    property string cfg_slotsDefault
}
