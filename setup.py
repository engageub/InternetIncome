#!/usr/bin/env python

from setuptools import setup, find_packages
from internetincome import __version__

with open("README.md", "r") as fh:
    long_description = fh.read()

with open("requirements.txt", "r") as fh:
    requirements = fh.read().splitlines()

setup(
    name="internetincome",
    version=__version__,
    author="InternetIncome Team",
    description="Passive Internet Bandwidth Sharing Manager",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/engageub/InternetIncome",
    packages=find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires=">=3.6",
    install_requires=requirements,
    entry_points={
        "console_scripts": [
            "internetincome=internetincome.cli:main",
        ],
    },
    include_package_data=True,
) 