from setuptools import setup

__version__ = '1.0.0'

setup(
    name='wiki_dump_parser',
    author="Abel 'Akronix' Serrano Juste",
    author_email='akronix5@gmail.com',
    description='A simple but fast python script that reads a XML dump of a \
wiki and output the processed data in a CSV file.',
    license="AGPL-3.0",
    keywords="wiki dump parser Wikia xml csv pandas proccessing history data",
    url='https://github.com/Grasia/wiki-scripts/tree/master/wiki_dump_parser',
    version=__version__,
    py_modules=['wiki_dump_parser'],
    python_requires='>=3',
)
