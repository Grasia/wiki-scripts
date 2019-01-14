from setuptools import setup
from os import path

from wiki_dump_parser import __version__


# read the contents of the README file
this_directory = path.abspath(path.dirname(__file__))
with open(path.join(this_directory, 'README.md'), encoding='utf-8') as f:
    long_description = f.read()

setup(
    name='wiki_dump_parser',
    author="Abel 'Akronix' Serrano Juste",
    author_email='akronix5@gmail.com',
    description='A simple but fast python script that reads the XML dump of a \
    wiki and output the processed data in a CSV file.',
    license="AGPL-3.0",
    keywords="wiki dump parser Wikia xml csv pandas proccessing history data",
    url='https://github.com/Grasia/wiki-scripts/tree/master/wiki_dump_parser',
    version=__version__,
    py_modules=['wiki_dump_parser'],
    python_requires='>=3',
    long_description=long_description,
    long_description_content_type='text/markdown'
)
