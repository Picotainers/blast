# blast
Source-built container image for BLAST+ tools.

## Quick Usage

```bash
# Pull the image
docker pull docker.io/picotainers/blast:latest

# Run the tool
docker run --rm -v "$(pwd):/data" docker.io/picotainers/blast:latest blast --help
```
