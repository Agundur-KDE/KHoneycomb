find_package(Qt6 REQUIRED COMPONENTS QuickTest Qml)

add_executable(tst_plasmoid tst_runner.cpp)
target_link_libraries(tst_plasmoid PRIVATE Qt6::QuickTest Qt6::Qml KF6::I18n)
target_compile_definitions(tst_plasmoid PRIVATE
    QUICK_TEST_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}"
)

add_test(NAME tst_plasmoid COMMAND tst_plasmoid)
set_tests_properties(tst_plasmoid PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen;QT_QUICK_BACKEND=software")
