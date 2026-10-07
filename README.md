# Camera Calibration with Kalibr and Docker

This is the Sphinx source for the Kalibr tutorial, using `sphinx_rtd_theme` to match the format of `pcs-docs-master.zip`. The tutorial preserves the mentor's commands and paths. Its title, introductory note, and discussion note were edited for this version.

Source files:

- [Tutorial content](calibration/docs/source/tutorial-original.md)
- [Sphinx home page](calibration/docs/source/index.rst)
- [Sphinx configuration](calibration/docs/source/conf.py)
- [Python dependencies](calibration/docs/requirements.txt)
- [Build script](calibration/docs/build.sh)

Keep the entire `calibration/docs/source/` directory together; it contains the fonts and sample results referenced by the tutorial. Generated `build/`, `html/`, and `.venv/` directories are not needed in the source package.

Build the documentation with Python 3.10 or newer:

```bash
python3 -m venv calibration/docs/.venv
calibration/docs/.venv/bin/python -m pip install -r calibration/docs/requirements.txt
bash calibration/docs/build.sh
```

Open `calibration/docs/build/html/index.html` after the build. The repository does not include ROS bag files, Docker images, or Kalibr source code. The tutorial's commands and paths have not been verified on another machine.
