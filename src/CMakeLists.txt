# TODO: adapt "org.kde.plasma" here & elsewhere if needed (see README)
add_definitions(-DTRANSLATION_DOMAIN=\"plasma_applet_gr.ictpro.jsalatas.plasma.pstate\")

add_library(plasma_applet_pstate MODULE pstate.cpp)

kcoreaddons_desktop_to_json(plasma_applet_pstate package/metadata.desktop SERVICE_TYPES plasma-applet.desktop)

target_link_libraries(plasma_applet_pstate
                      Qt5::Gui
                      KF5::Plasma
                      KF5::I18n)


install(TARGETS plasma_applet_pstate DESTINATION ${KDE_INSTALL_PLUGINDIR}/plasma/applets)

plasma_install_package(package gr.ictpro.jsalatas.plasma.pstate)

# Make the script executable
install(FILES
        package/contents/code/set_prefs.sh
        DESTINATION
        ${CMAKE_INSTALL_PREFIX}/share/plasma/plasmoids/gr.ictpro.jsalatas.plasma.pstate/contents/code/
        PERMISSIONS
        OWNER_EXECUTE OWNER_WRITE OWNER_READ)
