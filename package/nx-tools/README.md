# nx-tools

`nx-pick` selects an Nx project and target using fzf, then runs the target once.
Targets with named configurations get a third picker, including an option to
use the target's default configuration (or base options if no default is set).
Targets without named configurations skip this picker. Nx does not declare
whether an executor requires a configuration; the picker uses the configurations
exposed by `nx show project`.

Run it from an Nx workspace or one of its subdirectories:

```sh
nx-pick
nx-pick --configuration=production
nx-pick -- --watch
```

Extra arguments are forwarded unchanged to `nx run <project>:<target>`.
Passing `--configuration` or `-c` explicitly skips the configuration picker.
Escape or Ctrl-C cancels selection. The selected task inherits the terminal and
its exit status is returned.

The package supplies fzf and jq. Nx is resolved from the nearest ancestor's
`node_modules/.bin/nx`, falling back to `nx` on PATH; the workspace must have its
dependencies installed and its Node.js runtime available.
