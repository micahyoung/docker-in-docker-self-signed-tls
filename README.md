# Examples of Docker-in-docker using self-signed TLS in a containerized registry

## Requirements:
* MacOS: Docker Desktop
* Windows: Docker Desktop with Windows Containers enabled

## Steps:

### MacOS
```
cd macos
./test.sh
```

### Windows
```
# Run as administrator
cd windows
.\test.ps1
```

## Note:
Scripts clean up everything after they run so if you want to preserve the state, comment out the `cleanup` commands
