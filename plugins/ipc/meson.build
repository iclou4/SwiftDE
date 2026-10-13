evdev = dependency('libevdev')

ipc_include_dirs = include_directories('.', 'wayfire/plugins/ipc')

ipc = shared_module('ipc',
    ['ipc.cpp'],
    include_directories: [wayfire_api_inc, wayfire_conf_inc, plugins_common_inc],
    dependencies: [wlroots, pixman, wfconfig, wftouch, json, evdev, plugin_pch_dep],
    install: true,
    install_dir: conf_data.get('PLUGIN_PATH'))

stipc = shared_module('stipc',
    ['stipc.cpp'],
    include_directories: [wayfire_api_inc, wayfire_conf_inc, plugins_common_inc],
    dependencies: [wlroots, pixman, wfconfig, wftouch, json, evdev, plugin_pch_dep],
    install: true,
    install_dir: conf_data.get('PLUGIN_PATH'))

install_headers(['wayfire/plugins/ipc/ipc-method-repository.hpp', 'wayfire/plugins/ipc/ipc-helpers.hpp', 'wayfire/plugins/ipc/ipc-activator.hpp'], subdir: 'wayfire/plugins/ipc')
