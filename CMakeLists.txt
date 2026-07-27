cmake_minimum_required(VERSION 3.16)
project(khoneycomb)

set(KF6_MIN_VERSION "6.10.0")

find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)

find_package(KF6 ${KF6_MIN_VERSION} REQUIRED COMPONENTS
    I18n
)

set(PLASMOID_ID de.agundur.khoneycomb)
set(HIVE_PLASMOID_ID de.agundur.khivelaunch)

enable_testing()
add_test(NAME validate-metadata
    COMMAND python3 ${CMAKE_SOURCE_DIR}/scripts/validate-metadata.py
                    ${CMAKE_SOURCE_DIR}/package/metadata.json
)
add_test(NAME validate-metadata-hive
    COMMAND python3 ${CMAKE_SOURCE_DIR}/scripts/validate-metadata.py
                    ${CMAKE_SOURCE_DIR}/hive-package/metadata.json
)

ki18n_install(translate
    INSTALL_DESTINATION ${KDE_INSTALL_LOCALEDIR}
)

install(DIRECTORY package/ DESTINATION ${KDE_INSTALL_DATADIR}/plasma/plasmoids/${PLASMOID_ID})
install(DIRECTORY hive-package/ DESTINATION ${KDE_INSTALL_DATADIR}/plasma/plasmoids/${HIVE_PLASMOID_ID})
