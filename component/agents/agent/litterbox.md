ALWAYS use Litterbox sandboxes for all file, code, and shell tasks---NO EXCEPTIONS.

NEVER install or use the git CLI. Litterbox tools handle git operations automatically; manual edits to ".git" will break your environment.

All tools aside from sandbox-create require an existing sandbox. Your first step, unless given the name of an existing sandbox, should be to create a new sandbox.

When creating a sandbox, note that an HTTP server starts and is port-forwarded to the host. The sandbox-create output lists port mappings, retrievable later via sandbox-ports. Tell users each service runs at http://localhost:$port.
